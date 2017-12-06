
/*-----------------------------------------------------------------------------------------------------------------------------------------------------
*Title/Purpose 	: This do.file was developed by the Evans School Policy Analysis & Research Group (EPAR) 
				  to categorize smallholder farm households based on their degree of crop commercialization and livelihood diversification
				  and to generate summary statistics for households in different categories of commercialization
				  using the Tanzania National Panel Survey (TNPS) LSMS-ISA Wave 3 (2012-13)
*Author		    : Pierre Biscaye

*Date			: 31 October 2017

----------------------------------------------------------------------------------------------------------------------------------------------------*/

*Data source
*-----------
*The Tanzania National Panel Survey was collected by the Tanzania National Bureau of Statistics (NBS) 
*and the World Bank's Living Standards Measurement Study - Integrated Surveys on Agriculture(LSMS - ISA)
*The data were collected over the period October 2012 to November 2013.
*All the raw data, questionnaires, and basic information documents are available for downloading free of charge at the following link
*http://microdata.worldbank.org/index.php/catalog/2252

*We also use a separate data file prepared by the Bill & Melinda Gates Foundation which uses ESS data to categorize households according to whether they live in areas with high or low market and agricultural potential. We provide this data file separately from the raw World Bank data.

*Throughout the do-file, we sometimes use the shorthand LSMS to refer to the Tanzania National Panel Survey.

*Summary of Executing the Master do.file
*-----------
*This Master do.file constructs selected indicators using the Tanzania TNPS (TZA LSMS) data set.
*First save the raw unzipped data files from the World Bank in a new "input" folder that you must create. Do not change the structure or organization of the unzipped raw data files. 
*Also download and save the "Tanzania_W3_AgDev_Farmer Segmentation" file in this folder (from the GitHub repository "AGRA Report Supplemental dta Files" folder).

*The do. file constructs needed intermediate variables, saving dta files when appropriate in "merge" and "collapse" folders that you will need to create.

*The code first generates needed intermediate and final variables from the agriculture, livestock, and household questionnaires.
*These data files are then aggregated and cleaned for analysis at the household level, including construction of a farmer typology variable and estimation of summary statistics. We then output selected variables for use in the Project 356 data visualization on the EPAR website.

