/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adae_iss_soc_pt_eair_aesi3_week26);
/*
 * Purpose          : Treatment-emergent adverse events of special interest (phototoxicity) up to week 26:
 *                    number of subjects and study size and exposure-adjusted incidence rate by primary system organ class and preferred term by integrated analysis treatment group (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : ereiu (Katharina Meier) / date: 12FEB2024
 * Reference prog   : /var/swan/root/bhc/3427080/ia/stat/main001/dev/analysis/pgms/t_adae_iss_soc_pt_eair_aesi3_week52.sas
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 18MAR2024
 * Reason           : Update footnote
 ******************************************************************************/


%LET mosto_param_class = %scan(&extend_var_disp_26_nt_a., 1, '@');

%load_ads_dat(adsl_view, adsDomain = adsl, where     = &saf_cond.)
%load_ads_dat(adae_view, adsDomain = adae, adslWhere = &saf_cond., where = trtemfl = 'Y')

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_26_nt_a.
  , extend_rule = &extend_rule_disp_26_nt_a.
)

%extend_data(
    indat       = adae_view
  , outdat      = adae_ext
  , var         = &extend_var_disp_26_nt_a.
  , extend_rule = &extend_rule_disp_26_nt_a_ae.
  )

%m_add_time_window(indat = adsl_ext, outdat = adsl_ext);

%MACRO call_inc_100_patyears(title=Treatment-emergent adverse events up to week 26, where=1=1);
    %set_titles_footnotes(
        tit1 = "Table: &title.: number of subjects and study size and exposure-adjusted incidence rate by primary system organ class and preferred term by integrated analysis treatment group &saf_label."
      , ftn1 = "Adverse events (AEs) are sorted by alphabetical order of the MedDRA classification."
      , ftn2 = "A subject is counted only once within each primary SOC and preferred term. The preferred terms within the AESI with 0 events were not included in the table."
      , ftn3 = "Study size and exposure-adjusted IRs are calculated as following: For each study and treatment group, the exposure-adjusted incidence (= number of participants with event / sum of exposure days) is multiplied by the proportion of the study exposure to the total exposure across studies. Results are then added up across all studies for each treatment group."
      , ftn4 = "Where sum of exposure days = sum of time to first treatment-emergent event for participants if an event occurred + sum of treatment duration with time at risk after treatment end for participants without treatment-emergent event."
      , ftn5 = "The time at risk after treatment end is defined as time after end of treatment up to end of treatment-emergent window or death date, whichever is earlier."
      , ftn6 = "Results are provided per 100 person-years, where one person-year is defined as 365.25 days. *IRs are study size adjusted incidence rates according to Crowe et al (2016). AEs in this table are identified using Bayer MedDRA Queries (BMQ) as described in IA Safety SAP."
      , ftn7 = "N =number of subjects who received the respective treatment at any time, n=number of subjects with at least one such event. AESI= Adverse Events of Special Interest. &foot_oasis3_week26."
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
    title = Treatment-emergent adverse events of special interest - phototoxicity up to week 26
  , where = not missing(CQ03CD)
)


%endprog;