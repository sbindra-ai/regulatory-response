/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adsl_iss_disp_ovrl);
/*
 * Purpose          : Disposition in overall study (all randomized subjects)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gltlk (Rui Zeng) / date: 18MAR2024
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : eqczz (Petri Pulkkinen) / date: 05APR2024
 * Reason           :  Add footnote Risk difference is only shown where there
 *                    are at least 5 participants with one such event in either treatment group
 ******************************************************************************/


%LET mosto_param_class = %scan(&extend_var_disp_12_ezn_52., 1, '@');

**get data and select only relevant population;
%load_ads_dat(adsl_view, adsDomain = adsl, where = &rand_cond.)
%load_ads_dat(adds_view, adsDomain = adds, where = dscat in ('DISPOSITION EVENT' " ") and dsscat ne 'INFORMED CONSENT' and dsscat ne "END OF STUDY TREATMENT");

*Extend treatment group as needed;
%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_12_ezn_52.
  , extend_rule = &extend_rule_disp_12_ezn_52.
);

%extend_data(
    indat       = adds_view
  , outdat      = adds_ext
  , var         = &extend_var_disp_12_ezn_52.
  , extend_rule = &extend_rule_disp_12_ezn_52.
);

*Get treated start date;
*All EZN 120 mg (week 1-52): Treated with EZN.;
* subject 21652360022002 has different ARM vs. ACTARM: ARM = 'Placebo - Elinzanetant 120mg', ACTARM = 'Elinzanetant 120mg', so we need to use ACTARMCD in the condition.;
DATA adsl_ext2;
    SET adsl_ext;
    IF &mosto_param_class. = &trt_ezn_52. AND &mosto_param_class._ori = 9901 AND actarmcd = 'PLA_ELIN120' THEN trtsdt_drug = tr02sdt;
    ELSE                                                                                                       trtsdt_drug = tr01sdt;
    %M_PropIt(Var=dcsreas);
RUN;

DATA fup;
    SET adds_ext (WHERE = (epoch IN ("FOLLOW-UP" "POST-TREATMENT")));
    KEEP studyid usubjid fup;
    fup = 1;
RUN;

proc sort data = fup;
    by studyid usubjid;
RUN;

DATA disc;
    SET adds_ext (WHERE = (dssubdec = "STOP REGULAR SCHEDULED CONTACT" AND epoch="TREATMENT"));
    KEEP studyid usubjid disc;
    disc=1;
RUN;

DATA final;
    MERGE adsl_ext2(IN=a) fup(IN=b) disc(IN=d);
    BY studyid usubjid;
    IF a;
    IF NOT b AND NOT d THEN fup=0;
RUN;

ods escapechar="^";

*macro %m_overview_tab_response creates n(%) columns, and create a dataset m_all_subjects that has the subjects level data with response data for each category;
%overview_tab(
    data      = final
  , groups    = 'randfl   = "Y"'                                * 'Randomized/ Assigned to treatment'
                'trtsdt_drug ne .'                              * 'Treated'
                'complfl  = "Y"'                                * 'Completed study'
                'complfl  = "N" and dcsreas_prop eq " " and fup=1'                                                      * 'Did not complete study treatment but completed post-treatment phase/follow-up'
                '(complfl  = "N" and dcsreas_prop ne " ") or (complfl  = "N" and dcsreas_prop eq " " and fup=0)'        * "Did not complete study" * 'dcsreas_prop'*'Primary reason'
  , groupstxt = Number of subjects
  , n_group   = 1
  , complete  = none
  , outdat    = out_table
  , freeline  =
)

** Risk difference between EZN 120 mg (week 1-12) and Placebo (week 1-12) is stratified by study using Mantel-Haenszel test.: active = &trt_ezn_12., compare = &trt_pla_12.;
** For the risk ratio, a treatment-arm-size adjusted zero cell correction with zero term = 0.5 was applied.: correction_type = stratum_size, zero_term = 0.5;
%m_wrap_risk_difference(
    indat      = out_table
  , indat_adsl = adsl_ext
  , active     = &trt_ezn_12.
  , compare    = &trt_pla_12.
  , outdat     = out_table_riskdiff
)

DATA out_table_riskdiff;
    SET out_table_riskdiff;
    IF _order_ = 1 THEN CALL missing(rd_ci);      * Do not display risk difference for 100% row;
    IF index(propcase(_name_),"Missing") > 0 THEN _order_=_order_+ 0.99;   * Place 'Missing' at the last;
RUN;

DATA out_table_riskdiffinp;
    SET out_table_riskdiffinp;
    IF keyword = 'VAR' THEN value = '_COL_01 _COL_02 RD_CI _COL_03';
RUN;

%set_titles_footnotes(
    tit1 = "Table: Disposition in overall study &rand_label."
  , ftn1 = 'EZN 120 mg (week 1-26/1-52) refers to participants who have been randomized to either EZN 120 mg or Placebo-EZN 120 mg.'
  , ftn2 = 'For EZN 120 mg (week 1-12) and Placebo (week 1-12), treated refers to the treatment with EZN 120 mg or Placebo.'
  , ftn3 = '<cont>For EZN 120 mg (week 1-26/1-52), treated refers to all subjects who received EZN 120 mg excluding those who were randomized to Placebo-Elinzanetant and did not receive EZN 120 mg treatment.'
  , ftn4 = 'Definition of completed study = completed all phases of the study including the last visit.'
  , ftn5 = "Risk difference between EZN 120 mg (week 1-12) and Placebo (week 1-12) is stratified by study using Mantel-Haenszel test."
  , ftn6 = "Risk difference is only shown where there are at least 5 participants with one such event in either treatment group."
  , ftn7 = "CI = Confidence Interval. Percentages are calculated relative to the respective treatment group."
);

%mosto_param_from_dat(data = out_table_riskdiffinp, var = config);
%datalist(&config);

%endprog;