*********************************
/*OUTLINE of .do file contents
*********************************

1.1 REMOVE DUPLICATES IN SELECTED AG SECTIONS
1.2 PREPARE PLOT LEVEL DATA
1.3 PREPARE PLOT-CROP LEVEL DATA
1.4 PREPARE CROP LEVEL DATA
1.5 PREPARE OTHER AG SECTIONS DATA
1.6 MERGE ALL AG SECTIONS
	created file: "$merge/AG_sections_prepped.dta"

2.1 PREPARE LIVESTOCK DATA
2.2 PREPARE LIVESTOCK BY-PRODUCTS DATA
2.3 PREPARE FISHERIES DATA
2.4 MERGE ALL LIVESTOCK SECTIONS
	created file: "$collapse\LS_section_collapse_hh.dta"

3.1 PREPARE HOUSEHOLD ASSETS DATA
3.2 PREPARE HOUSEHOLD ROSTER DATA
3.3 PREPARE OFF-FARM INCOME DATA
3.4 PREPARE NON-FARM ENTERPRISES DATA
3.5 PREPARE OTHER INCOME DATA
3.6 MERGE ALL HOUSEHOLD SECTIONS
	created file:"$collapse\HH_section_collapse_hh.dta"

4.1 MERGE ALL SECTIONS FOR ANALYSIS
	created file: "$merge/tz3_merged_raw.dta"
4.2 TRIM AND CLEAN DATA
	created file: "$merge/tz3_merged_trimmed.dta"
4.3 CREATE NEW ANALYSIS VARIABLES
	created file: "$merge\tz3_merged_analysis.dta"
4.4 SUMMARY STATISTICS
4.5 OUTPUT DATA FOR VISUALIZATIONS

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

***************************************
///// 1.1 REMOVE DUPLICATES IN SELECTED AG SECTIONS /////
***************************************
{
**4A: crops by plots, LRS (annual crops)
clear
use "$input\Agriculture\AG_SEC_4A.dta"

*isid y3_hhid plotnum zaocode//we have some duplicate crops on the same plot
//now identifying plots with the same crop on plot twice
// use duplicates tag command to find obs that are preventing the unique idenitfier
duplicates tag y3_hhid plotnum zaocode, gen(duptag)
tab duptag // 11 obs duplicates 
*br if duptag ==1 | duptag==2 

sort y3_hhid plotnum zaocode // this code give unique dup identifier so that it can be dropped
quietly by y3_hhid plotnum zaocode:  gen dups = cond(_N==1,0,_n)
replace dups=. if dups==1 | dups ==0
label var dups "zaocode duplicates"

gen zaocode2=.
//three HHs have 'other' crops planted on same plot (thus cannot uniquely identify) 
replace zaocode2=899+dups if zaocode==998 & dups!=. //for "other" duplicates 90_
replace zaocode2=1299+dups if zaocode==31 & dups!=. //for beans duplicates 130_

replace zaocode=zaocode2 if dups!=. //replace zaocode value with new zaocode value if it is a duplicate

drop dups duptag // no longer needed
drop if zaocode==. //2249 obs

*isid y3_hhid plotnum zaocode, missok // ok
save "$merge\AG_SEC_4A_prepped.dta", replace

**4B: crops by plots, SRS (annual crops)
clear
use "$input\Agriculture\AG_SEC_4B.dta"

*isid y3_hhid plotnum zaocode//we have some duplicate crops on the same plot
//now identifying plots with the same crop on plot twice
// use duplicates tag command to find obs that are preventing the unique idenitfier
duplicates tag y3_hhid plotnum zaocode, gen(duptag)
tab duptag // 0 obs duplicates 
drop if zaocode==. //4225 obs

*isid y3_hhid plotnum zaocode, missok // ok
save "$merge\AG_SEC_4B_prepped.dta", replace

**5A: crops HH totals, LRS 
use "$input\Agriculture\AG_SEC_5A.dta", clear

*isid y3_hhid zaocode, missok // not a unique id
*Goal: get the unique id to be y3_hhid and zaocode

duplicates tag y3_hhid zaocode, gen(duptag)
tab duptag // 9 duplicates
*br if duptag !=0 

sort y3_hhid zaocode // this code give unique dup identifier so that it can be dropped
quietly by y3_hhid zaocode:  gen dups = cond(_N==1,0,_n)
replace dups=. if dups==1 | dups ==0
label var dups "zaocode duplicates"

gen zaocode2=.
replace zaocode2=899+dups if zaocode==998 & dups!=. //for "other" duplicates 90_
label var zaocode2 "new zaocode for duplicates"

replace zaocode=zaocode2 if dups!=. //replace zaocode value with new zaocode value if it is a duplicate

drop dups duptag
drop if zaocode==. //2266 obs

isid y3_hhid zaocode, missok
save "$merge\AG_SEC_5A_prepped.dta", replace

**5B: crops HH totals, SRS 
use "$input\Agriculture\AG_SEC_5B.dta", clear

*isid y3_hhid zaocode, missok // not a unique id
*Goal: get the unique id to be y3_hhid and zaocode

duplicates tag y3_hhid zaocode, gen(duptag)
tab duptag // 0 duplicates

drop if zaocode==. //4234 obs

save "$merge\AG_SEC_5B_prepped.dta", replace

**6A: fruit crops
clear
use "$input\Agriculture\AG_SEC_6A.dta" 
*isid y3_hhid plotnum zaocode //we have some duplicate crops on the same plot

//identifying plots with the same crop on plot twice
//use duplicates tag command to find obs that are preventing the unique idenitfier
duplicates tag y3_hhid plotnum zaocode, gen(duptag)
tab duptag // 24 duplicates
*br if duptag ==1 //problems are banana, mango, and other crops

sort y3_hhid plotnum zaocode // this code give unique dup identifier so that it can be dropped
quietly by y3_hhid plotnum zaocode:  gen dup = cond(_N==1,0,_n)
replace dup=. if dup==1 | dup ==0

//four households have two banana obs on plot. One hh has two mango observations. 
gen zaocode2=.
replace zaocode2=899+dup if zaocode==998 & dup!=. //for "other" duplicates 90_
replace zaocode2=1099+dup if zaocode==71 & dup!=. //for banana duplicates 110_
replace zaocode2=1199+dup if zaocode==73 & dup!=. //for mango duplicates 120_

replace zaocode=zaocode2 if dup!=. //replace zaocode value with new zaocode value if it is a duplicate

drop dup duptag //no longer needed
drop if zaocode==. //3126 obs
drop if plotnum=="." //0
*isid y3_hhid plotnum zaocode, missok 
save "$merge\AG_SEC_6A_prepped.dta", replace

**6B: Permanent crops
clear
use "$input\Agriculture\AG_SEC_6B"
*isid y3_hhid plotnum zaocode, missok //duplicates
duplicates tag y3_hhid plotnum zaocode, gen(duptag)
tab duptag // 105 duplicates
*br if duptag !=0 

//identifying plots with the same crop on plot twice
//use duplicates tag command to find obs that are preventing the unique idenitfier
sort y3_hhid plotnum zaocode // this code give unique dup identifier so that it can be dropped
quietly by y3_hhid plotnum zaocode:  gen dups = cond(_N==1,0,_n)
replace dups=. if dups==1 | dups ==0

gen zaocode2=.
replace zaocode2=399+dups if zaocode==304 & dups!=. //for timber duplicates: 40_
replace zaocode2=499+dups if zaocode==303 & dups!=. //for firewood/fodder duplicates 50_
replace zaocode2=599+dups if zaocode==21 & dups!=. // for cassava duplicates 60_
replace zaocode2=699+dups if zaocode==45 & dups!=. //for coconut duplicates 70_
replace zaocode2=799+dups if zaocode==46 & dups!=. //for cashew duplicates 80_
replace zaocode2=899+dups if zaocode==998 & dups!=. //for "other" duplicates 90_
replace zaocode2=999+dups if zaocode==54 & dups!=. //for coffee duplicates 100_
label var zaocode2 "new zaocode for duplicates"

replace zaocode=zaocode2 if dups!=. //replace zaocode value with new zaocode value if it is a duplicate

drop dups duptag
drop if zaocode==. //3051 obs
drop if plotnum=="." //0
*isid y3_hhid plotnum zaocode
save "$merge\AG_SEC_6B_prepped.dta", replace

**7A: Fruit crops
clear
use "$input\Agriculture\AG_SEC_7A"
*isid y3_hhid zaocode, missok
duplicates tag y3_hhid zaocode, gen(duptag)
tab duptag // 17 duplicates
*br if duptag !=0 

sort y3_hhid zaocode // this code give unique dup identifier so that it can be dropped
quietly by y3_hhid zaocode:  gen dups = cond(_N==1,0,_n)
replace dups=. if dups==1 | dups ==0
label var dups "zaocode duplicates"

gen zaocode2=.
replace zaocode2=899+dups if zaocode==998 & dups!=. //for "other" duplicates 90_
replace zaocode2=1099+dups if zaocode==71 & dups!=. //for banana duplicates 110_

replace zaocode=zaocode2 if dups!=. //replace zaocode value with new zaocode value if it is a duplicate

drop dups duptag //no longer needed
drop if zaocode==. //3129 obs
isid y3_hhid zaocode, missok
save "$merge\AG_SEC_7A_prepped.dta", replace

**7B: Permanent crops
clear 
use "$input\Agriculture\AG_SEC_7B"
*isid y3_hhid zaocode, missok

duplicates tag y3_hhid zaocode, gen(duptag)
tab duptag // 56 duplicates
*br if duptag !=0 

sort y3_hhid zaocode // this code give unique dup identifier so that it can be dropped
quietly by y3_hhid zaocode:  gen dups = cond(_N==1,0,_n)
replace dups=. if dups==1 | dups ==0
label var dups "zaocode duplicates"

gen zaocode2=.
replace zaocode2=399+dups if zaocode==304 & dups!=. //for timber duplicates: 40_
replace zaocode2=499+dups if zaocode==303 & dups!=. //for firewood/fodder duplicates 50_
replace zaocode2=599+dups if zaocode==21 & dups!=. // for cassava duplicates 60_
replace zaocode2=899+dups if zaocode==998 & dups!=. //for "other" duplicates 90_
replace zaocode2=999+dups if zaocode==54 & dups!=. //for coffee duplicates 100_
label var zaocode2 "new zaocode for duplicates"

replace zaocode=zaocode2 if dups!=. //replace zaocode value with new zaocode value if it is a duplicate

drop dups duptag
drop if zaocode==. //3057 obs
isid y3_hhid zaocode, missok
save "$merge\AG_SEC_7B_prepped.dta", replace

}



***************************************
///// 1.2 PLOT LEVEL DATA /////
***************************************
{
**start with 2A: LRS plot numbers (Ms)
clear
use "$input\Agriculture\AG_SEC_2A.dta" 

**adding in SRS for SEC_2B
merge 1:1 y3_hhid plotnum using "$input\Agriculture\AG_SEC_2B.dta", gen (_merge_SEC_2B)
** 1699 matched, 10772 not matched; GPS area measurement is the same on all matched plots

keep y3_hhid plotnum plotname ag2a_04 ag2a_09 ag2b_15 ag2b_20 //just the area measures

**add in 3A: LRS plot details
merge 1:1 y3_hhid plotnum using "$input\Agriculture\AG_SEC_3A.dta", gen (_plotLRS_plotdetails)
** 9157 matched, 3314 not matched from master
isid y3_hhid plotnum,missok // ok

**add in 3B: SRS plot details
merge 1:m y3_hhid plotnum using "$input\Agriculture\AG_SEC_3B.dta", gen (_plotSRS_plotdetails)
** 9173 matched, 3298 not matched from master
isid y3_hhid plotnum,missok // ok

drop if plotnum == ""  //49977 deleted

save "$merge\AG_SEC_2A2B3A3B_raw.dta", replace

**************Plot size************
gen plotsize_ha = ag2a_04*0.404685642 //27 missing
replace plotsize_ha = ag2b_15*0.404685642 if plotsize_ha==. //27 changes
la var plotsize_ha "Farmer reported plot size in hectares"

gen plotsize_ha_gps = ag2a_09* 0.404685642 //2078 missing
replace plotsize_ha_gps = ag2b_20*0.404685642 if plotsize_ha_gps==. //9 changes
la var plotsize_ha_gps "GPS measured plot size in hectares"

gen plot_area = plotsize_ha_gps //2069 missing
replace plot_area = plotsize_ha if plot_area ==. //2069 changes
la var plot_area "plot area measure, ha - GPS-based if they have one, farmer-report if not"

gen plot_area_cultivated=0 
replace plot_area_cultivated=plot_area if ag3a_40==1 | ag3b_40==1 //6506 changes
la var plot_area_cultivated "Area for plots cultivated in LRS or SRS, ha"

gen plot_area_farm=0
replace plot_area_farm=plot_area if ag3a_03==1 | ag3a_03==4 | ag3b_03==1 | ag3b_03==4 | ag3a_40==1 | ag3b_40==1 //cultivated or fallow, either season, 7183 changes
la var plot_area_farm "Area for plots cultivated or fallow in LRS or SRS, ha"

*******************Land rental cost and income****************
egen land_rental_income=rowtotal(ag3a_04 ag3b_04) //income in cash and in kind across both seasons
la var land_rental_income "How much did you receive for renting out this plot, cash and in-kind value, TSH"

gen land_value=ag3a_24 //33 missing
replace land_value=ag3b_24 if land_value==. //26 changes
la var land_value "Value of the plot if sold today, TSH"

egen land_rental_cost=rowtotal(ag3a_33 ag3b_33) //rental cost in cash and in kind across both seasons
la var land_rental_cost "How much did you pay for use of this plot, cash and in-kind value, TSH"

*******************Input costs*********************
egen input_purchased_cost=rowtotal(ag3a_45 ag3a_51 ag3a_58 ag3a_63 ag3b_45 ag3b_51 ag3b_58 ag3b_63) //sum of costs for organic and inorganic fertilizer and pesticides/herbicides in both seasons
la var input_purchased_cost "Cost of purchased organic and inorganic fertilizer and pesticides/herbicide, TSH"

egen inorgfert_purchased_cost=rowtotal(ag3a_51 ag3a_58 ag3b_51 ag3b_58) //inorganic fertilizer costs only, both seasons
la var inorgfert_purchased_cost "Cost of purchased inorganic fertilizer, TSH"

egen labor_hired_cost=rowtotal(ag3a_74_4 ag3a_74_8 ag3a_74_12 ag3a_74_16 ag3b_74_4 ag3b_74_8 ag3b_74_12 ag3b_74_16) //total wages paid for land prep & planting, weeding, ridging & fertilizing, and harvesting, both seasons
la var labor_hired_cost "Cost of hired labor, all activities, TSH"

*************Land use**************************
gen cultivated_lrs = ag3a_40==1
gen cultivated_srs = ag3b_40==1
la var cultivated_lrs "Plot cultivated in LRS"
la var cultivated_srs "Plot cultivated in SRS"

save "$merge\AG_SEC_2A2B3A3B_prepped.dta", replace

//collapse to HH level
collapse (sum) plot_area plot_area_cultivated plot_area_farm land_rental_cost land_rental_income land_value input_purchased_cost inorgfert_purchased_cost labor_hired_cost, by (y3_hhid)
la var plot_area "(sum) Plot area, ha"
la var plot_area_cultivated "(sum) Area for plots cultivated in LRS or SRS, ha"
la var plot_area_farm "(sum) Area for plots cultivated or fallow in LRS or SRS, ha"
la var land_rental_income "(sum) Plot rental income, cash and in-kind value, TSH"
la var land_value "(sum) Value of the plot if sold today, TSH"
la var land_rental_cost "(sum) Plot rental cost, cash and in-kind value, TSH"
la var input_purchased_cost "(sum) Cost of purchased organic and inorganic fertilizer and pesticides/herbicide, TSH"
la var inorgfert_purchased_cost "Cost of purchased inorganic fertilizer, TSH"
la var labor_hired_cost "(sum) Cost of hired labor, all activities, TSH"

save "$collapse\AG_SEC_2A2B3A3B_collapse.dta", replace
}
***************************************
///// 1.3 PLOT-CROP LEVEL DATA /////
***************************************
{
* LRS *

*First starting with field sizes
use "$merge\AG_SEC_2A2B3A3B_prepped.dta", clear
keep plot_area cultivated_lrs cultivated_srs y3_hhid plotnum

**Section 4A CROPS BY PLOT, LRS (ANNUAL CROPS)
merge 1:m y3_hhid plotnum using "$merge\AG_SEC_4A_prepped.dta", gen(_plotLRS_crop)
//7,934 matched, 2,546 not matched from master - including 1334 plots not cultivated in LRS but 1212 plots listed as cultivated in LRS
drop if zaocode==. //2546 observations deleted, all plots not matched from master
//now at plot-crop level

duplicates report y3_hhid plotnum zaocode		// 0 duplicates, already taken care of above
*duplicates drop y3_hhid plotnum zaocode, force	

*Percent of area
gen pure_stand = ag4a_01==1
gen percent_field = 0.25 if ag4a_02==1
replace percent_field = 0.50 if ag4a_02==2
replace percent_field = 0.75 if ag4a_02==3
replace percent_field = 1 if pure_stand==1
replace percent_field = 1 if percent_field==. //2 changes

*Total area on plot
bys y3_hhid plotnum: egen total_percent_field = total(percent_field)			// total on plot across ALL crops
replace percent_field = percent_field/total_percent_field if total_percent_field>1			// Rescaling, 3566 changes

gen crop_area_planted = percent_field*plot_area
la var crop_area_planted "Area planted with [crop], LRS, ha"

*Seed costs
gen seed_cost=ag4a_12
replace seed_cost=0 if seed_cost==.
la var seed_cost "Cost for purchased seed, TSH"

*ag4a_28 "What was the quantity harvested?(KGs)"
gen harv_quant_kg = .
replace harv_quant_kg = ag4a_28
replace harv_quant_kg =0 if ag4a_20==3 //153 changes, no harvest because of destruction
label var harv_quant_kg "(ag4a_28) Harvested Quantity(KGs), LRS_2012"

*ag4a_29 "What is the estimated value of the harvest crop? (TZ_Shillings)"
gen harv_value_tsh = .
replace harv_value_tsh = ag4a_29
replace harv_value_tsh =0 if ag4a_20==3 //153 changes, no harvest because of destruction
label var harv_value_tsh "(ag4a_29) Value of Harvested Crop (Tz_Shillings), LRS_2012"

save "$merge\AG_SEC_4A_prepped2.dta", replace

collapse (sum) crop_area_planted seed_cost harv_quant_kg harv_value_tsh, by (y3_hhid zaocode)
la var crop_area_planted "Area planted with [crop], ha"
la var seed_cost "Cost for purchased seed, TSH"
la var harv_quant_kg "Harvested Quantity, kg"
la var harv_value_tsh "Value of Harvested Crop, TSH"

save "$collapse\AG_SEC_4A_croplevel.dta", replace

* SRS *

*First starting with field sizes
use "$merge\AG_SEC_2A2B3A3B_prepped.dta", clear
keep plot_area cultivated_lrs cultivated_srs y3_hhid plotnum

**Section 4B CROPS BY PLOT, SRS (ANNUAL CROPS)
merge 1:m y3_hhid plotnum using "$merge\AG_SEC_4B_prepped.dta", gen(_plotSRS_crop)
//2,225 matched, 6,201 not matched from master - including 5,788 plots not cultivated in SRS but 413 plots listed as cultivated in SRS
drop if zaocode==. //6,201 observations deleted, all plots not matched from master
//now at plot-crop level

duplicates report y3_hhid plotnum zaocode		// 0 duplicates, already taken care of above
*duplicates drop y3_hhid plotnum zaocode, force	

*Percent of area
gen pure_stand = ag4b_01==1
gen percent_field = 0.25 if ag4b_02==1
replace percent_field = 0.50 if ag4b_02==2
replace percent_field = 0.75 if ag4b_02==3
replace percent_field = 1 if pure_stand==1
replace percent_field = 1 if percent_field==. //2 changes

*Total area on plot
bys y3_hhid plotnum: egen total_percent_field = total(percent_field)			// total on plot across ALL crops
replace percent_field = percent_field/total_percent_field if total_percent_field>1			// Rescaling, 3566 changes

gen crop_area_planted = percent_field*plot_area
la var crop_area_planted "Area planted with [crop], SRS, ha"

*Seed costs
gen seed_cost=ag4b_12
replace seed_cost=0 if seed_cost==.
la var seed_cost "Cost for purchased seed, TSH"

*ag4a_28 "What was the quantity harvested?(KGs)"
gen harv_quant_kg = .
replace harv_quant_kg = ag4b_28
replace harv_quant_kg =0 if ag4b_20==3 //68 changes, no harvest because of destruction
label var harv_quant_kg "(ag4b_28) Harvested Quantity(KGs), SRS"

*ag4a_29 "What is the estimated value of the harvest crop? (TZ_Shillings)"
gen harv_value_tsh = .
replace harv_value_tsh = ag4b_29
replace harv_value_tsh =0 if ag4b_20==3 //68 changes, no harvest because of destruction
label var harv_value_tsh "(ag4b_29) Value of Harvested Crop (Tz_Shillings), SRS"

save "$merge\AG_SEC_4B_prepped2.dta", replace

collapse (sum) crop_area_planted seed_cost harv_quant_kg harv_value_tsh, by (y3_hhid zaocode)
rename crop_area_planted crop_area_planted_SRS
rename seed_cost seed_cost_SRS
rename harv_quant_kg harv_quant_kg_SRS
rename harv_value_tsh harv_value_tsh_SRS
la var crop_area_planted_SRS "Area planted with [crop], ha"
la var seed_cost_SRS "Cost for purchased seed, TSH"
la var harv_quant_kg_SRS "Harvested Quantity, kg"
la var harv_value_tsh_SRS "Value of Harvested Crop, TSH"

save "$collapse\AG_SEC_4B_croplevel.dta", replace

* FRUIT *

*First starting with field sizes
use "$merge\AG_SEC_2A2B3A3B_prepped.dta", clear
keep plot_area cultivated_lrs cultivated_srs y3_hhid plotnum

**Section 6A: fruit crops
merge 1:m y3_hhid plotnum using "$merge\AG_SEC_6A_prepped.dta", gen (_plot_fruit)
//5,669 matched, 4,899 not matched from master
drop if zaocode==. //4,899 observations deleted
//now at plot-crop level

duplicates report y3_hhid plotnum zaocode		// 0 duplicates, already taken care of above
*duplicates drop y3_hhid plotnum zaocode, force	

gen number_fruits = ag6a_02
la var number_fruits "number of plants/trees on the plot (ag6a_02)"

gen harvest_quant_fruit = ag6a_09
la var harvest_quant_fruit "total amount of fruit harvested (ag6a_09)"

save "$merge\AG_SEC_6A_prepped2.dta", replace

collapse (sum) number_fruits harvest_quant_fruit, by (y3_hhid zaocode)
la var number_fruits "number of plants/trees on the plot"
la var harvest_quant_fruit "total amount of fruit harvested, kgs"

save "$collapse\AG_SEC_6A_croplevel.dta", replace

* PERMANENT *

*First starting with field sizes
use "$merge\AG_SEC_2A2B3A3B_prepped.dta", clear
keep plot_area cultivated_lrs cultivated_srs y3_hhid plotnum

**Section 6B: other permanent crops
merge 1:m y3_hhid plotnum using "$merge\AG_SEC_6B_prepped.dta", gen (_plot_fruit)
//4,675 matched, 4,275 not matched from master
drop if zaocode==. //4,275 observations deleted
//now at plot-crop level

duplicates report y3_hhid plotnum zaocode		// 0 duplicates, already taken care of above
*duplicates drop y3_hhid plotnum zaocode, force	

gen number_perm = ag6b_02
la var number_perm "number of plants/trees on the plot (ag6b_02)"

gen harvest_quant_perm = ag6b_09
la var harvest_quant_perm "total amount of permanent crop harvested (ag6b_09)"

save "$merge\AG_SEC_6B_prepped2.dta", replace

collapse (sum) number_perm harvest_quant_perm, by (y3_hhid zaocode)
la var number_perm "number of plants/trees on the plot"
la var harvest_quant_perm "total amount of permanent crop harvested, kgs"

save "$collapse\AG_SEC_6B_croplevel.dta", replace
}
***************************************
///// 1.4 CROP LEVEL DATA /////
***************************************
{
* FRUIT AND PERMANENT CROPS *

use "$input\Agriculture\AG_SEC_A.dta", clear
keep y3_hhid ag_a01_1 ag_a02_1 ag_a03_1 ag_a04_1

**FRUIT
merge 1:m y3_hhid using "$collapse\AG_SEC_6A_croplevel.dta", gen (_fruit)
//matched 4,934, not matched 3,125 from master

merge 1:1 y3_hhid zaocode using "$collapse\AG_SEC_6B_croplevel.dta", gen (_fruit_perm)
//matched 9 (other crops), not matched 8,050 from master, 3,557 from using

**add in 7A: Fruit crops total
merge 1:1 y3_hhid zaocode using "$collapse\AG_SEC_7A_prepped.dta", gen (_fruit_total)
**4884 matched, 6,734 not matched from master, 2 not matched from using (renamed duplicate crops)

**add in 7B: Permanent crops total
merge 1:1 y3_hhid zaocode using "$collapse\AG_SEC_7B_prepped.dta", gen (_perm_total)
**3516 matched, 8,102 not matched from master, 8 not matched from using (all renamed duplicate crops)

drop if zaocode==. //3125 obs deleted

//Fruit Price
gen fruit_sold_quant = ag7a_03
replace fruit_sold_quant = 0 if ag7a_03==. //7634 changes
gen fruit_sold_value = ag7a_04 //7634 missings
gen fruit_sold_price=fruit_sold_value/fruit_sold_quant //7634 missings

//Permanent Price
gen perm_sold_quant =ag7b_03
replace perm_sold_quant = 0 if ag7b_03==. //7580 changes
gen perm_sold_value = ag7b_04 //7581 missings
gen perm_sold_price=perm_sold_value/perm_sold_quant //7581 missings

//Generating spatial variables to back out prices for those households that produce fruit and permanent crops but do not sell them
egen ea_median_fruit_price=median(fruit_sold_price), by(zaocode ag_a01_1 ag_a02_1 ag_a04_1)
egen district_median_fruit_price=median(fruit_sold_price), by(zaocode ag_a01_1 ag_a02_1 )
egen region_median_fruit_price=median(fruit_sold_price), by(zaocode ag_a01_1)
egen nation_median_fruit_price=median(fruit_sold_price), by(zaocode)

egen ea_median_perm_price=median(perm_sold_price), by(zaocode ag_a01_1 ag_a02_1 ag_a04_1)
egen district_median_perm_price=median(perm_sold_price), by(zaocode ag_a01_1 ag_a02_1)
egen region_median_perm_price=median(perm_sold_price), by(zaocode ag_a01_1)
egen nation_median_perm_price=median(perm_sold_price), by(zaocode)

//Calculating the count of prices at different levels
egen ea_median_fruit_price_ct=count(fruit_sold_price), by(zaocode ag_a01_1 ag_a02_1 ag_a04_1)
egen district_median_fruit_price_ct=count(fruit_sold_price), by(zaocode ag_a01_1 ag_a02_1)
egen region_median_fruit_price_ct=count(fruit_sold_price), by(zaocode ag_a01_1)
egen nation_median_fruit_price_ct=count(fruit_sold_price), by(zaocode)

egen ea_median_perm_price_ct=count(perm_sold_price), by(zaocode ag_a01_1 ag_a02_1 ag_a04_1)
egen district_median_perm_price_ct=count(perm_sold_price), by(zaocode ag_a01_1 ag_a02_1)
egen region_median_perm_price_ct=count(perm_sold_price), by(zaocode ag_a01_1)
egen nation_median_perm_price_ct=count(perm_sold_price), by(zaocode)

//Generating Perennial Crop Value, use own HH sales price if available, median price from lowest geography with >=10 price observations if not
gen fruit_value = .
replace fruit_value = harvest_quant_fruit*(fruit_sold_price) //866
replace fruit_value = harvest_quant_fruit*(ea_median_fruit_price) if fruit_value==. & ea_median_fruit_price_ct>=10 //0
replace fruit_value = harvest_quant_fruit*(district_median_fruit_price) if fruit_value==. & district_median_fruit_price_ct>=10 //152
replace fruit_value = harvest_quant_fruit*(region_median_fruit_price) if fruit_value==. & region_median_fruit_price_ct>=10 //1212
replace fruit_value = harvest_quant_fruit*(nation_median_fruit_price) if fruit_value==. //2649
//tab zaocode if fruit_value==. & harvest_quant_fruit!=. *55 obs with missing values but non-missing quantities
//missing values for 1 cassava, cocoyams, malay apple, pomelo, durian, and mitobo, 23 plum, 18 peaches, and 8 "other"
//these will be given a value of 0

gen perm_value = .
replace perm_value = (harvest_quant_perm)*(perm_sold_price) //919
replace perm_value = (harvest_quant_perm)*(ea_median_perm_price) if perm_value==. & ea_median_perm_price_ct>=10 //2134
replace perm_value = (harvest_quant_perm)*(district_median_perm_price) if perm_value==. & district_median_perm_price_ct>=10 //0
replace perm_value = (harvest_quant_perm)*(region_median_perm_price) if perm_value==. & region_median_perm_price_ct>=10 //0
replace perm_value = (harvest_quant_perm)*(nation_median_perm_price) if perm_value==. //410
//tab zaocode if fruit_value==. & harvest_quant_fruit!=. *55 obs with missing values but non-missing quantities
//missing values for 2 sweet potato, 7 yams, 1 rubber, 6 kapok, 1 banana, 1 pineapple, 2 grapes, 11 medicinal plant, 17 fence tree, and 56 other
//these will be given a value of 0

egen perennial_value = rowtotal(fruit_value perm_value)
la var perennial_value "Value of fruit and permanent crop production, TSH"

egen perennial_sales = rowtotal(fruit_sold_value perm_sold_value)
la var perennial_sales "Value of fruit and permanent crop sales, TSH"

save "$merge/fruit_perm_prep.dta", replace

collapse (sum) perennial_value perennial_sales, by(y3_hhid)
la var perennial_value "(sum) Value of fruit and permanent crop production, TSH"
la var perennial_sales "(sum) Value of fruit and permanent crop sales, TSH"

save "$collapse/fruit_perm_collapse.dta", replace

* ANNUAL CROPS *

use "$input\Agriculture\AG_SEC_A.dta", clear
keep y3_hhid ag_a01_1 ag_a02_1 ag_a03_1 ag_a04_1

merge 1:m y3_hhid using "$collapse\AG_SEC_4A_croplevel.dta", gen (_LRS)
//matched 6,239, not matched 2,249 from master

merge 1:1 y3_hhid zaocode using "$collapse\AG_SEC_4B_croplevel.dta", gen (_LRS_SRS)
//matched 547 (crops grown by HH in both seasons), not matched 7,941 from master, 1,131 from using (crops grown by HH only in SRS)

**add in 5A: LRS crops total
merge 1:1 y3_hhid zaocode using "$collapse\AG_SEC_5A_prepped.dta", gen (_LRS_total)
**matched 6,153; 3,466 not matched from master, 3 not matched from using (renamed duplicate crops)

**add in 5B: SRS crops total
merge 1:1 y3_hhid zaocode using "$collapse\AG_SEC_5B_prepped.dta", gen (_SRS_total)
**1,648 matched, 7,974 not matched from master, 2 not matched from using (renamed duplicate crops)

drop if zaocode==. //2249 obs deleted

//LRS Price
gen LRS_sold_quant = ag5a_02
replace LRS_sold_quant = 0 if ag5a_02==. //5042 changes
gen LRS_sold_value = ag5a_03 //5042 missings
gen LRS_sold_price=LRS_sold_value/LRS_sold_quant //5042 missings

//SRS Price
gen SRS_sold_quant =ag5b_02
replace SRS_sold_quant = 0 if ag5b_02==. //6880 changes
gen SRS_sold_value = ag5b_03 //6880 missings
gen SRS_sold_price=SRS_sold_value/SRS_sold_quant //6880 missings

//Transport costs
egen sales_transport_costs=rowtotal(ag5a_22 ag5b_22)
la var sales_transport_costs "Crop sales transport expenses, TSH"

//Residue sales
egen residue_sold_value=rowtotal(ag5a_35 ag5b_35)
la var residue_sold_value "Value of crop residues sales, TSH"

//Total LRS and SRS Values
egen annual_value = rowtotal(harv_value_tsh harv_value_tsh_SRS)
la var annual_value "Value of LRS and SRS crop production, TSH"

egen annual_sales = rowtotal(LRS_sold_value SRS_sold_value)
la var annual_sales "Value of LRS and SRS crop sales, TSH"

egen area_planted = rowtotal(crop_area_planted crop_area_planted_SRS)
la var area_planted "Total area planted across LRS and SRS, ha"

egen seed_costs = rowtotal(seed_cost seed_cost_SRS)
la var seed_costs "Total seed costs across LRS and SRS, TSH"

save "$merge/LRS_SRS_prep.dta", replace

collapse (sum) sales_transport_costs residue_sold_value annual_value annual_sales area_planted seed_costs, by(y3_hhid)
la var sales_transport_costs "(sum) Crop sales transport expenses, TSH"
la var residue_sold_value "(sum) Value of crop residues sales, TSH"
la var annual_value "(sum) Value of LRS and SRS crop production, TSH"
la var annual_sales "(sum) Value of LRS and SRS crop sales, TSH"
la var area_planted "(sum) Total area planted across LRS and SRS, ha"
la var seed_costs "(sum) Total seed costs across LRS and SRS, TSH"

save "$collapse/LRS_SRS_collapse.dta", replace
}
*****************************************
////// 1.5 OTHER AG SECTIONS//////////
*****************************************
{
* 8. INPUT VOUCHERS *
use "$input\Agriculture\AG_SEC_08.dta", clear

gen voucher_transport_expenses=ag08_08

collapse (sum) voucher_transport_expenses, by (y3_hhid)

la var voucher_transport_expenses "Cost of transport to get/redeem input vouchers, TSH"

save "$collapse/AG_SEC_8_vouchers.dta", replace


* 10 PROCESSED CROPS AND BYPRODUCTS *
clear
use "$input\Agriculture\AG_SEC_10.dta"  

*information on amount of crops used to create various processed crops or by-products
*information on much processed crop/by-products were sold, and earnings
*very few sales, so will be nearly impossible to value by-product production
*easier to just value crop production, and any income from by-products to total income without subtract crop value as an input cost

gen crop_byprod_sales=ag10_11
gen crop_byprod_expenses=ag10_14

collapse (sum) crop_byprod_sales crop_byprod_expenses, by (y3_hhid)

la var crop_byprod_sales "Income from sales of crop by-products, TSH"
la var crop_byprod_expenses "Expenses from production of crop by-products, TSH"
	
save "$collapse/AG_SEC_10_byproducts.dta", replace

* 11 IMPLEMENT USE *

clear
use "$input\Agriculture\AG_SEC_11.dta"  

gen crop_implement_expenses=ag11_09

collapse (sum) crop_implement_expenses, by (y3_hhid)

la var crop_implement_expenses "Expenses from renting or borrowing farm implements or machiney, TSH"
	
save "$collapse/AG_SEC_11_implements.dta", replace

* 12 EXTENSION *

use "$input\Agriculture\AG_SEC_12A.dta", clear

gen extension_expenses=ag12a_06

collapse (sum) extension_expenses, by (y3_hhid)

la var extension_expenses "Cost of getting extension services, TSH"

save "$collapse/AG_SEC_12_extension.dta", replace
}

*****************************************
////// 1.6 MERGE ALL AG SECTIONS//////////
*****************************************
{
use "$collapse/AG_SEC_2A2B3A3B_collapse.dta", clear
//includes 3311 HHs reporting on LRS or SRS plots
merge 1:1 y3_hhid using "$collapse/LRS_SRS_collapse.dta", gen (_ag1)
//2962 matched, 349 not matched from master (161 with 0 area cultivated, 329 with no purchased inputs, just HHs which for some reason reported plot area but not any crop activity)
*only 2761 HHs report zaocodes for LRS plots even though 3,027 report cultivating a plot in LRS, 785 report zaocodes for SRS plots even though 952 report cultivating a plot in SRS
merge 1:1 y3_hhid using "$collapse/fruit_perm_collapse.dta", gen (_ag2)
//2396 matched, 915 not matched from master (did not grow fruit or permanent crops)
merge 1:1 y3_hhid using "$collapse/AG_SEC_8_vouchers.dta", gen (_ag3)
//3311 matched, 1699 not matched from using (non-farm HHs)
merge 1:1 y3_hhid using "$collapse/AG_SEC_10_byproducts.dta", gen (_ag4)
//5010 matched
merge 1:1 y3_hhid using "$collapse/AG_SEC_11_implements.dta", gen (_ag5)
//5010 matched
merge 1:1 y3_hhid using "$collapse/AG_SEC_12_extension.dta", gen (_ag6)
//5010 matched

save "$merge/AG_sections_raw.dta", replace

*Replace missings with 0s
local crop_vars plot_area plot_area_cultivated plot_area_farm land_rental_cost land_rental_income land_value input_purchased_cost inorgfert_purchased_cost ///
labor_hired_cost sales_transport_costs residue_sold_value annual_value annual_sales area_planted seed_costs perennial_value perennial_sales
foreach x of varlist `crop_vars'{
	replace `x'=0 if `x'==.
}

gen crop_expenses=land_rental_cost+input_purchased_cost+labor_hired_cost+sales_transport_costs+seed_costs+voucher_transport_expenses+crop_byprod_expenses+crop_implement_expenses+extension_expenses
gen crop_value=annual_value+perennial_value
gen crop_sales=annual_sales+perennial_sales
replace crop_value=crop_sales if crop_sales>crop_value
gen crop_income=residue_sold_value+crop_value+crop_byprod_sales
gen crop_income_net=crop_income-crop_expenses
la var crop_expenses "Cost of all expenses for crop production, TSH"
la var crop_value "Value of all crop production, TSH"
la var crop_sales "Value of all crop sales, TSH"
la var crop_income "Gross income from crop production (prod value+sales of resides and byprods), TSH"
la var crop_income_net "Net income from crop production (value - expenses), TSH"

keep y3_hhid plot_area plot_area_farm area_planted crop_value crop_sales crop_income crop_income_net inorgfert_purchased_cost land_rental_income
} 
save "$merge/AG_sections_prepped.dta", replace

***************************************
////// 2.1 LIVESTOCK////////////////
***************************************
{
*Counts of Livestock and Animal Transactions
use "$input\Livestock and Fisheries\LF_SEC_02", clear

//Number of livestock owned by household
replace lf02_04_1 = 0 if lf02_04_1==. //indigenous
replace lf02_04_2 = 0 if lf02_04_2==. //exotic

//Livestock Counts
gen ls_cattle_count=0
replace ls_cattle_count=lf02_04_1+lf02_04_2 if lvstckid==1 | lvstckid==2 | lvstckid==3 | lvstckid==4 | lvstckid==5 | lvstckid==6
la var ls_cattle_count "Count of bulls, cows, steers, heifers, and calves"

gen ls_poultry_count=0
replace ls_poultry_count=lf02_04_1+lf02_04_2 if lvstckid==10 | lvstckid==11 | lvstckid==12
la var ls_poultry_count "Count of chickens, ducks, and other poultry"

gen ls_other_count=0
replace ls_other_count=lf02_04_1+lf02_04_2 if lvstckid==7 | lvstckid==8 | lvstckid==9 | lvstckid==13 | lvstckid==14 | lvstckid==16
la var ls_other_count "Count of sheep, goats, pigs, rabbits, donkeys, and other"

gen ls_goat_count=0
replace ls_goat_count=lf02_04_1+lf02_04_2 if lvstckid==7
la var ls_goat_count "Count of goats"

gen ls_sheep_count=0
replace ls_sheep_count=lf02_04_1+lf02_04_2 if lvstckid==8
la var ls_sheep_count "Count of sheep"

gen ls_pig_count=0
replace ls_pig_count=lf02_04_1+lf02_04_2 if lvstckid==9
la var ls_pig_count "Count of pigs"

gen ls_rabbit_count=0
replace ls_rabbit_count=lf02_04_1+lf02_04_2 if lvstckid==13
la var ls_rabbit_count "Count of rabbits"

gen ls_donkey_count=0
replace ls_donkey_count=lf02_04_1+lf02_04_2 if lvstckid==14
la var ls_donkey_count "Count of donkeys"

gen ls_othero_count=0
replace ls_othero_count=lf02_04_1+lf02_04_2 if lvstckid==16
la var ls_othero_count "Count of other animals"

//TLU counts, following FAO guidelines
gen ls_tropical_units=0.5*ls_cattle_count+0.01*ls_poultry_count+0.1*ls_goat_count+0.1*ls_sheep_count+0.2*ls_pig_count+0.01*ls_rabbit_count+0.3*ls_donkey_count+0.01*ls_other_count
la var ls_tropical_units "Total Tropical Livestock Units (TLUs)"

//Livestock transactions; asked about all livestock categories
gen livestock_sales=0
replace livestock_sales=lf02_26 if lf02_26!=. //total value of sales of alive livestock in last 12 months (record 0 if no sales)
la var livestock_sales "Total value of sales of live [livestock] in last 12 months, TSH"

gen livestock_sales_dead=0
replace livestock_sales_dead=lf02_33 if lf02_33!=. //total value of sales of alive livestock in last 12 months (record 0 if no sales)
la var livestock_sales_dead "Total value of sales of slaughtered [livestock] in last 12 months, TSH"

gen livestock_purchase_cost=lf02_08
replace livestock_purchase_cost=0 if livestock_purchase_cost==.
la var livestock_purchase_cost "Total cost of purchasing [livestock], TSH"

collapse (sum) ls_cattle_count ls_poultry_count ls_other_count ls_tropical_units livestock_sales livestock_sales_dead livestock_purchase_cost, by(y3_hhid)

la var ls_cattle_count "(sum) Count of bulls, cows, steers, heifers, and calves"
la var ls_poultry_count "(sum) Count of chickens, ducks, and other poultry"
la var ls_other_count "(sum) Count of sheep, goats, pigs, rabbits, donkeys, and other"
la var ls_tropical_units "(sum) Total Tropical Livestock Units (TLUs)"
la var livestock_sales "(sum) Total value of sales of live livestock, TSH"
la var livestock_sales_dead "(sum) Total value of sales of slaughtered livestock, TSH"
la var livestock_purchase_cost "(sum) Total cost of purchasing livestock, TSH"

save "$collapse/LF_SEC_02_collapse.dta", replace

*Livestock Health
use "$input\Livestock and Fisheries\LF_SEC_03", clear

gen ls_health_expenses=lf03_14

collapse (sum) ls_health_expenses, by (y3_hhid)

la var ls_health_expenses "(sum) Total cost of livestock health expenditures, TSH"

save "$collapse/LF_SEC_03_collapse.dta", replace

*Livestock Feed and Water
use "$input\Livestock and Fisheries\LF_SEC_04", clear

egen ls_feedwater_expenses=rowtotal(lf04_04 lf04_09)

collapse (sum) ls_feedwater_expenses, by (y3_hhid)

la var ls_feedwater_expenses "(sum) Total cost of livestock feed and water expenditures, TSH"

save "$collapse/LF_SEC_04_collapse.dta", replace

*Livestock Labor
use "$input\Livestock and Fisheries\LF_SEC_05", clear

gen ls_labor_expenses=lf05_07

collapse (sum) ls_labor_expenses, by (y3_hhid)

la var ls_labor_expenses "(sum) Total cost of livestock labor expenditures, TSH"

save "$collapse/LF_SEC_05_collapse.dta", replace
}

***************************************
////// 2.2 LIVESTOCK BY-PRODUCTS////////////////
***************************************
{
*Milk
use "$input\Livestock and Fisheries\LF_SEC_06", clear
merge m:1 y3_hhid using "$input\Household\HH_SEC_A", generate (_merge_HH_SEC_A_EA_milk) //to get geographic levels
//2846 not matched from using, non-livestock HHs
drop if _merge_HH_SEC_A_EA_milk==2 //dropped

gen milk_production = (lf06_03)*365*((lf06_02)/12) //production liters per day * 365 days * proportion of months produced
egen milk_liters_sold=rowtotal(lf06_08 lf06_10) //liters of liquid milk and processed products (can't disaggregate price)
gen milk_sales=lf06_11*365*((lf06_02)/12) //sales TSH per day * 365 days * proportion of months produced
gen milk_price_liter=lf06_11/milk_liters_sold

egen ea_median_price_ls=median(milk_price_liter), by(lvstckcat hh_a01_1 hh_a02_1 hh_a03_1 hh_a04_1)
egen ward_median_price_ls=median(milk_price_liter), by(lvstckcat hh_a01_1 hh_a02_1 hh_a03_1)
egen district_median_price_ls=median(milk_price_liter), by(lvstckcat hh_a01_1 hh_a02_1)
egen region_median_price_ls=median(milk_price_liter), by(lvstckcat hh_a01_1)
egen nation_median_price_ls=median(milk_price_liter), by(lvstckcat)

egen ea_median_price_ls_ct=count(milk_price_liter), by(lvstckcat hh_a01_1 hh_a02_1 hh_a03_1 hh_a04_1)
egen ward_median_price_ls_ct=count(milk_price_liter), by(lvstckcat hh_a01_1 hh_a02_1 hh_a03_1)
egen district_median_price_ls_ct=count(milk_price_liter), by(lvstckcat hh_a01_1 hh_a02_1)
egen region_median_price_ls_ct=count(milk_price_liter), by(lvstckcat hh_a01_1)
egen nation_median_price_ls_ct=count(milk_price_liter), by(lvstckcat)

gen value_of_milk_prod=milk_production*milk_price_liter //346
replace value_of_milk_prod=milk_production*ea_median_price_ls if value_of_milk_prod==. & ea_median_price_ls_ct>=10 //0 changes
replace value_of_milk_prod=milk_production*ward_median_price_ls if value_of_milk_prod==. & ward_median_price_ls_ct>=10 //0 changes
replace value_of_milk_prod=milk_production*district_median_price_ls if value_of_milk_prod==. & district_median_price_ls_ct>=10 //23 changes
replace value_of_milk_prod=milk_production*region_median_price_ls if value_of_milk_prod==. & region_median_price_ls_ct>=10 //101 changes
replace value_of_milk_prod=milk_production*nation_median_price_ls if value_of_milk_prod==. & nation_median_price_ls_ct>=10 //34 changes
replace value_of_milk_prod=milk_production*nation_median_price_ls if value_of_milk_prod==. //29 changes

replace value_of_milk_prod=milk_sales if value_of_milk_prod<milk_sales & milk_sales!=. //21 changes

collapse (sum) milk_sales value_of_milk_prod, by(y3_hhid) 

la var milk_sales "(sum) Value of milk and milk product sales, TSH"
la var value_of_milk_prod "(sum) Value of milk production, TSH"

save "$collapse/LF_SEC_06_livestock.dta", replace

*Dung
use "$input\Livestock and Fisheries\LF_SEC_07", clear

gen value_livestock_dung_sales = lf07_03

collapse (sum) value_livestock_dung_sales, by(y3_hhid) 

la var value_livestock_dung_sales "(sum) Total value of livestock dung sales, TSH"

save "$collapse/LF_SEC_07_livestock.dta", replace

*Other Livestock Products
use "$input\Livestock and Fisheries\LF_SEC_08", clear
merge m:1 y3_hhid using "$input\Household\HH_SEC_A", generate (_merge_HH_SEC_A_LSprod) //to get geographic levels
//2846 not matched from using, non-livestock HHs
drop if _merge_HH_SEC_A_LSprod==2 //dropped

//Eggs
gen eggs_production = (lf08_03_1)*(lf08_02) if productid==1 //monthly production times number of months
gen eggs_sales=lf08_06 if productid==1
gen eggs_price_piece = (lf08_06)/(lf08_05_1) if productid==1

egen ea_median_price_piece=median(eggs_price_piece), by(productid hh_a01_1 hh_a02_1 hh_a03_1 hh_a04_1)
egen ward_median_price_piece=median(eggs_price_piece), by(productid hh_a01_1 hh_a02_1 hh_a03_1)
egen district_median_price_piece=median(eggs_price_piece), by(productid hh_a01_1 hh_a02_1)
egen region_median_price_piece=median(eggs_price_piece), by(productid hh_a01_1)
egen nation_median_price_piece=median(eggs_price_piece), by(productid)

egen ea_median_price_piece_ct=count(eggs_price_piece), by(productid hh_a01_1 hh_a02_1 hh_a03_1 hh_a04_1)
egen ward_median_price_piece_ct=count(eggs_price_piece), by(productid hh_a01_1 hh_a02_1 hh_a03_1)
egen district_median_price_piece_ct=count(eggs_price_piece), by(productid hh_a01_1 hh_a02_1)
egen region_median_price_piece_ct=count(eggs_price_piece), by(productid hh_a01_1)
egen nation_median_price_piece_ct=count(eggs_price_piece), by(productid)

gen value_of_eggs_prod=eggs_production*eggs_price_piece //346
replace value_of_eggs_prod=eggs_production*ea_median_price_piece if value_of_eggs_prod==. & ea_median_price_piece_ct>=10 //0 changes
replace value_of_eggs_prod=eggs_production*ward_median_price_piece if value_of_eggs_prod==. & ward_median_price_piece_ct>=10 //0 changes
replace value_of_eggs_prod=eggs_production*district_median_price_piece if value_of_eggs_prod==. & district_median_price_piece_ct>=10 //0 changes
replace value_of_eggs_prod=eggs_production*region_median_price_piece if value_of_eggs_prod==. & region_median_price_piece_ct>=10 //322 changes
replace value_of_eggs_prod=eggs_production*nation_median_price_piece if value_of_eggs_prod==. & nation_median_price_piece_ct>=10 //1116 changes
replace value_of_eggs_prod=eggs_production*nation_median_price_piece if value_of_eggs_prod==. //0 changes

replace value_of_eggs_prod=eggs_sales if value_of_eggs_prod<eggs_sales & eggs_sales!=. //5 changes

//Honey
gen honey_production = (lf08_03_1)*(lf08_02) if productid==2 //monthly production times number of months
gen honey_sales=lf08_06 if productid==2
gen honey_price_liter = (lf08_06)/(lf08_05_1) if productid==2 //18

egen nation_median_price_liter=median(honey_price_liter), by(productid)

gen value_of_honey_prod=honey_production*honey_price_liter //18
replace value_of_honey_prod=honey_production*nation_median_price_liter if value_of_honey_prod==. //11 changes

replace value_of_honey_prod=honey_sales if honey_sales>value_of_honey_prod & honey_sales!=. //1 change

//Skin/hides
gen hides_production=(lf08_03_1)*(lf08_02) if productid==3 //monthly production times number of months
gen hides_sales=lf08_06 if productid==3
gen hides_price_pieces = (lf08_06)/(lf08_05_1) if productid==3 //78

egen district_median_price_hpiece=median(hides_price_pieces), by(productid hh_a01_1 hh_a02_1)
egen region_median_price_hpiece=median(hides_price_pieces), by(productid hh_a01_1)
egen nation_median_price_hpiece=median(hides_price_pieces), by(productid)

egen district_median_price_hpiece_ct=count(hides_price_pieces), by(productid hh_a01_1 hh_a02_1)
egen region_median_price_hpiece_ct=count(hides_price_pieces), by(productid hh_a01_1)
egen nation_median_price_hpiece_ct=count(hides_price_pieces), by(productid)

gen value_of_hides_prod=hides_production*hides_price_pieces // 78
replace value_of_hides_prod=hides_production*district_median_price_hpiece if value_of_hides_prod==. & district_median_price_hpiece_ct>=10 //4 changes
replace value_of_hides_prod=hides_production*region_median_price_hpiece if value_of_hides_prod==. & region_median_price_hpiece_ct>=10 //19 changes
replace value_of_hides_prod=hides_production*nation_median_price_hpiece if value_of_hides_prod==. //70 changes

replace value_of_hides_prod=hides_sales if value_of_hides_prod<hides_sales & hides_sales!=. //3 changes

//other by-products
gen other_production = (lf08_03_1)*(lf08_02) if productid==4 //13
gen other_sales=lf08_06 if productid==4 //2
*can't value other_prod with so few obs
gen value_of_other_prod=other_sales

//collapse to HH level
local value_vars eggs_sales honey_sales hides_sales other_sales value_of_eggs_prod value_of_honey_prod value_of_hides_prod value_of_other_prod
collapse (sum) `value_vars', by(y3_hhid) 

la var eggs_sales "(sum) Value of eggs product sales, TSH"
la var value_of_eggs_prod "(sum) Value of eggs production, TSH"
la var honey_sales "(sum) Value of honey product sales, TSH"
la var value_of_honey_prod "(sum) Value of honey production, TSH"
la var hides_sales "(sum) Value of hides product sales, TSH"
la var value_of_hides_prod "(sum) Value of hides production, TSH"
la var other_sales "(sum) Value of other livestock product sales, TSH"
la var value_of_other_prod "(sum) Value of other livestock production, TSH"

save "$collapse/LF_SEC_08_livestock.dta", replace
}
***************************************
///// 2.3 FISHERIES////////////////
***************************************
{
*Fishery Hired Labour Expenses
use "$input\Livestock and Fisheries\LF_SEC_10", clear

gen fishery_fixed_wage_adult=lf10_01_1*lf10_01_2*lf10_03_1 //3 obs
gen fishery_fixed_wage_child=lf10_01_3*lf10_01_4*lf10_03_2 //3 obs
gen fishery_cash_wage_adult=lf10_01_1*lf10_01_2*lf10_07_1 //1 obs
gen fishery_cash_wage_child=lf10_01_3*lf10_01_4*lf10_07_2 //1 obs
egen fishery_total_wage=rowtotal(fishery_fixed_wage_adult fishery_fixed_wage_child fishery_cash_wage_adult fishery_cash_wage_child)

collapse (sum) fishery_total_wage, by(y3_hhid) 

la var fishery_total_wage "(sum) Total fishery hired labor wages, TSH"

save "$collapse/LF_SEC_10_livestock.dta", replace

*Fisheries Other Expenses
use "$input\Livestock and Fisheries\LF_SEC_11A", clear

gen fishing_gear_expenses=lf11_05
gen fishing_boat_expenses=lf11_07
gen fishing_rent_expenses=lf11_08

collapse (sum) fishing_gear_expenses fishing_boat_expenses fishing_rent_expenses, by(y3_hhid) 

la var fishing_gear_expenses "Expenses for purchasing fishing gear in last 12 months, TSH"
la var fishing_boat_expenses "Expenses for fishing boat fuel, oil, maintenance in last 12 months, TSH"
la var fishing_rent_expenses "Expenses for renting fishing gear in last 12 months, TSH"

save "$collapse/LF_SEC_11A_livestock.dta", replace

use "$input\Livestock and Fisheries\LF_SEC_11B", clear

gen fishing_other_expenses=lf11b_10_1

collapse (sum) fishing_other_expenses, by(y3_hhid) 

la var fishing_other_expenses "Expenses for other fishing inputs in last 12 months, TSH"

save "$collapse/LF_SEC_11B_livestock.dta", replace

*Fisheries Output
use "$input\Livestock and Fisheries\LF_SEC_12", clear

rename lf12_02_3 fish_code 
drop if fish_code==. /* "Other" = 59 */
rename lf12_05_1 fish_quantity_year
rename lf12_05_2 fish_quantity_unit
rename lf12_12_2 unit 
rename lf12_12_4 price_per_unit 
*rename lf12_12_6 unit_2
*rename lf12_12_8 price_unit_2
*Just seven observations of processing type #2, not worth using this to value fish catches. 
merge m:1 y3_hhid using "$input\Household\HH_SEC_A", generate (_merge_HH_SEC_A_LSprod) //to get geographic levels
//4893 not matched from using, non-livestock HHs
drop if _merge_HH_SEC_A_LSprod==2 //dropped
collapse (median) price_per_unit [aw=y3_weight], by (fish_code unit)
rename price_per_unit price_per_unit_median
replace price_per_unit_median = . if fish_code==33 //7 to missing
save "$collapse/LF_SEC_12_fish_prices.dta", replace

