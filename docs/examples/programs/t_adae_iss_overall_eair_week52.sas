/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adae_iss_overall_eair_week52);
/*
 * Purpose          : Treatment-emergent adverse events up to week 52: overall summary of number of subjects and study size and exposure-adjusted incidence rate by integrated analysis treatment group (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : erjli (Yosia Hadisusanto) / date: 09NOV2023
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 13DEC2023
 * Reason           : Update footnote
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 13FEB2024
 * Reason           : Footnote updates acc. to updated TLF specs
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 14FEB2024
 * Reason           : Update header
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 27MAR2024
 * Reason           : Re-ordering Footnote
 ******************************************************************************/

%LET mosto_param_class = %scan(&extend_var_disp_52_nt_a., 1, '@');

%load_ads_dat(adsl_view, adsDomain = adsl, where     = &saf_cond.)
%load_ads_dat(adae_view, adsDomain = adae, adslWhere = &saf_cond., where = trtemfl = 'Y')

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_52_nt_a.
  , extend_rule = &extend_rule_disp_52_nt_a.
)

%LET ezn_pure_cond      = (trt01an in (53));
%LET ezn_switcher_cond  = (trt02an in (53) and aphase = 'Week 13-52');
%LET pla_pure_cond      = (trt01an in (9901) and missing(trt02an));
%LET pla_switcher_cond  = (trt02an in (53) and aphase = 'Week 1-12');

%extend_data(
    indat       = adae_view
  , outdat      = adae_ext
  , var         = &extend_var_disp_52_nt_a.
  , extend_rule = &ezn_pure_cond. OR &ezn_switcher_cond. # &trt_ezn_52.
                @ &pla_pure_cond. OR &pla_switcher_cond. # &trt_pla_52.
)

%m_add_time_window(indat = adsl_ext, outdat = adsl_ext);

%set_titles_footnotes(
    tit1 = "Table: Treatment-emergent adverse events up to week 52: overall summary of number of subjects and study size and exposure-adjusted incidence rate by integrated analysis treatment group &saf_label."
  , ftn1 = "N = number of subjects who received the respective treatment at any time, n = number of subjects with at least one such event."
  , ftn2 = "Study size and exposure-adjusted IRs are calculated as following: For each study and treatment group, the exposure-adjusted incidence (= number of participants with event / sum of exposure days) is multiplied by the proportion of the study exposure to the total exposure across studies. Results are then added up across all studies for each treatment group."
  , ftn3 = "Where sum of exposure days = sum of time to first treatment-emergent event for participants if an event occurred + sum of treatment duration with time at risk after treatment end for participants without treatment-emergent event."
  , ftn4 = "The time at risk after treatment end is defined as time after end of treatment up to end of treatment-emergent window or death date, whichever is earlier."
  , ftn5 = "Results are provided per 100 person-years, where one person-year is defined as 365.25 days. 'Missing' is considered to be the lowest category of intensity."
  , ftn6 = "*IRs are study size adjusted incidence rates according to Crowe et al (2016)."
  , ftn7 = "For AEs of special safety interest, following AEs are considered: potential AESI liver event, somnolence or fatigue, phototoxicity, and post-menopausal uterine bleeding."
)

DATA adae_ext;
    SET adae_ext;
    IF missing(aedecod) THEN PUT "WARN" "ING: MISSING AEDECOD " usubjid= aeterm= aedecod=;
RUN;

%overview_tab(
    data     = adae_ext(WHERE=(not missing(aedecod)))
  , data_n   = adsl_ext
  , misstext = Missing
  , outdat   = out_table
  , freeline =
  , groups   =  "<DEL>"                                           * "<DEL>                                              # Number (%) of subjects with treatment-emergent adverse events"
                "not missing(aeterm)"                             * "not missing(aeterm)                                # Any AE"
                "not missing(aeterm)" * "<DEL>" * "max(asevn)"    * "<DEL>                                              #   Maximum intensity for any AE"
                "aerel = 'Y'"                                     * "aerel = 'Y'                                        # Any study drug-related AE"
                "aerel = 'Y'" * "<DEL>" * "max(asevn)"            * "<DEL>                                              #   Maximum intensity for study drug-related AE"
                "aerelpr = 'Y'"                                   * "aerelpr = 'Y'                                      # Any AE related to procedures required by the protocol"
                "not missing(aeacn)"                              * "<DEL>                                              # Action taken with study drug"  * 'aeacn' * 'aeacn # <DEL>'
                "assiny = 'Y'"                                    * "assiny = 'Y'                                       # Any AE of special safety interest"
                "<DEL>"                                           * " "
                "aeser = 'Y'"                                     * "aeser = 'Y'                                        # Any SAE"
                "aeser = 'Y' and aesdth = 'Y'"                    * "aeser = 'Y' and aesdth = 'Y'                       #   Results in death"
                "aeser = 'Y' and aeslife = 'Y'"                   * "aeser = 'Y' and aeslife = 'Y'                      #   Is life threatening"
                "aeser = 'Y' and aeshosp = 'Y'"                   * "aeser = 'Y' and aeshosp = 'Y'                      #   Requires or prolongs hospitalization"
                "aeser = 'Y' and aescong = 'Y'"                   * "aeser = 'Y' and AESCONG = 'Y'                      #   Congenital anomaly or birth defect"
                "aeser = 'Y' and aesdisab = 'Y'"                  * "aeser = 'Y' and AESDISAB = 'Y'                     #   Persistent or significant disability/incapacity"
                "aeser = 'Y' and aesmie = 'Y'"                    * "aeser = 'Y' and AESMIE = 'Y'                       #   Other medically important serious event"
                "aeser = 'Y' and aerel = 'Y'"                     * "aeser = 'Y' and aerel = 'Y'                        # Any study drug-related SAE"
                "aeser = 'Y' and aerelpr = 'Y'"                   * "aeser = 'Y' and aerelpr = 'Y'                      # Any SAE related to procedures required by the protocol"
                "aeser = 'Y' and aeacn = 'DRUG WITHDRAWN'"        * "aeser = 'Y' and aeacn = 'DRUG WITHDRAWN'           # Any SAE leading to discontinuation of study drug"
                "aeser = 'Y' and not missing(aeacn)"              * "<DEL>                                              # Action taken with SAE"  * 'aeacn' * "aeser = 'Y' and aeacn # <DEL>"
                "aesdth = 'Y'"                                    * "aesdth = 'Y'                                       # AE with outcome death"
)

%m_overview_100_patyears(
    indat       = adae_ext(WHERE=(not missing(aedecod)))
  , indat_adsl  = adsl_ext
  , indat_mosto = out_table
  , censordt    = enddt
  , startdt     = startdt
  , enddt       = enddt
  , event_var   = aedecod
  , adt         = astdt
  , outdat      = overall_eair_week52
  , debug       = Y
)

** Remove EAIR for some action taken categories;
DATA overall_eair_week52;
    SET overall_eair_week52;
    IF strip(_name_) IN  ('DOSE NOT CHANGED' 'DRUG INTERRUPTED' 'NOT APPLICABLE') THEN DO;
        IF NOT missing(eair_1) THEN _col_01 = tranwrd(_col_01, vvalue(eair_1), ' ');
        IF NOT missing(eair_2) THEN _col_02 = tranwrd(_col_02, vvalue(eair_2), ' ');
    END;
RUN;

%mosto_param_from_dat(data = overall_eair_week52inp, var = config)
%datalist(&config)


%endprog;

