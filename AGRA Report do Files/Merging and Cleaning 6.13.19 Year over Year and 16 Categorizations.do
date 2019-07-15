
//The following file cleans the data files for the 16 categories visualization and the Year over Year variablility visualization.  
//The first section merges the three waves for each country
//The second section takes some time and is just to create the files for the Year over Year variability visualization.
//The third section just appends the country files and cleans them up for the 16 Categories visualization


/////////////////////////////////////////////////////////
//				1. Merging Wave Files				   //
/////////////////////////////////////////////////////////
//The fields created by this section are used for both the Year over Year Variability section (2 below) and the 16 categories viz section (3 below)


**************************
**      1.1 Globals     **
**************************
//Creating Globals.  Note that these are based directly on the 335 household output files
clear
set more off
set maxvar 20000

global rawdataTZ3 "\\netid.washington.edu\wfs\EvansEPAR\Project\EPAR\Working Files\335 - Ag Team Data Support\Waves\Tanzania\Tanzania TNPS Wave 3 2012-13 (LSMS-ISA)"
global rawdataTZ2 "\\netid.washington.edu\wfs\EvansEPAR\Project\EPAR\Working Files\335 - Ag Team Data Support\Waves\Tanzania\Tanzania TNPS Wave 2 2010-11 (LSMS-ISA)"
global rawdataTZ1 "\\netid.washington.edu\wfs\EvansEPAR\Project\EPAR\Working Files\335 - Ag Team Data Support\Waves\Tanzania\Tanzania TNPS Wave 1 2008-09 (LSMS-ISA)"

global rawdataETH3 "\\netid.washington.edu\wfs\EvansEPAR\Project\EPAR\Working Files\335 - Ag Team Data Support\Waves\Ethiopia\Ethiopia ESS Wave 3 2015-16 (LSMS-ISA)"
global rawdataETH2 "\\netid.washington.edu\wfs\EvansEPAR\Project\EPAR\Working Files\335 - Ag Team Data Support\Waves\Ethiopia\Ethiopia ESS Wave 2 2013-14 (LSMS-ISA)"
global rawdataETH1 "\\netid.washington.edu\wfs\EvansEPAR\Project\EPAR\Working Files\335 - Ag Team Data Support\Waves\Ethiopia\Ethiopia ESS Wave 1 2011-12 (LSMS-ISA)"

global rawdataNGA3 "\\netid.washington.edu\wfs\EvansEPAR\Project\EPAR\Working Files\335 - Ag Team Data Support\Waves\Nigeria\Nigeria GHSP Wave 3 2015-16 (LSMS-ISA)"
global rawdataNGA2 "\\netid.washington.edu\wfs\EvansEPAR\Project\EPAR\Working Files\335 - Ag Team Data Support\Waves\Nigeria\Nigeria GHSP Wave 2 2012-13 (LSMS-ISA)"
global rawdataNGA1 "\\netid.washington.edu\wfs\EvansEPAR\Project\EPAR\Working Files\335 - Ag Team Data Support\Waves\Nigeria\Nigeria GHSP Wave 1 2010-11 (LSMS-ISA)"


global createddata "\\netid.washington.edu\wfs\EvansEPAR\Project\EPAR\Working Files\356 - Categorizing Smallholder Farmers\Visualizations Final\Data Cleaning\DTA Files"
global finaldata "\\netid.washington.edu\wfs\EvansEPAR\Project\EPAR\Working Files\356 - Categorizing Smallholder Farmers\Visualizations Final\Final Data Files for Visualizations\On Website"

****************************
** 1.2 Combining Waves TZ **
****************************
//This section combines the three waves for Tanzania and brings in the distance variables.
//The variables from each wave have a number added to the end of their name corresponding to the wave.

//Starting with wave 3
use "${rawdataTZ3}\Final DTA Files\Tanzania_NPS_LSMS_ISA_W3_household_variables.dta", clear
rename hhid y3_hhid
merge 1:1 y3_hhid using "${rawdataTZ3}\Raw DTA Files\Tanzania TNPS - LSMS-ISA Wave 3 (2012-13)\Household\HH_SEC_A.dta", keepusing(hh_a09 hh_a10) nogen
drop hhid
rename hh_a09 hhid
duplicates report hhid if hh_a10 ==1
keep if hh_a10 ==1
duplicates drop hhid, force
//Bringing in variables from the Geo vars file about distance to market, road etc.
merge 1:1 y3_hhid using "${rawdataTZ3}\Raw DTA Files\Tanzania TNPS - LSMS-ISA Wave 3 (2012-13)\Household\HouseholdGeovars_Y3.dta", keepusing(dist01 dist02 dist03 dist04 dist05) nogen keep(3) 

