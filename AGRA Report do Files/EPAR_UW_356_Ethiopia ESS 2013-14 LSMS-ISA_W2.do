
/*-----------------------------------------------------------------------------------------------------------------------------------------------------
*Title/Purpose 	: This do.file was developed by the Evans School Policy Analysis & Research Group (EPAR) 
				  to categorize smallholder farm households based on their degree of crop commercialization and livelihood diversification
				  and to generate summary statistics for households in different categories of commercialization
				  using the Ethiopia Socioeconomic Survey (ESS) LSMS-ISA Wave 2 (2013-14)
*Author		    : Pierre Biscaye

*Date			: 31 October 2017

----------------------------------------------------------------------------------------------------------------------------------------------------*/

*Data source
*-----------
*The Ethiopia Socioeconomic Survey was collected by the Ethiopia Central Statistical Agency (CSA) 
*and the World Bank's Living Standards Measurement Study - Integrated Surveys on Agriculture(LSMS - ISA)
*The data were collected over the period September to October 2013, November to December 2013, and February to April 2014. 
*All the raw data, questionnaires, and basic information documents are available for downloading free of charge at the following link
*http://microdata.worldbank.org/index.php/catalog/2247

*We also use a separate data file prepared by the Bill & Melinda Gates Foundation which uses ESS data to categorize households according to whether they live in areas with high or low market and agricultural potential. We provide this data file separately from the raw World Bank data.

*Throughout the do-file, we sometimes use the shorthand LSMS to refer to the Ethiopia Socioeconomic Survey.

*Summary of Executing the Master do.file
*-----------
*This Master do.file constructs selected indicators using the Ethiopia ESS (ETH LSMS) data set.
*First save the raw unzipped data files from the World Bank in a new "input" folder that you must create. Do not change the structure or organization of the unzipped raw data files. 
*Also download and save the "Ethiopia_W2_AgDev_Farmer Segmentation.dta" file in this folder (from the GitHub repository "AGRA Report Supplemental dta Files" folder).
*The do. file constructs needed intermediate variables, saving dta files when appropriate in "merge" and "collapse" folders that you will need to create.

*The code first generates needed intermediate and final variables from the agriculture, livestock, and household questionnaires.
*These data files are then aggregated and cleaned for analysis at the household level, including construction of a farmer typology variable and estimation of summary statistics. We then output selected variables for use in the Project 356 data visualization on the EPAR website.


*********************************
/*OUTLINE of .do file contents
*********************************

1.1 Prepare Ag Questionnaire Data at Household Level, collapse to holder level
1.2 Prepare Ag Questionnaire Data at Field Level, collapse to holder level
1.3 Prepare Ag Questionnaire Data at Field-Crop Level, collapse to crop level
1.4 Prepare Ag Questionnaire Data at Crop Level, collapse to holder level
1.5 Merge Ag Questionnaire Data at Holder Level, collapse to household level
	created file: "$merge\sect_ag_HH_w2_merge.dta"
	
2.1 Prepare Livestock Questionnaire Data at Livestock and Livestock by-product levels, collapse to holder level
2.2 Merge Livestock Questionnaire Data at Holder Level, collapse to household level
	created file: "$merge\sect_ls_hh_w2_merge.dta"
	
3.1 Prepare Household Questionnaire Income Data: Individual-Level Household Income, collapse to household level
3.2 Prepare Household Questionnaire Income Data: Non-Farm Enterprise Income, collapse to household level
3.3 Prepare Household Questionnaire Income Data: Other Income and Assistance, collapse to household level
3.4 Merge Household Questionnaire Data at Household Level
	created file: "$merge\sect_hh_info_w2_merge.dta"
	
4.1 Prepare for Analysis, Merge Data at Household level, Trim and Clean Data, Create New Variables
	created files: "$merge/et2_merged_raw.dta", "$merge/et2_merged_trimmed.dta", "$merge\et2_merged_analysis.dta"
4.2 Summary Statistics
4.3 Output data for visualizations

*/ 

*********************************
*** Directories and Paths     ***
*********************************
clear
clear matrix
clear mata
program drop _all
set more off

*NOTE: You will have to update the global macros below

*Add names of specific folders here
global input "desired filepath/raw data folder name"
global merge "desired filepath/created merged data folder name"
global collapse "desired filepath/created collapsed data folder name" 

///////////////////////////////////////////////
///		1.1 Prepare Ag Questionnaire Data	///
///		Prepare Data at Household Level		///
///		Collapse to Holder level			///
///////////////////////////////////////////////
{
***********************************************
//Post-planting Ag Questionnaire Cover (front page)//

clear
use "$input\Post-Planting\sect_cover_pp_w2.dta"
**This dataset is at the household level

rename pp_saq13 farm_type
keep holder_id household_id household_id2 ea_id ea_id2 rural pw2 saq01 saq02 saq03 saq04 saq05 saq06 pp_saq07 farm_type

save "$collapse\sect_cover_pp_w2_collapse.dta", replace

***********************************************
//Post-planting Ag Questionnaire Household Roster

clear
use "$input\Post-Planting\sect1_pp_w2.dta"
**This dataset is at the individual level

gen holder_sex_fem=.
replace holder_sex_fem=pp_s1q03 if pp_s1q00==pp_saq07 //set sex to sex of individual if individual is the "holder"/head of household
recode holder_sex_fem 1=0 2=1

gen holder_age=.
replace holder_age=pp_s1q02 if pp_s1q00==pp_saq07 //set age to age of individual if individual is the "holder"/head of household

//collapse to household level
collapse (max) holder_sex_fem holder_age, by(holder_id)
la var holder_sex_fem "Sex of holder of HH, 1=female"
la var holder_age "Age of holder of HH, years"

save "$collapse\sect1_pp_w2_collapse.dta", replace
	
***********************************************
//Post-planting Ag Questionnaire Seed Roster

clear
use "$input\Post-Planting\sect5_pp_w2.dta"
**Data are at crop-seed level

**Cost of purchased seed: transport cost + cost of the seed
gen seed_purchased_cost=0
replace seed_purchased_cost=pp_s5q08 if pp_s5q08!=. //value of all purchased seed
replace seed_purchased_cost=seed_purchased_cost+pp_s5q07 if pp_s5q07!=. //add cost of transportation to acquire seed

**Data also includes information on free and leftover seed, but only counting purchased inputs for this analysis

//collapse to household level
collapse (sum) seed_purchased_cost, by(holder_id) //collapse all seed purchase costs to HH level
la var seed_purchased_cost "Value of all seed purchased during current ag season (pp_s5q08), birr"

save "$collapse\sect5_pp_w2_collapse.dta", replace
}

///////////////////////////////////////////////
///		1.2 Prepare Ag Questionnaire Data	///
///		Prepare Data at Field Level			///
///		Collapse to Holder level			///
///////////////////////////////////////////////
{
***********************************************
//Post-planting Ag Questionnaire Parcel Roster

clear
use "$input\Post-Planting\sect2_pp_w2.dta"
**These data are at the parcel level

//Land rental cost and income (birr)
gen land_rental_cost=.
replace land_rental_cost=pp_s2q07_a //payment in cash
replace land_rental_cost=0 if land_rental_cost==.
replace land_rental_cost=land_rental_cost+pp_s2q07_b if pp_s2q07_b!=. //add estimated value of payment in kind
la var land_rental_cost "How much did you pay for use of [PARCEL], cash and in-kind value"

gen land_rental_income=.
replace land_rental_income=pp_s2q13_a //receipts in cash
replace land_rental_income=0 if land_rental_income==.
replace land_rental_income=land_rental_income+pp_s2q13_b if pp_s2q13_b!=. //add estimated value of receipts in kind
la var land_rental_income "How much did you receive for renting out this [PARCEL], cash and in-kind value"

//Collapse to household level
collapse (sum) land_rental_cost land_rental_income, by (holder_id) 
la var land_rental_cost "sum(land_rental_cost) How much did you pay for use of [PARCEL], cash and in-kind value"
la var land_rental_income "sum(land_rental_income), How much did you receive for renting out this [PARCEL], cash and in-kind value"

save "$collapse\sect2_pp_w2_collapse.dta", replace

***********************************************
//Post-planting Ag Questionnaire Field Roster

clear
use "$input\Post-Planting\sect3_pp_w2.dta"
**These data are at the field level

**Number of fields
egen number_fields = count(field_id), by(holder_id)
la var number_fields "Total number of fields per household"

**Field area
//Farmer-reported field area is measured in several units for which conversion factors are not available, so we cannot calculate field area in ha for ~1/3 of observations
gen field_area_fr_ha=.
replace field_area_fr_ha=pp_s3q02_a if pp_s3q02_c==1 | pp_s3q02_c==2 //only use reports in hectares or square meters; don't have file with conversion factors for local units
replace field_area_fr_ha=field_area_fr_ha*.0001 if pp_s3q02_c==2 //convert square meters to hectares
la var field_area_fr_ha "Area of field, farmer reported if used standard units, in hectares pp_s3q02"

//GPS-calculated field area in square meters is available for 95.8% of fields, so this is our best bet for field area
gen field_area_gps_ha=.
replace field_area_gps_ha=pp_s3q05_a*.0001
replace field_area_gps_ha=. if field_area_gps_ha==0 //replace 0 area observations with missings (430 observations)
la var field_area_gps_ha "Area of field, measured by GPS, in hectares pp_s3q05_a"

//Replace missing GPS area with farmer-reported, if available
gen field_area_ha=.
replace field_area_ha=field_area_gps_ha
replace field_area_ha=field_area_fr_ha if field_area_ha==. & field_area_fr_ha!=.
la var field_area_ha "field area measure, ha - GPS-based if they have one, farmer-report if not"

**Total area cultivated
//identify which fields are cultivated
gen landuse_cultivated=.
replace landuse_cultivated = 1 if pp_s3q03==1
replace landuse_cultivated = 0 if pp_s3q03!=1 & pp_s3q03!=.
label var landuse_cultivated "During this season, was this field cultivated (pp_s3q03)"
//take those fields and find their area - all other plots should be 0 or .
gen field_area_cultivated=field_area_ha if landuse_cultivated==1 & field_area_ha!=. //11,677 missing values generated
la var field_area_cultivated "Field area, cultivated fields, ha, based on pp_s3q03"

**Total farm land
gen landuse_farm=.
replace landuse_farm = 0 if pp_s3q03!=.
replace landuse_farm = 1 if pp_s3q03==1 | pp_s3q03==2 | pp_s3q03==3 | pp_s3q03==5 //cultivated, pasture, fallow, or prepared for belg season (excluded forest, home/homestead, and other
label var landuse_farm "Field is farm or pasture land (pp_s3q03)"
//take those fields and find their area - all other plots should be 0 or .
gen field_area_farm=field_area_ha if landuse_farm==1 & field_area_ha!=. //10,662 missing values generated
la var field_area_farm "Field area, farm or pasture land, ha, based on pp_s3q03"

**Value of purchased inorganic fertilizer 
//pp_s3q16d value of all purchased urea
//pp_s3q19d value of all purchased DAP
//pp_s3q20c value of all other purchased inorganic fertilizer
gen urea_value=0
replace urea_value=pp_s3q16d if pp_s3q16d!=.
gen dap_value=0
replace dap_value=pp_s3q19d if pp_s3q19d!=.
gen otherinorgfert_value=0
replace otherinorgfert_value=pp_s3q20c if pp_s3q20c!=.

gen inorgfert_purchased_value=urea_value+dap_value+otherinorgfert_value
la var inorgfert_purchased_value "sum of purchased value for urea, DAP, and other inorganic fertilizer, birr"

egen total_inorgfert_purchased_value = sum(inorgfert_purchased_value) if inorgfert_purchased_value!=., by(holder_id)
la var total_inorgfert_purchased_value "sum of total purchased value for inorganic fertilizer, birr"

save "$collapse\sect3_pp_w2_collapseprep.dta", replace

***************************************
//Collapse to Household level
local sumcollapse field_area_ha field_area_cultivated field_area_farm
local maxcollapse number_fields total_inorgfert_purchased_value

collapse (max) `maxcollapse' (sum) `sumcollapse', by (holder_id)

la var number_fields "Total number of fields per household"
la var field_area_ha "sum(field_area_ha), field area measure, ha - GPS-based if they have one, farmer-report if not"
la var field_area_cultivated "Field area, cultivated fields, ha, based on pp_s3q03"
la var field_area_farm "(sum)Field area, farm or pasture land, ha, based on pp_s3q03"
la var total_inorgfert_purchased_value "sum of total purchased value for inorganic fertilizer, birr"

save "$collapse\sect3_pp_w2_collapse.dta", replace
}

