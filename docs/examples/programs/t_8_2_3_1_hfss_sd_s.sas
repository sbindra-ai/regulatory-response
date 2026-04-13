/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_2_3_1_hfss_sd_s );
/*
 * Purpose          :  Proportion of days with participants having reported "quite a bit" or "very much"
 *                     sleep disturbance due to HF:
 *                     summary statistics and change from baseline by treatment group (FAS)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 29NOV2023
 * Reference prog   :
 ******************************************************************************/
*;

%MACRO m_mean_base_chg(param1 =,
                     param2= ,
                     ads   =    ,
                     param = ,
                     pop =   ,
                     round = )
/ DES = 'Summary statistics and change from baseline by treatment group';

%put >>>>>>>>>&pop.<<<<<<<<<<<<<<<<<<<<;


%load_ads_dat(&ads._view  , adsDomain = &ads. , adslWhere =  &pop. );
%load_ads_dat(adsl_view   , adsDomain = adsl  , where     =  &pop. );

%extend_data(indat = &ads._view , outdat =  &ads. );
%extend_data(indat = adsl_view  , outdat = adsl) ;


data &ads. ;
   set &ads.  ;

where paramcd = "&param1." and parcat1 = "&param2."
      and not missing(avisitn)
      and not missing(aval)
      and ANL04FL="Y"  ;

*Multiply proportion by 100 to get %  as per stats;
aval = aval * 100 ;
chg  = chg *100 ;


if ( 5 <= avisitn <= 260 ) or ( 700000 <= avisitn <= 700040 ) ;

attrib  TRT01PN  label = "Treatment" ;

run;


proc sort data=&ads.  out=tby (keep = &param. ) nodupkey;
    by &param.  ;
run;

%MTITLE;

%desc_tab(
    data           = &ads.
  , data_n       =  adsl
  , var          =  aval
  , stat         =  n mean std min median max
  , page         =  &param.
  , order        =  &param.
  , vlabel       = no
  , baseline     = ablfl = "Y"
  , compare_var    = chg
  , time         =   Avisitn
  , visittext    = Visit
  , baselinetext = baseline at visit
  , subject      = subjid
  , tablesby     = Tby
  , optimal      = yes
  , total        = NO
  , round_factor = &round.
  , class =   &treat_arm_p.
 , class_order  = &treat_arm_p. = &MOSTO_PARAM_CLASS_ORDER.
 , data_n_ignore = &param.
);


%MEND m_mean_base_chg;



%m_mean_base_chg(param1 =      %str(HFDB996),
               param2 =      %str(TWICE DAILY HOT FLASH DIARY V2.0),
               ads    =      %str(adqshfss),
               param =       %str(paramcd),
               pop   =        %str(&fas_cond.),
               round    =   0.1
                     ) ;

*----------------------------------*;
%endprog;