rename dist01 dist_road
rename dist02 dist_popcenter
rename dist03 dist_market
rename dist04 dist_admctr
rename dist05 dist_border

//All wave 3 variables have a "3" added to the end 
foreach k of varlist _all {
	rename `k' `k'3
}
rename hhid3 hhid
rename y2_hhid3 y2_hhid
//Bringing in Wave 2
merge 1:1 hhid using "${rawdataTZ2}\Final DTA Files\Tanzania_NPS_LSMS_ISA_W2_household_variables.dta" ,nogen keep(3)

//Bringing in distance variables
merge 1:1 y2_hhid using "${rawdataTZ2}\Raw DTA Files\Geo\HH.Geovariables_Y2.dta", keepusing(dist02 dist03 dist04 dist05 dist06) nogen keep(3)

rename dist02 dist_road
rename dist03 dist_popcenter
rename dist04 dist_market
rename dist06 dist_admctr
rename dist05 dist_border

//All Wave 2 varaibles have a "2" added to the end
foreach k of varlist _all {
if strmatch("`k'","*3")!=1 {
rename `k' `k'2
}
}
rename hhid2 hhid
rename hhid y2_hhid
merge 1:1 y2_hhid using "${rawdataTZ2}\Raw DTA Files\Household\HH_SEC_A.dta" , keepusing(hh_a11) nogen keep(3)
rename y2_hhid hhid
drop if hh_a11 == 3

replace hhid = hhid + "E"
replace hhid = subinstr(hhid, "01E","",1)
replace hhid = subinstr(hhid,"E","",1)
//Bringing in Wave 1
noisily merge 1:1 hhid using "${rawdataTZ1}\Final DTA Files\Tanzania_NPS_LSMS_ISA_W1_household_variables.dta" //, nogen keep (3)
//Bringing in Distance variables
merge 1:1 hhid using "${rawdataTZ1}\Raw DTA Files\Data - Geovariables\HH.Geovariables_Y1.dta", keepusing(dist02 dist03 dist04 dist05 dist06) nogen keep(3) 

rename dist02 dist_road
rename dist03 dist_popcenter
rename dist04 dist_market
rename dist06 dist_admctr
rename dist05 dist_border

// All Wave 1 variables have a "1" added to the end
foreach k of varlist _all {
if strmatch("`k'","*3")!=1 {
if strmatch("`k'","*2")!=1{
rename `k' `k'1
}
}
}
rename hhid1 hhid

save "${createddata}\Inflection Point Data TZ Merged.dta", replace
*/
*****************************
** 1.3 Combining Waves ETH **
*****************************
//This section brings in the three Ethiopia waves and adds the distance variables.
//The variables from each wave have a number added to the end of their name corresponding to the wave.

//Staring with Wave 3
use "${rawdataETH3}\Final DTA Files\final_data\Ethiopia_ESS_LSMS_ISA_W3_household_variables.dta", clear
rename hhid household_id2
//Bringing in distance varaibles
merge 1:1 household_id2 using "${rawdataETH3}\Raw DTA Files\ETH_HouseholdGeovars_y3.dta" , keepusing (dist_road dist_popcenter dist_market dist_border dist_admctr) nogen keep(3)
rename household_id2 hhid
rename dist_borderpost dist_border

//Adding a "3" to the end of all wave 3 varibles
foreach k of varlist _all {
	rename `k' `k'3
}
rename hhid3 hhid

//Bringing in Wave 2
merge 1:1 hhid using "${rawdataETH2}\Final DTA Files\final_data\Ethiopia_ESS_LSMS_ISA_W2_household_variables.dta", nogen keep(3)
rename hhid household_id2
//Bringing in Distance
merge 1:1 household_id2 using "${rawdataETH2}\Raw DTA Files\Geodata\Pub_ETH_HouseholdGeovars_Y2.dta" , keepusing (dist_road dist_popcenter dist_market dist_border dist_admctr) nogen keep(3)
rename household_id2 hhid
rename dist_borderpost dist_border

//Adding a "2" to all wave 2 variables
foreach k of varlist _all {
if strmatch("`k'","*3")!=1 {
rename `k' `k'2
}
}
rename hhid2 household_id2