use "$input\Livestock and Fisheries\LF_SEC_12", clear
rename lf12_02_3 fish_code 
drop if fish_code==. 
rename lf12_05_1 fish_quantity_year
rename lf12_05_2 unit
merge m:1 fish_code unit using "$collapse/LF_SEC_12_fish_prices.dta"
drop if _merge==2 //5 obs deleted
drop _merge
rename lf12_12_1 quantity_1
rename lf12_12_2 unit_1
rename lf12_12_4 price_unit_1
rename lf12_12_5 quantity_2
rename lf12_12_6 unit_2
rename lf12_12_8 price_unit_2
recode quantity_1 quantity_2 fish_quantity_year (.=0)
replace price_unit_1=0 if price_unit_1==. & quantity_1==0
replace price_unit_2=0 if price_unit_2==. & quantity_2==0
gen income_fish_sales = (quantity_1 * price_unit_1) + (quantity_2 * price_unit_2)
gen value_fish_harvest = (fish_quantity_year * price_unit_1) if unit==unit_1 /* Use household's price, if it's observed */ //48 missing
replace value_fish_harvest = (fish_quantity_year * price_per_unit_median) if value_fish_harvest==. //12 changes
*count if fish_quantity_year!=0 & value_fish_harvest==. /* 36 missing values */
replace value_fish_harvest=income_fish_sales if value_fish_harvest==. //36 changes
replace value_fish_harvest=income_fish_sales if value_fish_harvest<income_fish_sales & income_fish_sales!=. //7 changes

