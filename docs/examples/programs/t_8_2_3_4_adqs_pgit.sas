/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_2_3_4_adqs_pgit   );
/*

 * Purpose          : Transitions from baseline by time in {PGI-S item}: number of subjects <<subgroup>> (FAS)
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
 *****************************************************************************/
%macro pgis (param =  ,  formtn   =   );

%load_ads_dat(
        adqs_view  (where = (  paramcd in ("&param.") and
                               parcat1 = "PATIENT GLOBAL IMPRESSION VASOMOTOR SYMPTOMS V1.0"
                              and  avisitn in (5, 10 ,20, 30 ,40 ,80,120,160,260 , 700000 )
                              and anl04fl = "Y"
                             )
                    )
      , adsDomain = adqs
      , adslWhere = &fas_cond
    );

%load_ads_dat(adsl_view , adsDomain = adsl , where =  &fas_cond ) ;
%extend_data(indat = adqs_view , outdat =  adqs  );
%extend_data(indat = adsl_view  , outdat = adsl) ;

data adqs ;
    set adqs  ;

   aval_n   = input( strip(put( avalc ,  $&formtn.  )) ,  3. ) ;
   format aval_n  &formtn.;

    attrib  avalc   label = "PGI-S"
           avisitn  label = "Time"
           &treat_arm_p  label ='00'x
           ;
run;

proc sort data = adqs_view out = adqs_dup (keep = paramcd parcat1) nodupkey ;
    by parcat1 paramcd ;
RUN;

%MTITLE;

 %shift_tab(
     data          = adqs
   , data_n        = adsl
   , var           = aval_n
   , subject       = usubjid
   , by            = parcat1 paramcd avisitn
   , data_n_ignore = parcat1 paramcd avisitn
   , class         = trt01pn
   , complete      = YES
   , baseline      = avisitn=5
   , freeline      = trt01pn
   , maxlen        = 15
   , order          = parcat1 paramcd
   , tablesby      =   adqs_dup
   , together            = avisitn

 );

%MEND;

%pgis(param = PGVB101 , formtn =   _mshf. );
%pgis(param = PGVB102 , formtn =   _shf. );
%pgis(param = PGVB103 , formtn =   _ssp. );

%endprog;;