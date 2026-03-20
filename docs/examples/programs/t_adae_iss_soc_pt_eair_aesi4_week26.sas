/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adae_iss_soc_pt_eair_aesi4_week26);
/*
 * Purpose          : Treatment-emergent adverse events of special interest (post-menopausal uterine bleeding) up to week 26:
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
 * Reference prog   : /var/swan/root/bhc/3427080/ia/stat/main001/dev/analysis/pgms/t_adae_iss_soc_pt_eair_aesi4_week52.sas
 ******************************************************************************/

%LET mosto_param_class = %scan(&extend_var_disp_26_nt_a., 1, '@');

%load_ads_dat(adsl_view, adsDomain = adsl, where     = &saf_cond.)
%load_ads_dat(admh_view, adsDomain = admh, adslwhere = &saf_cond.);
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

%extend_data(
    indat       = admh_view
  , outdat      = admh_ext
  , var         = &extend_var_disp_26_nt_a.
  , extend_rule = &extend_rule_disp_26_nt_a.
);

DATA hysterectomy(KEEP=&subj_var.);
    SET admh_ext(WHERE=(mhdecod in ('Hysterectomy' 'Hysterosalpingectomy' 'Hysterosalpingo-oophorectomy' 'Radical hysterectomy')));
RUN;

PROC SORT DATA=adsl_ext;                BY &subj_var.; RUN;
PROC SORT DATA=adae_ext;                BY &subj_var.; RUN;
PROC SORT DATA=hysterectomy NODUPKEY;   BY &subj_var.; RUN;

** N = number of subjects with uterus are subjects without hysterectomy;

DATA adae_ext;
    MERGE adae_ext(IN=a) hysterectomy(IN=b);
    BY &subj_var.;
    IF a AND NOT b;
RUN;

DATA adsl_ext;
    MERGE adsl_ext(IN=a) hysterectomy(IN=b);
    BY &subj_var.;
    IF a AND NOT b;
RUN;

%m_add_time_window(indat = adsl_ext, outdat = adsl_ext);

%MACRO call_inc_100_patyears(title=Treatment-emergent adverse events up to week 26, where=1=1);
    %set_titles_footnotes(
        tit1 = "Table: &title.: number of subjects and study size and exposure-adjusted incidence rate by primary system organ class and preferred term by integrated analysis treatment group &saf_label."
      , ftn1 = "Adverse events (AEs) are sorted by alphabetical order of the MedDRA classification. A subject is counted only once within each primary SOC and preferred term."
      , ftn2 = "The preferred terms within the AESI with 0 events were not included in the table."
      , ftn3 = "For subjects with a medical history of hysterectomy, the AESI post-menopausal uterine bleeding should not be included."
      , ftn4 = "Study size and exposure-adjusted IRs are calculated as following: For each study and treatment group, the exposure-adjusted incidence (= number of participants with event / sum of exposure days) is multiplied by the proportion of the study exposure to the total exposure across studies. Results are then added up across all studies for each treatment group."
      , ftn5 = "Where sum of exposure days = sum of time to first treatment-emergent event for participants if an event occurred + sum of treatment duration with time at risk after treatment end for participants without treatment-emergent event."
      , ftn6 = "The time at risk after treatment end is defined as time after end of treatment up to end of treatment-emergent window or death date, whichever is earlier."
      , ftn7 = "Results are provided per 100 person-years, where one person-year is defined as 365.25 days. *IRs are study size adjusted incidence rates according to Crowe et al (2016). &foot_oasis3_week26."
      , ftn8 = "N =number of subjects with uterus who received the respective treatment at any time, n=number of subjects with at least one such event. AESI= Adverse Events of Special Interest."
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
    title = Treatment-emergent adverse events of special interest - post-menopausal uterine bleeding up to week 26
  , where = not missing(CQ04CD)
)

%endprog;