collapse (sum) value_fish_harvest income_fish_sales, by (y3_hhid)
lab var value_fish_harvest "Value of fish harvest (including what is sold), with values imputed using a national median for fish-unit-prices"
lab var income_fish_sales "Value of fish sales"

save "$collapse/LF_SEC_12_fisheries.dta", replace
}
************************************************
///// 2.4 LIVESTOCK MERGE////////////////
************************************************
{
use "$input\Household\HH_SEC_A", clear

//livestock and fisheries section 2 - livestock
merge 1:1 y3_hhid using "$collapse/LF_SEC_02_collapse.dta", keep (1 3) gen (_merge_livestock_1)
*not matched 2846 from master

//livestock and fisheries section 3 
merge 1:1 y3_hhid using "$collapse/LF_SEC_03_collapse.dta", keep (1 3) gen (_merge_livestock_2)
*not matched 2846 from master

//livestock and fisheries section 4
merge 1:1 y3_hhid using "$collapse/LF_SEC_04_collapse.dta", keep (1 3) gen (_merge_livestock_3)
*not matched 2846 from master

//livestock and fisheries section 5 
merge 1:1 y3_hhid using "$collapse/LF_SEC_05_collapse.dta", keep (1 3) gen (_merge_livestock_4)
*not matched 2846 from master

//livestock and fisheries section 6
merge 1:1 y3_hhid using "$collapse/LF_SEC_06_livestock.dta", keep (1 3) gen (_merge_livestock_5)
*not matched 2846 from master

//livestock and fisheries section 7 
merge 1:1 y3_hhid using "$collapse/LF_SEC_07_livestock.dta", keep (1 3) gen (_merge_livestock_6)
*not matched 2846 from master

//livestock section 8
merge 1:1 y3_hhid using "$collapse/LF_SEC_08_livestock.dta", keep (1 3) gen (_merge_livestock_7)
*not matched 2846 from master

//livestock section 10
merge 1:1 y3_hhid using "$collapse/LF_SEC_10_livestock.dta", keep (1 3) gen (_merge_livestock_8)
*not matched 4912 from master

//livestock section 11a
merge 1:1 y3_hhid using "$collapse/LF_SEC_11A_livestock.dta", keep (1 3) gen (_merge_livestock_9)
*not matched 4752 from master

//livestock section 11b
merge 1:1 y3_hhid using "$collapse/LF_SEC_11B_livestock.dta", keep (1 3) gen (_merge_livestock_10)
*not matched 4752 from master

//livestock section 12 (fisheries)
merge 1:1 y3_hhid using "$collapse/LF_SEC_12_fisheries.dta", keep (1 3) gen (_merge_livestock_12)
*not matched 4893 from master

save "$merge\LS_section_merge_hh.dta", replace

egen livestock_total_sales=rowtotal(livestock_sales livestock_sales_dead)
egen livestock_expenses=rowtotal(ls_health_expenses ls_feedwater_expenses ls_labor_expenses)
egen ls_byproduct_sales_value=rowtotal(milk_sales eggs_sales honey_sales hides_sales other_sales value_livestock_dung_sales)
egen ls_value_of_byproduct=rowtotal(value_of_milk_prod value_of_eggs_prod value_of_honey_prod value_of_hides_prod value_of_other_prod value_livestock_dung_sales)
egen fishery_expenses=rowtotal(fishery_total_wage fishing_gear_expenses fishing_boat_expenses fishing_rent_expenses fishing_other_expenses)

keep y3_hhid ls_cattle_count ls_poultry_count ls_other_count ls_tropical_units livestock_total_sales livestock_expenses livestock_purchase_cost ls_byproduct_sales_value ls_value_of_byproduct fishery_expenses value_fish_harvest income_fish_sales

la var livestock_total_sales "(sum) Total value of sales of livestock in last 12 months, TSH"
la var livestock_expenses "(sum) Total cost of labor and other expenses for livestock, TSH"
la var ls_byproduct_sales_value "(sum) Value of sales of livestock byproducts, TSH"
la var ls_value_of_byproduct "(sum) Value of production of livestock byproducts, TSH"
la var fishery_expenses "(sum) Total costs of fishery expenses, TSH"
}
save "$collapse\LS_section_collapse_hh.dta", replace

