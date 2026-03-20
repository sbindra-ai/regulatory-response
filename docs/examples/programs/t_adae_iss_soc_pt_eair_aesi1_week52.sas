/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adae_iss_soc_pt_eair_aesi1_week52);
/*
 * Purpose          : Treatment-emergent adverse events of special interest (any condition potentially triggering close liver observation) up to week 52:
 *                    number of subjects and study size and exposure-adjusted incidence rate by primary system organ class and preferred term by integrated analysis treatment group (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : erjli (Yosia Hadisusanto) / date: 26FEB2024
 * Reference prog   :
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

%MACRO call_inc_100_patyears(title=Treatment-emergent adverse events up to week 52, where=1=1);
    %set_titles_footnotes(
        tit1 = "Table: &title.: number of subjects and study size and exposure-adjusted incidence rate by primary system organ class and preferred term by integrated analysis treatment group &saf_label."
      , ftn1 = "Adverse events (AEs) are sorted by alphabetical order of the MedDRA classification."
      , ftn2 = "A subject is counted only once within each primary SOC and preferred term. The preferred terms within the AESI with 0 events were not included in the table."
      , ftn3 = "Study size and exposure-adjusted IRs are calculated as following: For each study and treatment group, the exposure-adjusted incidence (= number of participants with event / sum of exposure days) is multiplied by the proportion of the study exposure to the total exposure across studies. Results are then added up across all studies for each treatment group."
      , ftn4 = "Where sum of exposure days = sum of time to first treatment-emergent event for participants if an event occurred + sum of treatment duration with time at risk after treatment end for participants without treatment-emergent event."
      , ftn5 = "The time at risk after treatment end is defined as time after end of treatment up to end of treatment-emergent window or death date, whichever is earlier."
      , ftn6 = "Results are provided per 100 person-years, where one person-year is defined as 365.25 days. *IRs are study size adjusted incidence rates according to Crowe et al (2016)."
      , ftn7 = "Any condition triggering close liver observation according to protocol Section 10.5. results in true AESIs of liver events. Cases in this table are identified by defined Standardised MedDRA Queries and are beyond the protocol definition."
      , ftn8 = "N =number of subjects who received the respective treatment at any time, n=number of subjects with at least one such event. AESI= Adverse Events of Special Interest."
    )

    %m_inc_100_patyears(
        indat       = adae_ext(WHERE=(&where.))
      , indat_adsl  = adsl_ext
      , censordt    = enddt
      , startdt     = startdt
      , var         = aebodsys aedecod
      , triggercond = not missing(aedecod)
      , evlabel     = &evlabel.
      , anytxt      = &anytxt.
    )

%MEND;

%call_inc_100_patyears(
    title = Potential treatment-emergent adverse events of special interest - liver event up to week 52
  , where = not missing(CQ01CD)
)

%endprog;