merge 1:1 household_id2 using "${rawdataETH2}\Raw DTA Files\Household\sect_cover_hh_w2.dta", keepusing(household_id) nogen keep(3)
drop if missing(household_id)
//Bringing in Wave 1
merge 1:1 household_id using "${rawdataETH1}\Raw DTA Files\Pub_ETH_HouseholdGeovariables_Y1.dta" , keepusing (dist_road dist_popcenter dist_market dist_border dist_admctr) nogen keep(3)
rename household_id hhid
drop hhid


gen str18 hhid = string(region2, "%02.0f") + string(zone2, "%02.0f") + string(woreda2, "%02.0f") + string(kebele2, "%03.0f") + string(ea2, "%02.0f") + string(household2, "%03.0f")
noisily merge 1:1 hhid using "${rawdataETH1}\Final DTA Files\final_data\Ethiopia_ESS_LSMS_ISA_W1_household_variables.dta" //, nogen keep (3)
rename dist_borderpost dist_border
//Adding a "1" to all wave 1 variables
foreach k of varlist _all {
if strmatch("`k'","*3")!=1 {
if strmatch("`k'","*2")!=1{
rename `k' `k'1
}
}
}
rename hhid1 hhid
rename zone3 region_name
rename weight3 weight
gen lvstck_holding_pigs1 = 0
gen lvstck_holding_pigs2 = 0
gen lvstck_holding_pigs3 = 0

save "${createddata}\Inflection Point Data ETH Merged.dta", replace

*****************************
** 1.4 Combining Waves NGA **
*****************************
//This section combines the three waves for Nigeria and brings in the distance variables.
//The variables from each wave have a number added to the end of their name corresponding to the wave.

//Starting with wave 3
use "${rawdataNGA3}\Final DTA files\Nigeria_GHSP_LSMS_ISA_W3_household_variables.dta" , clear
rename value_manure_purch_sorgum_female value_manure_purch_sorgum_fem
rename value_manure_purch_cowpea_female value_manure_purch_cowpea_fem
rename value_manure_purch_swtptt_female value_manure_purch_swtptt_fem
rename value_manure_purch_cassav_female value_manure_purch_cassav_fem
rename value_manure_purch_banana_female value_manure_banana_cassav_fem

//Bringing in distance variables
merge 1:1 hhid using "${rawdataNGA3}\Raw DTA files\Nigeria GHSP - LSMS-ISA - Wave 3 (2015-16)\NGA_HouseholdGeovars_Y3.dta", keepusing (dist_road2 dist_popcenter2 dist_market dist_border2 dist_admctr) nogen keep(3)
rename dist_road2 dist_road
rename dist_popcenter2 dist_popcenter
rename dist_border2 dist_border
//dist_admctr dist_market
//Adding a "3" to all wave 3 variables
foreach k of varlist _all {
	rename `k' `k'3
}
rename hhid3 hhid
//Bringing in wave 2 variables
merge 1:1 hhid using "${rawdataNGA2}\Final DTA Files\Nigeria_GHSP_LSMS_ISA_W2_household_variables_usd.dta", nogen keep(3)
rename value_manure_purch_sorgum_female value_manure_purch_sorgum_fem
rename value_manure_purch_cowpea_female value_manure_purch_cowpea_fem
rename value_manure_purch_swtptt_female value_manure_purch_swtptt_fem
rename value_manure_purch_cassav_female value_manure_purch_cassav_fem
rename value_manure_purch_banana_female value_manure_banana_cassav_fem
//Bringing in distance variables
merge 1:1 hhid using "${rawdataNGA2}\Raw DTA Files\Geodata Wave 2\NGA_HouseholdGeovars_Y2.dta" , keepusing (dist_road2 dist_popcenter2 dist_market dist_border2 dist_admctr) nogen keep(3)
rename dist_road2 dist_road
rename dist_popcenter2 dist_popcenter
rename dist_border2 dist_border
//dist_admctr dist_market
//TAF END
//Adding a "2" to the end of all Wave 2 variables
foreach k of varlist _all {
if strmatch("`k'","*3")!=1 {
rename `k' `k'2
}
}
rename hhid2 hhid
//Bringing in wave 1 variables
merge 1:1 hhid using "${rawdataNGA1}\Final DTA Files\Nigeria_GHSP_LSMS_ISA_W1_household_variables_usd.dta", nogen keep(3)
/*
rename value_manure_purch_sorgum_female value_manure_purch_sorgum_fem
rename value_manure_purch_cowpea_female value_manure_purch_cowpea_fem
rename value_manure_purch_swtptt_female value_manure_purch_swtptt_fem
rename value_manure_purch_cassav_female value_manure_purch_cassav_fem
rename value_manure_purch_banana_female value_manure_banana_cassav_fem*/
//TAF 4.15.19
//Bringing in distance variables
merge 1:1 hhid using "${rawdataNGA1}\Raw DTA Files\Geodata\NGA_HouseholdGeovariables_Y1.dta", keepusing (dist_road dist_popcenter dist_market dist_border dist_admctr) nogen keep(3)
rename dist_borderpost dist_border

