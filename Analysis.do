****Priject: Gender and network
****Author:  Siyun Peng
****Date started: 2022/07/29
****Version: 18
****Purpose: data analysis




***************************************************************
**# 1 Descriptives
***************************************************************

use "C:\Users\peng_admin\Dropbox\peng\Academia\Work with Brea\P2P\Age and network\data\P2P_clean_PROB",clear 
cd "C:\Users\peng_admin\Dropbox\peng\Academia\Work with Brea\P2P\Age and network\results"

lab var npartner "# partner"

lab var b1density "Density"
replace mstrength=mstrength/2

lab var netsize "Total network size"

gen race=1 if RACE_WHITE==1 
replace race=4 if RACE_AMIND==1 | RACE_NATHAW_PACIS==1 | RACE_OTHER==1 //other trump white
replace race=3 if RACE_ASIAN==1 //Asian trump other
replace race=2 if RACE_BLACK_AFAM==1 //Black trump all
lab var race "Race"
lab de race 1 "White" 2 "Black" 3 "Asian" 4 "Other"
lab val race race

lab define work 0 "Not working" 1 "Currently working"
lab values work work
lab define kid 0 "No child" 1 "Having any child"
lab values kid kid

gen year=year(DEMOGRAPHICS_FINISHTIME)
lab var year "year"

gen covid=0 
replace covid=1 if DEMOGRAPHICS_FINISHTIME>mdy(3, 12, 2020)

gen dob_year=year-age
recode dob_year (1910/1919=2) (1920/1929=2) (1930/1939=3) (1940/1949=4) (1950/1959=5) (1960/1969=6) (1970/1979=7) (1980/1989=8) (1990/1999=9) (2000/2003=10),gen(cohort)
lab define cohort 2 "10/20s" 3 "30s" 4 "40s" 5 "50s" 6 "60s" 7 "70s" 8 "80s" 9 "90s" 10 "2000s"
lab values cohort cohort
lab var cohort "Cohort"

drop if missing(women, age, race, edu, married, faq, work, kid, npartner)

*apply weights
svyset psu [pw=wt_comb], strata(strata) //psu and strata fix variance
desctable i.women age i.race i.edu i.married i.faq i.work kid netsize npartner nkid notherfam nworkmate nfri nother  ///
		,filename("descriptives_PROB") stats(svymean svysemean min max) listwise

/*percentage bar		
graph bar npartner nkid notherfam nworkmate nfri nother [pw = wt_comb], over(age_grp) stack percent 
graph export "bar_composition_PROB.tif", replace

graph bar npartner nkid notherfam nworkmate nfri nother [pw = wt_comb], over(age_grp) stack 
graph export "bar_composition_PROB_num.tif", replace
*/

/*Figures
foreach x of varlist netsize pkin diverse msup msup3 plisten  minstrength psamerace mhassles b1density density {
	eststo `x': reg `x' women c.age##c.age race i.edu work married faq
}
coefplot (netsize, aseq(Network size)) (diverse, aseq(Diversity)) (b1density, aseq(Density)) (mhassles, aseq(Mean hassle)) (, aseq(Mean strength)) (plisten, aseq(Prop. listen)), xline(0) keep(women) legend(off) ciop(col(black)) swapnames
graph export "coef.tif", replace
*/
		
		
		


	
		
***************************************************************
**# 2 regression with weights
***************************************************************






