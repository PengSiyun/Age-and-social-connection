****Priject: Gender and network
****Author:  Siyun Peng
****Date started: 2022/07/28
****Version: 17
****Purpose: Data clean and merge for one generator





***************************************************************
**# 1 Clean Network alter level data
***************************************************************


foreach i in PROB HEALTH_COUNT HEALTH_TALK SOCIAL HASSLE {
*cd "C:\Users\siypeng\Dropbox\peng\Academia\Work with Brea\P2P\Age and network\data" //office
cd "C:\Users\peng_admin\Dropbox\peng\Academia\Work with Brea\P2P\Age and network\data" //home
use "egocentric_networks_peng.dta",clear


/*Select alters based on generators (skip to "network clean" section if using all generators)*/


*Select generators 
recode PROB HEALTH_COUNT HEALTH_TALK SOCIAL HASSLE (92 96=0)
keep if `i'==1 | PROB==96 //keep alters named in i

*create alter match file for alter-alter level data
preserve
replace PERSON="" if PERSON== "91" | PERSON== "92"
gen ALTER1 = PERSON 
gen ALTER2 = PERSON
keep SU_ID ALTER1 ALTER2
save "alter-match",replace
restore


/*network clean*/


sort SU_ID PERSON_COUNT
bysort SU_ID: egen netsize=count(PERSON_COUNT)
replace netsize=0 if PERSON_COUNT==96
replace netsize=. if PERSON_COUNT==92

*diversity measure (Cohen)
recode RELATIONSHIP* (92/max=.)
egen partner=rowtotal(RELATIONSHIP_SPOUSE RELATIONSHIP_PARTNER),mi
egen othfam=rowtotal(RELATIONSHIP_SIBLING RELATIONSHIP_GRANDPARENT RELATIONSHIP_GRANDCHILD RELATIONSHIP_RELATIVE),mi //group into other family
egen relneigh=rowtotal(RELATIONSHIP_ROOMMATE RELATIONSHIP_NEIGHBOR),mi //group into neighbors

recode partner othfam relneigh (1/max=1)
foreach x of varlist RELATIONSHIP_PARENT RELATIONSHIP_CHILD RELATIONSHIP_FRIEND RELATIONSHIP_COWORKER RELATIONSHIP_CHURCHMEMBER RELATIONSHIP_OTHER RELATIONSHIP_HEALTHPROV partner othfam relneigh {
egen u`x' = tag(SU_ID `x') if `x'>0 & !missing(`x') // e.g., count multiple friends as 1 friend
}
bysort SU_ID: egen diverse=total(uRELATIONSHIP_PARENT+uRELATIONSHIP_CHILD+uRELATIONSHIP_FRIEND+uRELATIONSHIP_COWORKER+uRELATIONSHIP_CHURCHMEMBER+uRELATIONSHIP_OTHER+uRELATIONSHIP_HEALTHPROV+upartner+uothfam+urelneigh),mi //cohen's 12 categories(volunteer, in-law, social club, and schoolmate are not in this data thus leaving us 8 of 12 Cohen's categories, and I added prof and other to have 10 in total)
replace diverse=. if missing(netsize)
replace diverse=0 if netsize==0
lab var diverse "Network diversity"
drop uRELATIONSHIP_PARENT-urelneigh partner othfam relneigh

*proportion/number of relation type
*one type for each alter

egen kin=rowtotal(RELATIONSHIP_SPOUSE RELATIONSHIP_PARTNER RELATIONSHIP_PARENT RELATIONSHIP_SIBLING RELATIONSHIP_CHILD RELATIONSHIP_GRANDPARENT RELATIONSHIP_GRANDCHILD RELATIONSHIP_RELATIVE),mi
recode kin (1/max=1)
bysort SU_ID: egen nkin=total(kin),mi
replace nkin=. if missing(netsize)
replace nkin=0 if netsize==0
lab var nkin "# Kin"
bysort SU_ID: egen pkin=mean(kin)
replace pkin=. if missing(netsize)
replace pkin=0 if netsize==0
lab var pkin "Prop. kin"

