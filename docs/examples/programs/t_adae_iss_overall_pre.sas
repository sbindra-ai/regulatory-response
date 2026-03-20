/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adae_iss_overall_pre);
/*
 * Purpose          : Pre-treatment adverse events: overall summary of number of subjects by integrated analysis treatment group (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : erjli (Yosia Hadisusanto) / date: 31OCT2023
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 04DEC2023
 * Reason           : Update footnote
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 26JAN2024
 * Reason           : # Use &extend_var_disp_12_a. to add total column (based on comment from ISS CRM)
 *                    # Remove AESI footnote and line "Any AE of special interest" (based on GSL's comment: AEs are of special interest to use only if they appear under treatment
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 13FEB2024
 * Reason           : Add footnote
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 14FEB2024
 * Reason           : Update header
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 15FEB2024
 * Reason           : Restrict ADAE to prefl = Y in %load_ads_dat
 *                    Use extend_rule = &extend_rule_disp_12_a.
 ******************************************************************************/

%let mosto_param_class = %scan(&extend_var_disp_12_a., 1, '@');

%load_ads_dat(adsl_view, adsDomain = adsl);
%load_ads_dat(adae_view, adsDomain = adae, where = prefl = 'Y');

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_12_a.
  , extend_rule = &extend_rule_disp_12_a.
);

%extend_data(
    indat       = adae_view
  , outdat      = adae_ext
  , var         = &extend_var_disp_12_a.
  , extend_rule = &extend_rule_disp_12_a.
);

%set_titles_footnotes(
    tit1 = "Table: Pre-treatment adverse events: overall summary of number of subjects by integrated analysis treatment group &saf_label."
  , ftn1 = "Pre-treatment adverse events refer to adverse events starting before the day of the first study drug. For SWITCH-1, pre-treatment adverse events are defined as the adverse events occurring during the time window between Screening Visit 2 and the first study drug intake."
  , ftn2 = "AE = Adverse Event, SAE = Serious Adverse Event."
)

%overview_tab(
    data        = adae_ext
  , data_n      = adsl_ext(WHERE=(&saf_cond.))
  , misstext    = Missing
  , groups      =
                      "<DEL>"                                           * "   Number (%) of subjects with pre-treatment adverse events"
                      "not missing(aeterm)"                             * "   Any AE"
                      "not missing(aeterm)" * "<DEL>" * "max(asevn)"    * "Maximum intensity for any AE"
                      "aerelpr = 'Y'"                                   * "   Any AE related to procedures required by the protocol"
                      "aeser = 'Y'"                                     * "   Any SAE"
                      "aeser = 'Y' and aesdth = 'Y'"                    * "     Results in death"
                      "aeser = 'Y' and aeslife = 'Y'"                   * "     Is life threatening"
                      "aeser = 'Y' and aeshosp = 'Y'"                   * "     Requires or prolongs hospitalization"
                      "aeser = 'Y' and aescong = 'Y'"                   * "     Congenital anomaly or birth defect"
                      "aeser = 'Y' and aesdisab = 'Y'"                  * "     Persistent or significant disability/incapacity"
                      "aeser = 'Y' and aesmie = 'Y'"                    * "     Other medically important serious event"
                      "aeser = 'Y' and aerelpr = 'Y'"                   * "   Any SAE related to procedures required by the protocol"
                      "aesdth = 'Y'"                                    * "   AE with outcome death"
)

%endprog;