///////////////////////////////////////////////
///		1.3 Prepare Ag Questionnaire Data	///
///		Prepare Data at Field-Crop Level	///
///		Collapse to Crop level				///
///////////////////////////////////////////////
{
//start with field roster from post-planting questionnaire to have info on area
clear
use "$collapse\sect3_pp_w2_collapseprep.dta"
**These data are at the field level; merge in other data at field-crop level

***********************************************
//4. Post-planting Ag Questionnaire Field-Crop Roster
merge 1:m holder_id parcel_id field_id using "$input\Post-Planting\sect4_pp_w2.dta", generate (_merge4pp2)
	//matched: 29,775
	//not matched from master: 10,495 //all but 152 are fields not used for cultivation
	//not matched from using: 60
**The data are at the field-crop level

***********************************************
//9. Post-harvest Ag Questionnaire Crop Harvest by Field
merge 1:1 holder_id parcel_id field_id crop_code using "$input\Post-Harvest\sect9_ph_w2.dta", generate (_merge9ph2)
	//matched: 29,563
	//not matched from master: 10,767 //all but 408 observations are on fields not used for cultivation; 10,495 have missing crop codes so did not plant
	//not matched from using: 12

***********************************************
//10. Post-harvest Ag Questionnaire Harvest Labor
merge 1:1 holder_id parcel_id field_id crop_code using "$input\Post-Harvest\sect10_ph_w2.dta", generate (_merge10ph2)
	//matched: 29,575
	//not matched from master: 10,767 //10,495 have missing crop codes so did not plant
	//not matched from using: 0

***********************************************
//Prepare Variables and Collapse

//Area planted (ha)
gen percent_field_plant=.
replace percent_field_plant=pp_s4q03 //approximately how much of field was planted with crop, %
replace percent_field_plant=100 if pp_s4q02==1 //replace with 100% if pure stand
replace percent_field_plant=percent_field_plant/100 //convert to percent
bys holder_id parcel_id field_id: egen total_percent_field = total(percent_field_plant)
replace percent_field_plant = percent_field_plant/total_percent_field if total_percent_field>1 //rescale for fields with total area to crops greater than total field area, 254 changes
la var percent_field_plant "percent of field planted with crop (pp_s4q03 and pp_s4q02)"

gen area_plant_ha = .
replace area_plant_ha = field_area_ha * percent_field_plant //values for 28,382 of 40,342 obs - missing values for 199 fields reported as cultivated and for which we have an area measure
la var area_plant_ha "Area Planted of Field with [CROP], field_area_ha * percent planted"

//Area harvested (ha)
gen percent_harvested=.
replace percent_harvested=1 if ph_s9q08==2 //100% is harvested if they answered "no" to "Was area harvested less than area planted?"
replace percent_harvested=ph_s9q09*.01 if ph_s9q08==1  //replace with % harvested if they answered "yes" to "Was area harvested less than area planted?", change percent to proportion
replace percent_harvested=. if percent_harvested>1 //1 change, had reported harvesting 801% of area planted
la var percent_harvested "Percent of area planted that has been harvested ph_s9q09"

gen area_harv_ha = .
replace area_harv_ha = area_plant_ha*percent_harvested
replace area_harv_ha=0 if ph_s9q03==2 //set 0 if they did not harvest [crop] from [field], 3,359 changes
la var area_harv_ha "Area harvested (area planted * percent_harvested)"

//Quantity harvested (kg)
gen harvest_weight_kg=.
replace harvest_weight_kg=ph_s9q05
replace harvest_weight_kg=ph_s9q04_a if ph_s9q04_b==1 //replace with first quantity reported, if that quantity also in kgs
la var harvest_weight_kg "Estimated weight of crop harvested in kilograms ph_s9q05"

//Labor costs
*according to questionnaire, wage is "per person per day", but appears to be "per day, for all workers", so dividing wage by # of workers to get wage/person/day then multiplying by number of person days
gen wage_male_pp = pp_s3q28_c/pp_s3q28_a		
gen wage_female_pp = pp_s3q28_f/pp_s3q28_d	
gen wage_child_pp = pp_s3q28_i/pp_s3q28_g		
recode wage_male_pp wage_female_pp wage_child_pp (0=.)		// if they are "hired" but don't get paid, we don't want to consider that a wage observation below

gen value_male_hired_pp = wage_male_pp*pp_s3q28_b			// average wage times number of days
gen value_female_hired_pp = wage_female_pp*pp_s3q28_e
gen value_child_hired_pp = wage_child_pp*pp_s3q28_h

*according to questionnaire, wage is "per person per day"
gen wage_male_ph = ph_s10q01_c/ph_s10q01_a
gen wage_female_ph = ph_s10q01_f/ph_s10q01_d
gen wage_child_ph = ph_s10q01_i/ph_s10q01_g
recode wage_male_ph wage_female_ph wage_child_ph (0=.)		// if they are "hired" but don't get paid, we don't want to consider that a wage observation

gen value_male_hired_ph = wage_male_ph*ph_s10q01_b
gen value_female_hired_ph = wage_female_ph*ph_s10q01_e
gen value_child_hired_ph = wage_child_ph*ph_s10q01_h

egen value_hired_labor = rowtotal(value_male_hired_pp value_female_hired_pp value_child_hired_pp value_male_hired_ph value_female_hired_ph value_child_hired_ph)

//not valuing household or free labor

save "$collapse\sect_ag_field_crop_w2.dta", replace

//generate crop-level totals

//Collapse to crop level
collapse (sum) area_plant_ha area_harv_ha harvest_weight_kg, by (holder_id crop_code)
la var area_plant_ha "sum by crop, Area Planted of Field with [CROP], field_area_ha * percent planted"
la var area_harv_ha "sum by crop, Area harvested (area planted * percent_harvested)"
la var harvest_weight_kg "sum by crop, Estimated weight of crop harvested in kilograms ph_s9q05"

drop if crop_code==.

save "$collapse\sect_ag_field_crop_w2_cropcollapse.dta", replace

***************************
//Labor costs
use "$collapse\sect_ag_field_crop_w2.dta", replace
collapse (sum) value_hired_labor, by (holder_id)
la var value_hired_labor "value of all hired labor on plots, birr"
save "$collapse\sect_ag_field_labor_w2_collapse.dta", replace

}

///////////////////////////////////////////////
///		1.4 Prepare Ag Questionnaire Data	///
///		Prepare Data at Crop Level			///
///		Collapse to Holder level			///
///////////////////////////////////////////////
{
***********************************************
//11. Post-harvest Ag Questionnaire Crop Disposition/Sales

** Basic Information Document says that there were errors in the data collection for Section 11 of the Post Harvest Survey - duplication of certain observations
clear
use "$input\Post-Harvest\sect11_ph_w2.dta"
duplicates tag household_id2 holder_id crop_code, gen(duptag) //identify duplicate observations
drop if duptag!=0 //drop observations if not unique; 150 observations dropped: 138 repeated 1 times, 12 repeated 2 times
drop duptag

save "$collapse\sect_ph11_w2_collapse.dta", replace

***********************************************
//12. Post-harvest Ag Questionnaire Crop Disposition/Sales (tree/fruit/vegetable/root crops)

** Basic Information Document says that there were errors in the data collection for Section 11 of the Post Harvest Survey - duplication of certain observations
clear
use "$input\Post-Harvest\sect12_ph_w2.dta"
duplicates tag household_id2 holder_id crop_code, gen(duptag) //identify duplicate observations
drop if duptag!=0 //drop observations if not unique; 239 observations dropped: 206 repeated 1 times, 21 repeated 2 times, 12 repeated 3 times
drop duptag

save "$collapse\sect_ph12_w2_collapse.dta", replace

***********************************************
//Merge, starting with collapsed field-crop level data at crop level
clear
use "$collapse\sect_ag_field_crop_w2_cropcollapse.dta"

merge 1:1 holder_id crop_code using "$collapse\sect_ph11_w2_collapse.dta", generate (_merge11ph2)
	//Matched: 9,322
	//not matched from master: 9,003 //2,100 have 0 harvested area, most others are tree/fruit/vegetable/root crops from section 12
	//not matched from using: 2

merge m:1 holder_id crop_code using "$collapse\sect_ph12_w2_collapse.dta", generate (_merge12ph2)
	//Matched: 7,286
	//not matched from master: 11,041 //1,956 have 0 harvested area, most others are annual crops from section 11
	//not matched from using: 0

//1,780 crop observations not matched, 1363 have 0 harvested weight, 1391 have 0 harvested area

***********************************************
//Prepare variables

drop if crop_code==.

//Annual crop sales
gen annual_crop_sold_qty=0
replace annual_crop_sold_qty=ph_s11q03_a if ph_s11q03_a!=. //kilograms sold
replace annual_crop_sold_qty=annual_crop_sold_qty+ph_s11q03_b/1000 if ph_s11q03_b!=. //add quantity in grams sold
la var annual_crop_sold_qty "Quantity of [annual crop] sold, kgs" 

gen annual_crop_sold_value=0
replace annual_crop_sold_value=ph_s11q04 if ph_s11q04!=. //total estimated value of sales (including cash and in kind), birr
la var annual_crop_sold_value "Total value of all [annual crop] sales, birr"

gen annual_crop_sold_price=.
replace annual_crop_sold_price=annual_crop_sold_value/annual_crop_sold_qty if annual_crop_sold_qty!=. & annual_crop_sold_value!=.
la var annual_crop_sold_price "Imputed price of [annual crop], birr/kg"

//Tree/fruit/vegetable/root crop sales
gen permfrt_crop_sold_qty=0
replace permfrt_crop_sold_qty=ph_s12q07 if ph_s12q07!=. //kilograms sold
la var permfrt_crop_sold_qty "Quantity of [tree/fruit/root crop] sold, kgs" 

gen permfrt_crop_sold_value=0
replace permfrt_crop_sold_value=ph_s12q08 if ph_s12q08!=. //total estimated value of sales (including cash and in kind), birr
la var permfrt_crop_sold_value "Total value of all [tree/fruit/root crop] sales, birr"

gen permfrt_crop_sold_price=.
replace permfrt_crop_sold_price=permfrt_crop_sold_value/permfrt_crop_sold_qty if permfrt_crop_sold_qty!=. & permfrt_crop_sold_value!=.
la var permfrt_crop_sold_price "Imputed price of [tree/fruit/root crop], birr/kg"

//Crop prices

*Imputed unit price, any crop - household level
gen unit_price=.
replace unit_price=annual_crop_sold_price if annual_crop_sold_price!=.
replace unit_price=permfrt_crop_sold_price if permfrt_crop_sold_price!=.
la var unit_price "Imputed price of [crop], birr/kg"

*Some households do not sell any of particular crops, so do not have impute HH-level prices for the crop
*To be able to estimate the value of these crops, we need to apply prices at higher levels. 
*Calculate median price at different levels, based on imputed prices of households reporting sales
egen ea_median_price=median(unit_price), by(crop_code saq01 saq02 saq03 saq04 ea_id2)
egen kebele_median_price=median(unit_price), by(crop_code saq01 saq02 saq03 saq04)
egen woreda_median_price=median(unit_price), by(crop_code saq01 saq02 saq03)
egen zone_median_price=median(unit_price), by(crop_code saq01 saq02)
egen region_median_price=median(unit_price), by(crop_code saq01)
egen nation_median_price=median(unit_price), by(crop_code)

*Calculate count of prices at different levels
egen ea_median_price_ct=count(unit_price), by(crop_code saq01 saq02 saq03 saq04 ea_id2)
egen kebele_median_price_ct=count(unit_price), by(crop_code saq01 saq02 saq03 saq04)
egen woreda_median_price_ct=count(unit_price), by(crop_code saq01 saq02 saq03)
egen zone_median_price_ct=count(unit_price), by(crop_code saq01 saq02)
egen region_median_price_ct=count(unit_price), by(crop_code saq01)
egen nation_median_price_ct=count(unit_price), by(crop_code)

//Harvest crop values

*Calculate value of harvested crop using the imputed price at lowest possible level with at least 10 non-missing observations, if no household-level imputed price is available
gen value_of_harvest=.
replace value_of_harvest=harvest_weight_kg*unit_price //estimated [crop] harvest value for households reporting sales of [crop]
replace value_of_harvest=harvest_weight_kg*ea_median_price if value_of_harvest==. & ea_median_price_ct>=10 //estimate [crop] value for households missing values in EAs with at least 10 HHs with imputed price, 5688 changes
replace value_of_harvest=harvest_weight_kg*kebele_median_price if value_of_harvest==. & kebele_median_price_ct>=10 //estimate [crop] value for households missing values in kebeles with at least 10 HHs with imputed price, 10 changes
replace value_of_harvest=harvest_weight_kg*woreda_median_price if value_of_harvest==. & woreda_median_price_ct>=10 //estimate [crop] value for households missing values in woredas with at least 10 HHs with imputed price, 1070 changes
replace value_of_harvest=harvest_weight_kg*zone_median_price if value_of_harvest==. & zone_median_price_ct>=10 //estimate [crop] value for households missing values in zones with at least 10 HHs with imputed price, 4527 changes
replace value_of_harvest=harvest_weight_kg*region_median_price if value_of_harvest==. & region_median_price_ct>=10 //estimate [crop] value for households missing values in regions with at least 10 HHs with imputed price, 1,404 changes
replace value_of_harvest=harvest_weight_kg*nation_median_price if value_of_harvest==. & nation_median_price_ct>=10 //estimate [crop] value for households missing values with at least 10 HHs with imputed price in the country, 472 changes
replace value_of_harvest=harvest_weight_kg*nation_median_price if value_of_harvest==. //estimate [crop] value for households missing values with any HH with imputed price in the country, 472 changes
//only 17 observations remain with a non-missing harvest_weight_kg but no value_of_harvest, implying no households in the country sold that crop

//Sales transport costs
gen cost_sales_transport=ph_s11q09

save "$collapse\sect_ag_crop_w2.dta", replace

***********************************************
//Collapse
collapse (sum) value_of_harvest annual_crop_sold_value permfrt_crop_sold_value area_plant_ha area_harv_ha cost_sales_transport, by (holder_id)
la var value_of_harvest "sum(value_of_harvest), harvest_weight_kg*imputed price at lowest level with >=3 price observations"
la var annual_crop_sold_value "sum(annual_crop_sold_value) Total value of all annual crop sales, birr"
la var permfrt_crop_sold_value "sum(permfrt_crop_sold_value) Total value of all tree/fruit/root crop sales, birr"
la var area_plant_ha "sum(area_plant_ha) total area planted, ha"
la var area_harv_ha "sum(area_harv_ha) total area harvested, ha"
la var cost_sales_transport "sum of costs for transport for crop sales, birr"

gen value_crop_sales=0
replace value_crop_sales=annual_crop_sold_value if annual_crop_sold_value!=.
replace value_crop_sales=value_crop_sales+permfrt_crop_sold_value if permfrt_crop_sold_value!=.
la var value_crop_sales "Total value of all crop sales, birr"

*replace value of harvest with total value of all crop sales, if total value of all crop sales is greater
replace value_of_harvest=value_crop_sales if value_of_harvest<value_crop_sales & value_crop_sales!=. //24 changes

save "$collapse\sect_ag_crop_w2_collapse.dta", replace
}