egen kid=rowtotal(RELATIONSHIP_GRANDCHILD RELATIONSHIP_CHILD),mi
recode kid (1/max=1)
bysort SU_ID: egen nkid=total(kid),mi
replace nkid=. if missing(netsize)
replace nkid=0 if netsize==0
lab var nkid "# (grand)child"
bysort SU_ID: egen pkid=mean(kid)
replace pkid=. if missing(netsize)
replace pkid=0 if netsize==0
lab var pkid "Prop. (grand)child"

egen partner=rowtotal(RELATIONSHIP_SPOUSE RELATIONSHIP_PARTNER),mi
recode partner (1/max=1)
replace partner=0 if kid==1  //kid takes priority
bysort SU_ID: egen npartner=total(partner),mi
replace npartner=. if missing(netsize)
replace npartner=0 if netsize==0
lab var npartner "# partner/spouse"
bysort SU_ID: egen ppartner=mean(partner)
replace ppartner=. if missing(netsize)
replace ppartner=0 if netsize==0
lab var ppartner "Prop. partner/spouse"

egen otherfam=rowtotal(RELATIONSHIP_PARENT RELATIONSHIP_SIBLING  RELATIONSHIP_GRANDPARENT RELATIONSHIP_RELATIVE),mi
recode otherfam (1/max=1)
replace otherfam=0 if kid==1 | partner==1 //kid&partner takes priority: 13 other family were checked for kid or partner
bysort SU_ID: egen notherfam=total(otherfam),mi
replace notherfam=. if missing(netsize)
replace notherfam=0 if netsize==0
lab var notherfam "# other family"
bysort SU_ID: egen potherfam=mean(otherfam)
replace potherfam=. if missing(netsize)
replace potherfam=0 if netsize==0
lab var potherfam "Prop. other family"

gen workmate=RELATIONSHIP_COWORKER
replace workmate=0 if kin==1 //family takes priority
bysort SU_ID: egen nworkmate=total(workmate),mi
replace nworkmate=. if missing(netsize)
replace nworkmate=0 if netsize==0
lab var nworkmate "# colleague"
bysort SU_ID: egen pworkmate=mean(workmate)
replace pworkmate=. if missing(netsize)
replace pworkmate=0 if netsize==0
lab var pworkmate "Prop. colleague"

/*
gen hlthpro=RELATIONSHIP_HEALTHPROV
replace hlthpro=0 if kin==1 | workmate==1 //family&workmate take priority
bysort SU_ID: egen nhlthpro=total(hlthpro),mi
replace nhlthpro=. if missing(netsize)
replace nhlthpro=0 if netsize==0
lab var nhlthpro "# health professional"
bysort SU_ID: egen phlthpro=mean(hlthpro)
replace phlthpro=. if missing(netsize)
replace phlthpro=0 if netsize==0
lab var phlthpro "Prop. health professional"
*/

gen fri=RELATIONSHIP_FRIEND
replace fri=0 if kin==1 | workmate==1  //family&workmate take priority
bysort SU_ID: egen nfri=total(fri),mi
replace nfri=. if missing(netsize)
replace nfri=0 if netsize==0
lab var nfri "# friend"
bysort SU_ID: egen pfri=mean(fri)
replace pfri=. if missing(netsize)
replace pfri=0 if netsize==0
lab var pfri "Prop. friend"

egen other=rowtotal(RELATIONSHIP_NEIGHBOR RELATIONSHIP_ROOMMATE RELATIONSHIP_CHURCHMEMBER RELATIONSHIP_OTHER),mi
recode other (1/max=1)
replace other=0 if kin==1 | workmate==1 | fri==1 //family takes priority
bysort SU_ID: egen nother=total(other),mi
replace nother=. if missing(netsize)
replace nother=0 if netsize==0
lab var nother "# other"
bysort SU_ID: egen pother=mean(other)
replace pother=. if missing(netsize)
replace pother=0 if netsize==0
lab var pother "Prop. other"
 

drop kin partner kid otherfam workmate fri other





recode HELP_LISTEN HELP_CARE HELP_ADVISE HELP_HELP HELP_MATERIAL (92/max=.)
egen sup=rowtotal(HELP_LISTEN HELP_CARE HELP_ADVISE HELP_HELP HELP_MATERIAL)
replace sup=. if missing(netsize)
replace sup=0 if netsize==0
bysort SU_ID: egen msup=mean(sup)
bysort SU_ID: egen sdsup=sd(sup)
bysort SU_ID: egen iqrsup=iqr(sup)
lab var msup "Mean number of support functions in network, HI=MORE"
recode sup (0/4=0) (5=1),gen(sup5)
drop sup 

