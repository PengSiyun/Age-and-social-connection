****Priject: Age and network
****Author:  Siyun Peng
****Date started: 2022/10/17
****Version: 18
****Purpose: data analysis



***************************************************************
**# 1 data clean
***************************************************************

  

use "C:\Users\peng_admin\Dropbox\peng\Academia\Work with Brea\P2P\Age and network\ATUS\ATUS_18_21.dta", clear
cd "C:\Users\peng_admin\Dropbox\peng\Academia\Work with Brea\P2P\Age and network\ATUS\Results"

drop if teage<18 //drop people<18 

recode tesex (1=0) (2=1),gen(women)
lab var women "Women"
lab de women 0 "Men" 1 "Women"
lab val women women

recode ptdtrace (4=3) (3 5/max=4),gen(race)
lab var race "Race"
lab de race 1 "White" 2 "Black" 3 "Asian" 4 "Other"
lab val race race

recode telfs (1 2=1) (3/5=0),gen(work)
lab var work "Working full/part time"
lab define work 0 "Not working" 1 "Currently working"
lab values work work

recode peeduca (31/38=1) (39=2) (40/42=3) (43/46=4),gen(edu)
lab def edu 1 "Less than HS" 2 "HS or GED" 3 "Some college/technical" 4 "College"
lab val edu edu
lab var edu "Education"

recode pemarit (1 2=1) (3/6=0),gen(partner)
replace partner=1 if cohabit==1
lab def partner 1 "Partnered" 0 "No partner" 
lab val partner partner
lab var partner "Partner status"

recode pedis* (1=1) (2=0)
egen faq=rowtotal(pedis*),mi
recode faq (1/max=1)
lab var faq "Functional activities limitation"

drop if teage<18 //drop people<18 to be consistent with P2P
gen dob_year=tuyear-teage
recode dob_year (1930/1939=1) (1940/1949=2) (1950/1959=3) (1960/1969=4) (1970/1979=5) (1980/1989=6) (1990/1999=7) (2000/2003=8),gen(cohort)
lab define cohort 1 "1930s" 2 "1940s" 3 "1950s" 4 "1960s" 5 "1970s" 6 "1980s" 7 "1990s" 8 "2000s"
lab values cohort cohort
lab var cohort "Cohort"

recode tudiarydate (0/20200312=0) (20200313/max=1) ,gen(covid)
lab define covid 0 "Before Covid" 1 "After Covid"
lab values covid covid
lab var covid "COVID-19"

lab var tphone_hrs "Virtual contact hours"

lab var tsocial_hrs "Hours with anyone"
lab var tpartner_hrs "Hours partner"
lab var tkid_hrs "Hours (grand)child"
lab var tofam_hrs "Hours other family"
lab var twork_hrs "Hours colleague"
lab var tfriend_hrs "Hours friend"
lab var tother_hrs "Hours other"

lab var tlsocial_hrs "Leisure hours with anyone"
lab var tlpartner_hrs "Leisure hours partner"
lab var tlkid_hrs "Leisure hours (grand)child"
lab var tlofam_hrs "Leisure hours other family"
lab var tlwork_hrs "Leisure hours colleague"
lab var tlfriend_hrs "Leisure hours friend"
lab var tlother_hrs "Leisure hours other"		

lab var teage "Age"
lab var tuyear "Year"
		
		


	
		
***************************************************************
**# 2 regression with weights
***************************************************************