************************************************
/////////// 3.1 HOUSEHOLD ASSETS////////////////////
************************************************
{
clear
use "$input\Household\HH_SEC_M"

gen phone_own=0
replace phone_own=1 if hh_m01!=0 & hh_m01!=. & (itemcode==402 | itemcode==403)

collapse (max) phone_own, by (y3_hhid)
la var phone_own "Any household member owns cell phone or landline"

save "$collapse/HH_SEC_M_asset_ownership.dta", replace
}
************************************************
/////////// 3.2 HOUSEHOLD ROSTER////////////////////
************************************************
{
use "$input\Household\HH_SEC_A", clear

//Merge in section B: Household Member Roster
sort y3_hhid
merge 1:m y3_hhid using "$input\Household\HH_SEC_B", generate (_merge_HH_SEC_B)
//matched: 25,412
//not matched:0

//Merge in section C: Education
merge 1:1 y3_hhid indidy3 using "$input\Household\HH_SEC_C", generate(_merge_HH_SEC_C)
//matched: 25,412
//not matched:0

//generate variable for HH size (note there is an "adult equivalent" hh size number in consumption file)
egen hh_size = count(indidy3), by(y3_hhid) 
la var hh_size "count (indidy3): number of household members"

*HH head information, hh_b05==1
gen hh_head_fem=0
replace hh_head_fem=1 if hh_b02==2 & hh_b05==1 //if sex is female
la var hh_head_fem "Head of household is female"

gen hh_head_age=hh_b04 if hh_b05==1 //age in years
la var hh_head_age "Age of head of household, years"

gen hh_head_married=0
replace hh_head_married=1 if (hh_b19==1 | hh_b19==2) & hh_b05==1 //married monogamous or polygamous
la var hh_head_married "Head of household is married (monogamous or polygamous)"

//Generate HH member information
gen hh_mem_fem=0
replace hh_mem_fem=1 if hh_b02==2 //if sex is female
la var hh_mem_fem "Household member is female"

gen hh_mem_male=0
replace hh_mem_male=1 if hh_b02==1 //if sex is male
la var hh_mem_male "Household member is male"

gen hh_mem_age=hh_b04 //age in years
la var hh_mem_age "Age of household member, years"

gen hh_mem_15_64=0
replace hh_mem_15_64=1 if hh_mem_age>14 & hh_mem_age<65
la var hh_mem_15_64 "Household member is between 15-64 years old"

//Education Level
*** The processes for making this loop and creating these lists came from looking at years of education as they are defined in the Basic Information Document
*** This loop lines up the entry code of 11 to 1 year of education, because according to the Basic Information Document, an entry
*** of 11 corresponds to completing 1-year of schooling. The loop matches up each code with its respective year of schooling completed

gen hh_mem_ed = .
local edu_codes 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 31 32 33 34 41 42 43 44 45 
local edu_years 1  2  3  4  5  6  7  8  8  8  8  9  10 11 12 12 13 13 13 14 15 16 17 18 

local n : word count `edu_codes'
forvalues i=1/`n' {
capture noisily local x : word `i' of `edu_codes'
capture noisily local y : word `i' of `edu_years'
	recode hh_mem_ed . = `y' if hh_c07==`x'
}