egen sup3=rowtotal(HELP_LISTEN HELP_CARE HELP_ADVISE)
replace sup3=. if missing(netsize)
replace sup3=0 if netsize==0
bysort SU_ID: egen msup3=mean(sup3)
bysort SU_ID: egen sdsup3=sd(sup3)
bysort SU_ID: egen iqrsup3=iqr(sup3)

lab var msup3 "Mean number of support functions in network (listen, care, advice)"

rename (HELP_LISTEN HELP_CARE HELP_ADVISE HELP_HELP HELP_MATERIAL) ///
       (listen care advice chores loan)
recode sup3 (0/2=0) (3=1)
foreach x of varlist listen care advice chores loan sup3 sup5 {
	replace `x'=. if missing(netsize)
	replace `x'=0 if netsize==0
	bysort SU_ID: egen n`x'=total(`x'),mi //missing means no alter
	bysort SU_ID: egen p`x'=mean(`x') //missing means no alter
}
lab var plisten "Prop. listen to you when upset"
lab var pcare "Prop. tell you they care about what happens to you"
lab var padvice "Prop. give suggestions when you have a problem"
lab var pchores "Prop. help you with daily chores"
lab var ploan "Prop. loan money when you are short of money"
lab var psup3 "Prop. 3 support functions"
lab var psup5 "Prop. 5 support functions"

lab var nlisten "# listen to you when upset"
lab var ncare "# tell you they care about what happens to you"
lab var nadvice "# give suggestions when you have a problem"
lab var nchores "# help you with daily chores"
lab var nloan "# loan money when you are short of money"
lab var nsup3 "# 3 support functions"
lab var nsup5 "# 5 support functions"
drop sup3 sup5

recode STRENGTH (92/max=.)
bysort SU_ID: egen mstrength=mean(STRENGTH)
replace mstrength=. if missing(netsize)
replace mstrength=0 if netsize==0

bysort SU_ID: egen minstrength=min(STRENGTH)
replace minstrength=. if missing(netsize)
replace minstrength=0 if netsize==0

bysort SU_ID: egen sdstrength=sd(STRENGTH)
replace sdstrength=. if missing(netsize)
replace sdstrength=0 if netsize==0

bysort SU_ID: egen iqrstrength=iqr(STRENGTH)
replace iqrstrength=. if missing(netsize)
replace iqrstrength=0 if netsize==0

lab var mstrength "Mean tie strength"
lab var minstrength "Minimum strength of tie"
lab var sdstrength "SD of tie strength"
lab var iqrstrength "IQR of tie strength"

fre SEX RACE EDUCATION HASSLE_FREQ

recode SEX RACE EDUCATION HASSLE_FREQ (92/98=.)

gen fem=SEX
recode fem (1=0)(2=1)(3/9=0)
bysort SU_ID: egen pfem=mean(fem)
replace pfem=. if missing(netsize)
replace pfem=0 if netsize==0
lab var pfem "Proportion female"
drop fem

gen samerace=RACE
recode samerace (2=0)
bysort SU_ID: egen psamerace=mean(samerace)
replace psamerace=. if missing(netsize)
replace psamerace=0 if netsize==0
lab var psamerace "Proportion same race"
drop samerace

gen hs=EDUCATION
gen col=EDUCATION
recode hs (1/2=1)(3/5=0)
recode col (5=1)(1/4=0)
bysort SU_ID: egen phs=mean(hs)
bysort SU_ID: egen pcol=mean(col)
replace phs=. if missing(netsize)
replace pcol=. if missing(netsize)
lab var phs "Proportion with HS educ or less"
lab var pcol "Proportion with college degree or more"
drop hs col

bysort SU_ID: egen mhassles=mean(HASSLE_FREQ)
replace mhassles=. if missing(netsize)
replace mhassles=0 if netsize==0
lab var mhassles "Mean frequency of hassles/problems"


keep SU_ID netsize-mhassles
duplicates drop SU_ID, force
save "network-ego",replace



***************************************************************
**# 2 Clean Network alter-alter level data 
***************************************************************