//Adding a "1" to the end of all wave 1 variables
foreach k of varlist _all {
if strmatch("`k'","*3")!=1 {
if strmatch("`k'","*2")!=1{
rename `k' `k'1
}
}
}
rename hhid1 hhid
rename state3 region_name
rename weight3 weight
save "${createddata}\Inflection Point Data NGA Merged.dta", replace

/////////////////////////////////////////////////////////
//	2. Creating Files for Year over Year Variability   //
/////////////////////////////////////////////////////////
//This section takes the files created in section 1 and creates the Year Over Year Variability files

**************************
**  2.1 Cleaning Files  **
**************************
//We are creating new files for each possible disaggregation.
//Because of this, we need to create separate files for each choice of Relative vs Absolute, gender of head of household, and household type (Agricultural, rural)
clear
set more off
set maxvar 20000
//This loop covers the options of whether a threshold is relative (e.g. under the median household for that year) or absolute (e.g. under 2ha).
foreach relative in Relative Absolute { 
//This loop covers the options for the gender of head of household (male, female, or any)
foreach head_of_household in any fhh mhh {
//This loop splits households into agricultural, rural, agricultural and rural, and all households.  These are defined based on the definitions used in 335.
foreach hhtype in all agricultural rural agricultural_rural {
//This loop covers each country separately.
foreach country in TZ ETH NGA {

use "${createddata}\Inflection Point Data `country' Merged.dta", clear
//Keeping only used variables
keep rural* region_name* fhh* grew_maize* w_labor_productivity_usd* w_land_productivity_usd* w_farm_income_usd* /*
*/ w_value_crop_production_usd* w_farm_area* w_proportion_cropvalue_sold* w_share_nonfarm* w_agwage_income_usd*  /*
*/ w_labor_family* w_labor_hired* w_total_income_usd* w_agwage_income_usd* w_farm_size_agland* w_total_cons_usd* /*
*/  weight* ag_hh* w_total_income_usd* w_value_livestock_products_usd* w_value_livestock_sales_usd* lvstck_holding_* hhid w_sales_livestock_products_usd* w_value_crop_sales_usd* //dist_*

//Dropping other households for disaggregation

if "`hhtype'" == "agricultural" | "`hhtype'" == "agricultural_rural" {
keep if ag_hh1 ==1 | ag_hh2 ==1 | ag_hh3 ==1
}
if "`hhtype'" == "rural" | "`hhtype'" == "agricultural_rural" {
keep if rural1 ==1 | rural2 ==1 | rural3 ==1
}
if "`head_of_household'" == "fhh" {
keep if fhh1 ==1 | fhh2==1 | fhh3==1
}
if "`head_of_household'" == "mhh" {
keep if fhh1 !=1 & fhh2 !=1 & fhh3 !=1
}
foreach k of varlist fhh* grew_maize* w_labor_productivity_usd* w_land_productivity_usd* w_farm_income_usd* w_value_crop_production_usd* w_farm_area* w_proportion_cropvalue_sold* w_share_nonfarm* w_agwage_income_usd* w_labor_family* w_labor_hired* w_total_income_usd* w_agwage_income_usd* w_farm_size_agland* w_total_cons_usd* weight* ag_hh* w_total_income_usd* w_value_livestock_products_usd* w_value_livestock_sales_usd* lvstck_holding_* /* dist_* */ {
replace `k' = 0 if missing(`k')
}
//Creating necessary variables
forvalues c=1(1)3 {
gen w_share_non_family_labor`c' = w_labor_hired`c'/(w_labor_hired`c' + w_labor_family`c')
replace w_share_non_family_labor`c' = 0 if missing(w_share_non_family_labor`c')
gen w_value_farm_production`c' = w_value_livestock_products_usd`c' /*+ w_value_livestock_sales_usd`c'*/ + w_value_crop_production_usd`c'
gen w_value_farm_sales`c' = w_sales_livestock_products_usd`c' + w_value_crop_sales_usd`c'
gen w_proportion_farmvalue_sold`c' = w_value_farm_sales`c'/w_value_farm_production`c'
}
save "${createddata}\Inflection Point Data Small Cleaned `country' `hhtype' `head_of_household' `relative'.dta", replace 
//Creating Highs and Lows
global criteria w_farm_size_agland lvstck_holding_tlu lvstck_holding_equine lvstck_holding_lrum lvstck_holding_srum lvstck_holding_pigs lvstck_holding_poultry w_share_non_family_labor w_proportion_cropvalue_sold w_share_nonfarm w_farm_income_usd w_total_income_usd w_value_farm_production w_total_cons_usd w_proportion_farmvalue_sold //dist_popcenter dist_market dist_border dist_admctr dist_road
foreach k of global criteria {
egen `k'L = rowmin(`k'*)
egen `k'H = rowmax(`k'*)
egen `k'TL = min(`k'L)
egen `k'TH = max(`k'H)
}
capture rename weight3 weight
keep hhid weight w_farm_size_agland* lvstck_holding_tlu* lvstck_holding_equine* lvstck_holding_lrum* lvstck_holding_srum* lvstck_holding_pigs* lvstck_holding_poultry* w_share_non_family_labor* w_proportion_cropvalue_sold* w_share_nonfarm* w_farm_income_usd* w_total_income_usd* w_value_farm_production* w_total_cons_usd* w_proportion_farmvalue_sold* //dist_*
save "${createddata}\Inflection Point Data `country' Low High `hhtype' `head_of_household' `relative'.dta", replace

**************************
**   2.2 Increments		**
**************************
//This section creates the increments.
//These increments are used to set each of the particular threseholds that varibility will be tested against.
//Originally these are set to 1/100th of the range, but then are standardized to more common values first by section, and then by variable.  

//This loop covers each individual variable, testing its volatility at each of the thresholds
foreach k of global criteria {

set more off

use "${createddata}\Inflection Point Data `country' Low High `hhtype' `head_of_household' `relative'.dta", clear
//dropping other variables
keep hhid weight `k'*

egen tot_weight = total(weight)
//Creating high and low locals for increment creation
local high =`k'TH[1]
local low = `k'TL[1]

local increment = (`high'-`low')/100 //Seeting the increment to 1/100th of the range

//This section sets increments to common values (so we don't have an odd decimal increase.
if `increment' <0.1 {
local increment = 0.01
}
if `increment' < .4 & `increment' >0.1 {
local increment = 0.2
}
if `increment' > .4 & `increment' < 1 {
local increment = 0.5
}
if `increment' < 5 & `increment' > 1 {
local increment = 2
}
if `increment' > 5 & `increment' < 50 {
local increment = 10
}
if `increment' < 500 & `increment' > 50 {
local increment = 100
}
if `increment' > 500 {
local increment = 800
}
if `low'<0 {
local low = -500
}
//Some variables, particularly livestock, have high outliers, so we set their highs, lows, and increments manually.  We also do this with monetary values so that they can be easily compared.
if "`k'" == "lvstck_holding_tlu" {
local low = 0
local increment = 0.1
local high = 10
}
if "`k'" == "lvstck_holding_equine" {
local low = 0
local increment = 1
local high = 10
}
if "`k'" == "lvstck_holding_lrum" {
local low = 0
local increment = 1
local high = 100
}
if "`k'" == "lvstck_holding_srum" {
local low = 0
local increment = 1
local high = 100
}
if "`k'" == "lvstck_holding_pigs" {
local low = 0
local increment = 1
local high = 30
}
if "`k'" == "lvstck_holding_poultry" {
local low = 0
local increment = 1
local high = 100
}
if "`k'" == "w_total_income_usd" {
local low = -500
local increment = 100
local high = 15000
}
if "`k'" == "w_farm_size_agland" {
local low = 0
local increment = 0.1
local high = 10
}
if "`k'" == "w_farm_income_usd" {
local low = -500
local increment = 50
local high = 5000
}
if "`k'" == "w_value_farm_production" {
local low = 0
local increment = 50
local high = 5000
}
if "`k'" == "w_total_cons_usd" {
local low = 0
local increment = 100
local high = 10000
}
//This forces all relatives to a low of 1, a high of 99 and an increment of 1
if "`relative'" == "Relative" {
local low = 1
local increment = 1
local high = 99
}


