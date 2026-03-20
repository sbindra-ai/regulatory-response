/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adae_iss_overall_post);
/*
 * Purpose          : Post-treatment adverse events: overall summary of number of subjects by integrated analysis treatment group
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
/* Changed by       : ereiu (Katharina Meier) / date: 13FEB2024
 * Reason           : Footnote updates acc. to updated TLF specs
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 14FEB2024
 * Reason           : Update header
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 22FEB2024
 * Reason           : Update footnote
 ******************************************************************************/

%let mosto_param_class = %scan(&extend_var_disp_12_nt_a., 1, '@');

%load_ads_dat(adsl_view, adsDomain = adsl);
%load_ads_dat(adae_view, adsDomain = adae);
%load_ads_dat(admh_view, adsDomain = admh);

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_12_nt_a.
  , extend_rule = &extend_rule_disp_12_nt_a.
);

%extend_data(
    indat       = adae_view
  , outdat      = adae_ext
  , var         = &extend_var_disp_12_nt_a.
  , extend_rule = (trt01an in (53)   and postfl = 'Y') # &trt_ezn_12.
                @ (trt01an in (9901) and postfl = 'Y') # &trt_pla_12.
);

%set_titles_footnotes(
    tit1 = "Table: Post-treatment adverse events: overall summary of number of subjects by integrated analysis treatment group &saf_label."
  , ftn1 = "Post-treatment adverse events start after the date of the last treatment date + 14 days."
  , ftn2 = "The treatment groups here refer to the initial treatment assignment. Namely for subjects switching from placebo to elinzanetant 120 mg, the post-treatment AEs are still assigned to the integrated analysis treatment group Placebo (week 1-12)."
  , ftn3 = "For AEs of special safety interest, following AEs are considered: potential AESI liver event, somnolence or fatigue, phototoxicity, and post-menopausal uterine bleeding."
  , ftn5 = "AE = Adverse Event, SAE = Serious Adverse Event."
)

%overview_tab(
    data        = adae_ext
  , data_n      = adsl_ext(WHERE=(&saf_cond.))
  , misstext    = Missing
  , groups      =
                      "<DEL>"                                           * "   Number (%) of subjects with post-treatment adverse events"
                      "not missing(aeterm)"                             * "   Any AE"
                      "not missing(aeterm)" * "<DEL>" * "max(asevn)"    * "Maximum intensity for any AE"
                      "aerel = 'Y'"                                     * "   Any study drug-related AE"
                      "aerelpr = 'Y'"                                   * "   Any AE related to procedures required by the protocol"
                      "assiny = 'Y'"                                    * "   Any AE of special interest"
                      "aeser = 'Y'"                                     * "   Any SAE"
                      "aeser = 'Y' and aesdth = 'Y'"                    * "     Results in death"
                      "aeser = 'Y' and aeslife = 'Y'"                   * "     Is life threatening"
                      "aeser = 'Y' and aeshosp = 'Y'"                   * "     Requires or prolongs hospitalization"
                      "aeser = 'Y' and aescong = 'Y'"                   * "     Congenital anomaly or birth defect"
                      "aeser = 'Y' and aesdisab = 'Y'"                  * "     Persistent or significant disability/incapacity"
                      "aeser = 'Y' and aesmie = 'Y'"                    * "     Other medically important serious event"
                      "aeser = 'Y' and aerel = 'Y'"                     * "   Any study drug-related SAE"
                      "aeser = 'Y' and aerelpr = 'Y'"                   * "   Any SAE related to procedures required by the protocol"
                      "aesdth = 'Y'"                                    * "   AE with outcome death"
)




%endprog;