///////////////////////////////////////////////
///		1.5 Prepare Ag Questionnaire Data	///
///		Merge at Holder level				///
///		Collapse to Household level			///
///////////////////////////////////////////////
{
clear
use "$collapse\sect_cover_pp_w2_collapse.dta"

merge 1:1 holder_id using "$collapse\sect1_pp_w2_collapse.dta", gen (_merge1pp2)
	//not matched: 0
	//matched: 3,779
	
merge 1:1 holder_id using "$collapse\sect5_pp_w2_collapse.dta", generate (_merge5pp2)
	//not matched: 599; 163 non-ag HHs, 245 livestock only HHs, 191 other HHs did not report on purchased seed
	//matched: 3,180
	
merge 1:1 holder_id using "$input\Post-Planting\sect7_pp_w2.dta", generate (_merge7pp2)
	//not matched: 0
	//matched: 3,779
	
merge 1:1 holder_id using "$collapse\sect2_pp_w2_collapse.dta", generate (_merge2pp2)
	//not matched: 54; all 54 are livestock only or none for farm type
	//matched: 3,725
	
merge 1:1 holder_id using "$collapse\sect3_pp_w2_collapse.dta", generate (_merge3pp2)
	//not matched: 56; all but 1 are livestock only or none for farm type
	//matched: 3,723

merge 1:1 holder_id using "$collapse\sect_ag_crop_w2_collapse.dta", generate (_mergeph2)
	//not matched: 519; 2 from using, 517 from master, households that did not report harvesting or harvested 0 weight
	//matched: 3,262
	
merge 1:1 holder_id using "$collapse\sect_ag_field_labor_w2_collapse.dta", generate (_mergeph3a)
	//not matched: 56; all but 1 are livestock only or none for farm type
	//matched: 3,725

save "$merge\sect_ag_holder_w2_collapseprep.dta", replace

*****************************************
//Collapse to household level
local max_vars farm_type
local sum_vars seed_purchased_cost land_rental_cost land_rental_income number_fields field_area_ha /*
*/field_area_cultivated field_area_farm total_inorgfert_purchased_value value_of_harvest annual_crop_sold_value permfrt_crop_sold_value /*
*/area_plant_ha area_harv_ha cost_sales_transport value_crop_sales value_hired_labor

collapse (max) `max_vars' (sum) `sum_vars', by (household_id2)

la var farm_type "What is farm type? 1=crop 2=livestock 3=both 4=none"
la var seed_purchased_cost "(sum)Value of all seed purchased during current ag season (pp_s5q08), birr"
la var land_rental_cost "(sum) How much did you pay for use of [PARCEL], cash and in-kind value"
la var land_rental_income "(sum) How much did you receive for renting out this [PARCEL], cash and in-kind value"
la var number_fields "(sum) Total number of fields per household"
la var field_area_ha "(sum) field area measure, ha - GPS-based if they have one, farmer-report if not"
la var field_area_cultivated "(sum) Field area, cultivated fields, ha, based on pp_s3q03"
la var field_area_farm "(sum) Field area, farm or pasture land, ha, based on pp_s3q03"
la var total_inorgfert_purchased_value "(sum) total purchased value for inorganic fertilizer, birr"
la var value_of_harvest "(sum) Estimated harvest value (all crops), based on harvest weight*imputed price"
la var annual_crop_sold_value "(sum) Total value of all annual crop sales, birr"
la var permfrt_crop_sold_value "(sum) Total value of all tree/fruit/root crop sales, birr"
la var area_plant_ha "(sum) total area planted, ha"
la var area_harv_ha "(sum) total area harvested, ha"
la var cost_sales_transport "(sum) cost of transport for crop sales, birr"
la var value_crop_sales "(sum) Total value of all crop sales, birr"
la var value_hired_labor "(sum) cost of all hired labor, birr"

***************************************
//Create additional variables 

*Total crop production costs
egen crop_prod_costs=rowtotal(total_inorgfert_purchased_value seed_purchased_cost land_rental_cost cost_sales_transport value_hired_labor)
la var crop_prod_costs "(sum) total costs of crop production, birr"

*No information in survey about crop byproducts

save "$merge\sect_ag_HH_w2_merge.dta", replace
}

