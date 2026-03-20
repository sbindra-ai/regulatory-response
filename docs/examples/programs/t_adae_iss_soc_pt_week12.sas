/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adae_iss_soc_pt_week12);
/*
 * Purpose          : Treatment-emergent adverse events up to week 12: number of subjects by primary system organ class and preferred term by integrated analysis treatment group (safety analysis set)
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
/* Changed by       : erjli (Yosia Hadisusanto) / date: 12MAR2024
 * Reason           : Re-ordering tables
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 04APR2024
 * Reason           : Set together = to be missing, so that next SOC PT continue on the same page
 ******************************************************************************/
/* Changed by       : eqczz (Petri Pulkkinen) / date: 05APR2024
 * Reason           : Use footnote from start.sas
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

**create numeric variable for ordering of AEOUT;
DATA adae_ext;
    SET adae_ext;
    IF missing(aeout) THEN aeout= 'missing';
    SELECT(aeout);
        WHEN('missing')                           aeoutn = 0;
        WHEN('UNKNOWN')                           aeoutn = 1;
        WHEN('RECOVERED/RESOLVED')                aeoutn = 2;
        WHEN('RECOVERING/RESOLVING')              aeoutn = 3;
        WHEN('RECOVERED/RESOLVED WITH SEQUELAE')  aeoutn = 4;
        WHEN('NOT RECOVERED/NOT RESOLVED')        aeoutn = 5;
        WHEN('FATAL')                             aeoutn = 6;
        OTHERWISE PUT 'ERROR: Term for outcome is unknown. Please check. ' usubjid= aeseq= aeout=;
    END;
RUN;

**create format for ordering of AEOUT;
PROC SQL NOPRINT;
    CREATE TABLE aeoutn_format AS SELECT DISTINCT "AEOUTN" AS fmtname, aeoutn AS start, propcase(aeout, '') AS label FROM adae_ext;
QUIT;

PROC FORMAT CNTLIN=aeoutn_format; RUN;

PROC DATASETS LIB=work MEMTYPE=data;
   MODIFY adae_ext;
   ATTRIB aeoutn FORMAT=aeoutn. LABEL="%scan(%varlabel(adae_view,aeout),1,'/')";
QUIT;


%MACRO call_inc_print(where=, title=, riskdiff=, ftn=);

    %incidence_print(
        data        = adae_ext(WHERE=(&where.))
      , data_n      = adsl_ext
      , var         = aebodsys aedecod
      , triggercond = not missing(aedecod)
      , sortorder   = alpha
      , evlabel     = &evlabel.
      , together    =
      , anytxt      = &anytxt.
      , outdat      = ae_soc_pt
    )

    %IF &riskdiff. = 1 %THEN %DO;

        %set_titles_footnotes(
            tit1 = "Table: &title.: number of subjects by primary system organ class and preferred term by integrated analysis treatment group &saf_label."
          , ftn1 = "Adverse events (AEs) are sorted by alphabetical order of the MedDRA classification."
          , ftn2 = "A subject is counted only once within each primary SOC and preferred term."
          , ftn3 = "(a) Mantel-Haenszel risk difference between EZN 120 mg (week 1-12) and Placebo (week 1-12) stratified by study and p-value of heterogeneity between studies based on Mantel-Haenszel Q-statistic."
          , ftn4 = "(b) Mantel-Haenszel risk ratio between EZN 120 mg (week 1-12) and Placebo (week 1-12) stratified by study and p-value of heterogeneity between studies based on Mantel-Haenszel Q-statistic."
          , ftn5 = "For the risk ratio, a treatment-arm-size adjusted zero cell correction with zero term = 0.5 was applied."
          , ftn6 = "If the number of subjects with an event is zero in both treatment groups in one study, that study will be excluded from the calculation of risk difference, risk ratio and p-values for heterogeneity."
          , ftn7 = "CI = Confidence Interval, N = number of subjects. Percentages are calculated relative to the respective treatment group. Subjects may be counted in more than one row."
          , ftn8 = "&foot_rr_min5."
        )

        ** Risk difference between EZN 120 mg (week 1-12) and Placebo (week 1-12) is stratified by study using Mantel-Haenszel test.: active = &trt_ezn_12., compare = &trt_pla_12.;
        ** For the risk ratio, a treatment-arm-size adjusted zero cell correction with zero term = 0.5 was applied.: Default values: correction_type = stratum_size, zero_term = 0.5;
        ** If the number of subjects with an event is zero in both treatment groups in one study, that study will be excluded from the calculation of risk difference, risk ratio and p-values for heterogeneity: zero_exclusion = YES;
        %m_wrap_risk_difference(
            indat          = ae_soc_pt
          , indat_adsl     = adsl_ext
          , m_all_subjects = inc_pat
          , active         = &trt_ezn_12.
          , compare        = &trt_pla_12.
          , zero_exclusion = YES
          , het_p_display  = YES
          , risk_ratio     = YES
        )
    %END;
    %ELSE %DO;

        %set_titles_footnotes(
            tit1 = "Table: &title.: number of subjects by primary system organ class and preferred term by integrated analysis treatment group &saf_label."
          , ftn1 = "Adverse events (AEs) are sorted by alphabetical order of the MedDRA classification."
          , ftn2 = "A subject is counted only once within each primary SOC and preferred term."
          , ftn3 = "N = number of subjects. Percentages are calculated relative to the respective treatment group. Subjects may be counted in more than one row."
        )

        %mosto_param_from_dat(data = ae_soc_ptinp, var = config)
        %datalist(&config)
    %END;

%MEND;

%call_inc_print(
    where    = 1=1
  , title    = Treatment-emergent adverse events up to week 12
  , riskdiff = 1
)

%set_titles_footnotes(
    tit1 = "Table: Treatment-emergent adverse events up to week 12 by maximum intensity: number of subjects by primary system organ class and preferred term by integrated analysis treatment group &saf_label."
  , ftn1 = "Only the most severe intensity is counted for multiple occurrences of the same adverse event in one individual."
  , ftn2 = "'Missing' is considered to be the lowest category of intensity."
  , ftn3 = "Adverse events are sorted by alphabetical order of the MedDRA classification."
  , ftn4 = "A subject is counted only once within each primary SOC and preferred term."
)

%incidence_print(
    data        = adae_ext
  , data_n      = adsl_ext
  , var         = aebodsys aedecod
  , categor     = asevn
  , triggercond = not missing(aeterm)
  , misstext    = Missing
  , sortorder   = alpha
  , evlabel     = &evlabel.
  , anytxt      = &anytxt.
)

%set_titles_footnotes(
    tit1 = "Table: Treatment-emergent adverse events up to week 12 by worst outcome: number of subjects by primary system organ class and preferred term by integrated analysis treatment group &saf_label."
  , ftn1 = "Only the worst outcome is counted for multiple occurrences of the same adverse event in one individual."
  , ftn2 = "Adverse events are sorted by alphabetical order of the MedDRA classification."
  , ftn3 = "A subject is counted only once within each primary SOC and preferred term."
)

%incidence_print(
    data        = adae_ext
  , data_n      = adsl_ext
  , var         = aebodsys aedecod
  , categor     = aeoutn
  , triggercond = not missing(aeterm)
  , misstext    = Missing
  , sortorder   = alpha
  , evlabel     = &evlabel.
  , anytxt      = &anytxt.
  , maxcattxt   = Worst
)


%call_inc_print(
    where = aerel = 'Y'
  , title = Treatment-emergent study drug-related adverse events up to week 12
)

%set_titles_footnotes(
    tit1 = "Table: Treatment-emergent study drug-related adverse events up to week 12 by maximum intensity: number of subjects by primary system organ class and preferred term by integrated analysis treatment group &saf_label."
  , ftn1 = "Only the most severe intensity is counted for multiple occurrences of the same adverse event in one individual."
  , ftn2 = "'Missing' is considered to be the lowest category of intensity."
  , ftn3 = "Adverse events are sorted by alphabetical order of the MedDRA classification."
  , ftn4 = "A subject is counted only once within each primary SOC and preferred term."
)

%incidence_print(
    data        = adae_ext(WHERE=(aerel = 'Y'))
  , data_n      = adsl_ext
  , var         = aebodsys aedecod
  , categor     = asevn
  , triggercond = not missing(aeterm)
  , misstext    = Missing
  , sortorder   = alpha
  , evlabel     = &evlabel.
  , anytxt      = &anytxt.
)

%set_titles_footnotes(
    tit1 = "Table: Treatment-emergent adverse events up to week 12: number of subjects with reported events under the SMQ accidents and injuries by preferred term and integrated analysis treatment group &saf_label."
  , ftn1 = "N = number of subjects. Percentages are calculated relative to the respective treatment group. Subjects may be counted in more than one row."
  , ftn2 = "Adverse events (AEs) are sorted by alphabetical order of the MedDRA classification."
  , ftn3 = "Standardised MedDRA Queries (SMQ) terms: accidents and injuries."
)

%incidence_print(
    data        = adae_ext(WHERE=(cq06cd = 6)) %** Z_CQNAM.6 [Accidents and injuries];
  , data_n      = adsl_ext
  , var         = aedecod
  , triggercond = not missing(aedecod)
  , sortorder   = alpha
  , evlabel     = Preferred Term#   MedDRA Version &v_meddra.
  , anytxt      = &anytxt.
)

%call_inc_print(
    where    = aeser = 'Y'
  , title    = Treatment-emergent serious adverse events up to week 12
  , riskdiff = 1
)

%call_inc_print(
    where = aerel = 'Y' and aeser = 'Y'
  , title = Treatment-emergent study drug-related serious adverse events up to week 12
)

%call_inc_print(
    where = aesdth = 'Y'
  , title = Treatment-emergent adverse events with fatal outcome up to week 12
)

%call_inc_print(
    where    = aeacn = 'DRUG WITHDRAWN'
  , title    = Treatment-emergent adverse events resulting in discontinuation of study drug up to week 12
  , riskdiff = 1
)

%call_inc_print(
    where = aerel = 'Y' and aeacn = 'DRUG WITHDRAWN'
  , title = Treatment-emergent study drug-related adverse events resulting in discontinuation of study drug up to week 12
)

%call_inc_print(
    where    = aeser = 'Y' and aeacn = 'DRUG WITHDRAWN'
  , title    = Treatment-emergent serious adverse events resulting in discontinuation of study drug up to week 12
  , riskdiff = 1
)

%endprog;