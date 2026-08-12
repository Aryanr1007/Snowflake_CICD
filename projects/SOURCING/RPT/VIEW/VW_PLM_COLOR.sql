create or replace view VW_PLM_COLOR(
	"PLM Color #",
	"Brand",
	"Original Brand",
	"Gender/Age",
	"Department",
	"Development Season",
	"Development Year",
	"Color",
	"Color ID",
	"Comments",
	"Print Pattern Color Description",
	"Description",
	-- "SAP Code",
	"Color Category"
) as
SELECT 
"PLM Color #",
"Brand",
"Original Brand",
"Gender/Age",
"Department",
"Development Season",
"Development Year",
 "Color",
 "Color ID",
"Comments",
"Print Pattern Color Description",
"Description",
-- "SAP Code",
"Color Category"

FROM
RAW.PLM_COLOR;