**************************
**    2.3 Directions	**
**************************
//This section categorizes each houshold as increasing, decreasing fluctuating or staying.
//It creates a new variable for each threshold and direction of household, as well as a corresponding global which is the actual threshold value.
//The values for this variable are the share of the total weight for that household.  Thse will be collasped later so that we cna see what the total weight for each category is.
local count = 1
forvalues kk = `low'(`increment')`high' {
//This creates the individual thresholds for each variable for each wave.  
//These are identical for the absolute, but vary for the relative definition.
if "`relative'" == "Absolute" {
forvalues c = 1(1)3 {
local kk`c' = `kk'
}
}

if "`relative'" == "Relative" {
forvalues c = 1(1)3 {

_pctile `k'`c' [aw=weight], p(`kk')
local kk`c' = r(r1)
}
}


//C= Change at all (I or D or F), S=Stay, I=Increase, D=Decrease, F = Fluctuate
gen `k'_C`count' = 0
//This count is used as a name for the threshold valeus as some of them have decimals.  This will be cashed out later in the next section.

//A households is considered to change if it is not the case that it was always under the threshold or always over the threshold
replace `k'_C`count' = weight/tot_weight if !((`kk1'<`k'1 & `kk2'<`k'2 & `kk3'<`k'3) | (`kk1'>=`k'1 & `kk2'>=`k'2 & `kk3'>=`k'3)) & (!missing(`k'1) & !missing(`k'2) & !missing(`k'3))
//This global corresponds the count to the particular threshold value due to issues with decimals in variable names
global `k'_C`count' = `kk'

//A household is considered to stay if it does not change, i.e. if it is always under the threshold or always over the threshold
gen `k'_S`count' = 0
replace `k'_S`count' = weight/tot_weight if ((`kk1'<`k'1 & `kk2'<`k'2 & `kk3'<`k'3) | (`kk1'>=`k'1 & `kk2'>=`k'2 & `kk3'>=`k'3)) & (!missing(`k'1) & !missing(`k'2) & !missing(`k'3))
//This global corresponds the count to the particular threshold value due to issues with decimals in variable names
global `k'_S`count' = `kk'

//A household is considered to increase if it moves from being under the threshold to above the threshold and does not go back.
gen `k'_I`count' = 0
replace `k'_I`count' = weight/tot_weight if (`kk3'<`k'3 & `kk1'>=`k'1 & `kk2'>=`k'2) & (!missing(`k'1) & !missing(`k'2) & !missing(`k'3))
replace `k'_I`count' = weight/tot_weight if (`kk3'<`k'3 & `kk1'>=`k'1 & `kk2'<`k'2) & (!missing(`k'1) & !missing(`k'2) & !missing(`k'3))
//This global corresponds the count to the particular threshold value due to issues with decimals in variable names
global `k'_I`count' = `kk'

//A household is considered to decrease if it moves from being above the threhsold to below the threshold and does not go back.
gen `k'_D`count' = 0
replace `k'_D`count' = weight/tot_weight if (`kk3'>=`k'3 & `kk1'<`k'1 & `kk2'<`k'2) & (!missing(`k'1) & !missing(`k'2) & !missing(`k'3))
replace `k'_D`count' = weight/tot_weight if (`kk3'>=`k'3 & `kk1'<`k'1 & `kk2'>=`k'2) & (!missing(`k'1) & !missing(`k'2) & !missing(`k'3))
//This global corresponds the count to the particular threshold value due to issues with decimals in variable names
global `k'_D`count' = `kk'

//A household is considered to fluctuate if it crosses the threshold twice.  
gen `k'_F`count' = 0
replace `k'_F`count' = weight/tot_weight if (`kk3'>=`k'3 & `kk1'>=`k'1 & `kk2'<`k'2) & (!missing(`k'1) & !missing(`k'2) & !missing(`k'3))
replace `k'_F`count' = weight/tot_weight if (`kk3'<`k'3 & `kk1'<`k'1 & `kk2'>=`k'2) & (!missing(`k'1) & !missing(`k'2) & !missing(`k'3))
//This global corresponds the count to the particular threshold value due to issues with decimals in variable names
global `k'_F`count' = `kk'

local count = `count' + 1
}

*****************************
** 2.4 Merging & Reshaping **
*****************************

global directions C S I D F 
//This loop creates a separate file for each direction and collapses them into a single observation.  This is done as a loop so that they can all be merged back together into a single observation for reshaping.
foreach direction of global directions {
preserve
collapse (sum) `k'_`direction'* //This collapses the share of weight for each direction into a single observation, split by the thresholds
gen id = 1 //needed for merging and reshaping
save "${createddata}\Inflection Point Data `country' Collapsed `k' `direction' `hhtype' `head_of_household' `relative'.dta", replace
restore
}
//We then merge the five dircetions back together to create a single file with only one observation.
use "${createddata}\Inflection Point Data `country' Collapsed `k' C `hhtype' `head_of_household' `relative'.dta", clear
merge 1:1 id using "${createddata}\Inflection Point Data `country' Collapsed `k' S `hhtype' `head_of_household' `relative'.dta", nogen
merge 1:1 id using "${createddata}\Inflection Point Data `country' Collapsed `k' I `hhtype' `head_of_household' `relative'.dta", nogen
merge 1:1 id using "${createddata}\Inflection Point Data `country' Collapsed `k' D `hhtype' `head_of_household' `relative'.dta", nogen
merge 1:1 id using "${createddata}\Inflection Point Data `country' Collapsed `k' F `hhtype' `head_of_household' `relative'.dta", nogen

save "${createddata}\Inflection Point Data `country' Collapsed `k' `hhtype' `head_of_household' `relative'.dta", replace
}
//Note that this is where the criteria loop above ends.  A new criteria loop starts below.