///////////////////////////////////////////////
///		2.1 Prepare Livestock Questionnaire Data	///
///		Prepare data at livestock and byproduct levels 	///
///		Collapse to Holder level			///
///////////////////////////////////////////////
{
***********************************************
//Livestock Population and Products
clear
use "$input\Livestock\sect8a_ls_w2.dta" 
*unique ID: holder_id ls_s8aq00 - at livestock population/product level

//Livestock Counts
gen ls_cattle_count=0
replace ls_cattle_count=ls_s8aq13a if ls_s8aq00==1
la var ls_cattle_count "Count of cattle"

gen ls_poultry_count=0
replace ls_poultry_count=ls_s8aq13a if ls_s8aq00==8 | ls_s8aq00==9 | ls_s8aq00==10 | ls_s8aq00==11 | ls_s8aq00==12 | ls_s8aq00==13
la var ls_poultry_count "Count of hens, cocks, cockerels, pullets, and chicks"

gen ls_other_count=0
replace ls_other_count=ls_s8aq13a if ls_s8aq00==2 | ls_s8aq00==3 | ls_s8aq00==4 | ls_s8aq00==5 | ls_s8aq00==6 | ls_s8aq00==7
la var ls_other_count "Count of sheep, goats, horses, donkeys, mules, and camels"

gen ls_sheepgoat_count=0
replace ls_sheepgoat_count=ls_s8aq13a if ls_s8aq00==2 | ls_s8aq00==3
la var ls_sheepgoat_count "Count of sheep and goats"

gen ls_horse_count=0
replace ls_horse_count=ls_s8aq13a if ls_s8aq00==4
la var ls_horse_count "Count of horses"

gen ls_donkey_count=0
replace ls_donkey_count=ls_s8aq13a if ls_s8aq00==5
la var ls_donkey_count "Count of donkeys"

gen ls_mule_count=0
replace ls_mule_count=ls_s8aq13a if ls_s8aq00==6
la var ls_mule_count "Count of mules"

gen ls_camel_count=0
replace ls_camel_count=ls_s8aq13a if ls_s8aq00==7
la var ls_camel_count "Count of camels"

*TLU counts, following FAO guidelines
gen ls_tropical_units=0.5*ls_cattle_count+0.01*ls_poultry_count+0.1*ls_sheepgoat_count+0.5*ls_horse_count+0.6*ls_mule_count+0.3*ls_donkey_count+0.7*ls_camel_count
la var ls_tropical_units "Total Tropical Livestock Units (TLUs)"

//Honey Production; beehives==14, by_products (calculating here though also reported in byproducts section
gen honey_prod_trad=.
replace honey_prod_trad=ls_s8aq26*ls_s8aq29a_1*ls_s8aq29b //number of traditional hives owned*traditional honey hive production per harvest*number of traditional honey hive harvests per year
replace honey_prod_trad=0 if honey_prod_trad==.
gen honey_prod_int=.
replace honey_prod_int=ls_s8aq27*ls_s8aq29c_1*ls_s8aq29d //number of intermediate hives owned*intermediate honey hive production per harvest*number of intermediate honey hive harvests per year
replace honey_prod_int=0 if honey_prod_int==.
gen honey_prod_mod=.
replace honey_prod_mod=ls_s8aq28*ls_s8aq29e_1*ls_s8aq29f  //number of modern hives owned*modern honey hive production per harvest*number of modern honey hive harvests per year
replace honey_prod_mod=0 if honey_prod_mod==.
gen honey_prod=honey_prod_trad+honey_prod_int+honey_prod_mod
la var honey_prod "Total honey production in last 12 months, kg"

//Milk Production; cattle==1, goats==3, camels==7, by_products (calculating here though also reported in byproducts section
gen milk_prod_months=ls_s8aq30 //average number of months during which livestock actually milked
replace milk_prod_months=12 if milk_prod_months>12 & milk_prod_months!=. //2 changes
gen milk_prod=ls_8aq29_b*milk_prod_months*ls_s8aq32_1*30 //number of livestock for milk owned by holder in last 12 months*avg # of months in which livestock actually milked*average quantity of milk produced per day per [livestock] in liters*30 days in a month
la var milk_prod "Total milk production in last 12 months, liters"

//Egg Production; laying hens==8, by_products (calculating here though also reported in byproducts section
gen egg_prod_local=.
replace egg_prod_local=ls_s8aq33*365/ls_s8aq36 //number of eggs per local breed hen per clutch*365 days/average number of days per clutch, local breed
replace egg_prod_local=0 if egg_prod_local==.
gen egg_prod_hybrid=.
replace egg_prod_hybrid=ls_s8aq34*365/ls_s8aq37 //number of eggs per hybrid hen per clutch*365 days/average number of days per clutch, hybrid
replace egg_prod_hybrid=0 if egg_prod_hybrid==.
gen egg_prod_exotic=.
replace egg_prod_exotic=ls_s8aq35*365/ls_s8aq38 //number of eggs per exotic hen per clutch*365 days/average number of days per clutch, exotic
replace egg_prod_exotic=0 if egg_prod_exotic==.
gen egg_prod=egg_prod_local+egg_prod_hybrid+egg_prod_exotic
la var egg_prod "Total egg production in last 12 months, number"

//Livestock sales; asked about all livestock categories
gen livestock_sales=0
replace livestock_sales=ls_s8aq60 if ls_s8aq60!=. //total value of sales of livestock in last 12 months, birr (record 0 if no sales)
la var livestock_sales "Total value of sales of [livestock] in last 12 months, birr"

//Livestock expenses
gen livestock_expenses=0
replace livestock_expenses=ls_s8aq62 if ls_s8aq62!=. //total cost of labor for livestock, birr
replace livestock_expenses=livestock_expenses+ls_s8aq64 if ls_s8aq64!=. //total cost of other expenses for livestock, birr
la var livestock_expenses "Total cost of labor and other expenses for [livestock], birr"
*No questions about cost of purchasing animals - just number of purchased animals

//Livestock stock variation
gen livestock_purchased=ls_s8aq44a //number of animals purchased
gen livestock_sold=0
replace livestock_sold=ls_s8aq46a if ls_s8aq46a!=. //number sold
gen livestock_slaughtered=0
replace livestock_slaughtered=ls_s8aq47a if ls_s8aq47a!=. //number slaughtered; value from meat sales capture in by-product section, so not valuing here
gen livestock_price=livestock_sales/livestock_sold

//Imputing cost of purchased livestock
egen ea_median_price_ls=median(livestock_price), by(ls_s8aq00 saq01 saq02 saq03 saq04 ea_id2)
egen kebele_median_price_ls=median(livestock_price), by(ls_s8aq00 saq01 saq02 saq03 saq04)
egen woreda_median_price_ls=median(livestock_price), by(ls_s8aq00 saq01 saq02 saq03)
egen zone_median_price_ls=median(livestock_price), by(ls_s8aq00 saq01 saq02)
egen region_median_price_ls=median(livestock_price), by(ls_s8aq00 saq01)
egen nation_median_price_ls=median(livestock_price), by(ls_s8aq00)

egen ea_median_price_ls_ct=count(livestock_price), by(ls_s8aq00 saq01 saq02 saq03 saq04 ea_id2)
egen kebele_median_price_ls_ct=count(livestock_price), by(ls_s8aq00 saq01 saq02 saq03 saq04)
egen woreda_median_price_ls_ct=count(livestock_price), by(ls_s8aq00 saq01 saq02 saq03)
egen zone_median_price_ls_ct=count(livestock_price), by(ls_s8aq00 saq01 saq02)
egen region_median_price_ls_ct=count(livestock_price), by(ls_s8aq00 saq01)
egen nation_median_price_ls_ct=count(livestock_price), by(ls_s8aq00)

gen value_of_purchased_ls=livestock_purchased*livestock_price //2726
replace value_of_purchased_ls=livestock_purchased*ea_median_price_ls if value_of_purchased_ls==. & ea_median_price_ls_ct>=10 //5 changes
replace value_of_purchased_ls=livestock_purchased*kebele_median_price_ls if value_of_purchased_ls==. & kebele_median_price_ls_ct>=10 //0 changes
replace value_of_purchased_ls=livestock_purchased*woreda_median_price_ls if value_of_purchased_ls==. & woreda_median_price_ls_ct>=10 //464 changes
replace value_of_purchased_ls=livestock_purchased*zone_median_price_ls if value_of_purchased_ls==. & zone_median_price_ls_ct>=10 //2197 changes
replace value_of_purchased_ls=livestock_purchased*region_median_price_ls if value_of_purchased_ls==. & region_median_price_ls_ct>=10 //5164 changes
replace value_of_purchased_ls=livestock_purchased*nation_median_price_ls if value_of_purchased_ls==. & nation_median_price_ls_ct>=10 //3080 changes
replace value_of_purchased_ls=livestock_purchased*nation_median_price_ls if value_of_purchased_ls==. //142 changes

replace livestock_purchased=0 if livestock_purchased==.
replace value_of_purchased_ls=0 if value_of_purchased_ls==.

//Collapse to holder level
collapse (sum) ls_cattle_count ls_poultry_count ls_other_count ls_tropical_units honey_prod milk_prod egg_prod livestock_sales livestock_expenses value_of_purchased_ls, by (holder_id)
la var ls_cattle_count "(sum) Count of cattle"
la var ls_poultry_count "(sum) Count of hens, cocks, cockerels, pullets, and chicks"
la var ls_other_count "(sum) Count of sheep, goats, horses, donkeys, mules, and camels"
la var ls_tropical_units "Total Tropical Livestock Units (TLUs)"
la var honey_prod "(sum) Total honey production in last 12 months, kg"
la var milk_prod "(sum) Total milk production in last 12 months, liters"
la var egg_prod "(sum) Total egg production in last 12 months, number"
la var livestock_sales "(sum) Total value of sales of livestock in last 12 months, birr"
la var livestock_expenses "(sum) Total cost of labor and other expenses for livestock, birr"
la var value_of_purchased_ls "(sum) Total cost of purchased livestock, birr"

save "$collapse\sect8a_ls_w2_collapse.dta", replace

***************************************************
//Livestock Byproducts
clear
use "$input\Livestock\sect8c_ls_w2.dta"
*unique ID: holder_id ls_s8cq00 - at livestock byproduct level
*milk 1, butter 2, cheese 3, beef 4, mutton/goat 5, camel meat 15, eggs 6, honey 12, wax 13, wool (sheep hair) 9, skin 8, hides 7, arera 16, aguat 17, others 18

//Costs of inputs
gen ls_byproduct_costs=0
replace ls_byproduct_costs=ls_s8cq04a if ls_s8cq04a!=. //costs of inputs (labor, transport, etc.) in production of byproduct, birr
la var ls_byproduct_costs "Costs of inputs (labor, transport, etc.) in production of [byproduct], birr"

//Production quantity

*units for a few production quantities are missing, apply most common unit for each byproduct (tab ls_s8cq00 ls_s8cq06a)
gen ls_byproduct_qty_unit=.
replace ls_byproduct_qty_unit=ls_s8cq06a
replace ls_byproduct_qty_unit=1 if ls_byproduct_qty_unit==. & ls_s8cq06b!=. & (ls_s8cq00==1 | ls_s8cq00==16 | ls_s8cq00==17) //42 changes
replace ls_byproduct_qty_unit=2 if ls_byproduct_qty_unit==. & ls_s8cq06b!=. & (ls_s8cq00==2 | ls_s8cq00==3 | ls_s8cq00==4 | ls_s8cq00==5 | ls_s8cq00==9 | ls_s8cq00==12 | ls_s8cq00==13| ls_s8cq00==18) //13 changes
replace ls_byproduct_qty_unit=3 if ls_byproduct_qty_unit==. & ls_s8cq06b!=. & (ls_s8cq00==6 | ls_s8cq00==7 | ls_s8cq00==8 | ls_s8cq00==15) //12 changes

gen ls_byproduct_qty_liters=.
replace ls_byproduct_qty_liters=ls_s8cq06b if ls_s8cq06b!=. & ls_byproduct_qty_unit==1 //quantity produced in last 12 months; units==liters
gen ls_byproduct_qty_kg=.
replace ls_byproduct_qty_kg=ls_s8cq06b if ls_s8cq06b!=. & ls_byproduct_qty_unit==2 //quantity produced in last 12 months; units==kgs
gen ls_byproduct_qty_num=.
replace ls_byproduct_qty_num=ls_s8cq06b if ls_s8cq06b!=. & ls_byproduct_qty_unit==3 //quantity produced in last 12 months; units==number
gen honey_byprod=.
replace honey_byprod=ls_byproduct_qty_kg if ls_s8cq00==12 & ls_byproduct_qty_kg!=.
gen milk_byprod=.
replace milk_byprod=ls_byproduct_qty_liters if ls_s8cq00==1 & ls_byproduct_qty_liters!=.
gen egg_byprod=.
replace egg_byprod=ls_byproduct_qty_num if ls_s8cq00==6 & ls_byproduct_qty_num!=.

//Sales quantity

*units for many sales quantities are missing, apply most common unit for each byproduct (tab ls_s8cq00 ls_s8cq07a)
gen ls_byproduct_sales_unit=.
replace ls_byproduct_sales_unit=ls_s8cq07a
replace ls_byproduct_sales_unit=1 if ls_byproduct_sales_unit==. & ls_s8cq07b!=. & (ls_s8cq00==1 | ls_s8cq00==16 | ls_s8cq00==17) //2349 changes
replace ls_byproduct_sales_unit=2 if ls_byproduct_sales_unit==. & ls_s8cq07b!=. & (ls_s8cq00==2 | ls_s8cq00==3 | ls_s8cq00==4 | ls_s8cq00==5 | ls_s8cq00==9 | ls_s8cq00==12 | ls_s8cq00==13| ls_s8cq00==18) //1307 changes
replace ls_byproduct_sales_unit=3 if ls_byproduct_sales_unit==. & ls_s8cq07b!=. & (ls_s8cq00==6 | ls_s8cq00==7 | ls_s8cq00==8 | ls_s8cq00==15) //618 changes
replace ls_byproduct_sales_unit=2 if ls_byproduct_sales_unit!=. & ls_s8cq00==9 //recode wool unit to kgs, which is how production quantity is typically reported, 6 changes

gen ls_byproduct_sales_liters=.
replace ls_byproduct_sales_liters=ls_s8cq07b if ls_s8cq07b!=. & ls_byproduct_sales_unit==1 //quantity sold in last 12 months; units==liters
gen ls_byproduct_sales_kg=.
replace ls_byproduct_sales_kg=ls_s8cq07b if ls_s8cq07b!=. & ls_byproduct_sales_unit==2 //quantity sold in last 12 months; units==kgs
gen ls_byproduct_sales_num=.
replace ls_byproduct_sales_num=ls_s8cq07b if ls_s8cq07b!=. & ls_byproduct_sales_unit==3 //quantity sold in last 12 months; units==number

//Sales value
gen ls_byproduct_sales_value=0
replace ls_byproduct_sales_value=ls_s8cq08a if ls_s8cq08a!=. //if sold, total value of sales in birr (record 0 if no sales)
replace ls_byproduct_sales_value=0 if ls_s8cq07b==0 //replace sales value with 0 if did not sell any, 33 changes
replace ls_byproduct_sales_value=0 if ls_s8cq06b==0 //replace sales value with 0 if did not produce any, 0 changes
*2,779 observations where ls_byproduct_sales_value!=0

//Calculating byproduct prices

*Imputed unit price, any byproduct - household level
gen unit_price_liters=.
replace unit_price_liters=ls_byproduct_sales_value/ls_byproduct_sales_liters //415 observations with a non-0 non-missing quantity sold in liters
la var unit_price_liters "Imputed price of [byproduct], birr/liters"
gen unit_price_kg=.
replace unit_price_kg=ls_byproduct_sales_value/ls_byproduct_sales_kg  //919 observations with a non-0 non-missing quantity sold in liters
la var unit_price_kg "Imputed price of [byproduct], birr/kg"
gen unit_price_num=.
replace unit_price_num=ls_byproduct_sales_value/ls_byproduct_sales_num  //1419 observations with a non-0 non-missing quantity sold in liters
la var unit_price_num "Imputed price of [byproduct], birr/number"

*Some households do not sell any of particular byproducts, so do not have imputed HH-level prices for the byproduct
*To be able to estimate the value of these byproducts, we need to apply prices at higher levels. 
*Calculate median price at different levels, based on imputed prices of households reporting sales
egen ea_median_price_liters=median(unit_price_liters), by(ls_s8cq00 saq01 saq02 saq03 saq04 ea_id2)
egen kebele_median_price_liters=median(unit_price_liters), by(ls_s8cq00 saq01 saq02 saq03 saq04)
egen woreda_median_price_liters=median(unit_price_liters), by(ls_s8cq00 saq01 saq02 saq03)
egen zone_median_price_liters=median(unit_price_liters), by(ls_s8cq00 saq01 saq02)
egen region_median_price_liters=median(unit_price_liters), by(ls_s8cq00 saq01)
egen nation_median_price_liters=median(unit_price_liters), by(ls_s8cq00)

egen ea_median_price_kg=median(unit_price_kg), by(ls_s8cq00 saq01 saq02 saq03 saq04 ea_id2)
egen kebele_median_price_lg=median(unit_price_kg), by(ls_s8cq00 saq01 saq02 saq03 saq04)
egen woreda_median_price_kg=median(unit_price_kg), by(ls_s8cq00 saq01 saq02 saq03)
egen zone_median_price_kg=median(unit_price_kg), by(ls_s8cq00 saq01 saq02)
egen region_median_price_kg=median(unit_price_kg), by(ls_s8cq00 saq01)
egen nation_median_price_kg=median(unit_price_kg), by(ls_s8cq00)

egen ea_median_price_num=median(unit_price_num), by(ls_s8cq00 saq01 saq02 saq03 saq04 ea_id2)
egen kebele_median_price_num=median(unit_price_num), by(ls_s8cq00 saq01 saq02 saq03 saq04)
egen woreda_median_price_num=median(unit_price_num), by(ls_s8cq00 saq01 saq02 saq03)
egen zone_median_price_num=median(unit_price_num), by(ls_s8cq00 saq01 saq02)
egen region_median_price_num=median(unit_price_num), by(ls_s8cq00 saq01)
egen nation_median_price_num=median(unit_price_num), by(ls_s8cq00)

*Calculate count of prices at different levels
egen ea_median_price_liters_ct=count(unit_price_liters), by(ls_s8cq00 saq01 saq02 saq03 saq04 ea_id2)
egen kebele_median_price_liters_ct=count(unit_price_liters), by(ls_s8cq00 saq01 saq02 saq03 saq04)
egen woreda_median_price_liters_ct=count(unit_price_liters), by(ls_s8cq00 saq01 saq02 saq03)
egen zone_median_price_liters_ct=count(unit_price_liters), by(ls_s8cq00 saq01 saq02)
egen region_median_price_liters_ct=count(unit_price_liters), by(ls_s8cq00 saq01)
egen nation_median_price_liters_ct=count(unit_price_liters), by(ls_s8cq00)

egen ea_median_price_kg_ct=count(unit_price_kg), by(ls_s8cq00 saq01 saq02 saq03 saq04 ea_id2)
egen kebele_median_price_kg_ct=count(unit_price_kg), by(ls_s8cq00 saq01 saq02 saq03 saq04)
egen woreda_median_price_kg_ct=count(unit_price_kg), by(ls_s8cq00 saq01 saq02 saq03)
egen zone_median_price_kg_ct=count(unit_price_kg), by(ls_s8cq00 saq01 saq02)
egen region_median_price_kg_ct=count(unit_price_kg), by(ls_s8cq00 saq01)
egen nation_median_price_kg_ct=count(unit_price_kg), by(ls_s8cq00)

egen ea_median_price_num_ct=count(unit_price_num), by(ls_s8cq00 saq01 saq02 saq03 saq04 ea_id2)
egen kebele_median_price_num_ct=count(unit_price_num), by(ls_s8cq00 saq01 saq02 saq03 saq04)
egen woreda_median_price_num_ct=count(unit_price_num), by(ls_s8cq00 saq01 saq02 saq03)
egen zone_median_price_num_ct=count(unit_price_num), by(ls_s8cq00 saq01 saq02)
egen region_median_price_num_ct=count(unit_price_num), by(ls_s8cq00 saq01)
egen nation_median_price_num_ct=count(unit_price_num), by(ls_s8cq00)

//Byproduct production values

*Calculate value of livestock byproduct production using the imputed price for different units at lowest possible level with at least *10* (not 3) non-missing observations, if no household-level imputed price is available
gen value_of_byproduct_liters=.
replace value_of_byproduct_liters=ls_byproduct_qty_liters*unit_price_liters //estimated [byproduct] harvest value for households reporting sales of [byproduct]
replace value_of_byproduct_liters=ls_byproduct_qty_liters*ea_median_price_liters if value_of_byproduct_liters==. & ea_median_price_liters_ct>=10 //estimate [byproduct] value for households missing values in EAs with at least 3 HHs with imputed price, 1 change
replace value_of_byproduct_liters=ls_byproduct_qty_liters*kebele_median_price_liters if value_of_byproduct_liters==. & kebele_median_price_liters_ct>=10 //estimate [byproduct] value for households missing values in kebeles with at least 3 HHs with imputed price, 0 changes
replace value_of_byproduct_liters=ls_byproduct_qty_liters*woreda_median_price_liters if value_of_byproduct_liters==. & woreda_median_price_liters_ct>=10 //estimate [byproduct] value for households missing values in woredas with at least 3 HHs with imputed price, 89 changes
replace value_of_byproduct_liters=ls_byproduct_qty_liters*zone_median_price_liters if value_of_byproduct_liters==. & zone_median_price_liters_ct>=10 //estimate [byproduct] value for households missing values in zones with at least 3 HHs with imputed price, 118 changes
replace value_of_byproduct_liters=ls_byproduct_qty_liters*region_median_price_liters if value_of_byproduct_liters==. & region_median_price_liters_ct>=10 //estimate [byproduct] value for households missing values in regions with at least 3 HHs with imputed price, 1074 changes
replace value_of_byproduct_liters=ls_byproduct_qty_liters*nation_median_price_liters if value_of_byproduct_liters==. & nation_median_price_liters_ct>=10 //estimate [byproduct] value for households missing values with at least 3 HHs with imputed price in the country, 1255 changes
replace value_of_byproduct_liters=ls_byproduct_qty_liters*nation_median_price_liters if value_of_byproduct_liters==. //estimate [byproduct] value for households missing values with any HH with imputed price in the country, 850 changes
//11 observations remain with a non-missing ls_byproduct_qty_liters but no value_of_byproduct_liters, implying no households in the country sold that byproduct in this unit: mutton/goat (most obs in kg), skin (most obs in number), wax (most obs in kg)

gen value_of_byproduct_kg=.
replace value_of_byproduct_kg=ls_byproduct_qty_kg*unit_price_kg //estimated [byproduct] harvest value for households reporting sales of [byproduct]
replace value_of_byproduct_kg=ls_byproduct_qty_kg*ea_median_price_kg if value_of_byproduct_kg==. & ea_median_price_kg_ct>=10 //estimate [byproduct] value for households missing values in EAs with at least 3 HHs with imputed price, 2 changes
replace value_of_byproduct_kg=ls_byproduct_qty_kg*kebele_median_price_kg if value_of_byproduct_kg==. & kebele_median_price_kg_ct>=10 //estimate [byproduct] value for households missing values in kebeles with at least 3 HHs with imputed price, 0 changes
replace value_of_byproduct_kg=ls_byproduct_qty_kg*woreda_median_price_kg if value_of_byproduct_kg==. & woreda_median_price_kg_ct>=10 //estimate [byproduct] value for households missing values in woredas with at least 3 HHs with imputed price, 0 changes
replace value_of_byproduct_kg=ls_byproduct_qty_kg*zone_median_price_kg if value_of_byproduct_kg==. & zone_median_price_kg_ct>=10 //estimate [byproduct] value for households missing values in zones with at least 3 HHs with imputed price, 260 changes
replace value_of_byproduct_kg=ls_byproduct_qty_kg*region_median_price_kg if value_of_byproduct_kg==. & region_median_price_kg_ct>=10 //estimate [byproduct] value for households missing values in regions with at least 3 HHs with imputed price, 546 changes
replace value_of_byproduct_kg=ls_byproduct_qty_kg*nation_median_price_kg if value_of_byproduct_kg==. & nation_median_price_kg_ct>=10 //estimate [byproduct] value for households missing values with at least 3 HHs with imputed price in the country, 650 changes
replace value_of_byproduct_kg=ls_byproduct_qty_kg*nation_median_price_kg if value_of_byproduct_kg==. //estimate [byproduct] value for households missing values with any HH with imputed price in the country, 167 changes
//42 observations remain with a non-missing ls_byproduct_qty_kg but no value_of_byproduct_kg implying no households in the country sold that byproduct in this unit: skin (most obs in number), wool (sheep hair) (1 obs in number), camel meat (most obs in number), aguat (most obs in liters)

gen value_of_byproduct_num=.
replace value_of_byproduct_num=ls_byproduct_qty_num*unit_price_num //estimated [byproduct] harvest value for households reporting sales of [byproduct]
replace value_of_byproduct_num=ls_byproduct_qty_num*ea_median_price_num if value_of_byproduct_num==. & ea_median_price_num_ct>=10 //estimate [byproduct] value for households missing values in EAs with at least 3 HHs with imputed price, 8 changes
replace value_of_byproduct_num=ls_byproduct_qty_num*kebele_median_price_num if value_of_byproduct_num==. & kebele_median_price_num_ct>=10 //estimate [byproduct] value for households missing values in kebeles with at least 3 HHs with imputed price, 0 changes
replace value_of_byproduct_num=ls_byproduct_qty_num*woreda_median_price_num if value_of_byproduct_num==. & woreda_median_price_num_ct>=10 //estimate [byproduct] value for households missing values in woredas with at least 3 HHs with imputed price, 50 changes
replace value_of_byproduct_num=ls_byproduct_qty_num*zone_median_price_num if value_of_byproduct_num==. & zone_median_price_num_ct>=10 //estimate [byproduct] value for households missing values in zones with at least 3 HHs with imputed price, 473 changes
replace value_of_byproduct_num=ls_byproduct_qty_num*region_median_price_num if value_of_byproduct_num==. & region_median_price_num_ct>=10 //estimate [byproduct] value for households missing values in regions with at least 3 HHs with imputed price, 239 changes
replace value_of_byproduct_num=ls_byproduct_qty_num*nation_median_price_num if value_of_byproduct_num==. & nation_median_price_num_ct>=10 //estimate [byproduct] value for households missing values with at least 3 HHs with imputed price in the country, 95 changes
replace value_of_byproduct_num=ls_byproduct_qty_num*nation_median_price_num if value_of_byproduct_num==. //estimate [byproduct] value for households missing values with any HH with imputed price in the country, 125 changes
//54 observations remain with a non-missing ls_byproduct_qty_num but no value_of_byproduct_num, implying no households in the country sold that byproduct in this unit: beef (most obs in kg), wool (sheep hair) (most obs in kg), aguat (most obs in liters), others (most obs in kg)

*Calculate total value of byproduct production
egen ls_value_of_byproduct=rowtotal(value_of_byproduct_liters value_of_byproduct_kg value_of_byproduct_num)

//Collapse to HH level
collapse (sum) ls_byproduct_costs honey_byprod milk_byprod egg_byprod ls_byproduct_sales_value ls_value_of_byproduct, by (holder_id)
la var ls_byproduct_costs "(sum) Costs of inputs (labor, transport, etc.) in production of [byproduct], birr"
la var honey_byprod "(sum) Total honey production in last 12 months, kg"
la var milk_byprod "(sum) Total milk production in last 12 months, liters"
la var egg_byprod "(sum) Total egg production in last 12 months, number"
la var ls_byproduct_sales_value "(sum) Value of sales of livestock byproducts, birr"
la var ls_value_of_byproduct "(sum) Value of production of livestock byproducts, birr"

save "$collapse\sect8c_ls_w2_collapse.dta", replace
}

