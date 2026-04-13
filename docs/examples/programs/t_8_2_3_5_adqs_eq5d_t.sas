/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_2_3_5_adqs_eq5d_t   );
/*
 * Purpose          : Transitions from baseline by time in {EQ-5D-5L item}: number of subjects  (FAS)
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 27NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/t_8_2_3_5_adqs_eq5d_t.sas (emvsx (Phani Tata) / date: 27JUL2023)
 ******************************************************************************/

%macro trans(param = ,title = ,  len = ,  formtn   = );

%load_ads_dat(
    adqs_view
  , adsDomain = adqs
  , where     = &param.
  , adslWhere = &fas_cond
);

%load_ads_dat(adsl_view , adsDomain = adsl , where =  &fas_cond );

%extend_data(indat = adqs_view , outdat =  adqs  );
%extend_data(indat = adsl_view  , outdat = adsl) ;


data adqs ;
    set adqs  ;
    where     (0 < avisitn < 900000 ) and anl04fl = "Y" ;;

    aval_n   = input( strip(put( avalc ,  $&formtn.  )) ,  3. ) ;
    format aval_n  &formtn.;

    attrib              avisitn  label = "Time"
           &treat_arm_p  label ='00'x  ;

run;


%let title =  &title. ;
%MTITLE;

%shift_tab(
    data          = adqs
  , data_n        = adsl
  , var           = aval_n
  , subject       = usubjid
  , by            = avisitn
  , data_n_ignore = avisitn
  , class         = trt01pn
  , complete      = YES
  , baseline      = avisitn=5
  , freeline      = trt01pn
  , maxlen        = &len.
  , together      = trt01pn
);
%MEND;

%trans(      param = %str(paramcd in ('EQ5D0201') ),
 title = %str(Mobility) ,
 len =  %str(15) ,   formtn = _eqm. );

%trans(      param = %str(paramcd in ('EQ5D0202') ),
 title = %str(Self-Care) ,
 len =  %str(15) ,   formtn = _eqsc. );

%trans(      param = %str(paramcd in ('EQ5D0203') ),
 title = %str(Usual Activities) ,
 len =  %str(10) ,   formtn = _equa. );

%trans(      param = %str(paramcd in ('EQ5D0204') ),
title = %str(Pain/Discomfort) ,
len =  %str(15) ,   formtn = _eqpd. );

%trans(      param = %str(paramcd in ('EQ5D0205') ),
title = %str(Anxiety/Depression) ,
len =  %str(10) ,   formtn = _eqad. );

%endprog ;
