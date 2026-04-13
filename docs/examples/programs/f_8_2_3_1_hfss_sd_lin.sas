/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = f_8_2_3_1_hfss_sd_lin );
/*
 * Purpose          : Line Plot for  HFDB996 - change from baseline in proportion of days with
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 06MAR2024
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/f_8_2_3_1_hfss_sd_lin.sas (emvsx (Phani Tata) / date: 13OCT2023)
 ******************************************************************************/

*HFDB996 - change from baseline in proportion of days with
participants having reported "quite a bit" or "very much" sleep disturbance due to HF *;

%MACRO  m_f_line_plot(   param1 = paramcd ,
                      param2= parcat1,
                      ads = ,
                      pop =  ,
                      label_x = ,
                      label_y = ,
                      lgtitle =  ,
                      cond = )

/ DES = '###Line plot of change from baseline###';

*----------------------------------*;
%* Put your macro code here!;
*----------------------------------*;
%load_ads_dat(&ads._view  , adsDomain = &ads. , adslWhere =  &pop. )
%load_ads_dat(adsl_view   , adsDomain = adsl  , where     =  &pop. )

%extend_data(indat = &ads._view , outdat =  &ads. );
%extend_data(indat = adsl_view  , outdat = adsl) ;

data &ads. ;
set &ads. ;
where paramcd = "&param1." and parcat1 = "&param2." and not missing(chg) and ANL04FL="Y"  ;

aval = aval *100 ;
chg = chg *100 ;
if ( 5 <= avisitn <= 260 ) or ( 700000 <= avisitn <= 700040 ) ;

attrib  TRT01PN  label = "Treatment" ;
run;
*As per Clinical team (Taru,Christian ) request 02/24/2024 to spread visits *;
data &ads. ;
  set  &ads. ;
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

PROC DATASETS LIBRARY=WORK NOLIST;
MODIFY  &ads.  ;
FORMAT chg  9.2;
QUIT;

%MTITLE;

%gral_style(
markers         = CircleFilled
, graphdatadefault = linethickness=2px )

%MeanDeviationPlot(
    data          =  &ads.
  , data_n        = adsl
  , xvar          = avisitn
  , yvar          = chg
  , class         = &treat_arm_p.
  , class_order   = &mosto_param_class_order.
  , xtype         = discrete
  , xstart        = min
  , xend          = max
  , xlabel        = &label_x
  , ylabel        = &label_y
  , subject       = usubjid
  , title_ny      = No
  , legendtitle   = &lgtitle
  , style         = report2
  , stat          = ARITH_CL95          /* Figure describes the time course of mean and 95% confidence interval */
);

%MEND m_f_line_plot;

%m_f_line_plot( param1 = %str(HFDB996) ,
              param2=  %str(TWICE DAILY HOT FLASH DIARY V2.0),
             ads    = %str(adqshfss) ,
             pop    = %str(&fas_cond.) ,
             label_x  = %str(Time (weeks)) ,
             label_y  = %nrbquote(Change in proportion of days (%) (mean +/- 95% CI)) ,
             lgtitle = %str(Treatment Group)
             ) ;

%endprog;

