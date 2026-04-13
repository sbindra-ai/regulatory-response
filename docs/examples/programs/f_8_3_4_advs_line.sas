/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = f_8_3_4_advs_line );
/*
 * Purpose          : Line plot  Parameter , name unit by treatment Group
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 27FEB2024
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/f_8_3_4_advs_line.sas (emvsx (Phani Tata) / date: 05OCT2023)
 ******************************************************************************/

%load_ads_dat(adsl_view, adsDomain = adsl, where = &saf_cond)
%load_ads_dat(advs_view, adsDomain = advs , adslWhere =  &saf_cond )
%extend_data(indat = adsl_view, outdat = adsl)
%extend_data(indat = advs_view, outdat = advs)

data advs_ph ;
   set advs ;
   where anl01fl = "Y"
        and   paramcd in (  "SYSBP" , "DIABP" )
        and   0 < avisitn < 900000 ;
* round AVAL BASE and CHG **;
  aval2= chg ;
  if paramcd = "SYSBP" then paramcdn = 1 ;
  if paramcd = "DIABP" then paramcdn = 2 ;
run;

*As per Clinical team (Taru,Christian ) request 02/24/2024 to spread visits *;
data advs_ph ;
  set  advs_ph ;
     if avisitn = 5 then n_avsitn = 0 ;
     else if avisitn = 600010 then n_avsitn = 261 ;
     else if avisitn = 700000 then n_avsitn = 300 ;
     else if avisitn = 700010 then n_avsitn = 310 ;
     else if avisitn = 700020 then n_avsitn = 320 ;
     else if avisitn = 700030 then n_avsitn = 330 ;
     else if avisitn = 700040 then n_avsitn = 340 ;

     else n_avsitn = avisitn  ;
 format n_avsitn _plotvis. ;
run;

%MTITLE;

%gral_style(
   markers         = CircleFilled
  , graphdatadefault = linethickness=2px )

%MeanDeviationPlot(
   data     = advs_ph
 , xvar     = n_avsitn
 , yvar     = aval2
 , class    =  &treat_arm_a.
 , xtype    = data
 , filename = &prog.
 , ylabel   = Change in $paramcd$ (mean +/- 95% CI)
 , by       = paramcdn paramcd
 , title_ny    = No
 , legendtitle = Treatment Group
 , style    = report2
 , xlabel   = Time (weeks)
 , stat          = ARITH_CL95          /* Figure describes the time course of mean and 95% confidence interval */
);



%endprog(
    cleanWork       = y
  , cleanTitlesFoot = y
  , verbose         = Y
)