//Did the member ever go to school?
gen school_any = .
replace school_any = 0 if hh_c03==2
replace school_any = 1 if hh_c03==1

replace hh_mem_ed=0 if school_any==0

gen hh_head_ed=hh_mem_ed if hh_b05==1

//Collapse
collapse (sum) hh_mem_fem hh_mem_male hh_mem_15_64 (max) hh_size hh_head_fem hh_head_age hh_head_married hh_head_ed hh_mem_ed, by (y3_hhid)
la var hh_mem_fem "(sum) Female household members"
la var hh_mem_male "(sum) Male household members"
la var hh_mem_15_64 "(sum) Household members between 15-64 years old"
la var hh_size "(sum) Total number of household members"
la var hh_head_fem "Head of household is female"
la var hh_head_age "Age of head of household, years"
la var hh_head_married "Head of household is married (monogamous or polygamous)"
la var hh_head_ed "Education of head of household, years"
la var hh_mem_ed "Education of most educated HH member, years"

save "$collapse\HH_indy_merge.dta", replace
}
************************************************
////// 3.3 OFF-FARM INCOME: HH Data SEC E////// 
************************************************ 
{
use "$input\Household\HH_SEC_E", clear

//merge m:1 y3_hhid indidy3 using "$collapse/HH_indy_merge.dta", gen (_offfarm_income)

//MAKING A HUGE ASSUMPTION HERE THAT FARMERS WHO REPORTED THEIR WAGES DAILY WORKED 5 DAYS/WEEK
//primary off-farm job - salary and then other payments
gen offfarm_income_1 = (hh_e26_1)*(hh_e31)*(hh_e30)*(hh_e29) if hh_e26_2==1
replace offfarm_income_1 = (hh_e26_1)*((hh_e31)/8)*(hh_e30)*(hh_e29) if hh_e26_2==2 
replace offfarm_income_1 = (hh_e26_1)*(hh_e30)*(hh_e29) if hh_e26_2==3
replace offfarm_income_1 = ((hh_e26_1)*(hh_e30)*(hh_e29))/2 if hh_e26_2==4
replace offfarm_income_1 = (hh_e26_1)*(hh_e29) if hh_e26_2==5
replace offfarm_income_1 = ((hh_e26_1)*(hh_e29))/3 if hh_e26_2==6
replace offfarm_income_1 = ((hh_e26_1)*(hh_e29))/6 if hh_e26_2==7
replace offfarm_income_1 = hh_e26_1 if hh_e26_2==8
replace offfarm_income_1 = hh_e26_1 if offfarm_income_1==. //4 changes that we are not sure on timing of

gen offfarm_income_2 = (hh_e28_1)*(hh_e31)*(hh_e30)*(hh_e29) if hh_e28_2==1
replace offfarm_income_2 = (hh_e28_1)*((hh_e31)/8)*(hh_e30)*(hh_e29) if hh_e28_2==2 
replace offfarm_income_2 = (hh_e28_1)*(hh_e30)*(hh_e29) if hh_e28_2==3
replace offfarm_income_2 = ((hh_e28_1)*(hh_e30)*(hh_e29))/2 if hh_e28_2==4
replace offfarm_income_2 = (hh_e28_1)*(hh_e29) if hh_e28_2==5
replace offfarm_income_2 = ((hh_e28_1)*(hh_e29))/3 if hh_e28_2==6
replace offfarm_income_2 = ((hh_e28_1)*(hh_e29))/6 if hh_e28_2==7
replace offfarm_income_2 = hh_e28_1 if hh_e28_2==8

//secondary off-farm job - salary and then other payments
gen offfarm_income_3 = (hh_e44_1)*(hh_e49)*(hh_e48)*(hh_e47) if hh_e44_2==1
replace offfarm_income_3 = (hh_e44_1)*((hh_e49)/8)*(hh_e48)*(hh_e47) if hh_e44_2==2 
replace offfarm_income_3 = (hh_e44_1)*(hh_e48)*(hh_e47) if hh_e44_2==3
replace offfarm_income_3 = ((hh_e44_1)*(hh_e48)*(hh_e47))/2 if hh_e44_2==4
replace offfarm_income_3 = (hh_e44_1)*(hh_e47) if hh_e44_2==5
replace offfarm_income_3 = ((hh_e44_1)*(hh_e47))/3 if hh_e44_2==6

gen offfarm_income_4 = (hh_e46_1)*(hh_e49)*(hh_e48)*(hh_e47) if hh_e46_2==1
replace offfarm_income_4 = (hh_e46_1)*((hh_e49)/8)*(hh_e48)*(hh_e47) if hh_e46_2==2 
replace offfarm_income_4 = (hh_e46_1)*(hh_e48)*(hh_e47) if hh_e46_2==3
replace offfarm_income_4 = ((hh_e46_1)*(hh_e48)*(hh_e47))/2 if hh_e46_2==4
replace offfarm_income_4 = (hh_e46_1)*(hh_e47) if hh_e46_2==5
replace offfarm_income_4 = ((hh_e46_1)*(hh_e47))/3 if hh_e46_2==6

//total offfarm income
egen offfarm_income=rowtotal(offfarm_income_1 offfarm_income_2 offfarm_income_3 offfarm_income_4)

gen offfarm_income_1_ag=offfarm_income_1 if hh_e21_2==1 | hh_e21_2==3
gen offfarm_income_2_ag=offfarm_income_2 if hh_e21_2==1 | hh_e21_2==3
gen offfarm_income_3_ag=offfarm_income_3 if hh_e39_2==1 | hh_e39_2==3
gen offfarm_income_4_ag=offfarm_income_4 if hh_e39_2==1 | hh_e39_2==3

egen offfarm_income_ag=rowtotal(offfarm_income_1_ag offfarm_income_2_ag offfarm_income_3_ag offfarm_income_4_ag)

collapse (sum) offfarm_income offfarm_income_ag, by(y3_hhid)

la var offfarm_income "Total annual income from off-farm work, TSH"
la var offfarm_income_ag "Total annual income from off-farm ag work, TSH"

save "$collapse\offfarm_income.dta", replace
}
************************************************
////// 3.4 NON-FARM ENTERPRISES: HH Data SEC N////// 
************************************************ 
{
use "$input\Household\HH_SEC_N", clear

//using average net income (profit) here rather than gross income
gen non_farm_ent_income = (hh_n20)*(hh_n19)
gen non_farm_ent_income_ag = non_farm_ent_income if hh_n02_3==1 | hh_n02_3==3

collapse (sum) non_farm_ent_income non_farm_ent_income_ag, by (y3_hhid)

la var non_farm_ent_income "Total annual income from non-farm enterprise work, TSH"
la var non_farm_ent_income_ag "Total annual income from non-farm ag enterprise work, TSH"

save "$collapse\non_farm_ent_income.dta", replace
}