///////////////////////////////////////////////
///		2.2 Prepare Livestock Questionnaire Data	///
///		Merge collapsed sections at holder level	///
///		Collapse to Household level			///
///////////////////////////////////////////////
{
clear
use "$input\Livestock\sect_cover_ls_w2.dta" //cover
*unique ID: holder_id

merge 1:1 holder_id using "$collapse\sect8a_ls_w2_collapse.dta", gen (_merge8als2)
	//not matched: 481 from master //households that are crop only or "none" farm type
	//matched: 3,331
	
merge 1:1 holder_id using "$collapse\sect8c_ls_w2_collapse.dta", generate (_merge8cls2)
	//not matched: 0
	//matched: 3,812

save "$merge\sect_ls_holder_w2_collapse.dta", replace

//Collapse to HH level
collapse (max) ls_cattle_count ls_poultry_count ls_other_count ls_tropical_units livestock_sales livestock_expenses value_of_purchased_ls ls_byproduct_costs ls_byproduct_sales_value ls_value_of_byproduct, by (household_id2)

la var ls_cattle_count "(sum) Count of cattle"
la var ls_poultry_count "(sum) Count of hens, cocks, cockerels, pullets, and chicks"
la var ls_other_count "(sum) Count of sheep, goats, horses, donkeys, mules, and camels"
la var ls_tropical_units "Total Tropical Livestock Units (TLUs)"
la var livestock_sales "(sum) Total value of sales of livestock in last 12 months, birr"
la var livestock_expenses "(sum) Total cost of labor and other expenses for livestock, birr"
la var value_of_purchased_ls "(sum) Total cost of purchased livestock, birr"
la var ls_byproduct_costs "(sum) Costs of inputs (labor, transport, etc.) in production of [byproduct], birr"
la var ls_byproduct_sales_value "(sum) Value of sales of livestock byproducts, birr"
la var ls_value_of_byproduct "(sum) Value of production of livestock byproducts, birr"

save "$merge\sect_ls_hh_w2_merge.dta", replace
}

