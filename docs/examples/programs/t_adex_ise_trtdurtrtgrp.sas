/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adex_ise_trtdurtrtgrp);
/*
 * Purpose          : Create table: Treatment duration by treatment group (full analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gltlk (Rui Zeng) / date: 17FEB2024
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_3_1_adex_trtdurtrtgrp.sas (enpjp (Prashant Patel) / date: 12SEP2023)
 ******************************************************************************/

%LET mosto_param_class = &mosto_param_class_eff.;

%load_ads_dat(
    adsl_view
  , adsDomain = adsl
  , where     = &fas_cond.
);

%load_ads_dat(adex_view, adsDomain = adex, adslWhere = &fas_cond., where = paramcd='DURWGR' and aval ne . and parcat2 = "by treatment group")/*DURW ==> Treatment Duration weeks */

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_eff.
  , extend_rule = &extend_rule_disp_eff.
);

%extend_data(
    indat       = adex_view
  , outdat      = adex_ext
  , var         = &extend_var_disp_eff.
  , extend_rule = &extend_rule_disp_eff.
);

data adex;
   set adex_ext;
    label aval = "Duration of treatment (weeks)"
          avalca1n = "Treatment duration categories (disjunct)"
          aphase = "Treatment Period";
          days=aval*7;
RUN;

data adex2;
    set adex;
    if  aphase= "Overall" and days>=1 then do; crit1n=1; crit1="at least 1 day"; output; end;
    if  aphase= "Overall" and days>=28 then do crit1n=4; crit1="at least 4 weeks"; output; end;
    if  aphase= "Overall" and days>=84 then do; crit1n=12; crit1="at least 12 weeks"; output; end;
    if  aphase= "Overall" and days>=175 then do; crit1n=25; crit1="at least 25 weeks"; output; end;
    label crit1n="Treatment duration categories (cumulative)";
    format crit1n _exp.;
RUN;

%set_titles_footnotes(
    tit1 = "Table: Treatment duration by treatment group &fas_label."
  , ftn1 = "&foot_placebo_ezn."
  , ftn2 = "&foot_sd."
  , ftn3 = 'Overall duration of treatment is defined as the number of days from the day of first study drug intake up to and including the day of last study drug intake.'
  , ftn4 = "&foot_w12."
  , ftn5 = "&foot_w26."
  , ftn6 = "According protocol, the Visit T6/End of treatment was allowed to be Week 26 - 7 days (i.e. at day 176 to 182)."
);

%desc_freq_tab(
    data          = adex
  , var           = aval avalca1n
  , data_n        = adsl_ext
  , by            = aphase
  , data_n_ignore = aphase
  , outdat        = one
  , basepct       = N_CLASS
  , stat          = N NMISS MEAN STD MEDIAN MIN MAX
  , round_factor  = 0
  , order_var     = aphase = "Week 1-12" "Week 13-26" "Overall"
)

%desc_freq_tab(
    data          = adex(where = (aphase = "Overall"))
  , var           = aval avalca1n                        /*use AVAL to keep the same outdat structure as above macro call*/
  , data_n        = adsl_ext
  , by            = aphase
  , data_n_ignore = aphase
  , outdat        = two
  , incln         = NO
  , basepct       = N_CLASS
  , stat          = N NMISS MEAN STD MEDIAN MIN MAX
  , round_factor  = 0
  , order_var     = aphase = "Week 1-12" "Week 13-26" "Overall"
);

%desc_freq_tab(
    data          = adex2(where = (aphase = "Overall"))
  , var           = aval crit1n                         /*use AVAL to keep the same outdat structure as above macro call*/
  , var_freq      = crit1n
  , data_n        = adsl_ext
  , by            = aphase
  , data_n_ignore = aphase
  , outdat        = three
  , incln         = NO
  , basepct       = N_CLASS
  , stat          = N NMISS MEAN STD MEDIAN MIN MAX
  , round_factor  = 0
  , order_var     = aphase = "Week 1-12" "Week 13-26" "Overall"
);

data one;
    set one(in=a where = (_var_ = "aval"))
        two(in=b where = (_var_ = "AVALCA1N" and text ne "n" and text ne "   missing"))
        three(in=c where = (_var_ = "CRIT1N"  and text ne "n" and text ne "   missing"));
    if a then _posi_=_posi_+10;
    else if b then _posi_=_posi_+20;
    else if c then _posi_=_posi_+30;
    label text = "    ";
    _col_01 = tranwrd(_col_01," (100%)","");
    _col_02 = tranwrd(_col_02," (100%)","");
RUN;

%mosto_param_from_dat(data = oneinp, var = varlist)
%datalist(&varlist.)

%endprog();