************************************************
////// 3.5 OTHER INCOME: HH Data SEC O, Q////// 
************************************************ 
{
use "$input\Household\HH_SEC_O1",clear

egen assistance_income = rowtotal(hh_o03 hh_o04 hh_o05)
collapse (sum) assistance_income, by (y3_hhid)
la var assistance_income "Total annual income from govt or NGO assistance, TSH"

save "$collapse\assistance_income.dta", replace

use "$input\Household\HH_SEC_Q1",clear

egen rental_pension_other_income=rowtotal(hh_q06 hh_q07 hh_q08)
collapse (sum) rental_pension_other_income, by (y3_hhid)
la var rental_pension_other_income "Total annual rental, pension, and other income, TSH"

save "$collapse\other_income.dta", replace

use "$input\Household\HH_SEC_Q2",clear

egen fin_assist_income = rowtotal(hh_q23 hh_q26)
collapse (sum) fin_assist_income, by (y3_hhid)
la var fin_assist_income "Total annual income from remittances or financial assistance, TSH"

save "$collapse\finance_income.dta", replace
}
*****************************
////// 3.6 Merge HH section///////////
*****************************
{
clear
use "$input\Household\HH_SEC_A"

//household section M - asset ownership
merge 1:1 y3_hhid using "$collapse/HH_SEC_M_asset_ownership.dta", keep (1 3) gen (_hh_asset)

//household section E - labor
merge 1:1 y3_hhid using "$collapse\offfarm_income.dta", keep (1 3) gen (_hh_offfarm_income)

//household section N - non-farm enterprises
merge 1:1 y3_hhid using "$collapse\non_farm_ent_income.dta", keep (1 3) gen (_hh_non_farm_ent_income)

//household section O - assistance
merge 1:1 y3_hhid using "$collapse\assistance_income.dta", keep (1 3) gen (_hh_assistance_income)

//household section Q1 - other income
merge 1:1 y3_hhid using "$collapse\other_income.dta", keep (1 3) gen (_hh_other_income)

//household section Q2 - financial assistance
merge 1:1 y3_hhid using "$collapse\finance_income.dta", keep (1 3) gen (_hh_finance_income)

//geovariables
merge 1:1 y3_hhid using "$input\Household\HouseholdGeovars_y3.dta", keep(1 3) gen(_hh_geovars)
//22 HHs missing geovariables

//consumption dta
merge 1:1 y3_hhid using "$input/ConsumptionNPS3.dta", keep (1 3) gen(_hh_consumption)
//127 HHs missing consumption data

//HH roster
merge 1:1 y3_hhid using "$collapse\HH_indy_merge.dta", keep (1 3) gen (_household_B)
}
save "$collapse\HH_section_collapse_hh.dta", replace

**********************************************
////// 4.1 MERGE ALL SECTIONS FOR ANALYSIS	//
**********************************************

use "$collapse\HH_section_collapse_hh.dta", clear

merge 1:1 y3_hhid using "$merge/AG_sections_prepped.dta", keep (1 3) gen(_hh_ag_merge)
merge 1:1 y3_hhid using "$collapse\LS_section_collapse_hh.dta", keep (1 3) gen(_hh_ag_ls_merge)

merge 1:1 y3_hhid using "$input\Tanzania_W3_AgDev_Farmer Segmentation.dta", gen (_segmentation)
*not matched: 22 from master, no segmentation info for these HHs

keep y3_hhid hh_a06 hh_a13 y3_rural y3_cluster clusterid strataid y3_weight hh_a01_1 hh_a01_2 hh_a02_1 hh_a02_2 hh_a03_1 hh_a03_2 hh_a04_1 hh_a04_2 ///
phone_own offfarm_income offfarm_income_ag non_farm_ent_income non_farm_ent_income_ag assistance_income rental_pension_other_income fin_assist_income ///
dist01 dist03 clim01 clim03 crops01 lat_dd_mod lon_dd_mod expm expmR hhsize adulteq ///
hh_mem_fem hh_mem_male hh_mem_15_64 hh_size hh_head_fem hh_head_age hh_head_married hh_head_ed hh_mem_ed ///
plot_area plot_area_farm inorgfert_purchased_cost area_planted crop_value crop_sales crop_income crop_income_net land_rental_income ///
ls_cattle_count ls_poultry_count ls_other_count ls_tropical_units livestock_purchase_cost value_fish_harvest income_fish_sales livestock_total_sales livestock_expenses ls_byproduct_sales_value ls_value_of_byproduct fishery_expenses ///
shf updatedsegment mktaccess

global vars ls_cattle_count ls_poultry_count ls_other_count ls_tropical_units livestock_purchase_cost value_fish_harvest income_fish_sales
foreach v of global vars{
	replace `v'=0 if `v'==.
}

save "$merge/tz3_merged_raw.dta", replace

**********************************************
///// 4.2 Trimming and Creation of New Variables
**********************************************

use "$merge/tz3_merged_raw.dta", clear

