CREATE OR REPLACE PROCEDURE USP_PLM_COLOR()
RETURNS VARCHAR(256)
LANGUAGE SQL
EXECUTE AS OWNER
AS '
    DECLARE
    DbName VARCHAR(10);
    TableName1 VARCHAR(256);
    TableName2 VARCHAR(256);
    TableName3 VARCHAR (256);

    BEGIN

    SELECT XFRM.SVF_GET_SOURCE_DATABASE(''PLM'') INTO DbName;

    TableName1 := CONCAT(DbName, ''.PLM_PLMUSER.lcscolor'');
    TableName2 := CONCAT(DbName, ''.PLM_PLMUSER.wtuser'');
    TableName3 := CONCAT(DbName, ''.PLM_PLMUSER.wttypedefinition'');

    
    INSERT OVERWRITE INTO RAW.PLM_COLOR

    SELECT
    lcscolor.colorname,
    lcscolor.ida2a2,
    lcscolor.colorhexidecimalvalue,
    lcscolor.thumbnail,
    lcscolor.ida3a7,
    lcscolor.ida3c8,
    lcscolor.statestate,
    lcscolor.createstampa2,
    lcscolor.modifystampa2,
   CASE 
    WHEN LENGTH(wttypedefinition.name) - LENGTH(REPLACE(wttypedefinition.name, ''.'', '''')) >= 2
    THEN SPLIT_PART(
            SPLIT_PART(wttypedefinition.name, ''.'', 3),
            ''_'',
            1
         )
    ELSE wttypedefinition.name
END AS "Type",
    wttypedefinition.branchiditerationinfo,
    lcscolor.ptc_str_1typeinfolcscolor AS "Color",
    SPLIT_PART(TRIM(lcscolor.ptc_str_1typeinfolcscolor), '' '', 1) as "Color ID",
    CASE 
    WHEN originalBrandDisplayName.EN_US IS NOT NULL 
    THEN 
        CASE 
            WHEN originalBrandDisplayName.EN_US = ''Crewcuts''
            THEN ''J.Crew''
            ELSE brandDisplayName.EN_US
        END
    ELSE SPLIT_PART(SPLIT_PART(lcscolor.ptc_str_14typeinfolcscolor, '','', 1), ''|~*~|'', 1)
END AS "Brand",
   
  COALESCE(
    originalBrandDisplayName.EN_US,
    SPLIT_PART(SPLIT_PART(lcscolor.ptc_str_14typeinfolcscolor, '','', 1), ''|~*~|'', 1)
) AS "Original Brand",

    COALESCE(
    genderDisplayName.EN_US,
    SPLIT_PART(SPLIT_PART(lcscolor.ptc_str_10typeinfolcscolor, '','', 1), ''|~*~|'', 1)
) AS "Gender/Age",
    COALESCE(
    seasonDisplayName.EN_US,
    lcscolor.ptc_str_18typeinfolcscolor
) AS "Development Season",
   COALESCE(
    yearDisplayName.EN_US,
    lcscolor.ptc_str_19typeinfolcscolor
) AS "Development Year",
    lcscolor.ptc_str_7typeinfolcscolor AS "Comments",
    lcscolor.ptc_lng_1typeinfolcscolor AS "PLM Color #",
    lcscolor.ptc_str_2typeinfolcscolor AS "Print Pattern Color Description",
    lcscolor.ptc_str_3typeinfolcscolor AS "Description",
    lcscolor.ptc_str_16typeinfolcscolor AS "SAP Code",
    COALESCE(
    departmentDisplayName.EN_US,
    SPLIT_PART(SPLIT_PART(lcscolor.PTC_STR_6TYPEINFOLCSCOLOR, '','', 1), ''|~*~|'', 1)
) AS "Department",
    useDisplayName.EN_US as "Use",
    CASE 
        WHEN 
            "Use" = ''Main Color'' 
            AND "SAP Code" IS NOT NULL
            AND TRIM("SAP Code") != ''''
        THEN ''J.Crew Color''
    END AS "Color Category"
    
    FROM IDENTIFIER(:TableName1) AS lcscolor

    INNER JOIN IDENTIFIER(:TableName3) AS wttypedefinition
        ON lcscolor.branchida2typedefinitionrefe = wttypedefinition.branchiditerationinfo
        AND wttypedefinition.latestiterationinfo = ''1''
        AND lcscolor.branchida2typedefinitionrefe IN (
            ''57262'', ''95934'', ''95624'', ''95795'',
            ''95076'', ''95194'', ''95405'', ''2145998987''
        )
        AND "Type" <> ''com.jcrew.StandardColor_Colors_Color''
        AND lcscolor._fivetran_deleted = FALSE
        AND wttypedefinition._fivetran_deleted = FALSE
    
    LEFT JOIN IDENTIFIER(:TableName2) AS creator
        ON lcscolor.ida3a7 = creator.ida2a2
        AND creator._fivetran_deleted = FALSE
        
    LEFT JOIN IDENTIFIER(:TableName2) AS modifier
        ON lcscolor.ida3c8 = modifier.ida2a2
        AND modifier._fivetran_deleted = FALSE

    LEFT JOIN RAW.PLM_DISPLAYNAME AS useDisplayName
        on lcscolor.ptc_str_11typeInfoLCSColor = useDisplayName.NAME
        and useDisplayName.TYPE = ''jcUse''

    LEFT JOIN RAW.PLM_DISPLAYNAME AS brandDisplayName
    ON SPLIT_PART(SPLIT_PART(lcscolor.ptc_str_14typeinfolcscolor, '','', 1), ''|~*~|'', 1) = brandDisplayName.NAME
    AND brandDisplayName.TYPE = ''brand''

    LEFT JOIN RAW.PLM_DISPLAYNAME AS originalBrandDisplayName
        ON SPLIT_PART(SPLIT_PART(lcscolor.ptc_str_14typeinfolcscolor, '','', 1), ''|~*~|'', 1) = originalBrandDisplayName.NAME
        AND originalBrandDisplayName.TYPE = ''brand''
    
    LEFT JOIN RAW.PLM_DISPLAYNAME AS departmentDisplayName
        ON SPLIT_PART(SPLIT_PART(lcscolor.PTC_STR_6TYPEINFOLCSCOLOR, '','', 1), ''|~*~|'', 1) = departmentDisplayName.NAME
        AND departmentDisplayName.TYPE = ''department''
    
    LEFT JOIN RAW.PLM_DISPLAYNAME AS genderDisplayName
        ON SPLIT_PART(SPLIT_PART(lcscolor.ptc_str_10typeinfolcscolor, '','', 1), ''|~*~|'', 1) = genderDisplayName.NAME
        AND genderDisplayName.TYPE = ''jcGenderAge''
    
    LEFT JOIN RAW.PLM_DISPLAYNAME AS seasonDisplayName
        ON lcscolor.ptc_str_18typeinfolcscolor = seasonDisplayName.NAME
        AND seasonDisplayName.TYPE = ''jcDevelopmentSeason''
    
    LEFT JOIN RAW.PLM_DISPLAYNAME AS yearDisplayName
        ON lcscolor.ptc_str_19typeinfolcscolor = yearDisplayName.NAME
        AND yearDisplayName.TYPE = ''year''

    QUALIFY ROW_NUMBER() over ( partition BY "PLM Color #" order by lcscolor.modifystampa2 ) = 1;

RETURN ''USP_PLM_COLOR created successfully'';

    END
';