//Reshaping 
//This section reshapes the data to be long instead of wide, with separate variables for the direction
global directions C S I D F 
set more off
//This loop goes over each of the indicators or criteria for which we want to test thresholds
foreach k of global criteria {
//This loops over the relevant directions.
foreach direction of global directions{
use "${createddata}\Inflection Point Data `country' Collapsed `k' `hhtype' `head_of_household' `relative'.dta", clear
keep `k'_`direction'*  //This drops the other directions
generate id = 1
reshape long `k'_`direction', i(id) j(`k') //Reshapes the data to be long
local number = _N
forvalues c =1(1)`number' {
replace `k' = ${`k'_`direction'`c'} in `c' //Inputs the globals from section 2.3 above into a new variable
}
drop id
rename `k'_ Percent_Of_Households_`direction'  
capture label drop component
save "${createddata}\Inflection Point Data `country' `k' `direction' `hhtype' `head_of_household' `relative'.dta", replace
}
//Merging together all of the directions
use "${createddata}\Inflection Point Data `country' `k' C `hhtype' `head_of_household' `relative'.dta", clear
merge 1:1 `k' using "${createddata}\Inflection Point Data `country' `k' S `hhtype' `head_of_household' `relative'.dta", nogen
merge 1:1 `k' using "${createddata}\Inflection Point Data `country' `k' I `hhtype' `head_of_household' `relative'.dta", nogen
merge 1:1 `k' using "${createddata}\Inflection Point Data `country' `k' D `hhtype' `head_of_household' `relative'.dta", nogen
merge 1:1 `k' using "${createddata}\Inflection Point Data `country' `k' F `hhtype' `head_of_household' `relative'.dta", nogen
save "${createddata}\Inflection Point Data `country' `k' `hhtype' `head_of_household' `relative'.dta", replace
export excel using "${createddata}\Inflection Point Data `country' `k' `hhtype' `head_of_household'.xls", replace firstrow(variables)

