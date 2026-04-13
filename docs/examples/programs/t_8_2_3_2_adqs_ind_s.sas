/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_2_3_2_adqs_ind_s  );
/*
 * Purpose          :  MENQOL score for each of the 29 items separately:
 *                     summary statistics and change from baseline by treatment group (FAS):
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
 ******************************************************************************/;


%load_ads_dat(adqs_view  , adsDomain = adqs , adslWhere =  &fas_cond.);
%load_ads_dat(adsl_view   , adsDomain = adsl  , where     = &fas_cond.);

%extend_data(indat = adqs_view , outdat =  adqs );
%extend_data(indat = adsl_view  , outdat = adsl) ;


data adqs ;
   set adqs  ;
 where  parcat1 = "MENOPAUSE-SPECIFIC QUALITY-OF-LIFE QUESTIONNAIRE (MENQOL)"
          and not missing(avisitn)
          and not missing(aval)
          and ANL04FL = "Y"
          and  paramtyp = "DERIVED";

    if ( 5 <= avisitn <= 260 ) or ( 700000 <= avisitn <= 700040 ) ;
    if 800 <Input(compress(paramcd ,  , 'kd' ), best.)  < 830   ;

    paramcd1 = strip(substr(put(paramcd ,Z_QSTST. ),19 ))  ;

    attrib  TRT01PN  label = "Treatment" ;
run;


proc sort data= adqs  out=tby (keep = paramcd paramcd1) nodupkey;
    by paramcd ;
run;
%MTITLE;

%desc_tab(
    data         = adqs
  , data_n       =  adsl
  , var          =  aval
  , stat         =  n mean std min median max
  , order        =  paramcd paramcd1
  , vlabel       = no
  , baseline     = ablfl = "Y"
  , compare_var  = chg
  , time         =   Avisitn
  , visittext    = Visit
  , baselinetext = baseline at visit
  , subject      = subjid
  , tablesby     = Tby
  , optimal      = yes
  , total        = NO
  , round_factor =  0
  , class        =   &treat_arm_p.
 , class_order   = &treat_arm_p. = &MOSTO_PARAM_CLASS_ORDER.
 , data_n_ignore = paramcd paramcd1
 , page          = Paramcd paramcd1
);

%endprog;
