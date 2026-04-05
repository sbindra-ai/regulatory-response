/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adex_ise_comptrtgrp);
/*
 * Purpose          : Create table: Treatment compliance by treatment group (full analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gltlk (Rui Zeng) / date: 28FEB2024
 * Reference prog   :
 ******************************************************************************/

%LET mosto_param_class = &mosto_param_class_eff.;

%load_ads_dat(
    adsl_view
  , adsDomain = adsl
  , where     = &fas_cond.
);

%load_ads_dat(
    adex_view
  , adsDomain = adex
  , where     = paramcd in('CMPCRFGR' 'CMPDRYGR') and aval ne . and parcat2 = "by treatment group"
  , adslWhere = &fas_cond.
)

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
    label aval    ="Compliance (%)"
          avalca1n="Categories n (%)"
          parcat1 ="Treatment compliance"
          aphase  ="Treatment Period";
RUN;

%set_titles_footnotes(
    tit1 = "Table: Treatment compliance by treatment group &fas_label."
    , ftn1 = 'Compliance (%) = 100 * Number of capsules taken / Number of planned capsules per protocol'
    , ftn2 = "&foot_placebo_ezn."
    , ftn3 = "&foot_sd."
    , ftn4 = "&foot_w12."
    , ftn5 = "&foot_w26."
);

%desc_freq_tab(
    data          = adex
  , var           = aval avalca1n
  , data_n        = adsl_ext
  , page          = parcat1
  , by            = aphase
  , data_n_ignore = aphase parcat1
  , missing       = yes
  , stat          = n nmiss mean std min median max
  , round_factor  = 0.1
  , order_var     = aphase = "Week 1-12" "Week 13-26" "Overall"
)

%endprog();