///////////////////////////////////////////////
///		3.1 Household Questionnaire Income Data	///
///		Individual-Level Household Income			///
///		Collapse to Household level			///
///////////////////////////////////////////////
{
clear
use "$input\Household\sect_cover_hh_w2.dta" //cover
*unique ID: household_id2

merge 1:m household_id2 using "$input\Household\sect1_hh_w2.dta", gen (_merge1hh2) //HH roster
	//not matched: 0 
	//matched: 26,158
//data are now at individual level
*unique ID: household_id2, individual_id2
	
merge 1:1 individual_id2 using "$input\Household\sect2_hh_w2.dta", gen (_merge2hh2) //HH education
	//not matched: 2,373 from master, these individuals are no longer a member of the household in this wave
	//matched: 23,785

merge 1:1 individual_id2 using "$input\Household\sect4_hh_w2.dta", gen (_merge4hh2) //HH labor and time use
	//not matched: 2,373 from master, these individuals are no longer a member of the household in this wave
	//matched: 23,785

*HH head information, hh_s1q02==1
gen hh_head_fem=0
replace hh_head_fem=1 if hh_s1q03==2 & hh_s1q02==1 //if sex is female
replace hh_head_fem=1 if hh_s1q04e==2 & hh_s1q02==1 //replace with corrected sex if provided
la var hh_head_fem "Head of household is female"

gen hh_head_age=hh_s1q04_a if hh_s1q02==1 //age in years
replace hh_head_age=hh_s1q04h if hh_s1q04h!=. & hh_s1q02==1 //replace with corrected age if provided
la var hh_head_age "Age of head of household, years"

gen hh_head_married=0
replace hh_head_married=1 if (hh_s1q08==2 | hh_s1q08==3) & hh_s1q02==1 //married monogamous or polygamous
la var hh_head_married "Head of household is married (monogamous or polygamous)"

//recode education variable into years
gen education_years=.
replace education_years=0 if hh_s2q03==2 //recode 0 years if never attended school
replace education_years=0 if hh_s2q05==0
replace education_years=1 if hh_s2q05==1
replace education_years=2 if hh_s2q05==2
replace education_years=3 if hh_s2q05==3
replace education_years=4 if hh_s2q05==4
replace education_years=5 if hh_s2q05==5
replace education_years=6 if hh_s2q05==6
replace education_years=7 if hh_s2q05==7
replace education_years=8 if hh_s2q05==8
replace education_years=9 if hh_s2q05==9
replace education_years=10 if hh_s2q05==10
replace education_years=11 if hh_s2q05==11
replace education_years=12 if hh_s2q05==12
replace education_years=13 if hh_s2q05==13 //12th grade + 1, old curriculum
replace education_years=13 if hh_s2q05==14 //teacher training certificate, old curriculum
replace education_years=13 if hh_s2q05==15 //1 year college, old curriculum
replace education_years=14 if hh_s2q05==16 //2 years college, old curriculum
replace education_years=14 if hh_s2q05==17 //diploma, old curriculum
replace education_years=15 if hh_s2q05==18 //3 years college, old curriculum
replace education_years=16 if hh_s2q05==19 //bachelor's degree, old curriculum
replace education_years=17 if hh_s2q05==20 //postgraduate diploma, old curriculum
replace education_years=9 if hh_s2q05==21 //9th grade, new curriculum
replace education_years=10 if hh_s2q05==22 //10th grade, new curriculum
replace education_years=11 if hh_s2q05==23 //11th grade, new curriculum
replace education_years=12 if hh_s2q05==24 //12th grade, new curriculum
replace education_years=11 if hh_s2q05==25 //certificate (10+1), new curriculum
replace education_years=12 if hh_s2q05==26 //level 2 vocational/technical course, new curriculum
replace education_years=12 if hh_s2q05==27 //certificate (10+2), new curriculum
replace education_years=11 if hh_s2q05==28 //1 year 10+3 or level 3 vocational/technical course, new curriculum
replace education_years=12 if hh_s2q05==29 //2 years 10+3 or level 3 vocational/technical course, new curriculum
replace education_years=13 if hh_s2q05==30 //diploma 10+3 or level 3 vocational/technical course, new curriculum
replace education_years=13 if hh_s2q05==31 //1 year college, new curriculum
replace education_years=14 if hh_s2q05==32 //2 years college, new curriculum
replace education_years=15 if hh_s2q05==33 //3 years college, new curriculum
replace education_years=16 if hh_s2q05==34 //bachelor's degree, new curriculum
replace education_years=17 if hh_s2q05==35 //above bachelor's, new curriculum
//other codes: 93=informal education (read and write but no regular school), 94=adult literacy program, 95=satellite, 96=non-regular (read and write by religious institute, no regular school), 98=not educated

gen hh_head_education=education_years if hh_s1q02==1 //highest grade completed
la var hh_head_education "Years of education of head of household"

rename education_years hh_mem_ed

//Generate HH member information
gen hh_mem_fem=0
replace hh_mem_fem=1 if hh_s1q03==2 //if sex is female
replace hh_mem_fem=1 if hh_s1q04e==2 //replace with corrected sex if provided
la var hh_mem_fem "Household member is female"

gen hh_mem_age=hh_s1q04_a //age in years
replace hh_mem_age=hh_s1q04h if hh_s1q04h!=. //replace with corrected age if provided
la var hh_mem_age "Age of household member, years"

gen hh_mem_15_64=0
replace hh_mem_15_64=1 if hh_mem_age>14 & hh_mem_age<65
la var hh_mem_15_64 "Household members is between 15-64 years old"

gen hh_size=hh_saq09
la var hh_size "Number of household members"

*Income from assistance for school
gen school_assistance=hh_s2q15
la var school_assistance "Value of assistance to attend school, current school year, birr"

*Main job wage/salary income
gen main_job_months=hh_s4q13 //how many months of last 12 did individual work at this job
replace main_job_months=12 if hh_s4q13>12
gen main_job_weeks=hh_s4q14 //during these months, approximately how many weeks per month did you work at this job
replace main_job_weeks=5 if hh_s4q14>5
gen main_job_hours=hh_s4q14 //during these weeks, approximately how many hours per week did you work at this job; no obvious outliers, max is 99 from a max possible 168

gen main_job_income=.
replace main_job_income=hh_s4q16 if hh_s4q17==8 //16 respondents reported an annual wage/salary
replace main_job_income=hh_s4q16 if hh_s4q17==7 //8 respondents reported a half-year wage/salary, but none had worked more than 6 of last 12 months so would not have received the wage/salary twice
replace main_job_income=hh_s4q16 if hh_s4q17==6 //4 respondents reported a quarter-year wage/salary, but none had worked more than 4 of last 12 months so would not have received the wage/salary more than once
replace main_job_income=hh_s4q16*main_job_months if hh_s4q17==5 //multiply by number of months of last 12 the individuals worked if it is a monthly wage/salary
replace main_job_income=hh_s4q16*main_job_months*main_job_weeks/2 if hh_s4q17==4 //for respondents reporting a fortnight (2 week) wage/salary, multiply by number of months of last 12 the individuals worked and by number of weeks worked per month on average, and divide by 2 (because a fortnight is 2 weeks)
replace main_job_income=hh_s4q16*main_job_months*main_job_weeks if hh_s4q17==3 //for respondents reporting a weekly wage/salary, multiply by number of months of last 12 the individuals worked and by number of weeks worked per month on average
replace main_job_income=hh_s4q16*main_job_months*main_job_weeks*main_job_hours/8 if hh_s4q17==2 //for respondents reporting a daily wage/salary, multiply by number of months of last 12 the individuals worked and by number of weeks worked per month on average and by number of hours worked per week on average, and divide by 8 (ASSUME 8 hours of work per day)
replace main_job_income=hh_s4q16*main_job_months*main_job_weeks*main_job_hours if hh_s4q17==1 //for respondents reporting an hourly wage/salary, multiply by number of months of last 12 the individuals worked and by number of weeks worked per month on average and by number of hours worked per week on average
la var main_job_income "Total income from main job over last 12 months, birr"

gen main_job_income_ag=main_job_income if hh_s4q11_b==1 | hh_s4q11_b==2

*Main job allowances/gratuities income
gen main_job_extra_income=.
replace main_job_extra_income=hh_s4q18 if hh_s4q19==8 //123 respondents reported annual extras
replace main_job_extra_income=hh_s4q18 if hh_s4q19==7 //31 respondents reported half-year extras
replace main_job_extra_income=hh_s4q18*2 if hh_s4q19==7 & main_job_months>6 //multiply by 2 for respondents who worked more than 6 of last 12 months so may have received the extras twice
replace main_job_extra_income=hh_s4q18 if hh_s4q19==6 //4 respondents reported quarter-year extras
replace main_job_extra_income=hh_s4q18*4 if hh_s4q19==6 & main_job_months>4 //all 14 worked 12 months, multiply by 4
replace main_job_extra_income=hh_s4q18*main_job_months if hh_s4q19==5 //multiply by number of months of last 12 the individuals worked if it is a monthly wage/salary
replace main_job_extra_income=hh_s4q18*main_job_months*main_job_weeks/2 if hh_s4q19==4 //for respondents reporting a fortnight (2 week) wage/salary, multiply by number of months of last 12 the individuals worked and by number of weeks worked per month on average, and divide by 2 (because a fortnight is 2 weeks)
replace main_job_extra_income=hh_s4q18*main_job_months*main_job_weeks if hh_s4q19==3 //for respondents reporting a weekly wage/salary, multiply by number of months of last 12 the individuals worked and by number of weeks worked per month on average
replace main_job_extra_income=hh_s4q18*main_job_months*main_job_weeks*main_job_hours/8 if hh_s4q19==2 //for respondents reporting a daily wage/salary, multiply by number of months of last 12 the individuals worked and by number of weeks worked per month on average and by number of hours worked per week on average, and divide by 8 (ASSUME 8 hours of work per day)
replace main_job_extra_income=hh_s4q18*main_job_months*main_job_weeks*main_job_hours if hh_s4q19==1 //for respondents reporting an hourly wage/salary, multiply by number of months of last 12 the individuals worked and by number of weeks worked per month on average and by number of hours worked per week on average
la var main_job_extra_income "Total income from main job extra allowances and gratuities over last 12 months, birr"

gen main_job_extra_income_ag=main_job_extra_income if hh_s4q11_b==1 | hh_s4q11_b==2

*Secondary job wage/salary income
gen second_job_months=hh_s4q24 //how many months of last 12 did individual work at this job
replace second_job_months=12 if hh_s4q24>12
gen second_job_weeks=hh_s4q25 //during these months, approximately how many weeks per month did you work at this job
replace second_job_weeks=5 if hh_s4q25>5
gen second_job_hours=hh_s4q26 //during these weeks, approximately how many hours per week did you work at this job; no obvious outliers, max is 99 from a max possible 168

gen second_job_income=.
replace second_job_income=hh_s4q27 if hh_s4q28==8 //1 respondents reported an annual wage/salary
replace second_job_income=hh_s4q27 if hh_s4q28==7 //0 respondents reported a half-year wage/salary
replace second_job_income=hh_s4q27 if hh_s4q28==6 //0 respondents reported a quarter-year wage/salary
replace second_job_income=hh_s4q27*second_job_months if hh_s4q28==5 //multiply by number of months of last 12 the individuals worked if it is a monthly wage/salary
replace second_job_income=hh_s4q27*second_job_months*second_job_weeks/2 if hh_s4q28==4 //for respondents reporting a fortnight (2 week) wage/salary, multiply by number of months of last 12 the individuals worked and by number of weeks worked per month on average, and divide by 2 (because a fortnight is 2 weeks)
replace second_job_income=hh_s4q27*second_job_months*second_job_weeks if hh_s4q28==3 //for respondents reporting a weekly wage/salary, multiply by number of months of last 12 the individuals worked and by number of weeks worked per month on average
replace second_job_income=hh_s4q27*second_job_months*second_job_weeks*second_job_hours/8 if hh_s4q28==2 //for respondents reporting a daily wage/salary, multiply by number of months of last 12 the individuals worked and by number of weeks worked per month on average and by number of hours worked per week on average, and divide by 8 (ASSUME 8 hours of work per day)
replace second_job_income=hh_s4q27*second_job_months*second_job_weeks*second_job_hours if hh_s4q28==1 //for respondents reporting an hourly wage/salary, multiply by number of months of last 12 the individuals worked and by number of weeks worked per month on average and by number of hours worked per week on average
la var second_job_income "Total income from secondary job over last 12 months, birr"

gen second_job_income_ag=second_job_income if hh_s4q22_b==1 | hh_s4q22_b==2

*Secondary job allowances/gratuities income
gen second_job_extra_income=.
replace second_job_extra_income=hh_s4q29 if hh_s4q30==8 //0 respondents reported annual extras
replace second_job_extra_income=hh_s4q29 if hh_s4q30==7 //0 respondents reported half-year extras
replace second_job_extra_income=hh_s4q29 if hh_s4q30==6 //0 respondents reported quarter-year extras
replace second_job_extra_income=hh_s4q29*second_job_months if hh_s4q30==5 //multiply by number of months of last 12 the individuals worked if it is a monthly wage/salary
replace second_job_extra_income=hh_s4q29*second_job_months*second_job_weeks/2 if hh_s4q30==4 //for respondents reporting a fortnight (2 week) wage/salary, multiply by number of months of last 12 the individuals worked and by number of weeks worked per month on average, and divide by 2 (because a fortnight is 2 weeks)
replace second_job_extra_income=hh_s4q29*second_job_months*second_job_weeks if hh_s4q30==3 //for respondents reporting a weekly wage/salary, multiply by number of months of last 12 the individuals worked and by number of weeks worked per month on average
replace second_job_extra_income=hh_s4q29*second_job_months*second_job_weeks*second_job_hours/8 if hh_s4q30==2 //for respondents reporting a daily wage/salary, multiply by number of months of last 12 the individuals worked and by number of weeks worked per month on average and by number of hours worked per week on average, and divide by 8 (ASSUME 8 hours of work per day)
replace second_job_extra_income=hh_s4q29*second_job_months*second_job_weeks*second_job_hours if hh_s4q30==1 //for respondents reporting an hourly wage/salary, multiply by number of months of last 12 the individuals worked and by number of weeks worked per month on average and by number of hours worked per week on average
la var second_job_extra_income "Total income from main job extra allowances and gratuities over last 12 months, birr"

gen second_job_extra_income_ag=second_job_extra_income if hh_s4q22_b==1 | hh_s4q22_b==2

*PSNP labor income
gen psnp_income=hh_s4q33*hh_s4q32 //income on days worked for PSNP * number of days in past 12 months worked for PSNP program
la var psnp_income "Total income from PSNP labor over last 12 months, birr"

*Other temporary/casual labor
gen otherlabor_income=hh_s4q36*hh_s4q35 //income on days worked as temporary/casual labor * number of days in past 12 months worked as temporary/casual labor
la var otherlabor_income "Total income from other temporary/casual labor over last 12 months, birr"

*Total paid income
egen total_paid_income=rowtotal(main_job_income main_job_extra_income second_job_income second_job_extra_income psnp_income school_assistance)
la var total_paid_income "Total non-HH job income from all sources  over last 12 months, birr"

egen total_paid_income_ag=rowtotal(main_job_income_ag main_job_extra_income_ag second_job_income_ag second_job_extra_income_ag)
la var total_paid_income_ag "Non-HH job income from employment in ag over last 12 months, birr"

save "$collapse\sect1-4_hh_w2_collapseprep.dta", replace

//Collapse
collapse (sum) total_paid_income total_paid_income_ag hh_mem_fem hh_mem_15_64 (max) hh_size hh_head_fem hh_head_age hh_head_married hh_head_education hh_mem_ed, by (household_id2)
la var total_paid_income "(sum) Total non-HH job income from all sources  over last 12 months, birr"
la var total_paid_income_ag "(sum) Total non-HH job income from ag labor over last 12 months, birr"
la var hh_mem_fem "(sum) Female household members"
la var hh_mem_15_64 "(sum) Household members between 15-64 years old"
la var hh_size "Number of household members"
la var hh_head_fem "Head of household is female"
la var hh_head_age "Age of head of household, years"
la var hh_head_married "Head of household is married (monogamous or polygamous)"
la var hh_head_education "Years of education of head of household"
la var hh_mem_ed "Education of most educated HH member, years"

save "$collapse\sect1-4_hh_w2_collapse.dta", replace
}

