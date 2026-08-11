create or replace view VW_PLM_PRODUCT(
	"PLM Product #",
	"Brand",
	"Original Brand",
	"Sourcing Department",
	"Sub-Brand",
	"Gender/Age",
	"Product Name",
	"Product Description",
	"Sourcing Team",
	"R-N-D Development",
	"Wash Comments",
	"Product Creator",
	"Product Created On",
	"Size Category Parent",
	"Approved to Make Photo Sample",
	"HTS Comments",
	"Unable to Provide HTS"
) as
select 
   "PLM Product #",
   "Brand",
    "Original Brand",
    "Sourcing Department",
    "Sub-Brand",
    "Gender/Age",
    "Product Name",
    "Product Description",
    "Sourcing Team",
    "R-N-D Development",
    "Wash Comments",
     "Product Creator",
    "Product Created On",
    "Size Category Parent",
    "Approved to Make Photo Sample",
    "HTS Comments",
    "Unable to Provide HTS"
from 
    raw.PLM_Product;