*no control for social roles
estimates clear
foreach x of varlist netsize npartner nkid notherfam nworkmate nfri nother {
    svy: reg `x' c.age##c.age i.cohort i.year i.race i.edu i.women i.faq 
	estimates store `x'
margins, at(age=(20 (10) 70 75)) saving(`x'0, replace)
marginsplot, ylab(0 (2) 8) tit("") ytit("`: var label `x''",size(large)) xtit("") recastci(rarea) ciopt(color(%30)) plotopts(mlabel(_margin) mlabf(%12.1f) mlabp(12) mlabs(med)) legend(off) saving(`x'0, replace) 
sleep 500 //quit dropbox will fix the issue
}
graph combine "netsize0" "npartner0" "nkid0" "notherfam0" "nworkmate0" "nfri0" "nother0" , ///
imargin(0 0 0 0) ycommon 
graph export "composition_nocontrol_PROB.tif", replace
esttab * using "nocontrol.csv",label replace b(%5.2f) se(%5.2f) nogap r2 compress nonum noomitted noconstant



*controls

estimates clear
foreach x of varlist netsize npartner nkid notherfam nworkmate nfri nother {
    svy: reg `x' c.age##c.age i.cohort i.year i.race i.edu i.women i.faq i.married i.kid i.work  
	estimates store `x'
	margins, at(age=(20 (10) 70 75)) saving(`x', replace)
sleep 500
marginsplot,ylab(0 (2) 8) tit("") ytit("`: var label `x''",size(large)) xtit("") recastci(rarea) ciopt(color(%30)) plotopts(mlabel(_margin) mlabf(%12.1f) mlabp(12) mlabs(med)) legend(off) saving(`x',replace)
}
graph combine "netsize" "npartner" "nkid" "notherfam" "nworkmate" "nfri" "nother" , ///
imargin(0 0 0 0) ycommon 
graph export "composition_control_PROB.tif", replace
esttab * using "control.csv",label replace b(%5.2f) se(%5.2f) nogap r2 compress nonum noomitted noconstant

*overlay no control and with controls
foreach x in netsize npartner nkid notherfam nworkmate nfri nother  {
combomarginsplot "`x'" "`x'0", labels("Adjusted for social roles" "Baseline") tit("") ytit("`: var label `x''",size(large)) xtit("") recastci(rarea) ciopt(color(%30)) plot1opts(mlabel(_margin) mlabf(%12.1f) mlabp(12) mlabs(med)) legend(off size(med)) ylab(0 (2) 8) saving(`x',replace)
}
grc1leg "netsize" "npartner" "nkid" "notherfam" "nworkmate" "nfri" "nother" ,legendfrom("netsize") position(4) ring(0) imargin(0 0 0 0) ycommon 
graph export "composition_overlay_PROB.tif", replace


/*cohort and period effects*/


foreach x of varlist netsize npartner nkid notherfam nworkmate nfri nother  {
    svy: reg `x' i.women c.age##c.age i.cohort i.year i.race i.edu i.married i.kid i.faq i.work  
	margins i.cohort, saving(`x', replace)
sleep 500
marginsplot,ylab(0 (2) 8) tit("") ytit("`: var label `x''",size(large)) xtit("") recastci(rarea) ciopt(color(%30)) plotopts(mlabel(_margin) mlabf(%12.1f) mlabp(12) mlabs(med)) legend(off size(med)) saving(`x',replace)
}
graph combine "netsize" "npartner" "nkid" "notherfam" "nworkmate" "nfri" "nother" , ///
imargin(0 0 0 0) ycommon 
graph export "composition_control_PROB_cohort.tif", replace

foreach x of varlist netsize npartner nkid notherfam nworkmate nfri nother  {
    svy: reg `x' i.women c.age##c.age i.cohort i.year i.race i.edu i.married i.kid i.faq i.work  
	margins i.year, saving(`x', replace)
sleep 500
marginsplot,ylab(0 (2) 8) tit("") ytit("`: var label `x''",size(large)) xtit("") recastci(rarea) ciopt(color(%30)) plotopts(mlabel(_margin) mlabf(%12.1f) mlabp(12) mlabs(med)) legend(off size(med)) saving(`x',replace)
}
graph combine "netsize" "npartner" "nkid" "notherfam" "nworkmate" "nfri" "nother" , ///
imargin(0 0 0 0) ycommon 
graph export "composition_control_PROB_period.tif", replace


		
		
***************************************************************
**# 3 Interaction
***************************************************************




*network relations by marital status
estimates clear
foreach x of varlist netsize npartner nkid notherfam nworkmate nfri nother {
    svy: reg `x' i.women c.age##c.age##i.married i.cohort i.year i.race i.edu i.kid i.faq i.work 
	estimates store `x'
margins, dydx(married) at(age=(20 (10) 70 75)) saving(`x',replace)
}
esttab * using "by married.csv",label replace b(%5.2f) se(%5.2f) nogap r2 compress nonum noomitted noconstant

*network relations by no kid
estimates clear
foreach x of varlist netsize npartner nkid notherfam nworkmate nfri nother {
    svy: reg `x' i.women c.age##c.age##i.kid i.cohort i.year i.race i.edu i.faq i.work i.married 
	estimates store `x'
margins, dydx(kid) at(age=(20 (10) 70 75)) saving(`x'1,replace)
}
esttab * using "by kid.csv",label replace b(%5.2f) se(%5.2f) nogap r2 compress nonum noomitted noconstant

*network relations by work
estimates clear
foreach x of varlist netsize npartner nkid notherfam nworkmate nfri nother {
    svy: reg `x' i.women c.age##c.age##i.work i.cohort i.year i.race i.edu i.faq i.married i.kid i.year 
	estimates store `x'
margins, dydx(work) at(age=(20 (10) 70 75)) saving(`x'0,replace)
}
esttab * using "by work.csv",label replace b(%5.2f) se(%5.2f) nogap r2 compress nonum noomitted noconstant

*overlay social roles interactions
foreach x in netsize npartner nkid notherfam nworkmate nfri nother  {
combomarginsplot "`x'" "`x'0" "`x'1", labels("Partnership" "Employment" "Parenthood") tit("") ytit("`: var label `x''",size(large)) xtit("") recastci(rarea) ciopt(color(%20)) legend(off size(med)) yline(0) saving(`x',replace)
}
grc1leg "netsize" "npartner" "nkid" "notherfam" "nworkmate" "nfri" "nother" ,legendfrom("netsize") position(4) ring(0) imargin(0 0 0 0) ycommon 
graph export "interaction_overlay_PROB.tif", replace

/*
foreach x of varlist pkin mstrength b1density {
    svy: reg `x' i.women i.age_grp7##i.work i.race i.edu i.faq i.married i.kid i.year
margins i.kid, at(age_grp7=(2 (1) 7))
marginsplot, tit("") ytit("`: var label `x''",size(large)) xtit("") plot1opts(lp(dash)) plot2opts(lp(solid)) plotopt(msymbol(i)) recastci(rarea) ciopt(color(%30)) legend(off) saving(`x',replace)
}
grc1leg "pkin" "mstrength" "b1density", legendfrom("pkin") position(4) ring(0) imargin(0 0 0 0)  
graph export "structure_work_`i'.tif", replace


*network relations by college
foreach x of varlist netsize npartner nkid notherfam nworkmate nfri nother {
    svy: reg `x' i.women i.age_grp##i.college i.race i.work i.faq i.married i.kid i.year 
margins i.college, at(age_grp=(2 (1) 8))
marginsplot, tit("") ytit("`: var label `x''",size(large)) xtit("") plot1opts(lp(dash)) plot2opts(lp(solid)) plotopt(msymbol(i)) recastci(rarea) ciopt(color(%30)) legend(off) saving(`x',replace)
}
grc1leg "netsize" "npartner" "nkid" "notherfam" "nworkmate" "nfri" "nother" ,legendfrom("netsize") position(4) ring(0) imargin(0 0 0 0) ycommon 
graph export "composition_college_`i'.tif", replace


*network relations by faq
foreach x of varlist netsize npartner nkid notherfam nworkmate nfri nother {
    svy: reg `x' i.women i.age_grp##i.faq i.race i.work i.edu i.married i.kid i.year 
margins i.faq, at(age_grp=(2 (1) 8))
marginsplot, tit("") ytit("`: var label `x''",size(large)) xtit("") plot1opts(lp(dash)) plot2opts(lp(solid)) plotopt(msymbol(i)) recastci(rarea) ciopt(color(%30)) legend(off) saving(`x',replace)
}
grc1leg "netsize" "npartner" "nkid" "notherfam" "nworkmate" "nfri" "nother" ,legendfrom("netsize") position(4) ring(0) imargin(0 0 0 0) ycommon 
graph export "composition_faq_`i'.tif", replace
*/




***************************************************************
**# 4 Sensitivity analysis
***************************************************************


*pre-COVID only
foreach x of varlist netsize npartner nkid notherfam nworkmate nfri nother {
    svy: reg `x' c.age##c.age i.cohort i.year i.race i.edu i.women i.faq i.married i.kid i.work if covid==0 
	estimates store `x'
	margins, at(age=(20 (10) 70 75)) saving(`x', replace)
sleep 500
marginsplot,ylab(0 (2) 8) tit("") ytit("`: var label `x''",size(large)) xtit("") recastci(rarea) ciopt(color(%30)) plotopts(mlabel(_margin) mlabf(%12.1f) mlabp(12) mlabs(med)) legend(off size(med)) saving(`x',replace)
}
graph combine "netsize" "npartner" "nkid" "notherfam" "nworkmate" "nfri" "nother" , ///
imargin(0 0 0 0) ycommon 
graph export "composition_control_PROB_precovid.tif", replace

*recode period as covid
foreach x of varlist netsize npartner nkid notherfam nworkmate nfri nother {
    svy: reg `x' c.age##c.age i.cohort i.covid i.race i.edu i.women i.faq i.married i.kid i.work 
	estimates store `x'
	margins, at(age=(20 (10) 70 75)) saving(`x', replace)
sleep 500
marginsplot,ylab(0 (2) 8) tit("") ytit("`: var label `x''",size(large)) xtit("") recastci(rarea) ciopt(color(%30)) plotopts(mlabel(_margin) mlabf(%12.1f) mlabp(12) mlabs(med)) legend(off size(med)) saving(`x',replace)
}
graph combine "netsize" "npartner" "nkid" "notherfam" "nworkmate" "nfri" "nother" , ///
imargin(0 0 0 0) ycommon 
graph export "composition_control_PROB_covid.tif", replace

*Negative binomial regression //not converge indicating poor model fit

foreach x of varlist netsize npartner nkid notherfam nworkmate nfri nother {
    svy: nbreg `x' i.women c.age##c.age i.cohort i.year i.race i.edu i.married i.kid i.faq i.work 
margins, at(age=(20 (10) 70 75))
marginsplot,ylab(0 (2) 8) tit("") ytit("`: var label `x''",size(large)) xtit("") recastci(rarea) ciopt(color(%30)) plotopts(mlabel(_margin) mlabf(%12.1f) mlabp(12) mlabs(medsmall)) legend(off) saving(`x',replace)
}
graph combine "netsize" "npartner" "nkid" "notherfam" "nworkmate" "nfri" "nother" , ///
imargin(0 0 0 0) ycommon 
graph export "composition_control_PROB_count.tif", replace

