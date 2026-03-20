/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adae_iss_soc_pt_abuse_post);
/*
 * Purpose          : Post-treatment adverse events: number of subjects with adverse events related to abuse potential by primary system organ class and preferred term by integrated analysis treatment group (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : erjli (Yosia Hadisusanto) / date: 28FEB2024
 * Reference prog   :
 ******************************************************************************/

%let mosto_param_class = %scan(&extend_var_disp_12_nt_a., 1, '@');

%load_ads_dat(adsl_view, adsDomain = adsl, where     = &saf_cond.)

%load_ads_dat(
    adae_view
  , adsDomain = adae
  , where     = cq05cd = 5 %** Z_CQNAM.5 [Abuse potential];
  , adslWhere = &saf_cond.
)

** *Placebo (week 1-52) includes only those participants who received Placebo only. Switchers are only assigned to EZN 120 mg (week 1-52).;
%LET extend_var_disp_52_abuse  = trt01an @FORMAT=_trtgrp_split. LABEL = "IA Treatment Group";
%LET extend_rule_disp_52_abuse = trt01an in (53) OR trt02an IN (53)        # &trt_ezn_52.
                              @ trt01an in (9901) AND missing(trt02an)    # &trt_pla_52.
                                ;

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_52_abuse.
  , extend_rule = &extend_rule_disp_52_abuse.
)

%extend_data(
    indat       = adae_view
  , outdat      = adae_ext
  , var         = &extend_var_disp_52_abuse.
  , extend_rule = &extend_rule_disp_52_abuse.
)

%set_titles_footnotes(
    tit1 = "Table: Post-treatment adverse events: number of subjects with adverse events related to abuse potential by primary system organ class and preferred term by integrated analysis treatment group &saf_label."
  , ftn1 = "N = number of subjects. Percentages are calculated relative to the respective treatment group. Subjects may be counted in more than one row."
  , ftn2 = "*Placebo (week 1-52) includes only those participants who received Placebo only. Switchers are only assigned to EZN 120 mg (week 1-52)."
  , ftn3 = "For abuse potential, post-treatment adverse events are all adverse events with an onset after the last study drug intake date. Events are assigned to the study drug the participant received last."
  , ftn4 = "Adverse events (AEs) are sorted by alphabetical order of the MedDRA classification."
  , ftn5 = "A subject is counted only once within each primary SOC and preferred term."
  , ftn6 = "Standardised MedDRA Queries (SMQ) terms: Drug abuse and dependence; SMQ Drug withdrawal."
  , ftn7 = "Preferred terms: Euphoric mood; Feeling abnormal; Feeling drunk; Feeling of relaxation; Dizziness; Thinking abnormal; Hallucination; Inappropriate affect; Somnolence; Aggression; Drug tolerance; Psychotic disorder."
  , ftn8 = "High Level Group Term (HLGT): Mood disorders and disturbances NEC."
  , ftn9 = "High Level Term (HLT): Confusion and disorientation; Substance related and addictive disorders."
)

%incidence_print(
    data              = adae_ext(WHERE=(not missing(trtedt) and astdt > trtedt))
  , data_n            = adsl_ext
  , var               = aebodsys aedecod
  , triggercond       = not missing(aedecod)
  , sortorder         = alpha
  , evlabel           = &evlabel.
  , anytxt            = &anytxt.
  , outdat            = out_inc
)

DATA out_inc;
    SET out_inc;
    ATTRIB _col_02 LABEL = "%varlabel(out_inc, _col_02)*";
RUN;

%mosto_param_from_dat(data = out_incinp, var = config)
%datalist(&config)


%endprog;