/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adae_iss_soc_pt_pre);
/*
 * Purpose          : Pre-treatment adverse events: number of subjects by primary system organ class and preferred term by integrated analysis treatment group
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
    tit1 = "Table: Pre-treatment adverse events: number of subjects by primary system organ class and preferred term by integrated analysis treatment group &saf_label."
  , ftn1 = "Adverse events (AEs) are sorted by alphabetical order of the MedDRA classification."
  , ftn2 = "A subject is counted only once within each primary SOC and preferred term."
  , ftn3 = "Pre-treatment adverse events refer to adverse events starting before the day of the first study drug. For SWITCH-1, pre-treatment adverse events are defined as the adverse events occurring during the time window between Screening Visit 2 and the first study drug intake."
  , ftn4 = "N = number of subjects. Percentages are calculated relative to the respective treatment group. Subjects may be counted in more than one row."
)

%incidence_print(
    data        = adae_ext
  , data_n      = adsl_ext(WHERE=(&saf_cond.))
  , var         = aebodsys aedecod
  , triggercond = not missing(aeterm)
  , sortorder   = alpha
  , evlabel     = &evlabel.
  , anytxt      = &anytxt.
)

%endprog;