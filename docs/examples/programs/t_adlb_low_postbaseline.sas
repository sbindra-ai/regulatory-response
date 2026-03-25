/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
    %iniprog(name = t_adlb_low_postbaseline);
/*
 * Purpose          : Post-baseline low abnormalities by laboratory category and treatment: number of subjects (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gdcpl (Derek Li) / date: 15MAR2024
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : evmqf (Rowland Hale) / date: 18MAR2024
 * Reason           : Changed foot_sexbh_explanation to foot_bap_ul_explanation
 ******************************************************************************/
/* Changed by       : gdcpl (Derek Li) / date: 29MAR2024
 * Reason           : change paramn to paramcd
 ******************************************************************************/

%LET mosto_param_class = %scan(&extend_var_disp_12_ezn_52_a, 1, '@');

* Load and extend data;
%load_ads_dat(adlb_view, adsDomain = adlb, where = paramcd in (%trim(%quoteWords(&lb_safety_param., quote = Y))) and paramcd not in (&liver_param.) and &lb_avisit_selection., adslWhere = &saf_cond.);
%load_ads_dat(adsl_view, adsDomain = adsl, where = &saf_cond.);

%extend_data(
    indat       = adlb_view
  , outdat      = adlb_ext
  , var         = &extend_var_disp_12_ezn_52_a.
  , extend_rule = &extend_rule_disp_12_ezn_52_anofl.
);

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , subj_var    = USUBJID
  , var         = &extend_var_disp_12_ezn_52_a.
  , extend_rule = &extend_rule_disp_12_ezn_52_a1.
);



data adlb_tab;
    set adlb_ext;
    format &mosto_param_class. _trtgrp_split.;
    if paramcd not in (&lb_cat_urine.);
    *%m_switcher_avisit;
    if missing(lbstat);
    if missing(ablfl) then ablfl = "N"; * To avoid missing values message in %cond_incidence_tab;
RUN;

%let long_ftn = %str(Post-baseline is defined for EZN 120 mg (week 1-12) and Placebo (week 1-12) as following: All measurements taken at or after the date of first study drug intake are considered with the following exceptions:
                For SWITCH-1, all measurements up to and including the last observation are included. For OASIS 1-2 measurements during the open-label phase and follow-up are excluded. For OASIS 3 measurements after initial
                12 weeks (= the date of first study drug intake + 83 days) are excluded. It might have a longer duration than the TEAE interval. For EZN 120 mg (week 1-52), post-baseline is defined as all measurements
                taken at or after the first study drug intake of elinzanetant 120 mg until the last observation.);
%let long_ftn = %SYSFUNC(COMPBL(&long_ftn.));

%set_titles_footnotes(
    tit1 = "Table: Post-baseline low laboratory abnormalities by laboratory category and treatment: number of subjects &saf_label."
  , ftn1 = "The denominator (Den) represents the number of subjects at baseline with a normal or higher than normal laboratory assessment, and at least one valid laboratory value after start of treatment. "
  , ftn2 = "<cont>Subjects with missing or low abnormal values at baseline are not included in the denominator."
  , ftn3 = "The numerator (Num) represents the number of subjects with at least one low laboratory assessment post-baseline, and a normal or higher than normal laboratory assessment at baseline."
/*  , ftn4 = "&long_ftn."*/
  , ftn5 = "For OASIS 3, measurements up to day 182 (inclusive) for EZN 120 mg (week 1-26) are considered."
  , ftn6 = 'Unscheduled visits were included in the analysis.'
  , ftn7 = "&foot_bap_ul_explanation."
);

%cond_incidence_tab(
    data               = adlb_tab
  , data_n             = adsl_ext
  , subject            = &subj_var
  , group              = parcat1 paramcd
  , total              = no
  , abnormal_condition = anrind = "LOW" and &post_baseline_cond.
  , baseline_condition = ablfl = "Y" and anrind in ("HIGH" "NORMAL")
  , collabel           = Laboratory variable
  , outdat             = tmp
  , optimal            = YES
  , hsplit             = "#"
  , splitby            = NO
);

%let _vars = %getDataValueList(tmpinp(WHERE = (keyword = 'VAR')), value);

data tmp;
    set tmp;
    array Avars $ &_vars.;
    do over Avars;
        Avars = tranwrd(Avars, "Num", "#Num");
    END;
RUN;

%mosto_param_from_dat(data = tmpinp, var = varlist)
%datalist(&varlist.)

%symdel long_ftn _vars;
%endprog();