//generating $PPP for consumption per capita
//$PPP conversion: 0.361 TSHS = $1 for 2012, so divide TSHS by 0.361 to get $PPP
//from http://data.worldbank.org/indicator/PA.NUS.PPPC.RF?end=2012&locations=TZ&start=1990
gen tot_cons_per_capita_PPP =.
replace tot_cons_per_capita_PPP = expmR/adulteq/365
replace tot_cons_per_capita_PPP = (tot_cons_per_capita_PPP)/0.361
//now convert the PPP values into USD so can look at the $3.10 cutoff as requested by Stan
//http://data.worldbank.org/indicator/PA.NUS.FCRF?end=2012&locations=TZ&start=1960
//2012 conversion: 1583.00 Tshs in $1, so divide previous variable by this number to get USD
gen tot_cons_per_capita_final =(tot_cons_per_capita_PPP)/1583
la var tot_cons_per_capita_final "total daily consumption per capita converted from $PPP in USD, 2012"

//generating HH under $3.10 dummy variable
gen hh_310 = 0
replace hh_310 = 1 if tot_cons_per_capita_final<=3.1

rename inorgfert_purchased_cost total_inorgfert_value

gen offfarm_income_nonag=offfarm_income-offfarm_income_ag
la var offfarm_income_nonag "(sum) Total non-HH job income from non-ag labor over last 12 months, TSH"

gen livestock_income_net=livestock_total_sales+ls_value_of_byproduct+value_fish_harvest-livestock_expenses-livestock_purchase_cost-fishery_expenses
la var livestock_income_net "Net income from livestock production (value of ls sales+value of byproducts and fisheries-expenses), TSH"

**Winsorize top and bottom 1% of selected continuous variables (replace with 1st and 99th percentile)
local trimming crop_income_net livestock_income_net plot_area plot_area_farm area_planted  
winsor2 `trimming', suffix(_w) cuts(1 99)

**Winsorize top 1% of selected continuous variables (replace with 99th percentile) where trimming at the bottom does not make sense
local trimming offfarm_income_nonag offfarm_income_ag non_farm_ent_income assistance_income rental_pension_other_income fin_assist_income /// 
land_rental_income crop_value crop_sales total_inorgfert_value ls_cattle_count ls_poultry_count ls_other_count ls_tropical_units
winsor2 `trimming', suffix(_w) cuts(0 99)

gen farm_income=offfarm_income_ag_w+crop_income_net_w+livestock_income_net_w
la var farm_income "Total income from farm sources (net crop and livestock income+income for ag labor and enterprise), TSH)"
gen nonfarm_income=non_farm_ent_income+offfarm_income_nonag_w+assistance_income_w+rental_pension_other_income_w+fin_assist_income_w+land_rental_income_w
la var nonfarm_income "Total income from nonfarm sources (income for enterprise+non-ag labor+other+assistance+land rental), TSH"

**Winsorize top and bottom 1% of new continuous variables (replace with 1st and 99th percentile)
local trimming farm_income nonfarm_income  
winsor2 `trimming', suffix(_w) cuts(1 99)

gen total_income=farm_income_w+nonfarm_income_w
la var total_income "Total income from all sources, TSH"

**Convert TSH to dollars
global exchange_rate 1578.5 //end Dec 2012 value from http://www.xe.com/currencycharts/?from=USD&to=TZS&view=10Y
global inflation 0.1454 //inflation from 2012 to 2014 https://data.worldbank.org/indicator/FP.CPI.TOTL?locations=TZ-ET&name_desc=true
global monetary_vars farm_income_w nonfarm_income_w total_income crop_sales_w crop_value_w total_inorgfert_value_w
foreach p of global monetary_vars {
	gen `p'_usd = (`p' / ${exchange_rate})/(1+${inflation})
}

la var farm_income_w_usd "Total income from farm sources, 2014 USD"
la var nonfarm_income_w_usd "Total income from nonfarm sources, 2014 USD"
la var total_income_usd "Total income from all sources, 2014 USD"
la var crop_sales_w_usd "Toral value of crop sales, 2014 USD"
la var crop_value_w_usd "Toral value of crop production, 2014 USD"

gen farm_productivity=crop_value_w_usd/plot_area_farm_w //1755 missing values; 0 farm area
la var farm_productivity "Value of crop harvest/HH farm area, 2014 USD/ha"
winsor2 farm_productivity, suffix(_w) cuts(1 99)

gen inorgfert_ha=total_inorgfert_value_w_usd/area_planted_w //2050 missing values, 0 or missing area planted
la var inorgfert_ha "Value of inorganic fertilizer purchased/HH area planted, 2014 USD/ha"

save "$merge/tz3_merged_trimmed.dta", replace


**********************************************
////// 4.3 Creation of New Analysis Variables ////
**********************************************


use "$merge/tz3_merged_trimmed.dta", clear

*Non-farm proportion of HH income
gen nonfarm_income_prop=nonfarm_income_w/total_income //62 missings - total income==0
replace nonfarm_income_prop=0 if nonfarm_income_w<0 //0 share of + income coming from nonfarm sources, 0 changes
replace nonfarm_income_prop=1 if farm_income_w<0 //0 share of + income coming from farm sources, 295 changes
replace nonfarm_income_prop=0 if nonfarm_income_prop==. //0 share if no income, 62 changes
la var nonfarm_income_prop "Proportion of total HH income from non-farm sources"

gen nonfarm_income_prop_cat=0 if nonfarm_income_prop<=0.33 //1761 changes
replace nonfarm_income_prop_cat=1 if nonfarm_income_prop>0.33 & nonfarm_income_prop!=. //3249 changes
la var nonfarm_income_prop_cat "Non-farm income more than 1/3 of total, dummy"

*Farm area categories
gen farm_area_cat=0 if plot_area_farm_w==0 //1755
replace farm_area_cat=1 if plot_area_farm_w>0 & plot_area_farm_w<=4 //2733
replace farm_area_cat=2 if plot_area_farm_w>4 & plot_area_farm_w!=. //522
la var farm_area_cat "Total HH farm area, 0ha,0<ha<=4,>4ha"

gen non_crop=0
replace non_crop=1 if plot_area_farm_w==0 & crop_value_w==0 //1746
la var non_crop "Non-crop household; 0 farm area and 0 value of harvest"

*Alternative criteria for smallholder definitions: different farm area and tropical livestock unit thresholds, can also apply rural dummy
gen farm_area_0_4_ha= farm_area_cat==1 //2733
la var farm_area_0_4_ha "Farm area >0 and <=4 ha"

gen farm_area_0_2_ha=0 
replace farm_area_0_2_ha=1 if plot_area_farm_w>0 & plot_area_farm_w<=2 //2113
la var farm_area_0_2_ha "Farm area >0 and <=2 ha"

gen farm_area_0_40pct_ha=0
_pctile plot_area_farm_w [aweight=y3_weight], p(40)
return list //r(r40)=0.3897
replace farm_area_0_40pct_ha=1 if plot_area_farm_w>0 & plot_area_farm_w<=r(r1) //654
la var farm_area_0_40pct_ha "Farm area >0 and <=40th percentile of ha"

gen tlu_40pct=0
_pctile ls_tropical_units_w [aweight=y3_weight], p(40)
return list //r(r40)=1
replace tlu_40pct=1 if ls_tropical_units_w<=r(r1) //2880
la var tlu_40pct "Total TLUs<=40th percentile" //40th pctile =0

gen tlu_50pct=0
_pctile ls_tropical_units_w [aweight=y3_weight], p(50)
return list //r(r40)=1
replace tlu_50pct=1 if ls_tropical_units_w<=r(r1) //2880
la var tlu_50pct "Total TLUs<=median" //median =0

*Crop commercialization categories
gen prop_crop_value_sold=crop_sales_w/crop_value_w //1876 missing values
replace prop_crop_value_sold=0 if crop_value_w==0 //1876 changes
la var prop_crop_value_sold "Proportion of crop production value sold"

gen crop_sales_prop_cat=1 if prop_crop_value_sold<=0.05 //2837
replace crop_sales_prop_cat=2 if prop_crop_value_sold>0.05 & prop_crop_value_sold<=0.5 //1154
replace crop_sales_prop_cat=3 if prop_crop_value_sold>0.5 & prop_crop_value_sold!=. //1019
la var crop_sales_prop_cat "Crop sales/Crop production value, <=0.05, 0.05-0.5, >0.5"

*Farmer segment dummy variables
gen lolo = updatedsegment==1
gen lohi = updatedsegment==2
gen hilo = updatedsegment==3
gen hihi = updatedsegment==4
la var updatedsegment "1=Low Ag Potential/Low Market Access, 2=Low/High, 3=High/Low, 4=High/High"

*Commercialization categorization
gen commercial_cat=.
replace commercial_cat=1 if crop_sales_prop_cat==1 & nonfarm_income_prop_cat==0 //522
replace commercial_cat=2 if crop_sales_prop_cat==2 & nonfarm_income_prop_cat==0 //666
replace commercial_cat=3 if crop_sales_prop_cat==3 & nonfarm_income_prop_cat==0 //573
replace commercial_cat=4 if (crop_sales_prop_cat==1 | crop_sales_prop_cat==2) & nonfarm_income_prop_cat==1 //2803
replace commercial_cat=5 if crop_sales_prop_cat==3 & nonfarm_income_prop_cat==1 //446
la var commercial_cat "HH commercial. cat.,1subsist.,2pre-comm.,3specialized comm.,4transition,5diversified"

gen cat_subsistence = commercial_cat==1
gen cat_pre_comm = commercial_cat==2
gen cat_spec_comm = commercial_cat==3
gen cat_transition = commercial_cat==4
gen cat_diversified = commercial_cat==5

gen rural_hh=y3_rural==1

save "$merge\tz3_merged_analysis.dta", replace

**********************************************
/////// 4.4 Summary Statistics		///
**********************************************

use "$merge\tz3_merged_analysis.dta", clear

svyset clusterid [pweight=y3_weight], strata(strataid) singleunit(centered)

//Means by Commercialization Category, Smallholders (0<ha<=4 farm area) Only
local varlist hh_head_fem hh_head_age hh_head_married hh_size hh_mem_fem hh_mem_male hh_mem_15_64 rural_hh lolo lohi hilo hihi phone_own /// 
ls_cattle_count_w ls_poultry_count_w ls_other_count_w plot_area_w area_planted_w ///
total_income_usd farm_income_w_usd nonfarm_income_w_usd farm_productivity_w inorgfert_ha nonfarm_income_prop prop_crop_value_sold

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


**********************************************
////// 4.5 Output data for visualizations ///
**********************************************

**Original estimates

use "$merge\tz3_merged_analysis.dta", clear

keep y3_hhid rural_hh hh_size hh_mem_fem hh_mem_male hh_mem_15_64 hh_head_fem hh_head_age hh_head_married hh_head_ed updatedsegment phone_own ///
ls_cattle_count_w ls_poultry_count_w ls_other_count_w ls_tropical_units_w plot_area_w area_planted_w farm_area_cat farm_productivity_w inorgfert_ha ///
crop_sales_w_usd crop_value_w_usd prop_crop_value_sold crop_sales_prop_cat total_income_usd farm_income_w_usd nonfarm_income_w_usd ///
nonfarm_income_prop nonfarm_income_prop_cat commercial_cat tlu_40pct tlu_50pct farm_area_0_4_ha farm_area_0_2_ha farm_area_0_40pct_ha

export delimited using "$merge\TZ_Wave3_Viz Data_Updated.csv", replace
