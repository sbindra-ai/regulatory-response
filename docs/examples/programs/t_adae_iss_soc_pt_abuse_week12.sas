/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adae_iss_soc_pt_abuse_week12);
/*
 * Purpose          : On-treatment adverse events up to week 12: number of subjects with adverse events related to abuse potential by primary system organ class and preferred term by integrated analysis treatment group (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : erjli (Yosia Hadisusanto) / date: 14FEB2024
 * Reference prog   :
 ******************************************************************************/

%let mosto_param_class = %scan(&extend_var_disp_12_nt_a., 1, '@');

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
    tit1 = "Table: On-treatment adverse events up to week 12: number of subjects with adverse events related to abuse potential by primary system organ class and preferred term by integrated analysis treatment group &saf_label."
  , ftn1 = "N = number of subjects. Percentages are calculated relative to the respective treatment group. Subjects may be counted in more than one row."
  , ftn2 = "On-treatment adverse events are defined as adverse events with an onset between first and last study drug intake date."
  , ftn3 = "Adverse events (AEs) are sorted by alphabetical order of the MedDRA classification."
  , ftn4 = "A subject is counted only once within each primary SOC and preferred term."
  , ftn5 = "Standardised MedDRA Queries (SMQ) terms: Drug abuse and dependence; SMQ Drug withdrawal."
  , ftn6 = "Preferred terms: Euphoric mood; Feeling abnormal; Feeling drunk; Feeling of relaxation; Dizziness; Thinking abnormal; Hallucination; Inappropriate affect; Somnolence; Aggression; Drug tolerance; Psychotic disorder."
  , ftn7 = "High Level Group Term (HLGT): Mood disorders and disturbances NEC."
  , ftn8 = "High Level Term (HLT): Confusion and disorientation; Substance related and addictive disorders."
)

%incidence_print(
    data              = adae_ext(WHERE=(not missing(trtsdt) and trtsdt <= astdt <= trtedt))
  , data_n            = adsl_ext
  , var               = aebodsys aedecod
  , triggercond       = not missing(aedecod)
  , sortorder         = alpha
  , evlabel           = &evlabel.
  , anytxt            = &anytxt.
)


%endprog;