/*match alters based on generators (skip to "network clean" section if using all generators)*/


use "egocentric_networks_pairs.dta",clear
merge m:1 SU_ID ALTER1 using "alter-match",keepusing(ALTER1)
keep if _merge==3 //keep matched alters for alter1
drop _merge
merge m:1 SU_ID ALTER2 using "alter-match",keepusing(ALTER2)
keep if _merge==3 //keep matched alters for alter2
drop _merge


/*network clean*/


merge m:1 SU_ID using "network-ego"
fre netsize if _merge==2 //FOCAL missing from alter-alter data due to netsize<2

bysort SU_ID: egen npossties=count(NET_PAIRS) //count refused and don't know
recode NET_PAIRS (97/98=.)
bysort SU_ID: egen density=mean(NET_PAIRS)

recode NET_PAIRS (2/3=1) (0/1=0),gen(netpairs1)
bysort SU_ID: egen totnum=total(netpairs1),mi //for Binary density
gen bdensity=totnum/npossties
lab var bdensity "Binary density (Sort of or very close)"

recode NET_PAIRS (1/3=1) (0=0),gen(netpairs2)
bysort SU_ID: egen totnum2=total(netpairs2),mi //for Binary density
gen b1density=totnum2/npossties
lab var b1density "Binary density (know each other)"


*calculate Effective size
replace totnum2=totnum2/2 //double counting
gen efctsize=netsize-2*totnum2/netsize
replace efctsize=0 if netsize==0 
label var efctsize "Effective size"

keep SU_ID netsize-mhassles *density efctsize
duplicates drop SU_ID, force






***************************************************************
**# 3 Merge with non-network data
***************************************************************




merge 1:1 SU_ID using "demographics.dta",nogen
merge 1:1 SU_ID using "cognitive_function.dta",nogen
merge 1:1 SU_ID using "end_material.dta",nogen
merge 1:1 SU_ID using "family_health.dta",nogen
merge 1:1 SU_ID using "P2P_panel_weights.dta",nogen




/*Differentiate 0 and missing for network measures*/


replace netsize=0 if missing(netsize) //true netsize==0
replace netsize=. if SU_ID==11133450 //one focal is missing in network interview
foreach z of varlist netsize-mhassles *density efctsize {
replace `z'=. if missing(netsize)
replace `z'=0 if netsize==0
}



/*Clean DEMOGRAPHICS*/


personage DOB_DATE DEMOGRAPHICS_FINISHTIME, gen(age) //install personage if not alreday 
lab var age "Age"

recode GENDER_ID (2=1)(1=0)(3/max=.),gen(women)
lab var women "Women"
lab de women 0 "Men" 1 "Women"
lab val women women

recode EDUCATION (3/4=3)(5=4)(92=.),gen(edu)
lab def edu 1 "Less than HS" 2 "HS or GED" 3 "Some college/technical" 4 "College"
lab val edu edu
lab var edu "Education"

recode edu (1/3=0) (4=1),gen(college)
lab var college "College"

recode MARITAL_STATUS (2/3=2)(4/6=3)(92=.),gen(marital)
lab def marital 1 "Never married" 2 "Married/cohabitating" 3 "Sep/Wid/Div"
lab val marital marital
lab var marital "Marital status"
recode marital (2=1) (1 3=0),gen(married)
lab define married 0 "No partner" 1 "Partnered"
lab values married married
lab var married "Partner status"

recode RACE_WHITE (92/98=.) ,gen(white)
lab var white "White"


/*Clean Cognitive function*/


recode CHECKERS_FREE-REDCROSS_FREE (2=0)(92/max=.)
egen cog=rowtotal(CHECKERS_FREE-REDCROSS_FREE),mi
lab var cog "Total number of words correct on free recall"

recode FUNC_* (0=0) (1/3=1) (8/max=.)
egen faq=rowtotal(FUNC_*),mi
recode faq (1/max=1)
lab var faq "Functional activities limitation"



/*Clean family*/


recode CHILDREN (2=0)(92/max=.),gen(kid)
lab var kid "Ever have any (step)child"


/*Clean employment status*/


recode EMP_STATUS (1 2=1) (3/10=0) (92/98=.), gen(work)
lab var work "Working"

save "P2P_clean_`i'.dta",replace
}