///////////////////////////////////////////////
///		3.2 Household Questionnaire Income Data	///
///		Non-Farm Enterprise Income			///
///		Collapse to Household level			///
///////////////////////////////////////////////
{
clear
use "$input\Household\sect_cover_hh_w2.dta" //cover
*unique ID: household_id2

merge 1:1 household_id2 using "$input\Household\sect11a_hh_w2.dta", gen (_merge11ahh2) //Non-Farm Enterprises Filter
	//not matched: 0 
	//matched: 5,262
	
merge 1:m household_id2 using "$input\Household\sect11b_hh_w2.dta", gen (_merge11bhh2) //Non-Farm Enterprises (household-enterprise level)
	//not matched: 3,473 //HHs not responding yes to any type of non-farm enterprise
	//matched: 2,292
//data are now at household-enterprise level

*Time of enterprise operation
gen enterprise_months=hh_s11bq09 //during last 12 months of operating, how many months was the enterprise active
replace enterprise_months=12 if hh_s11bq09>12 & hh_s11bq09!=.
gen enterprise_days=hh_s11bq10 //during months when operating, average number of days per month in which enterprise operates
replace enterprise_days=30 if hh_s11bq10>31 & hh_s11bq10!=.

*Enterprise income
gen enterprise_income=hh_s11bq13*enterprise_months //average monthly sales during months the enterprise was operating in last 12 months*number of months enterprise active
la var enterprise_income "Sales from enterprise over past 12 months (avg. monthly sales*months active), birr"

gen enterprise_income_ag=enterprise_income if hh_s11bq01_b==1 | hh_s11bq01_b==2

*Costs
egen monthly_costs=rowtotal(hh_s11bq14_a hh_s11bq14_b hh_s11bq14_c hh_s11bq14_d hh_s11bq14_e)
gen enterprise_costs=monthly_costs*enterprise_months //average monthly costs during months the enterprise was operating in last 12 months*number of months enterprise active

gen enterprise_costs_ag=enterprise_costs if hh_s11bq01_b==1 | hh_s11bq01_b==2

*Share of income from enterprise
gen enterprise_income_cash_share=.
replace enterprise_income_cash_share=0 if hh_s11bq15==1 //almost none
replace enterprise_income_cash_share=0.25 if hh_s11bq15==2 //about 25%
replace enterprise_income_cash_share=0.5 if hh_s11bq15==3 //about 50%
replace enterprise_income_cash_share=0.75 if hh_s11bq15==4 //about 75%
replace enterprise_income_cash_share=1 if hh_s11bq15==5 //almost all
la var enterprise_income_cash_share "Share of total HH cash income from this enterprise, past 12 months"

//Collapse to HH level
collapse (sum) enterprise_income enterprise_income_ag enterprise_costs enterprise_costs_ag enterprise_income_cash_share, by (household_id2)
la var enterprise_income "(sum) Sales from enterprise over past 12 months (avg. monthly sales*months active), birr"
la var enterprise_income_ag "(sum) Sales from ag-related enterprise over past 12 months (avg. monthly sales*months active), birr"
la var enterprise_costs  "(sum) Costs from enterprise over past 12 months (avg. monthly sales*months active), birr"
la var enterprise_costs_ag  "(sum) Costs from ag-related enterprise over past 12 months (avg. monthly sales*months active), birr"
la var enterprise_income_cash_share "(sum) Share of total HH cash income from this enterprise, past 12 months"

*Net enterprise income
gen enterprise_income_net=enterprise_income-enterprise_costs
la var enterprise_income_net "Net income from enterprise over past 12 months (revenues - expenses), birr"
gen enterprise_income_net_ag=enterprise_income_ag-enterprise_costs_ag
la var enterprise_income_net_ag "Net income from ag-related enterprise over past 12 months (revenues - expenses), birr"

save "$collapse\sect11_hh_w2_collapse.dta", replace
}
///////////////////////////////////////////////
///		3.3 Household Questionnaire Income Data	///
///		Other Income and Assistance			///
///		Collapse to Household level			///
///////////////////////////////////////////////
{
clear
use "$input\Household\sect12_hh_w2" //other income
*unique ID: household_id2 hh_s12q00
//The data are at the item/income source level

gen other_income=hh_s12q02
la var other_income "Income from this [source] received over last 12 months, birr"

collapse (sum) other_income, by (household_id2)
la var other_income "(sum) Income from other sources received over last 12 months, birr"

save "$collapse\sect12_hh_w2_collapse.dta", replace

clear
use "$input\Household\sect13_hh_w2" //assistance
*unique ID: household_id2 hh_s13q00
//The data are at the assistance type level

*aggregate value of cash, food, and in-kind assistance over last 12 months
egen assistance_income=rowtotal(hh_s13q03 hh_s13q04 hh_s13q05 )
la var assistance_income "Value of cash, food, and in-kind assistance over last 12 months, birr"

collapse (sum) assistance_income, by (household_id2)
la var assistance_income "(sum) Value of cash, food, and in-kind assistance over last 12 months, birr"

save "$collapse\sect13_hh_w2_collapse.dta", replace
}
****Cell phone ownership
use "$input\Household\sect9_hh_w2.dta", clear
gen phone_own=0
replace phone_own=1 if hh_s9q22==1
la var phone_own "Any household members owns cell phone or landline"
keep phone_own household_id2
save "$collapse\sect9_hh_w2_collapse.dta", replace

///////////////////////////////////////////////
///		3.4 Household Questionnaire  Data	///
///		Merge at Household level			///
///////////////////////////////////////////////
{
clear
use "$input\Household\sect_cover_hh_w2.dta"

keep household_id household_id2 ea_id ea_id2 rural pw2 saq01 saq02 saq03 saq04 saq05 saq06 saq07 saq08 hh_saq09

merge 1:1 household_id2 using "$collapse\sect1-4_hh_w2_collapse.dta", gen (_merge_hh1_hh2) //income from individual labor
	//not matched: 0 
	//matched: 5,262

merge 1:1 household_id2 using "$collapse\sect9_hh_w2_collapse.dta", gen (_merge_hh2_hh2) //housing
	//not matched: 0 
	//matched: 5,262
	
merge 1:1 household_id2 using "$collapse\sect11_hh_w2_collapse.dta", gen (_merge_hh3_hh2) //income from HH enterprises
	//not matched: 0 
	//matched: 5,262

merge 1:1 household_id2 using "$collapse\sect12_hh_w2_collapse.dta", gen (_merge_hh4_hh2) //income from other income sources
	//not matched: 0 
	//matched: 5,262
	
merge 1:1 household_id2 using "$collapse\sect13_hh_w2_collapse.dta", gen (_merge_hh5_hh2) //income from assistance
	//not matched: 0 
	//matched: 5,262

gen rural_hh=0
replace rural_hh=1 if rural==1
la var rural_hh "Household lives in a rural area"
	
save "$merge\sect_hh_info_w2_merge.dta", replace
}
///////////////////////////////////////////////
///		4.1 Analyses						///
///		Merge Data at Household level		///
///////////////////////////////////////////////

*We need region variables for weights
use "$input/Household/sect_cover_hh_w2.dta", clear
gen clusterid = ea_id2
gen strataid=saq01 if rural==1 //assign region as strataid to rural respondents; regions from from 1 to 7 and then 12 to 15
gen stratum_id=.
replace stratum_id=16 if rural==2 & saq01==1 //Tigray, small town
replace stratum_id=17 if rural==2 & saq01==3 //Amhara, small town
replace stratum_id=18 if rural==2 & saq01==4 //Oromiya, small town
replace stratum_id=19 if rural==2 & saq01==7 //SNNP, small town
replace stratum_id=20 if rural==2 & (saq01==2 | saq01==5 | saq01==6 | saq01==12 | saq01==13 | saq01==15) //Other regions, small town
replace stratum_id=21 if rural==3 & saq01==1 //Tigray, large town
replace stratum_id=22 if rural==3 & saq01==3 //Amhara, large town
replace stratum_id=23 if rural==3 & saq01==4 //Oromiya, large town
replace stratum_id=24 if rural==3 & saq01==7 //SNNP, large town
replace stratum_id=25 if rural==3 & saq01==14 //Addis Ababa, large town
replace stratum_id=26 if rural==3 & (saq01==2 | saq01==5 | saq01==6 | saq01==12 | saq01==13 | saq01==15) //Other regions, large town

replace strataid=stratum_id if rural!=1 //assign new strata IDs to urban respondents, stratified by region and small or large towns
keep clusterid strataid household_id2 pw2
save "$merge/et2_weights_merge.dta", replace

clear
use "$merge\sect_hh_info_w2_merge.dta"

merge 1:1 household_id2 using "$merge\sect_ag_HH_w2_merge.dta", gen (_merge_356_1_hh2)
	//not matched: 1,616 from master (1,499 are urban HHs, likely no ag activity), 26 from using
	//matched: 3,646
drop if _merge_356_1_hh2==2 //26 obs deleted
	
merge 1:1 household_id2 using "$merge\sect_ls_hh_w2_merge.dta", gen (_merge_356_2_hh2)
	//not matched: 1,603 from master (1,462 are urban HHs, likely no ls activity), 11 from using
	//matched: 3,659
drop if _merge_356_2_hh2==2 //11 obs deleted

merge 1:1 household_id2 using "$input\Ethiopia_W2_AgDev_Farmer Segmentation.dta", gen (_merge_356_3_hh2)
	//not matched: 14 from using
	//matched: 5,262
drop if _merge_356_3_hh2==2 //14 obs deleted

merge 1:1 household_id2 using "$merge/et2_weights_merge.dta", gen (_merge_356_4_hh2)
	//all matched

save "$merge/et2_merged_raw.dta", replace

**********************************************
//Trimming and Creation of New Variables

use "$merge/et2_merged_raw.dta", clear

replace hh_mem_fem=hh_size if hh_mem_fem>hh_size & hh_mem_fem!=. & hh_size!=.
gen hh_mem_male=hh_size-hh_mem_fem
replace hh_mem_male=0 if hh_mem_male==.
la var hh_mem_male "Total Number of Men in HH"

rename total_inorgfert_purchased_value total_inorgfert_value
gen total_paid_income_nonag=total_paid_income-total_paid_income_ag
la var total_paid_income_nonag "(sum) Total non-HH job income from non-ag labor over last 12 months, birr"

gen crop_income_net=value_of_harvest-crop_prod_costs
replace crop_income_net=0 if crop_income_net==.
la var crop_income_net "Net income from crop production (value of harvest - production costs), birr"

replace livestock_sales=0 if livestock_sales==. 
replace livestock_expenses=0 if livestock_expenses==. 
replace value_of_purchased_ls=0 if value_of_purchased_ls==. 
gen livestock_income_net=livestock_sales+ls_value_of_byproduct-livestock_expenses-value_of_purchased_ls-ls_byproduct_costs
replace livestock_income_net=0 if livestock_income_net==.
la var livestock_income_net "Net income from livestock production (value of ls sales+value of byproducts-livestock and byproduct expenses), birr"

**Winsorize top and bottom 1% of selected continuous variables (replace with 1st and 99th percentile)
local trimming enterprise_income_net crop_income_net livestock_income_net field_area_ha field_area_farm area_plant_ha   
winsor2 `trimming', suffix(_w) cuts(1 99)

**Winsorize top 1% of selected continuous variables (replace with 99th percentile) where trimming at the bottom does not make sense
local trimming total_paid_income_nonag total_paid_income_ag other_income assistance_income land_rental_income value_of_harvest /// 
crop_prod_costs value_crop_sales total_inorgfert_value ls_cattle_count ls_poultry_count ls_other_count ls_tropical_units
winsor2 `trimming', suffix(_w) cuts(0 99)

**Replace missings with 0s for non-farm HHs
replace ls_cattle_count_w=0 if ls_cattle_count_w==.
replace ls_poultry_count_w=0 if ls_poultry_count_w==.
replace ls_other_count_w=0 if ls_other_count_w==.
replace ls_tropical_units_w=0 if ls_tropical_units_w==.
replace livestock_income_net_w=0 if livestock_income_net_w==.
replace field_area_ha_w=0 if field_area_ha_w==.
replace field_area_farm_w=0 if field_area_farm_w==.
replace area_plant_ha_w=0 if area_plant_ha_w==.
replace land_rental_income_w=0 if land_rental_income_w==.
replace value_of_harvest_w=0 if value_of_harvest_w==.
replace crop_prod_costs_w=0 if crop_prod_costs_w==.
replace value_crop_sales_w=0 if value_crop_sales_w==.
replace total_inorgfert_value_w=0 if total_inorgfert_value_w==.

gen farm_income=total_paid_income_ag_w+crop_income_net_w+livestock_income_net_w
la var farm_income "Total income from farm sources (net crop income+net livestock income+wages for ag labor), birr)"
gen nonfarm_income=enterprise_income_net_w+total_paid_income_nonag_w+other_income_w+assistance_income_w+land_rental_income_w
la var nonfarm_income "Total income from nonfarm sources (net enterprise+wages for nonag labor+other+assistance+land rental), birr"

**Winsorize top and bottom 1% of new continuous variables (replace with 1st and 99th percentile)
local trimming farm_income nonfarm_income  
winsor2 `trimming', suffix(_w) cuts(1 99)

gen total_income=farm_income_w+nonfarm_income_w
la var total_income "Total income from all sources, birr"

**Convert birr to PPP dollars (instead of exchange rates)
global exchange_rate 19.146 //end Dec 2013 value from http://www.xe.com/currencycharts/?from=USD&to=ETB&view=5Y
global inflation 0.0688 //inflation from 2013 to 2014 https://data.worldbank.org/indicator/FP.CPI.TOTL?locations=TZ-ET&name_desc=true
global monetary_vars farm_income_w nonfarm_income_w total_income value_crop_sales_w value_of_harvest_w total_inorgfert_value_w
foreach p of global monetary_vars {
	gen `p'_usd = (`p' / ${exchange_rate})/(1+${inflation})
}

la var farm_income_w_usd "Total income from farm sources, 2014 USD"
la var nonfarm_income_w_usd "Total income from nonfarm sources, 2014 USD"
la var total_income_usd "Total income from all sources, 2014 USD"
la var value_crop_sales_w_usd "Toral value of crop sales, 2014 USD"
la var value_of_harvest_w_usd "Toral value of crop production, 2014 USD"

gen farm_productivity=value_of_harvest_w_usd/field_area_farm_w //2119 missing values; 503 with 0 farm area, 1616 with missing farm area; 69 observations with non-0 harvest value but 0 farm area
la var farm_productivity "Value of crop harvest/HH farm area, 2014 USD/ha"
winsor2 farm_productivity, suffix(_w) cuts(1 99)

gen inorgfert_ha=total_inorgfert_value_w_usd/area_plant_ha_w //2193 missing values, 0 or missing area planted
la var inorgfert_ha "Value of inorganic fertilizer purchased/HH area planted, 2014 USD/ha"

save "$merge/et2_merged_trimmed.dta", replace

**********************************************
//Creation of New Analysis Variables

use "$merge/et2_merged_trimmed.dta", clear

*Non-farm proportion of HH income
gen nonfarm_income_prop=nonfarm_income_w/total_income //95 missings - total income==0
replace nonfarm_income_prop=0 if nonfarm_income_w<0 //0 share of + income coming from nonfarm sources, 194 changes
replace nonfarm_income_prop=1 if farm_income_w<0 //0 share of + income coming from farm sources, 204 changes
replace nonfarm_income_prop=0 if nonfarm_income_prop==. //0 share if no income, 94 changes
la var nonfarm_income_prop "Proportion of total HH income from non-farm sources"

