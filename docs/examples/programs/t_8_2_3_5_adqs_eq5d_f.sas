/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_2_3_5_adqs_eq5d_f    );
/*
 * Purpose          : EQ-5D-5L <<item>>: number of subjects by treatment group (FAS)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 29NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/t_8_2_3_5_adqs_eq5d_f.sas (emvsx (Phani Tata) / date: 27JUL2023)
 ******************************************************************************/
%macro param (par =  ,  formtn   =    );

%load_ads_dat(adqs_view, adsDomain = adqs , adslWhere =  &fas_cond )
%load_ads_dat(adsl_view , adsDomain = adsl , where =  &fas_cond )
%extend_data(indat = adqs_view , outdat =  adqs  );
%extend_data(indat = adsl_view  , outdat = adsl) ;

*EQ-5D-5L ;

data adqs ;
    set adqs  ;

where parcat1 = "EQ-5D-5L"
      and paramcd  in ("&par.")
      and anl04fl = "Y"
       and  (0 < avisitn < 900000 );

aval_n   = input( strip(put( avalc ,  $&formtn.  )) ,  3. ) ;
format aval_n  &formtn.;

attrib  &treat_arm_p  label = "Treatment group"
       paramcd   label = "EQ-5D-5L"
       avisitn  label = "Time";
run;

proc sort data = adqs out = tby (keep = paramcd ) nodupkey;
    by  paramcd ;
run;

%MTITLE;

%freq_tab(
    data          = adqs
  , data_n        = adsl
  , var           = aval_n
  , subject       = &subj_var.
  , page          = paramcd
  , order         = Paramcd
  , by            = avisitn
  , data_n_ignore = paramcd
  , total         = NO
  , class         = &treat_arm_p
  , hlabel        = Yes
  , missing       = NO
  , tablesby      = TBY
  , layout        = MINIMAL_BY
);

%MEND;
 %param (par = EQ5D0201 ,   formtn = _eqm. );
 %param (par = EQ5D0202  ,   formtn = _eqsc. );
 %param (par = EQ5D0203  ,   formtn = _equa. );
 %param (par = EQ5D0204  ,   formtn = _eqpd. );
 %param (par = EQ5D0205  ,   formtn = _eqad. );

%endprog;