*apply weights
replace tufnwgtp=tu20fwgt if tuyear==2020 //2020 weights are in different variable of tu20fwgt: 2020 weights is different to account for COVID 
forvalues i = 1/160 {
    local xvar = "tufnwgtp" + string(`i', "%03.0f")  // formats the number to 3 digits with leading zeros
    local yvar = "tu20fwgt" + string(`i', "%03.0f")  // formats the number to 3 digits with leading zeros
    replace `xvar' = `yvar' if tuyear==2020
}

svyset [pw=tufnwgtp], sdrweight(tufnwgtp???) vce(sdr) mse 

*descriptive table
desctable women teage i.race i.edu partner faq work tsocial_hrs tpartner_hrs tkid_hrs tofam_hrs twork_hrs tfriend_hrs tother_hrs tphone_hrs, filename("descriptives") stats(svymean svysemean min max) listwise 

/*percentage bar		
graph bar tpartner_mins tkid_mins toth_fam_mins twrkmate_mins tfrnd_mins tothr_mins [pw = tufinlwgt], over(age_grp) stack percent 
graph export "bar_composition.tif", replace

graph bar tpartner_mins tkid_mins toth_fam_mins twrkmate_mins tfrnd_mins tothr_mins [pw = tufinlwgt], over(age_grp) stack 
graph export "bar_composition_num.tif", replace
*/


/*no control for social roles (Classic APC by constranit cohort effect into 10-year interval)*/


estimates clear
foreach x of varlist tsocial_hrs tpartner_hrs tkid_hrs tofam_hrs twork_hrs tfriend_hrs tother_hrs {
    svy: reg `x' c.teage##c.teage##c.teage i.cohort i.tuyear i.race i.edu i.women i.faq i.tudiaryday i.trholiday  
	estimates store `x'
margins, at(teage=(20 (10) 70 75)) saving(`x'0,replace)
marginsplot, tit("") ytit("`: var label `x''",size(large)) xtit("") recastci(rarea) ciopt(color(%30)) plotopts(mlabel(_margin) mlabf(%12.1f) mlabp(12) mlabs(med)) legend(off) saving(`x',replace)
}
graph combine "tsocial_hrs" "tpartner_hrs" "tkid_hrs" "tofam_hrs" "twork_hrs" "tfriend_hrs" "tother_hrs" , ///
imargin(0 0 0 0) ycommon 
graph export "social_nocontrol.tif", replace
esttab * using "nocontrol.csv",label replace b(%5.2f) se(%5.2f) nogap r2 compress nonum noomitted noconstant





/*controls*/


estimates clear
foreach x of varlist tsocial_hrs tpartner_hrs tkid_hrs tofam_hrs twork_hrs tfriend_hrs tother_hrs {
    svy: reg `x' c.teage##c.teage##c.teage i.cohort i.tuyear i.race i.edu i.women i.faq i.tudiaryday i.trholiday i.partner i.work 
	estimates store `x'
margins, at(teage=(20 (10) 70 75)) saving(`x',replace)
marginsplot, tit("") ytit("`: var label `x''",size(large)) xtit("") recastci(rarea) ciopt(color(%30)) plotopts(mlabel(_margin) mlabf(%12.1f) mlabp(12) mlabs(medsmall)) legend(off) saving(`x',replace)
}
graph combine "tsocial_hrs" "tpartner_hrs" "tkid_hrs" "tofam_hrs" "twork_hrs" "tfriend_hrs" "tother_hrs" , ///
imargin(0 0 0 0) ycommon 
graph export "social_control.tif", replace
esttab * using "control.csv",label replace b(%5.2f) se(%5.2f) nogap r2 compress nonum noomitted noconstant


*overlay no control and with controls
foreach x in tsocial_hrs tpartner_hrs tkid_hrs tofam_hrs twork_hrs tfriend_hrs tother_hrs {
combomarginsplot "`x'" "`x'0", labels("Adjusted for social roles" "Baseline")  tit("") ytit("`: var label `x''",size(large)) xtit("") recastci(rarea) ciopt(color(%30)) plot1opts(mlabel(_margin) mlabf(%12.1f) mlabp(12) mlabs(med)) legend(off size(med)) saving(`x',replace)
}
grc1leg "tsocial_hrs" "tpartner_hrs" "tkid_hrs" "tofam_hrs" "twork_hrs" "tfriend_hrs" "tother_hrs" ,legendfrom("tsocial_hrs") position(4) ring(0) imargin(0 0 0 0) ycommon 
graph export "social_overlay.tif", replace


/*cohort and period effects*/


foreach x of varlist tsocial_hrs tpartner_hrs tkid_hrs tofam_hrs twork_hrs tfriend_hrs tother_hrs {
    svy: reg `x' i.tuyear c.teage##c.teage##c.teage i.cohort i.women i.race i.edu i.partner i.faq i.work i.tudiaryday i.trholiday
margins i.cohort, saving(`x',replace)
marginsplot, tit("") ytit("`: var label `x''",size(large)) xtit("") recastci(rarea) ciopt(color(%30)) plotopts(mlabel(_margin) mlabf(%12.1f) mlabp(12) mlabs(med)) legend(off size(med)) saving(`x',replace)
}
graph combine "tsocial_hrs" "tpartner_hrs" "tkid_hrs" "tofam_hrs" "twork_hrs" "tfriend_hrs" "tother_hrs" , ///
imargin(0 0 0 0) ycommon 
graph export "social_control_cohort.tif", replace
	
foreach x of varlist tsocial_hrs tpartner_hrs tkid_hrs tofam_hrs twork_hrs tfriend_hrs tother_hrs {
    svy: reg `x' i.tuyear c.teage##c.teage##c.teage i.cohort i.women i.race i.edu i.partner i.faq i.work i.tudiaryday i.trholiday 
margins i.tuyear, saving(`x',replace)
marginsplot, tit("") ytit("`: var label `x''",size(large)) xtit("") recastci(rarea) ciopt(color(%30)) plotopts(mlabel(_margin) mlabf(%12.1f) mlabp(12) mlabs(med)) legend(off size(med)) saving(`x',replace)
}
graph combine "tsocial_hrs" "tpartner_hrs" "tkid_hrs" "tofam_hrs" "twork_hrs" "tfriend_hrs" "tother_hrs" , ///
imargin(0 0 0 0) ycommon 
graph export "social_control_period.tif", replace


		
		
		
***************************************************************
**# 3 Interaction 
***************************************************************




*by partner status
estimates clear
foreach x of varlist tsocial_hrs tpartner_hrs tkid_hrs tofam_hrs twork_hrs tfriend_hrs tother_hrs {
    svy: reg `x' i.women c.teage##c.teage##c.teage c.teage##c.teage##i.partner i.tuyear i.cohort i.race i.edu i.faq i.work i.tudiaryday i.trholiday  
	estimates store `x'
margins, dydx(partner) at(teage=(20 (10) 70 75)) saving(`x',replace)
}
esttab * using "by partner.csv",label replace b(%5.2f) se(%5.2f) nogap r2 compress nonum noomitted noconstant

*network relations by work
estimates clear
foreach x of varlist tsocial_hrs tpartner_hrs tkid_hrs tofam_hrs twork_hrs tfriend_hrs tother_hrs {
    svy: reg `x' i.women c.teage##c.teage##c.teage c.teage##c.teage##i.work i.tuyear i.cohort i.race i.edu i.partner i.faq i.tudiaryday i.trholiday
	estimates store `x'
margins, dydx(work) at(teage=(20 (10) 70 75)) saving(`x'0,replace)
}
esttab * using "by work.csv",label replace b(%5.2f) se(%5.2f) nogap r2 compress nonum noomitted noconstant

*overlay interactions 
foreach x in tsocial_hrs tpartner_hrs tkid_hrs tofam_hrs twork_hrs tfriend_hrs tother_hrs {
combomarginsplot "`x'" "`x'0", labels("Partnership" "Employment")  tit("") ytit("`: var label `x''",size(large)) xtit("") recastci(rarea) ciopt(color(%20)) legend(off size(med)) yline(0) saving(`x',replace)
}
grc1leg "tsocial_hrs" "tpartner_hrs" "tkid_hrs" "tofam_hrs" "twork_hrs" "tfriend_hrs" "tother_hrs" ,legendfrom("tsocial_hrs") position(4) ring(0) imargin(0 0 0 0) ycommon 
graph export "interaction_overlay.tif", replace

/*network relations by college
foreach x of varlist social_mins tpartner_mins tkid_mins toth_fam_mins twrkmate_mins tfrnd_mins tothr_mins {
    svy: reg `x' i.women i.age_grp##i.college i.white i.married i.faq i.work i.tudiaryday i.trholiday i.year 
margins i.college, at(age_grp=(2 (1) 8))
marginsplot, tit("") ytit("`: var label `x''") xtit("") plot1opts(lp(dash)) plot2opts(lp(solid)) plotopt(msymbol(i)) recastci(rarea) ciopt(color(%30)) legend(off) saving(`x',replace)
}
grc1leg "social_mins" "tpartner_mins" "tkid_mins" "toth_fam_mins" "twrkmate_mins" "tfrnd_mins" "tothr_mins" , legendfrom("social_mins") position(4) ring(0) imargin(0 0 0 0) ycommon 
graph export "composition_college.tif", replace


*network relations by faq
foreach x of varlist social_mins tpartner_mins tkid_mins toth_fam_mins twrkmate_mins tfrnd_mins tothr_mins {
    svy: reg `x' i.women i.age_grp##i.faq i.white i.edu i.married i.work i.tudiaryday i.trholiday i.year 
margins i.faq, at(age_grp=(2 (1) 8))
marginsplot, tit("") ytit("`: var label `x''") xtit("") plot1opts(lp(dash)) plot2opts(lp(solid)) plotopt(msymbol(i)) recastci(rarea) ciopt(color(%30)) legend(off) saving(`x',replace)
}
grc1leg "social_mins" "tpartner_mins" "tkid_mins" "toth_fam_mins" "twrkmate_mins" "tfrnd_mins" "tothr_mins" , legendfrom("social_mins") position(4) ring(0) imargin(0 0 0 0) ycommon 
graph export "composition_faq.tif", replace
*/






***************************************************************
**# 4 Sensitivity analysis
***************************************************************



/*Virtual contact time 
svy: reg tphone_hrs i.women i.tuyear c.teage##c.teage##c.teage i.cohort i.race i.edu i.partner i.faq i.work i.tudiaryday i.trholiday 
margins, at(teage=(20 (10) 70 75)) 
marginsplot, tit("") ytit("`: var label tphone_hrs'") xtit("") recastci(rarea) ciopt(color(%30)) plotopts(mlabel(_margin) mlabf(%12.1f) mlabp(12) mlabs(medsmall)) legend(off) ylab(0 (2) 10) saving(tphone_hrs,replace)
graph export "Phone_control.tif", replace
*/

*preCOVID only (c.teage##c.teage##c.teage not used due to poor model fit, use c.teage##c.teage instead)
preserve
keep if covid==0 // could only do analysis before covid shutdown
foreach x of varlist tsocial_hrs tpartner_hrs tkid_hrs tofam_hrs twork_hrs tfriend_hrs tother_hrs {
    svy: reg `x' i.women i.tuyear c.teage##c.teage i.cohort i.race i.edu i.partner i.faq i.work i.tudiaryday i.trholiday
margins, at(teage=(20 (10) 70 75)) saving(`x',replace)
marginsplot, tit("") ytit("`: var label `x''",size(large)) xtit("") recastci(rarea) ciopt(color(%30)) plotopts(mlabel(_margin) mlabf(%12.1f) mlabp(12) mlabs(med)) legend(off size(med)) saving(`x',replace)
}
graph combine "tsocial_hrs" "tpartner_hrs" "tkid_hrs" "tofam_hrs" "twork_hrs" "tfriend_hrs" "tother_hrs" , ///
imargin(0 0 0 0) ycommon 
graph export "social_control_preCOVID.tif", replace
restore		

*recode period into COVID 
foreach x of varlist tsocial_hrs tpartner_hrs tkid_hrs tofam_hrs twork_hrs tfriend_hrs tother_hrs {
    svy: reg `x' i.women i.covid c.teage##c.teage i.cohort i.race i.edu i.partner i.faq i.work i.tudiaryday i.trholiday
margins, at(teage=(20 (10) 70 75)) saving(`x',replace)
marginsplot, tit("") ytit("`: var label `x''",size(large)) xtit("") recastci(rarea) ciopt(color(%30)) plotopts(mlabel(_margin) mlabf(%12.1f) mlabp(12) mlabs(med)) legend(off size(med)) saving(`x',replace)
}
graph combine "tsocial_hrs" "tpartner_hrs" "tkid_hrs" "tofam_hrs" "twork_hrs" "tfriend_hrs" "tother_hrs" , ///
imargin(0 0 0 0) ycommon 
graph export "social_control_COVID.tif", replace

/*Leisure time (Figure A1) //narrow defination of social time
foreach x of varlist tlsocial_hrs tlpartner_hrs tlkid_hrs tlofam_hrs tlwork_hrs tlfriend_hrs tlother_hrs {
    svy: reg `x' i.women i.tuyear c.teage##c.teage##c.teage i.cohort i.race i.edu i.partner i.faq i.work i.tudiaryday i.trholiday
margins, at(teage=(20 (10) 70 75)) saving(`x',replace)
marginsplot, tit("") ytit("`: var label `x''") xtit("") recastci(rarea) ciopt(color(%30)) plotopts(mlabel(_margin) mlabf(%12.1f) mlabp(12) mlabs(medsmall)) legend(off) saving(`x',replace)
}
graph combine "tlsocial_hrs" "tlpartner_hrs" "tlkid_hrs" "tlofam_hrs" "tlwork_hrs" "tlfriend_hrs" "tlother_hrs" , ///
imargin(0 0 0 0) ycommon 
graph export "Leisure_control.tif", replace
*/

*Negative binomial regression //not converge indicating poor model fit

foreach x of varlist tsocial_hrs tpartner_hrs tkid_hrs tofam_hrs twork_hrs tfriend_hrs tother_hrs {
    svy: nbreg `x' i.women i.tuyear c.teage##c.teage##c.teage i.cohort i.race i.edu i.partner i.faq i.work i.tudiaryday i.trholiday 
margins, at(teage=(20 (10) 70 75)) saving(`x',replace)
marginsplot, tit("") ytit("`: var label `x''",size(large)) xtit("") recastci(rarea) ciopt(color(%30)) plotopts(mlabel(_margin) mlabf(%12.1f) mlabp(12) mlabs(medsmall)) legend(off) saving(`x',replace)
}
graph combine "tsocial_hrs" "tpartner_hrs" "tkid_hrs" "tofam_hrs" "twork_hrs" "tfriend_hrs" "tother_hrs" , ///
imargin(0 0 0 0) ycommon 
graph export "nbreg_social_control.tif", replace


	
		
	