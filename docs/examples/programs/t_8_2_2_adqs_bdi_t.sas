/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_2_2_adqs_bdi_t  );
/*
 * Purpose          : Transitions from baseline by time in BDI-II-total-score: number of subjects  (FAS)
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

*summary statistics and change from baseline by treatment group * ;
*Table : Table: BDIB999 - Total Score
                  BECK DEPRESSION INVENTORY (BDI):*;

%macro trans(param = ,title = ,  len =  );

%load_ads_dat(
    adqs_view
  , adsDomain = adqs
  , where     = &param. and  avisitn in ( 5, 40 ,80,120,160,260 ,700000 ) and ANL04FL="Y"
  , adslWhere = &fas_cond
  , keep  = usubjid parcat1 paramcd avisitn avalca1n  aval
  , adslvars =  &treat_arm_p
);

%load_ads_dat(adsl_view , adsDomain = adsl , where =  &fas_cond );

%extend_data(indat = adqs_view , outdat =  adqs  );
%extend_data(indat = adsl_view  , outdat = adsl) ;


data  adqs ;
    set adqs   ;

    attrib  avisitn  label = "Visit"
           &treat_arm_p  label ='00'x  ;


run;

%MTITLE;

%shift_tab(
    data          = adqs
  , data_n        = adsl
  , var           =  avalca1n
  , subject       = usubjid
  , by            = avisitn
  , data_n_ignore = avisitn
   , order        = avalca1n
  , class         = trt01pn
  , complete      = OBSERVED_MIN
  , baseline      = avisitn=5
  , freeline      = avisitn
  , together      = trt01pn
  , maxlen        =  &len.
);
%MEND;

%trans(      param = %str(paramcd in ('BDIB999') ),
 title = %str(BDI-II-total score) ,
 len =  %str(18) );


%endprog;