//We then reshape again, bringing in the direction of the household movement into a single column of values
rename Percent_Of_Households_C Percent_Of_Households_1
rename Percent_Of_Households_S Percent_Of_Households_2
rename Percent_Of_Households_I Percent_Of_Households_3
rename Percent_Of_Households_D Percent_Of_Households_4
rename Percent_Of_Households_F Percent_Of_Households_5
reshape long Percent_Of_Households_, i(`k') j(movement)
label define Movement 1 "Change" 2 "Stay" 3 "Increase" 4 "Decrease" 5 "Fluctuate"
label values movement Movement
rename Percent_Of_Households_ Percent_Of_Households
generate criteria = "`k'"
rename `k' Threshold_Value
gen country = "`country'"
save "${createddata}\Inflection Point Data `country' `k' long `hhtype' `head_of_household' `relative'.dta", replace
export excel using "${createddata}\Inflection Point Data `country' `k' long `hhtype' `head_of_household' `relative'.xls", replace firstrow(variables)
}
}
//Again, we end the criteria loop, but jump back into it below.  However, here we also end the country loop, as our first task in the next section is to append the country files together.

**************************
**   2.5 Appending		**
**************************
// This section appends the original disaggregations together

//This loop brings in all of the country files for each criteria
foreach k of global criteria {
use "${createddata}\Inflection Point Data TZ `k' long `hhtype' `head_of_household' `relative'.dta", clear
append using "${createddata}\Inflection Point Data ETH `k' long `hhtype' `head_of_household' `relative'.dta"
append using "${createddata}\Inflection Point Data NGA `k' long `hhtype' `head_of_household' `relative'.dta"
save "${createddata}\Inflection Point Data `k' long `hhtype' `head_of_household' `relative'.dta", replace
}

