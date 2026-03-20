/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adae_iss_het_week12);
/*
 * Purpose          : Custom table: Treatment-emergent adverse events with heterogeneous treatment effects between studies up to week 12: number of subjects by preferred term and study by integrated analysis treatment group (safety analysis set)
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
/* Changed by       : erjli (Yosia Hadisusanto) / date: 04APR2024
 * Reason           : Adjust footnote
 ******************************************************************************/
/* Changed by       : eqczz (Petri Pulkkinen) / date: 05APR2024
 * Reason           : Use footnote from start.sas
 ******************************************************************************/


%LET mosto_param_class = %scan(&extend_var_disp_12_nt_a., 1, '@');

%load_ads_dat(adsl_view, adsDomain = adsl,     where=&saf_cond.);
%load_ads_dat(adae_view, adsDomain = adae, adslwhere=&saf_cond., where = trtemfl = 'Y');

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext(DROP=extend_cond)
  , var         = &extend_var_disp_12_nt_a.
  , extend_rule = &extend_rule_disp_12_nt_a.
);

%extend_data(
    indat       = adae_view
  , outdat      = adae_ext(DROP=extend_cond)
  , var         = &extend_var_disp_12_nt_a.
  , extend_rule = (trt01an in (53)   and aphase = 'Week 1-12') # &trt_ezn_12.
                @ (trt01an in (9901) and aphase = 'Week 1-12') # &trt_pla_12.
);

** Extend studyid = 'Pool';
%extend_data(indat = adae_ext, outdat = adae_pool, subj_var = usubjid_ori, var = studyid, extend_rule = _ALL_ @ _ALL_ # 'Pool')
%extend_data(indat = adsl_ext, outdat = adsl_pool, subj_var = usubjid_ori, var = studyid, extend_rule = _ALL_ @ _ALL_ # 'Pool')

%MACRO call_inc_print(where=1=1, title=Treatment-emergent adverse events with heterogeneous treatment effects between studies up to week 12);

    %incidence_print(
        data        = adae_pool(WHERE=(&where.))
      , data_n      = adsl_pool
      , subject     = usubjid
      , by          = studyid
      , var         = aedecod
      , outpat      = inc_pat_pool
      , triggercond = not missing(aedecod)
      , sumcount    = NO
      , sortorder   = alpha
      , evlabel     = Preferred Term#   MedDRA Version &v_meddra.
      , outdat      = ae_pt_inc_pool
    );

    ** Calculate for pool;
    %m_wrap_risk_difference(
        indat          = ae_pt_inc_pool(WHERE=(studyid IN ('Pool')))
      , indat_adsl     = adsl_ext
      , m_all_subjects = inc_pat_pool(WHERE=(studyid NE 'Pool'))
      , active         = &trt_ezn_12.
      , compare        = &trt_pla_12.
      , zero_exclusion = YES
      , het_p_display  = YES
      , risk_ratio     = YES
      , outdat         = ae_pt_riskdiff_pool
    )

    ** Calculate for studies;
    %m_wrap_risk_difference(
        indat          = ae_pt_inc_pool(WHERE=(studyid NOT IN ('Pool' '')))
      , indat_adsl     = adsl_ext
      , m_all_subjects = inc_pat_pool(WHERE=(studyid NE 'Pool'))
      , active         = &trt_ezn_12.
      , compare        = &trt_pla_12.
      , stratum_type   = study
      , risk_ratio     = YES
      , outdat         = ae_pt_riskdiff_study
    )

    ** Stack pool and studies;
    DATA ae_pt_riskdiff_total;
        SET ae_pt_riskdiff_pool
            ae_pt_riskdiff_study
            ;
    RUN;

    ** Only Preferred Terms with heterogeneity p-value for Risk Difference or Risk Ratio <0.05 are presented.;
    DATA pt_presented(KEEP=_ic_var1 het_p_value_under_005);
        SET ae_pt_riskdiff_pool(WHERE=(NOT missing(_ic_var1) AND (.Z < rd_het_p < 0.05 OR .Z < rr_het_p < 0.05)));
        ATTRIB het_p_value_under_005 LABEL = "Heterogeneity p-value for Risk Difference or Risk Ratio <0.05";
        het_p_value_under_005 = 1;
    RUN;

    %mergeDat(baseDat = ae_pt_riskdiff_total, keyDat = pt_presented, by = _ic_var1)

    %set_titles_footnotes(
        tit1 = "Table: &title.: number of subjects by preferred term and study by integrated analysis treatment group &saf_label."
      , ftn1 = "Only Preferred Terms with heterogeneity p-value for Risk Difference or Risk Ratio <0.05 are presented."
      , ftn2 = "(a) For the Pool: Mantel-Haenszel risk difference between EZN 120 mg (week 1-12) and Placebo (week 1-12) stratified by study and p-value of heterogeneity between studies based on Mantel-Haenszel Q statistic. For by study results: Wald confidence intervals are calculated."
      , ftn3 = "(b) For the Pool: Mantel-Haenszel risk ratio between EZN 120 mg (week 1-12) and Placebo (week 1-12) stratified by study and p-value of heterogeneity between studies based on Mantel-Haenszel Q statistic. For by study results: Wald confidence intervals are calculated."
      , ftn4 = "For the risk ratio, a treatment-arm-size adjusted zero cell correction with zero term = 0.5 was applied."
      , ftn5 = "CI = Confidence Interval, N = number of subjects. Percentages are calculated relative to the respective treatment group. Subjects may be counted in more than one row."
      , ftn6 = "&foot_rr_min5."
      , ftn7 = "Preferred terms are sorted alphabetically. 21686 = SWITCH-1, 21651 = OASIS 1, 21652 = OASIS 2, 21810 = OASIS 3."
    )

    %LET l_miss = %sysfunc(getoption(missing));
    OPTIONS MISSING='';

    %datalist(
        data     = ae_pt_riskdiff_total(WHERE=(het_p_value_under_005 = 1))
      , by       = _levtxt studyid
      , var      = _col_01 _col_02 ('Risk Difference (a)' rd_ci rd_het_p) ('Risk Ratio (b)' rr_ci rr_het_p)
      , ncolumn1 = _col_01 _col_02
      , freeline = _levtxt
      , together = _levtxt
    )

    OPTION MISSING="&l_miss.";
%MEND;

%call_inc_print()

%call_inc_print(
    where = aeser = 'Y'
  , title = Treatment-emergent serious adverse events with heterogeneous treatment effects between studies up to week 12
)

%call_inc_print(
    where = aeacn = 'DRUG WITHDRAWN'
  , title = Treatment-emergent adverse events resulting in discontinuation of study drug with heterogeneous treatment effects between studies up to week 12
)

%call_inc_print(
    where = aeser = 'Y' and aeacn = 'DRUG WITHDRAWN'
  , title = Treatment-emergent serious adverse events resulting in discontinuation of study drug with heterogeneous treatment effects between studies up to week 12
)


%endprog;