/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_3_1_adex_trtdurtrtgrp);
/*
 * Purpose          : Treatment duration by treatment group (FAS/SAF)
 * Programming Spec :
 * Validation Level : 2 - Verification by Double Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : enpjp (Prashant Patel) / date: 01DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_3_1_adex_trtdurtrtgrp.sas (enpjp (Prashant Patel) / date: 09SEP2023)
 ******************************************************************************/

%macro rpt(pop=, trt=, poplabel=);
%load_ads_dat(adsl_view, adsDomain = adsl, where = &pop.)
%load_ads_dat(adex_view, adsDomain = adex, adslWhere = &pop., where = paramcd='DURWGR' and aval ne . and parcat2 = "by treatment group")/*DURW ==> Treatment Duration weeks */

%extend_data(indat = adsl_view, outdat = adsl)
%extend_data(indat = adex_view, outdat = adex)

data adex;
   set adex_view;
    label aval = "Duration of treatment (weeks)"
          avalca1n = "Treatment duration categories (disjunct)"
          aphase = "Treatment Period";
          days=aval*7;
RUN;

data adex2;
    set adex/*(drop=crit:)*/;
    if  aphase= "Overall" and days>=1 then do; crit1n=1; crit1="at least 1 day"; output; end;
    if  aphase= "Overall" and days>=28 then do crit1n=2; crit1="at least 4 weeks"; output; end;
    if  aphase= "Overall" and days>=84 then do; crit1n=3; crit1="at least 12 weeks"; output; end;
    if  aphase= "Overall" and days>=175 then do; crit1n=4; crit1="at least 25 weeks"; output; end;
    label crit1n="Treatment duration categories (cumulative)";
    format crit1n _crit.;
RUN;


%mtitle;
%desc_freq_tab(
    data          = adex
  , var           = aval avalca1n
  , class         = &trt.
  , data_n        = adsl_view
  , subject       = usubjid
  , by            = aphase
  , data_n_ignore = aphase
  , total         = NO
  , class_order   = aphase
  , outdat        = one
  , incln         = NO
  , basepct       = N_CLASS
  , hlabel        = YES
  , levlabel      = YES
  , dintable      = YES
  , stat          = N NMISS MEAN STD MEDIAN MIN MAX
  , round_factor  = 0
  , order_var     = aphase = "Week 1-12" "Week 13-26" "Overall"
)

%desc_freq_tab(
    data          = adex(where = (aphase = "Overall"))
  , var           = aval avalca1n
  , class         = &trt.
  , data_n        = adsl_view
  , subject       = usubjid
  , by            = aphase
  , data_n_ignore = aphase
  , total         = NO
  , outdat        = three
  , incln         = NO
  , basepct       = N_CLASS
  , hlabel        = NO
  , levlabel      = YES
  , dintable      = YES
  , stat          = N NMISS MEAN STD MEDIAN MIN MAX
  , round_factor  = 0
  , order_var     = aphase = "Week 1-12" "Week 13-26" "Overall"
);

%desc_freq_tab(
    data          = adex2(where = (aphase = "Overall"))
  , var           = aval  crit1n
  , class         = &trt.
  , var_freq      = crit1n
  , data_n        = adsl_view
  , subject       = usubjid
  , by            = aphase
  , data_n_ignore = aphase
  , total         = NO
  , outdat        = four
  , complete      = ALL
  , incln         = NO
  , basepct       = N_CLASS
  , levlabel      = YES
  , dintable      = YES
  , stat          = N NMISS MEAN STD MEDIAN MIN MAX
  , round_factor  = 0
  , order_var     = aphase = "Week 1-12" "Week 13-26" "Overall"
);

data one;
    set one(in=a where = (_var_ = "aval"))
        three(in=b where = (_var_ = "AVALCA1N" and text ne "n" and text ne "   missing"))
        four(in=c where = (_var_ = "CRIT1N"  and text ne "n" and text ne "   missing" ));
    if a then _posi_=_posi_+10;
    else if b then _posi_=_posi_+20;
    else if c then _posi_=_posi_+30;
    label text = "    ";
    col1 = tranwrd(col1," (100%)","");
    col2 = tranwrd(col2," (100%)","");
RUN;

%mosto_param_from_dat(
    data    = oneinp
  , var     = l_call
  , keyword = keyword
  , value   = value
)

%datalist(&l_call)

%MEND;

%rpt(pop=%str(&FAS_COND), trt=&TREAT_ARM_P, poplabel=&FAS_LABEL);
%rpt(pop=%str(&SAF_COND), trt=&TREAT_ARM_A, poplabel=&SAF_LABEL);
%rpt(pop=%str(&SLAS_COND), trt=&TREAT_ARM_p, poplabel=&SLAS_LABEL);

%endprog();