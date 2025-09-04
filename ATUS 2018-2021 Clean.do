*Project: age and social connectedness
*Author: Siyun Peng
*Date: 2024/1/13


cd "C:\Users\siypeng\OneDrive - Indiana University\ATUS"

********************************************************************************

**# 1 LOADING ACTIVITY DATA AND MERGING WHO DATA

********************************************************************************

use "atusact_0322.dta", clear

*Home 
recode tewhere (1=1) (2/99=0) (else=.),gen(home)

*Merging with WHO file
merge 1:m tucaseid tuactivity_n using "atuswho_0322.dta"
*100 percent of cases merged so I can safely drop the _merge variable
drop _merge

*drop activites missing on WHERE and WHO (i.e., refused or don't know)
recode tewhere (-3 -2 = 1) (else=0),gen(miss_where)
recode tuwho_code (-3 -2 =1 ) (else=0),gen(miss_who)
drop if miss_where==1 | miss_who==1

*Consolidating 'who' variable into categories
recode tuwho_code (-3 -2 -1=.) (18 19=.) (20 21=1) (22 23 27=2) (40 52 57=3) (else=4),gen(child)
label define child 1 "Partner" 2 "(Grand)child" 3 "child<18" 4 "Other"
lab values child child

recode tuwho_code (-3 -2 -1=.) (18 19=.) (20 21=1) (22 23 27 40=2) (24 25 26 30 51 52 53=3) (55 59 60 61 62=4) (54=5) (28 29 56 57 58=6),gen(who)
label define who 1 "Partner" 2 "(Grand)child" 3 "Other family" 4 "Collegues" 5 "Friend" 6 "Other"
lab values who who




********************************************************************************

**# 2 Identify time with child<18

********************************************************************************


/*create living arrangement variable using roster file (run this code once to replace the original roster file)
use "atusrost_0322.dta",clear
drop if terrp==40 //drop children not in the household
bysort tucaseid: egen hou_num=count(tulineno)
lab var hou_num "# people in the household"
recode terrp (-2 -3 18 19=.) (20 21=1) (22/27=2) (28/30=3),gen(living)
lab define living 0 "Alone" 1 "Living with partner" 2 "Living with family" 3 "Living with non-kin",replace
lab values living living
bysort tucaseid: egen living_min=min(living)
bysort tucaseid: replace living=0 if hou_num==1 //=alone if only self in the household
bysort tucaseid: replace living=1 if living_min==1 //=partner if a partner is in the household
bysort tucaseid: replace living=2 if living_min==2 //=family if family in the household and no partner
bysort tucaseid: replace living=3 if living_min==3 //=non-kin if only non-kin in the household
drop living_min
save "atusrost_0322.dta",replace
*/

*Merging with Roster file (this can provide info on who and age of household members)
merge m:1 tulineno tucaseid using "atusrost_0322.dta"
drop _merge
replace child=3 if teage<18 & child==2
label define child 1 "Partner" 2 "Adult child" 3 "Child<18" 4 "Other",replace
lab values child child

recode child (1 2 4=0) (3=1)
label define child 0 "Adult" 1 "Child<18",replace
lab values child child


/*Creating a single var for each category that shows the total number of minutes R spends with each type of person*/


*only keep one friend if multiple friends in the same activity
duplicates drop tucaseid tuactivity_n who,force 

*social time with partner
gen partner_hrs = tuactdur24/60 if who==1
egen tpartner_hrs = total(partner_hrs), by(tucaseid) 

*social time with (Grand)child
gen kid_hrs = tuactdur24/60 if who==2
egen tkid_hrs = total(kid_hrs), by(tucaseid) 

*social time with other family
gen ofam_hrs = tuactdur24/60 if who==3
egen tofam_hrs = total(ofam_hrs), by(tucaseid) 

*social time with Collegues
gen work_hrs = tuactdur24/60 if who==4
egen twork_hrs = total(work_hrs), by(tucaseid) 

*social time with Friend
gen friend_hrs = tuactdur24/60 if who==5
egen tfriend_hrs = total(friend_hrs), by(tucaseid) 

*social time with Other
gen other_hrs = tuactdur24/60 if who==6
egen tother_hrs = total(other_hrs), by(tucaseid) 

/*Create total leisure social hours:
12 Socializing, Relaxing, and Leisure
*/

*leisure social time with adults
recode trcodep (120101/129999=1) (else=0),gen(leisure) 

*leisure social time with partner
gen lpartner_hrs = partner_hrs if leisure==1 
egen tlpartner_hrs = total(lpartner_hrs), by(tucaseid) 

*leisure social time with (Grand)child
gen lkid_hrs = kid_hrs if leisure==1 
egen tlkid_hrs = total(lkid_hrs), by(tucaseid) 

*leisure social time with other family
gen lofam_hrs = ofam_hrs if leisure==1 
egen tlofam_hrs = total(lofam_hrs), by(tucaseid) 

*leisure social time with Collegues
gen lwork_hrs = work_hrs if leisure==1 
egen tlwork_hrs = total(lwork_hrs), by(tucaseid) 

*leisure social time with Friend
gen lfriend_hrs = friend_hrs if leisure==1
egen tlfriend_hrs = total(lfriend_hrs), by(tucaseid) 

*leisure social time with Other
gen lother_hrs = other_hrs if leisure==1 
egen tlother_hrs = total(lother_hrs), by(tucaseid) 


*total social time 
duplicates drop tucaseid tuactivity_n,force //only count one activity regardless of multiple people
gen social_hrs = tuactdur24/60 if !missing(who)
egen tsocial_hrs = total(social_hrs), by(tucaseid) //total time for all activites with anyone

*Total leisure social time with adutls
gen lsocial_hrs = social_hrs if leisure==1 
egen tlsocial_hrs = total(lsocial_hrs), by(tucaseid)



*Create total phone hours:
recode trcodep (160101/169999=1),gen(phone) 
gen phone_hrs = tuactdur24/60 if phone==1 
egen tphone_hrs = total(phone_hrs), by(tucaseid) 



********************************************************************************

**# 3 MERGING DATA (LONG FORMAT) WITH RESPODENT SUMMARY FILE

********************************************************************************





*Dropping all duplicate cases leaves us with a single line for each R
duplicates drop tucaseid, force
keep tucaseid t*_hrs 

merge 1:1 tucaseid using "atussum_0322.dta"
drop _merge

*Merging with replicating weights file
merge 1:1 tucaseid using "atusrepwgt_0322.dta"
drop _merge

*Merging with 2020 replicating weights file 
merge 1:1 tucaseid using "atusrepwgt_20.dta"
drop _merge

*Merging with Respondent file
merge 1:1 tucaseid  using "atusresp_0322.dta"
drop _merge

*Merging with Roster file again to get living measure
merge 1:m tucaseid using "atusrost_0322.dta"
drop _merge
recode terrp (20 21=1) (-3 -2=.) (else=0),gen(cohabit)
gsort tucaseid -cohabit //order cohabit=1 first
duplicates drop tucaseid,force //keep first occurence

*merge with current population surveys
merge 1:1 tucaseid tulineno using  "atuscps_0322.dta" //tulineno indentify members of househouse
*Not all cases match because only a subset of CPS completed the ATUS. Since this is a study of the ATUS, we can safely drop all non-ATUS CPS respondents (_merge==2)
drop if _merge==2
drop _merge

********************************************************************************

**# 4 SAVING DATA (LONG FORMAT)

********************************************************************************

keep if inrange(tuyear,2018,2021) //keep 2018-2021 data
save "C:\Users\siypeng\Dropbox\peng\Academia\Work with Brea\P2P\Age and network\ATUS\ATUS_18_21.dta", replace




