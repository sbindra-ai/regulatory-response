/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adae_iss_soc_pt_eair_abuse_week52);
/*
 * Purpose          : On-treatment adverse events up to week 52: number of subjects and study size and exposure-adjusted incidence rate
 *                    of adverse events related to abuse potential by primary system organc class and preferred term by integrated analysis treatment group (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : erjli (Yosia Hadisusanto) / date: 29NOV2023
 * Reference prog   :
 ******************************************************************************/

%LET mosto_param_class = %scan(&extend_var_disp_52_nt_a., 1, '@');

%load_ads_dat(adsl_view, adsDomain = adsl, where = &saf_cond.)

%load_ads_dat(
    adae_view
  , adsDomain = adae
  , where     = cq05cd = 5 %** Z_CQNAM.5 [Abuse potential];
  , adslWhere = &saf_cond.
)

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
    tit1           = "Table: On-treatment adverse events up to week 52: number of subjects and study size and exposure-adjusted incidence rate of adverse events related to abuse potential by primary system organ class and preferred term by integrated analysis treatment group &saf_label."
  , ftn1           = "N = number of subjects who received the respective treatment at any time, n = number of subjects with at least one such event. A subject is counted only once within each primary SOC and preferred term."
  , ftn2           = "On-treatment adverse events are defined as adverse events with an onset between first and last study drug intake date. Adverse events (AEs) are sorted by alphabetical order of the MedDRA classification."
  , ftn3           = "Study size and exposure-adjusted IRs are calculated as following: For each study and treatment group, the exposure-adjusted incidence (= number of participants with event / sum of exposure days) is multiplied by the proportion of the study exposure to the total exposure across studies. Results are then added up across all studies for each treatment group."
  , ftn4           = "Where sum of exposure days = sum of time to first treatment-emergent event for participants if an event occurred + sum of treatment duration with time at risk after treatment end for participants without treatment-emergent event."
  , ftn5           = "The time at risk after treatment end is defined as time after end of treatment up to end of treatment-emergent window or death date, whichever is earlier. Results are provided per 100 person-years, where one person-year is defined as 365.25 days. *IRs are study size adjusted incidence rates according to Crowe et al (2016)."
  , ftn6           = "Standardised MedDRA Queries (SMQ) terms: Drug abuse and dependence; SMQ Drug withdrawal. Preferred terms: Euphoric mood; Feeling abnormal; Feeling drunk; Feeling of relaxation; Dizziness; Thinking abnormal; Hallucination; Inappropriate affect; Somnolence; Aggression; Drug tolerance; Psychotic disorder. High Level Group Term (HLGT): Mood disorders and disturbances NEC. High Level Term (HLT): Confusion and disorientation; Substance related and addictive disorders."
)

%m_inc_100_patyears(
    indat       = adae_ext(WHERE=(not missing(trtsdt) and trtsdt <= astdt <= trtedt))
  , indat_adsl  = adsl_ext
  , censordt    = enddt
  , startdt     = startdt
  , var         = aebodsys aedecod
  , triggercond = not missing(aedecod)
  , evlabel     = &evlabel.
  , anytxt      = &anytxt.
)


%endprog;