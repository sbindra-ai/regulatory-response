/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
    %iniprog(name = t_advs_sysbp_summary);
/*
 * Purpose          : Percentage of subjects with maximum systolic blood pressure by category of blood pressure post-baseline (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : ereiu (Katharina Meier) / date: 01MAR2024
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : eqczz (Petri Pulkkinen) / date: 05APR2024
 * Reason           : Add footnote for RR/RD
 ******************************************************************************/

%LET mosto_param_class = %scan(&extend_var_disp_12_ezn_52_a, 1, '@');

* Load and extend data;
%load_ads_dat(advs, adsDomain = advs, where = paramcd eq 'SYSBP', adslWhere = &saf_cond.);
%load_ads_dat(adsl, adsDomain = adsl, where = &saf_cond.);

%extend_data(
    indat       = advs
  , outdat      = advs_ext
  , subj_var    = USUBJID
  , var         = &extend_var_disp_12_ezn_52_a.
  , extend_rule = &extend_rule_disp_12_ezn_52_anofl.
);
%extend_data(
    indat       = adsl
  , outdat      = adsl_ext
  , subj_var    = USUBJID
  , var         = &extend_var_disp_12_ezn_52_a
  , extend_rule = &extend_rule_disp_12_ezn_52_a1
);

* Prepare data;
DATA advs_ext;
    SET advs_ext;
    IF (&mosto_param_class. IN (1,2) AND crit1fl='Y')
      OR ( &mosto_param_class. IN (4) AND (( &mosto_param_class._ori = 9901 AND crit2fl='Y') OR crit3fl='Y'))
      OR ( &mosto_param_class. IN (6) AND (( &mosto_param_class._ori = 9901 AND crit2fl='Y') OR crit4fl='Y')) ;
    format &mosto_param_class. _trtgrp_split.;
RUN;

DATA adsl_ext;
    SET adsl_ext;
    format &mosto_param_class. _trtgrp_split.;
RUN;

* Calculate frequencies;
%overview_tab(
    data      = advs_ext
  , data_n    = adsl_ext
  , subject   = STUDYID USUBJID
  , total     = no
  , groups    = 'aval<90'    * '<90'
                'aval>=90'   * '>=90'
                'aval>=120'  * '>=120'
                'aval>=140'  * '>=140'
                'aval>=160'  * '>=160'
                'aval>=180'  * '>=180'
  , groupstxt = Systolic blood pressure (mm Hg)
  , outdat    = out_table
  , maxlen    = 30
  , hsplit    = '#'
);

* Calculate risk difference;
%m_wrap_risk_difference(
    indat      = out_table
  , indat_adsl = adsl_ext
  , active     = &trt_ezn_12.
  , compare    = &trt_pla_12.
  , outdat     = tmp
);

* Update order of displayed variables;
DATA tmpinp;
    SET tmpinp;
    IF keyword='VAR' THEN value='_col_01 _col_02 RD_CI _col_03 _col_04';
RUN;

* Output;
%set_titles_footnotes(
    tit1 = "Table: Percentage of subjects with maximum systolic blood pressure by category of blood pressure post-baseline &saf_label."
  , ftn1 = "Risk difference between EZN 120 mg (week 1-12) and Placebo (week 1-12) is stratified by study using Mantel-Haenszel test."
  , ftn2 = "For OASIS 3, the event onset is up to day 182 (inclusive) for EZN 120 mg (week 1-26)."
  , ftn3 = "N= number of participants in integrated analysis treatment group with available blood pressure data; n= number of participants with indicated blood pressure."
  , ftn4 = "CI = Confidence Interval. Percentages are calculated relative to the respective treatment group. Subjects may be counted in more than one row."
  , ftn5 = "Risk difference is only shown where there are at least 5 participants with one such event in either treatment group."
);

%mosto_param_from_dat(data = tmpinp, var = g_call);
%datalist(&g_call);

%endprog;