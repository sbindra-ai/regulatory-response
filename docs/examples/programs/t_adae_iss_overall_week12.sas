/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adae_iss_overall_week12);
/*
 * Purpose          : Treatment-emergent adverse events up to week 12: overall summary of number of subjects by integrated analysis treatment group (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : erjli (Yosia Hadisusanto) / date: 22NOV2023
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 04DEC2023
 * Reason           : Update footnote
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 13FEB2024
 * Reason           : Footnote updates acc. to updated TLF specs
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 14FEB2024
 * Reason           : Update header
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 04APR2024
 * Reason           : Indented action taken as requested
 ******************************************************************************/
/* Changed by       : eqczz (Petri Pulkkinen) / date: 05APR2024
 * Reason           : Use footnote from start.sas
 ******************************************************************************/

%let mosto_param_class = %scan(&extend_var_disp_12_nt_a., 1, '@');

%load_ads_dat(adsl_view, adsDomain = adsl, where     = &saf_cond.)
%load_ads_dat(adae_view, adsDomain = adae, adslWhere = &saf_cond., where = trtemfl = 'Y')

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_12_nt_a.
  , extend_rule = &extend_rule_disp_12_nt_a.
)

%extend_data(
    indat       = adae_view
  , outdat      = adae_ext
  , var         = &extend_var_disp_12_nt_a.
  , extend_rule = (trt01an in (53)   and aphase = 'Week 1-12') # &trt_ezn_12.
                @ (trt01an in (9901) and aphase = 'Week 1-12') # &trt_pla_12.
)

%set_titles_footnotes(
    tit1 = "Table: Treatment-emergent adverse events up to week 12: overall summary of number of subjects by integrated analysis treatment group &saf_label."
  , ftn1 = "(a) Mantel-Haenszel risk difference between EZN 120 mg (week 1-12) and Placebo (week 1-12) stratified by study and p-value of heterogeneity between studies based on Mantel-Haenszel Q-statistic."
  , ftn2 = "(b) Mantel-Haenszel risk ratio between EZN 120 mg (week 1-12) and Placebo (week 1-12) stratified by study and p-value of heterogeneity between studies based on Mantel-Haenszel Q-statistic."
  , ftn3 = "For the risk ratio, a treatment-arm-size adjusted zero cell correction with zero term = 0.5 was applied."
  , ftn4 = "If the number of subjects with an event is zero in both treatment groups in one study, that study will be excluded from the calculation of risk difference, risk ratio and p-values for heterogeneity."
  , ftn5 = "CI = Confidence Interval, N = number of subjects. Percentages are calculated relative to the respective treatment group. Subjects may be counted in more than one row."
  , ftn6 = "For AEs of special safety interest, following AEs are considered: potential AESI liver event, somnolence or fatigue, phototoxicity, and post-menopausal uterine bleeding."
  , ftn7 = "AE = Adverse Event, SAE = Serious Adverse Event."
  , ftn8 = "&foot_rr_min5."
)

%overview_tab(
    data        = adae_ext
  , data_n      = adsl_ext
  , misstext    = Missing
  , outdat      = out_table
  , freeline    =
  , groups      =
                      "<DEL>"                                                       * "Number (%) of subjects with treatment-emergent adverse events"
                      "not missing(aeterm)"                                         * "Any AE"
                      "not missing(aeterm)" * "<DEL>" * "max(asevn)"                * "Maximum intensity for any AE"
                      "aerel = 'Y'"                                                 * "Any study drug-related AE"
                      "aerel = 'Y'" * "<DEL>" * "max(asevn)"                        * "Maximum intensity for study drug-related AE"
                      "aerelpr = 'Y'"                                               * "Any AE related to procedures required by the protocol"
                      "not missing(aeacn)" * "<DEL>"  * 'aeacn'                     * "Action taken with study drug"
                      "assiny = 'Y'"                                                * "Any AE of special safety interest"
                      "<DEL>"                                                       * " "
                      "aeser = 'Y'"                                                 * "Any SAE"
                      "aeser = 'Y' and aesdth = 'Y'"                                * "     Results in death"
                      "aeser = 'Y' and aeslife = 'Y'"                               * "     Is life threatening"
                      "aeser = 'Y' and aeshosp = 'Y'"                               * "     Requires or prolongs hospitalization"
                      "aeser = 'Y' and aescong = 'Y'"                               * "     Congenital anomaly or birth defect"
                      "aeser = 'Y' and aesdisab = 'Y'"                              * "     Persistent or significant disability/incapacity"
                      "aeser = 'Y' and aesmie = 'Y'"                                * "     Other medically important serious event"
                      "aeser = 'Y' and aerel = 'Y'"                                 * "Any study drug-related SAE"
                      "aeser = 'Y' and aerelpr = 'Y'"                               * "Any SAE related to procedures required by the protocol"
                      "aeser = 'Y' and aeacn = 'DRUG WITHDRAWN'"                    * "Any SAE leading to discontinuation of study drug"
                      "aeser = 'Y' and not missing(aeacn)"  * "<DEL>"   * 'aeacn'   * "Action taken with SAE"
                      "aesdth = 'Y'"                                                * "AE with outcome death"
)

** Risk difference between EZN 120 mg (week 1-12) and Placebo (week 1-12) is stratified by study using Mantel-Haenszel test.: active = &trt_ezn_12., compare = &trt_pla_12.;
** For the risk ratio, a treatment-arm-size adjusted zero cell correction with zero term = 0.5 was applied.: correction_type = stratum_size, zero_term = 0.5;

** If the number of subjects with event is zero in both treatment groups in one study, that study will be excluded from the calculation
** of risk difference, risk ratio and p-values for heterogeneity. So set zero_exclusion = yes;

%m_wrap_risk_difference(
    indat          = out_table
  , indat_adsl     = adsl_ext
  , active         = &trt_ezn_12.
  , compare        = &trt_pla_12.
  , zero_exclusion = YES
  , het_p_display  = YES
  , risk_ratio     = YES
  , outdat         = out_table_rd
)

** Align the display of action taken;
DATA out_table_rd;
    SET out_table_rd;
    IF _order_ IN (7.00001 20.00001) THEN DO;
        _name_ = "   " || STRIP(_name_);
    END;
RUN;

%LET l_miss = %sysfunc(getoption(missing));
OPTIONS MISSING='';

%mosto_param_from_dat(data = out_table_rdinp, var = config)
%datalist(&config)

OPTION MISSING="&l_miss.";

%endprog;