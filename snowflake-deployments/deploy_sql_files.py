import os
import sys
import json
import argparse
import snowflake.connector
from cryptography.hazmat.primitives import serialization

# ------------------ Argument Parsing ------------------
parser = argparse.ArgumentParser()
parser.add_argument('--project', required=True)
parser.add_argument('--files', required=True)
parser.add_argument('--config_file', required=True)
parser.add_argument('--key_path', required=True)
parser.add_argument('--replacements', required=False, help="Space-separated replacements, e.g. '_DEV=_PRD DEV_DB=PRD_DB'")
args = parser.parse_args()

# ------------------ Load Config ------------------
if not os.path.isfile(args.config_file):
    print(f"🔴 Config file not found at {args.config_file}")
    sys.exit(1)

with open(args.config_file, 'r') as f:
    all_configs = json.load(f)

if args.project not in all_configs:
    print(f"🔴 Project {args.project} not found in config file.")
    sys.exit(1)

config = all_configs[args.project]
snowflake_conf = config.get("snowflake")
schemas_conf = config.get("schemas")

# ------------------ Load Private Key ------------------
if not os.path.isfile(args.key_path):
    print(f"🔴 Private key file not found at {args.key_path}")
    sys.exit(1)

with open(args.key_path, "rb") as key_file:
    password = config.get("key_password")
    try:
        p_key = serialization.load_pem_private_key(
            key_file.read(),
            password=password.encode() if password else None,
        )
    except Exception as e:
        print(f"🔴 Failed to load private key: {e}")
        sys.exit(1)

private_key_bytes = p_key.private_bytes(
    encoding=serialization.Encoding.DER,
    format=serialization.PrivateFormat.PKCS8,
    encryption_algorithm=serialization.NoEncryption(),
)

# ------------------ Connect to Snowflake ------------------
conn = snowflake.connector.connect(
    user=snowflake_conf['user'],
    account=snowflake_conf['account'].split('.')[0],
    private_key=private_key_bytes,
    role=snowflake_conf['role'],
    warehouse=snowflake_conf['warehouse'],
    database=snowflake_conf['database']
)
cursor = conn.cursor()

# ------------------ Replacements Dictionary ------------------
replacements = {}

# From CLI args
if args.replacements:
    for pair in args.replacements.split():
        if '=' in pair:
            k, v = pair.split('=', 1)
            replacements[k] = v

# From config db_replacements
config_replacements = config.get("db_replacements", {})
replacements.update(config_replacements)

# ------------------ Function to Run SQL ------------------
def run_sql_script(cursor, script_path, schema, replacements):
    with open(script_path, 'r') as f:
        sql = f.read()
    for old, new in replacements.items():
        sql = sql.replace(old, new)
    print(f"📄 Executing {script_path} in schema [{schema}] with replacements: {replacements}")
    cursor.execute(f"USE SCHEMA {schema};")
    cursor.execute(sql)

# ------------------ Changed Files ------------------
changed_files = args.files.split()
deployed_any = False
base_project = args.project.split('_')[0].upper()

# ------------------ Handle ADHOC.sql ------------------
adhoc_path = os.path.join("projects", base_project, "ADHOC.sql")
if adhoc_path in changed_files:  # ✅ Only run if in changed files
    if os.path.isfile(adhoc_path):
        print(f"📌 ADHOC.sql detected in changes, executing first...")
        try:
            with open(adhoc_path, 'r') as f:
                adhoc_sql = f.read()
            for old, new in replacements.items():
                adhoc_sql = adhoc_sql.replace(old, new)
            print(f"📄 Running ADHOC.sql with replacements: {replacements}")
            cursor.execute(adhoc_sql)
            print("✅ ADHOC.sql executed successfully.")
            deployed_any = True
        except Exception as e:
            print(f"❌ Failed executing ADHOC.sql: {e}")
            cursor.close()
            conn.close()
            sys.exit(1)
    else:
        print(f"⚠️ ADHOC.sql listed as changed but not found locally.")
else:
    print("ℹ️ ADHOC.sql not in changed files, skipping.")

# ------------------ Deploy Changed Files in Priority Order ------------------
object_priority = [
    "STREAM",
    "TABLE",
    "DYNAMIC_TABLE",
    "VIEW",
    "MATERIALIZED_VIEW",
    "FUNCTION",
    "PROCEDURE",
    "TASK"
]

# Group files by object type
files_by_type = {obj_type: [] for obj_type in object_priority}

for file_path in changed_files:
    if file_path == adhoc_path:  # ✅ Skip ADHOC here, already handled
        continue

    parts = file_path.split('/')
    if len(parts) < 4:  # projects/<project>/<schema>/<object_type>/file.sql
        print(f"⚠️ WARNING: Skipping invalid path: {file_path}")
        continue

    project_folder = parts[1]        # MARKETING
    schema_folder = parts[2]         # RPT
    object_type = parts[3].upper()   # TABLE / VIEW / STREAM / etc.

    # Normalize names
    if object_type in ["MATERIALIZEDVIEW", "MATERIALIZED-VIEW"]:
        object_type = "MATERIALIZED_VIEW"
    elif object_type in ["DYNAMICTABLE", "DYNAMIC-TABLE"]:
        object_type = "DYNAMIC_TABLE"
    elif object_type.endswith("S"):  # allow plural
        object_type = object_type[:-1]

    if project_folder.upper() != base_project:
        print(f"⚠️ Skipping file not in current project: {file_path}")
        continue

    folder_info = schemas_conf.get(schema_folder)
    if not folder_info:
        print(f"⚠️ WARNING: No config for schema folder '{schema_folder}', skipping {file_path}")
        continue

    schema = folder_info.get('schema')
    if not schema:
        print(f"⚠️ WARNING: Schema not defined for {schema_folder}, skipping {file_path}")
        continue

    if object_type not in files_by_type:
        print(f"⚠️ WARNING: Unknown object type '{object_type}', skipping {file_path}")
        continue

    files_by_type[object_type].append((file_path, schema))

# Deploy in fixed order
for obj_type in object_priority:
    for file_path, schema in files_by_type[obj_type]:
        if not os.path.exists(file_path):
            print(f"⚠️ File {file_path} does not exist locally, skipping.")
            continue
        try:
            run_sql_script(cursor, file_path, schema, replacements)
            print(f"✅ Deployed: {file_path}")
            deployed_any = True
        except Exception as e:
            print(f"❌ Failed deploying {file_path}: {e}")
            cursor.close()
            conn.close()
            sys.exit(1)

cursor.close()
conn.close()

if deployed_any:
    print("🎉 Deployment Complete in priority order")
else:
    print("ℹ️ No valid files to deploy.")
