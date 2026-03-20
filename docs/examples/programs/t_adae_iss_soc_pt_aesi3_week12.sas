/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adae_iss_soc_pt_aesi3_week12);
/*
 * Purpose          : Treatment-emergent adverse events of special interest (phototoxicity) up to week 12: number of subjects by primary system organ class and preferred term by integrated analysis treatment group (safety analysis set)
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : erjli (Yosia Hadisusanto) / date: 18MAR2024
 * Reference prog   : /var/swan/root/bhc/3427080/ia/stat/main001/dev/analysis/pgms/t_adae_iss_soc_pt_aesi1_week12.sas
 ******************************************************************************/

%let mosto_param_class = %scan(&extend_var_disp_12_nt_a., 1, '@');

%load_ads_dat(adsl_view, adsDomain = adsl, where     = &saf_cond.)
%load_ads_dat(adae_view, adsDomain = adae, adslWhere = &saf_cond., where = trtemfl = 'Y')

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

%MACRO call_inc_print(where=, title=, ftn=);

    %set_titles_footnotes(
        tit1 = "Table: &title.: number of subjects by primary system organ class and preferred term by integrated analysis treatment group &saf_label."
      , ftn1 = "Adverse events (AEs) are sorted by alphabetical order of the MedDRA classification."
      , ftn2 = "A subject is counted only once within each primary SOC and preferred term."
      , ftn3 = "The preferred terms within the AESI with 0 events were not included in the table."
      , ftn4 = "N =number of subjects. Percentages are calculated relative to the respective treatment group. Subjects may be counted in more than one row."
      , ftn5 = "&ftn."
      , ftn7 = "AESI= Adverse Events of Special Interest."
    )

    %incidence_print(
        data        = adae_ext(WHERE=(&where.))
      , data_n      = adsl_ext
      , var         = aebodsys aedecod
      , triggercond = not missing(aedecod)
      , sortorder   = alpha
      , evlabel     = &evlabel.
      , anytxt      = &anytxt.
    )

%MEND;

%call_inc_print(
    where = not missing(CQ03CD)
  , title = Treatment-emergent adverse events of special interest - phototoxicity up to week 12
  , ftn  =  %str(AEs in this table are identified using Bayer MedDRA Queries (BMQ) as described in IA Safety SAP.)
)


%endprog;