//This loop appends all of the criteria files
clear 
local first "Yes"
foreach k of global criteria {
if "`first'" == "No" {
append using "${createddata}\Inflection Point Data `k' long `hhtype' `head_of_household' `relative'.dta"
}

if "`first'" == "Yes" {
use "${createddata}\Inflection Point Data `k' long `hhtype' `head_of_household' `relative'.dta"
local first "No"
}

}
generate Household_Type = "`hhtype'"
save "${createddata}\Inflection Point Data long All `hhtype' `head_of_household' `relative'.dta", replace

}
//We now end the household type loop, and append all of the types of hosuehold together.
use "${createddata}\Inflection Point Data long All all `head_of_household' `relative'.dta", clear
append using "${createddata}\Inflection Point Data long All agricultural `head_of_household' `relative'.dta"
append using "${createddata}\Inflection Point Data long All rural `head_of_household' `relative'.dta"
append using "${createddata}\Inflection Point Data long All agricultural_rural `head_of_household' `relative'.dta"

generate Head_Of_Household = "`head_of_household'"
save "${createddata}\Inflection Point Data long All `head_of_household' `relative'.dta", replace
}
//Here we end the gender of the head of household loop and append these together
use "${createddata}\Inflection Point Data long All any `relative'.dta", clear
append using "${createddata}\Inflection Point Data long All mhh `relative'.dta"
append using "${createddata}\Inflection Point Data long All fhh `relative'.dta"

generate Universality = "`relative'"
save "${createddata}\Inflection Point Data long All `relative'.dta", replace
export excel using "${createddata}\Inflection Point Data long All `relative'.xlsx", replace firstrow(variables)
}
//Finally, we end the relative vs absolute loop and append thes files together.
use "${createddata}\Inflection Point Data long All Relative.dta", clear
append using "${createddata}\Inflection Point Data long All Absolute.dta"

save "${finaldata}\Inflection Point Data long All Universal.dta", replace
export excel using "${finaldata}\Year Over Year Variability.xlsx", replace firstrow(variables)



/////////////////////////////////////////////////////////
//	  3. Creating Files for Sixteen Categorizations	   //
/////////////////////////////////////////////////////////
//This section creates the file for the sixteen categorizations viz.
//All it does is drop the unused variables and append the files together.

clear
set more off
set maxvar 20000

foreach country in TZ NGA ETH {
use "${createddata}\Inflection Point Data `country' Merged.dta", clear

forvalues c=1(1)3 {
gen w_value_farm_production`c' = w_value_livestock_products_usd`c' /*+ w_value_livestock_sales_usd`c'*/ + w_value_crop_production_usd`c'
gen w_value_farm_sales`c' = w_sales_livestock_products_usd`c' + w_value_crop_sales_usd`c'
gen w_proportion_farmvalue_sold`c' = w_value_farm_sales`c'/w_value_farm_production`c'
}


keep rural* fhh* grew_maize* w_labor_productivity_usd* w_land_productivity_usd* w_farm_income_usd* /*
*/ w_value_crop_production_usd* w_farm_area* w_proportion_cropvalue_sold* w_share_nonfarm* w_agwage_income_usd*  /*
*/ w_labor_family* w_labor_hired* w_total_income_usd* w_agwage_income_usd* w_farm_size_agland* w_total_cons_usd* /*
*/  weight* ag_hh* w_total_income_usd* w_value_livestock_products_usd* w_value_livestock_sales_usd* lvstck_holding_* hhid w_daily_peraeq_cons_usd* /* TAF START 5.2.19
 */ share_livestock_prod_sold* w_cost_total_ha_usd* w_proportion_farmvalue_sold*
drop *2
generate country = "`country'"
rename hhid hhid_`country'
save "${createddata}\Inflection Point Data `country' Merged Small.dta", replace
}
use "${createddata}\Inflection Point Data TZ Merged Small.dta", clear
append using "${createddata}\Inflection Point Data NGA Merged Small.dta"
append using "${createddata}\Inflection Point Data ETH Merged Small.dta"
save "${finaldata}\Inflection Point Data Sankey.dta", replace
export excel using "${finaldata}\Inflection Point Data Sankey.xlsx", replace firstrow(variables)