gen nonfarm_income_prop_cat=0 if nonfarm_income_prop<=0.33 //2372 changes
replace nonfarm_income_prop_cat=1 if nonfarm_income_prop>0.33 & nonfarm_income_prop!=. //2890 changes
la var nonfarm_income_prop_cat "Non-farm income more than 1/3 of total, dummy"

*Farm area categories
gen farm_area_cat=0 if field_area_farm_w==0 //2119
replace farm_area_cat=1 if field_area_farm_w>0 & field_area_farm_w<=4 //2988
replace farm_area_cat=2 if field_area_farm_w>4 & field_area_farm_w!=. //155
la var farm_area_cat "Total HH farm area, 0ha,0<ha<=4,>4ha"

gen non_crop=0
replace non_crop=1 if field_area_farm_w==0 & value_of_harvest_w==0 //2050
la var non_crop "Non-crop household; 0 farm area and 0 value of harvest"

*Alternative criteria for smallholder definitions: different farm area and tropical livestock unit thresholds, can also apply rural dummy
gen farm_area_0_4_ha= farm_area_cat==1
la var farm_area_0_4_ha "Farm area >0 and <=4 ha"

gen farm_area_0_2_ha=0 
replace farm_area_0_2_ha=1 if field_area_farm_w>0 & field_area_farm_w<=2 //2560
la var farm_area_0_2_ha "Farm area >0 and <=2 ha"

gen farm_area_0_40pct_ha=0
_pctile field_area_farm_w [aweight=pw2], p(40)
return list //r(r40)=0.3897
replace farm_area_0_40pct_ha=1 if field_area_farm_w>0 & field_area_farm_w<=r(r1) //938
la var farm_area_0_40pct_ha "Farm area >0 and <=40th percentile of ha"

gen tlu_40pct=0
_pctile ls_tropical_units_w [aweight=pw2], p(40)
return list //r(r40)=1
replace tlu_40pct=1 if ls_tropical_units_w<=r(r1) //2943
la var tlu_40pct "Total TLUs<=40th percentile"

gen tlu_50pct=0
_pctile ls_tropical_units_w [aweight=pw2], p(50)
return list //r(r40)=1
replace tlu_50pct=1 if ls_tropical_units_w<=r(r1) //3303
la var tlu_50pct "Total TLUs<=median"

*Crop commercialization categories
gen prop_crop_value_sold=value_crop_sales_w/value_of_harvest_w //2172 missing values
replace prop_crop_value_sold=0 if value_of_harvest_w==0 //2172 changes
la var prop_crop_value_sold "Proportion of crop production value sold"

gen crop_sales_prop_cat=1 if prop_crop_value_sold<=0.05 //3417
replace crop_sales_prop_cat=2 if prop_crop_value_sold>0.05 & prop_crop_value_sold<=0.5 //1446
replace crop_sales_prop_cat=3 if prop_crop_value_sold>0.5 & prop_crop_value_sold!=. //399
la var crop_sales_prop_cat "Crop sales/Crop production value, <=0.05, 0.05-0.5, >0.5"

*Farmer segment dummy variables
gen lolo = oldsegment==1
gen lohi = oldsegment==2
gen hilo = oldsegment==3
gen hihi = oldsegment==4
la var oldsegment "1=Low Ag Potential/Low Market Access, 2=Low/High, 3=High/Low, 4=High/High"

*Commercialization categorization
gen commercial_cat=.
replace commercial_cat=1 if crop_sales_prop_cat==1 & nonfarm_income_prop_cat==0 //999
replace commercial_cat=2 if crop_sales_prop_cat==2 & nonfarm_income_prop_cat==0 //1081
replace commercial_cat=3 if crop_sales_prop_cat==3 & nonfarm_income_prop_cat==0 //292
replace commercial_cat=4 if (crop_sales_prop_cat==1 | crop_sales_prop_cat==2) & nonfarm_income_prop_cat==1 //2783
replace commercial_cat=5 if crop_sales_prop_cat==3 & nonfarm_income_prop_cat==1 //107
la var commercial_cat "HH commercial. cat.,1subsist.,2pre-comm.,3specialized comm.,4transition,5diversified"

gen cat_subsistence = commercial_cat==1
gen cat_pre_comm = commercial_cat==2
gen cat_spec_comm = commercial_cat==3
gen cat_transition = commercial_cat==4
gen cat_diversified = commercial_cat==5

save "$merge\et2_merged_analysis.dta", replace

///////////////////////////////////////
///			4.2 Summary Statistics		///
///////////////////////////////////////

clear
use "$merge\et2_merged_analysis.dta"

svyset clusterid [pweight=pw2], strata(strataid) singleunit(centered)

//Means by Commercialization Category, Smallholders (0<ha<=4 farm area) Only
local varlist hh_head_fem hh_head_age hh_head_married hh_size hh_mem_fem hh_mem_male hh_mem_15_64 rural_hh lolo lohi hilo hihi phone_own /// 
ls_cattle_count_w ls_poultry_count_w ls_other_count_w field_area_ha_w area_plant_ha_w ///
total_income_ppp farm_income_w_ppp nonfarm_income_w_ppp farm_productivity_w inorgfert_ha nonfarm_income_prop prop_crop_value_sold

eststo des_all: svy, subpop(if farm_area_cat==1): mean `varlist'
matrix N = e(_N)
estadd scalar subpop_N = N[1,1]

eststo des_1: svy, subpop(if farm_area_cat==1 & commercial_cat==1): mean `varlist'
matrix N = e(_N)
estadd scalar subpop_N = N[1,1]

eststo des_2: svy, subpop(if farm_area_cat==1 & commercial_cat==2): mean `varlist'
matrix N = e(_N)
estadd scalar subpop_N = N[1,1]

eststo des_3: svy, subpop(if farm_area_cat==1 & commercial_cat==3): mean `varlist'
matrix N = e(_N)
estadd scalar subpop_N = N[1,1]

eststo des_4: svy, subpop(if farm_area_cat==1 & commercial_cat==4): mean `varlist'
matrix N = e(_N)
estadd scalar subpop_N = N[1,1]

eststo des_5: svy, subpop(if farm_area_cat==1 & commercial_cat==5): mean `varlist'
matrix N = e(_N)
estadd scalar subpop_N = N[1,1]

//Percentage of Smallholder HHs by Commercialization Category
eststo smallholder_cat: svy, subpop(if farm_area_cat==1): mean cat_subsistence cat_pre_comm cat_spec_comm cat_transition cat_diversified

/*
//Summary Stats by Farmer Segment
eststo des_segment_1: estpost sum prop_crop_value_sold_2 nonfarm_income_prop_2 [aweight = pw2] if area_cult_0_w==1 & oldsegment==1, d
eststo des_segment_2: estpost sum prop_crop_value_sold_2 nonfarm_income_prop_2 [aweight = pw2] if area_cult_0_w==1 & oldsegment==2, d
eststo des_segment_3: estpost sum prop_crop_value_sold_2 nonfarm_income_prop_2 [aweight = pw2] if area_cult_0_w==1 & oldsegment==3, d
eststo des_segment_4: estpost sum prop_crop_value_sold_2 nonfarm_income_prop_2 [aweight = pw2] if area_cult_0_w==1 & oldsegment==4, d

eststo des_segment_1: estpost sum prop_crop_value_sold_2 nonfarm_income_prop_2 [aweight = pw2] if area_cult_0_2_w==1 & oldsegment==1, d
eststo des_segment_2: estpost sum prop_crop_value_sold_2 nonfarm_income_prop_2 [aweight = pw2] if area_cult_0_2_w==1 & oldsegment==2, d
eststo des_segment_3: estpost sum prop_crop_value_sold_2 nonfarm_income_prop_2 [aweight = pw2] if area_cult_0_2_w==1 & oldsegment==3, d
eststo des_segment_4: estpost sum prop_crop_value_sold_2 nonfarm_income_prop_2 [aweight = pw2] if area_cult_0_2_w==1 & oldsegment==4, d

eststo des_segment_1: estpost sum prop_crop_value_sold_2 nonfarm_income_prop_2 [aweight = pw2] if area_cult_0_4_w==1 & oldsegment==1, d
eststo des_segment_2: estpost sum prop_crop_value_sold_2 nonfarm_income_prop_2 [aweight = pw2] if area_cult_0_4_w==1 & oldsegment==2, d
eststo des_segment_3: estpost sum prop_crop_value_sold_2 nonfarm_income_prop_2 [aweight = pw2] if area_cult_0_4_w==1 & oldsegment==3, d
eststo des_segment_4: estpost sum prop_crop_value_sold_2 nonfarm_income_prop_2 [aweight = pw2] if area_cult_0_4_w==1 & oldsegment==4, d

eststo des_segment_1: estpost sum prop_crop_value_sold_2 nonfarm_income_prop_2 [aweight = pw2] if area_cult_grtr_4_w==1 & oldsegment==1, d
eststo des_segment_2: estpost sum prop_crop_value_sold_2 nonfarm_income_prop_2 [aweight = pw2] if area_cult_grtr_4_w==1 & oldsegment==2, d
eststo des_segment_3: estpost sum prop_crop_value_sold_2 nonfarm_income_prop_2 [aweight = pw2] if area_cult_grtr_4_w==1 & oldsegment==3, d
eststo des_segment_4: estpost sum prop_crop_value_sold_2 nonfarm_income_prop_2 [aweight = pw2] if area_cult_grtr_4_w==1 & oldsegment==4, d

//Summary Stats by 3x3 Typology
local varlist hh_head_fem hh_head_age hh_mem_fem hh_mem_male hh_mem_15_64 rural_hh field_area_ha_w area_plant_ha_w ls_cattle_count_w ls_poultry_count_w ls_other_count_w ///
phone_own distance_market total_income_2_w farm_productivity_2_w inorg_fert_value_ha_2_w
eststo des_0_4_ha_a_a_both: estpost sum `varlist' [aweight = pw2] if area_cult_0_4_w==1 & crop_sales_prop_cat_2==1 & nonfarm_income_prop_cat_2==1, d
eststo des_0_4_ha_a_b_both: estpost sum `varlist' [aweight = pw2] if area_cult_0_4_w==1 & crop_sales_prop_cat_2==1 & nonfarm_income_prop_cat_2==2, d
eststo des_0_4_ha_a_c_both: estpost sum `varlist' [aweight = pw2] if area_cult_0_4_w==1 & crop_sales_prop_cat_2==1 & nonfarm_income_prop_cat_2==3, d
eststo des_0_4_ha_b_a_both: estpost sum `varlist' [aweight = pw2] if area_cult_0_4_w==1 & crop_sales_prop_cat_2==2 & nonfarm_income_prop_cat_2==1, d
eststo des_0_4_ha_b_b_both: estpost sum `varlist' [aweight = pw2] if area_cult_0_4_w==1 & crop_sales_prop_cat_2==2 & nonfarm_income_prop_cat_2==2, d
eststo des_0_4_ha_b_c_both: estpost sum `varlist' [aweight = pw2] if area_cult_0_4_w==1 & crop_sales_prop_cat_2==2 & nonfarm_income_prop_cat_2==3, d
eststo des_0_4_ha_c_a_both: estpost sum `varlist' [aweight = pw2] if area_cult_0_4_w==1 & crop_sales_prop_cat_2==3 & nonfarm_income_prop_cat_2==1, d
eststo des_0_4_ha_c_b_both: estpost sum `varlist' [aweight = pw2] if area_cult_0_4_w==1 & crop_sales_prop_cat_2==3 & nonfarm_income_prop_cat_2==2, d
eststo des_0_4_ha_c_c_both: estpost sum `varlist' [aweight = pw2] if area_cult_0_4_w==1 & crop_sales_prop_cat_2==3 & nonfarm_income_prop_cat_2==3, d

//HH counts by 3x3 typology and Farmer Segment
tab crop_sales_prop_cat_2 nonfarm_income_prop_cat_2 if area_cult_0_4_w==1 & oldsegment==1
tab crop_sales_prop_cat_2 nonfarm_income_prop_cat_2 if area_cult_0_4_w==1 & oldsegment==2
tab crop_sales_prop_cat_2 nonfarm_income_prop_cat_2 if area_cult_0_4_w==1 & oldsegment==3
tab crop_sales_prop_cat_2 nonfarm_income_prop_cat_2 if area_cult_0_4_w==1 & oldsegment==4
*/

///////////////////////////////////
//4.3 Output data for visualizations
///////////////////////////////////

**Original estimates

use "$merge\et2_merged_analysis.dta", clear

keep household_id2 rural_hh hh_size hh_mem_fem hh_mem_male hh_mem_15_64 hh_head_fem hh_head_age hh_head_married hh_head_education oldsegment phone_own ///
ls_cattle_count_w ls_poultry_count_w ls_other_count_w ls_tropical_units_w field_area_ha_w area_plant_ha_w farm_area_cat farm_productivity_w inorgfert_ha ///
value_crop_sales_w_usd value_of_harvest_w_usd prop_crop_value_sold crop_sales_prop_cat total_income_usd farm_income_w_usd nonfarm_income_w_usd ///
nonfarm_income_prop nonfarm_income_prop_cat commercial_cat tlu_40pct tlu_50pct farm_area_0_4_ha farm_area_0_2_ha farm_area_0_40pct_ha

export delimited using "$merge\ETH_Wave2_Viz Data_Updated.csv", replace
