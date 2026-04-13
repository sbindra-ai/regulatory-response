/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_2_3_3_adqs_isi_sev );
/*
 * Purpose          :  Severity ISI categories: number of subjects by treatment group (full analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 27JUL2023
 * Reference prog   :
 ******************************************************************************/;

%load_ads_dat(adqs_view  , adsDomain = adqs , adslWhere =  &fas_cond. );
%load_ads_dat(adsl_view   , adsDomain = adsl  , where     = &fas_cond. );

%extend_data(indat = adqs_view , outdat = adqs );
%extend_data(indat = adsl_view  , outdat = adsl) ;

data adqs ;
   set adqs  ;

where paramcd = "ISIB0999" and parcat1 = "ISI"
      and not missing(avisitn)
      and avisitn in (5, 40 ,80,120,160,260 , 700000 )
      and ANL04FL="Y"  ;

attrib  TRT01PN  label = "Treatment"
       AVALCA1N   label = "ISI category" ;

keep PARAMCD   TRT01PN   aval  SUBJID avisitn
     parcat1 avisitn   AVALCA1N avalc USUBJID  ;

run;

proc sort data =adqs    ;
        by PARAMCD AVALCA1N  TRT01PN     SUBJID avisitn  ;
run;

%MTITLE;

%freq_tab(
    data     = adqs
  , data_n   = adsl
  , var      = AVALCA1N
  , subject  = &subj_var.
  , page     = paramcd
  , by       = avisitn
  , order    = paramcd
  , class    = &treat_arm_p
  , hlabel   = Yes
  , missing  = NO
  , total    = NO
  , data_n_ignore       =  paramcd

);

%endprog;
