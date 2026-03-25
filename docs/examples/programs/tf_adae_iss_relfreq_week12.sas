/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = tf_adae_iss_relfreq_week12);
/*
 * Purpose          : Treatment-emergent adverse events with a relative frequency of at least 2% in any group up to week 12: number of subjects by preferred term and integrated analysis treatment group (safety analysis set)
 *                    Figure: Risk difference of treatment-emergent adverse events with a relative frequency of at least 2% in any group up to week 12 (safety analysis set)
 *                    Figure: Risk ratio of treatment-emergent adverse events with a relative frequency of at least 2% in any group up to week 12 (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : erjli (Yosia Hadisusanto) / date: 11JUL2023
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : gltlk (Rui Zeng) / date: 13JUL2023
 * Reason           : add figures codes
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 30NOV2023
 * Reason           : Update headers
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 04APR2024
 * Reason           : Use pvalue6.4 format for the plot
 *                    Remove ** after the RD (95%CI) for the plot
 ******************************************************************************/
/* Changed by       : eqczz (Petri Pulkkinen) / date: 05APR2024
 * Reason           : Use RR and RD footnote from start.sas
 ******************************************************************************/

%let mosto_param_class = %scan(&extend_var_disp_12_nt_a., 1, '@');

%load_ads_dat(adsl_view, adsDomain = adsl,   where = &saf_cond.);
%load_ads_dat(adae_view, adsDomain = adae, adslwhere=&saf_cond., where = trtemfl = 'Y');

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_12_nt_a.
  , extend_rule = &extend_rule_disp_12_nt_a.
);

%extend_data(
    indat       = adae_view
  , outdat      = adae_ext
  , var         = &extend_var_disp_12_nt_a.
  , extend_rule = (trt01an in (53)   and aphase = 'Week 1-12') # &trt_ezn_12.
                @ (trt01an in (9901) and aphase = 'Week 1-12') # &trt_pla_12.
);

** Relative frequency of at least 2% in any group ;
%LET threshold = 2;

%incidence_print(
    data        = adae_ext
  , data_n      = adsl_ext
  , var         = aedecod
  , triggercond = aedecod ne " "
  , sumcount    = NO
  , threshold   = &threshold.
  , sortorder   = freqa
  , frqvar      = 1
  , evlabel     = Preferred term# MedDRA version &v_meddra.
  , outdat      = ae_pt
)

%m_wrap_risk_difference(
    indat          = ae_pt
  , indat_adsl     = adsl_ext
  , m_all_subjects = inc_pat
  , active         = &trt_ezn_12.
  , compare        = &trt_pla_12.
  , zero_exclusion = YES
  , het_p_display  = YES
  , risk_ratio     = YES
  , outdat         = ae_pt_riskdiff
)

DATA ae_pt_riskdiff;
    SET ae_pt_riskdiff;
    ATTRIB aedecod LENGTH=$%varlen(adae_ext, aedecod);
    aedecod  = _ic_var1;
RUN;

** Calculate the new double False Discovery Rate (dFDR) for rd_probz and append to rd_ci: * if dFDR p-value < 0.05 and ** if dFDR p-value < 0.01;
%m_dfdr(
    input_ds  = ae_pt_riskdiff
  , soc_ds    = adae_ext
  , probz     = rd_probz
  , alpha1    = 0.05
  , alpha2    = 0.01
  , var       = rd_ci
  , output_ds = ae_pt_riskdiff_dfdr_rd
);

** Calculate the new double False Discovery Rate (dFDR) for rr_probz and append to rr_ci: * if dFDR p-value < 0.05 and ** if dFDR p-value < 0.01;
%m_dfdr(
    input_ds  = ae_pt_riskdiff_dfdr_rd
  , soc_ds    = adae_ext
  , probz     = rr_probz
  , alpha1    = 0.05
  , alpha2    = 0.01
  , var       = rr_ci
  , output_ds = ae_pt_riskdiff_dfdr_rd_rr
);

%set_titles_footnotes(
    tit1 = "Table: Treatment-emergent adverse events with a relative frequency of at least &threshold.% in any group up to week 12: number of subjects by preferred term and integrated analysis treatment group &saf_label."
  , ftn1 = "Preferred terms are sorted by frequency in descending order in treatment group EZN 120 mg (week 1-12)."
  , ftn2 = "(a) Mantel-Haenszel risk difference between EZN 120 mg (week 1-12) and Placebo (week 1-12) stratified by study and p-value of heterogeneity between studies based on Mantel-Haenszel Q-statistic."
  , ftn3 = "(b) Mantel-Haenszel risk ratio between EZN 120 mg (week 1-12) and Placebo (week 1-12) stratified by study and p-value of heterogeneity between studies based on Mantel-Haenszel Q-statistic."
  , ftn4 = "For the risk ratio, a treatment-arm-size adjusted zero cell correction with zero term = 0.5 was applied."
  , ftn5 = "If the number of subjects with an event is zero in both treatment groups in one study, that study will be excluded from the calculation of risk difference, risk ratio and p-values for heterogeneity."
  , ftn6 = "For multiplicity adjustment the new double False Discovery Rate (dFDR) method (D.V. Mehrotra and A.J. Adewale 2011) is applied to stratified two-sided p-values using z-scores."
  , ftn7 = "* indicates a dFDR p-value < 0.05, ** indicates a dFDR p-value < 0.01."
  , ftn8 = "CI = Confidence Interval, N = number of subjects. Percentages are calculated relative to the respective treatment group. Subjects may be counted in more than one row."
  , ftn9 = "&foot_rr_min5."
)

DATA ae_pt_riskdiffinp;
    SET ae_pt_riskdiffinp;
    IF keyword = 'DATA' THEN value = 'ae_pt_riskdiff_dfdr_rd_rr';
RUN;

%mosto_param_from_dat(data = ae_pt_riskdiffinp, var = config)
%datalist(&config)

*****************************************************;
*Figure: Double dot plot showing proportions of subjects with AEs;
*****************************************************;
data adsl_ext;
    set adsl_ext;
    attrib &mosto_param_class. FORMAT = _trtgrp.;
RUN;

*Dot plot dataset;
DATA dplot;
    SET ae_pt_riskdiff_dfdr_rd_rr;
    LABEL pct1 = "n (%)"
          pct2 = "n (%)";
    LENGTH pct1 pct2 $200.;

    pct1 = strip(scan(_col_01, 1, "N"));
    pct2 = strip(scan(_col_02, 1, "N"));

    ATTRIB percent FORMAT = 5.1 LABEL="Percent";

    &mosto_param_class. = &trt_ezn_12.;
    percent = input(scan(compress(pct1, "<)% "), 2, "("), best.);
    OUTPUT;
    &mosto_param_class. = &trt_pla_12.;
    percent = input(scan(compress(pct2, "<)% "), 2, "("), best.);
    OUTPUT;
RUN;

%let gral_width = 8.75in;

%MACRO dotplot_risk(effect =, tit=, ftn=);
PROC SORT DATA = dplot OUT=dplot_&effect.;
    BY descending &effect. aedecod &mosto_param_class.;
RUN;

DATA dplot_&effect.2;
    SET dplot_&effect.;
    BY descending &effect. aedecod;
    RETAIN group;

    IF _N_ = 1 THEN group = 0;
    IF FIRST.aedecod THEN group = group + 1;
    page = ceil(group/30);

    ** The "**" after the RD (95%CI) is not needed in this graph. This only refers to the tables for common AEs.;
    rd_ci = TRANWRD(rd_ci,'*', '');
    rr_ci = TRANWRD(rr_ci,'*', '');

    format &effect. percent 6.0;
    FORMAT &effect._ci_dfdr_p_val pvalue6.4;
RUN;

**set titles and footnotes, create output;
%local l_linesize;
%let l_linesize = %sysfunc(getoption(linesize, keyword));
option linesize=255;
%set_titles_footnotes(
    tit1 = "Figure: Risk &tit. of treatment-emergent adverse events with a relative frequency of at least &threshold.% in any group up to week 12 &saf_label."
  , ftn1 = "Mantel-Haenszel estimates stratified by study for the risk &tit. are displayed."
  , ftn2 = "For multiplicity adjustment the new double False Discovery Rate method is applied to stratified two-sided p-values using z-scores."
  , ftn3 = "&ftn."
  , ftn4 = "If the number of subjects with event is zero in both treatment groups in one study, that study will be excluded from the calculation of risk &tit.."
  , ftn5 = "The plot is sorted by risk &tit. in descending order."
)
option &l_linesize;

%DotPlot(
     data          = dplot_&effect.2
   , data_n        = adsl_ext
   , SUBJECT       = studyid usubjid
   , by            = page
   , data_n_ignore = page
   , xvar          = percent
   , x2var         = &effect.
   , lower_error   = &effect._LowerCL
   , upper_error   = &effect._UpperCL
   , show_x2       = YES
   %IF %upcase(&effect.) = RR %THEN %DO;
   , x2type        = LOG
   , X2REFLINE     = 1
   , xticklist     = 0 1 2 3 4 5 6 7 8 9 10     /*may update when data final*/
   %END;
   %ELSE %IF %upcase(&effect.) = RD %THEN %DO;
   , x2type        = LIN
   , X2REFLINE     = 0
   , xticklist     = 0 1 2 3 4 5 6 7 8         /*may update when data final*/
   , x2ticklist    = -6 -4 -2 0 2 4 6          /*may update when data final*/
   %END;
   , class         = &mosto_param_class.
   , class_data    = adsl_ext
   , subgroup      = aedecod
   , subgroup_by_order = DATA
   , header_type   = STANDARD
   %IF %upcase(&effect) = RD %THEN %DO;
      , column_headers = EZN 120 mg|(week 1-12)| n (%) # Placebo|(week 1-12)| n (%) # Percent # Risk &tit.| (%)(95% CI) # Risk &tit.| (%)(95% CI) # P-value
   %END;
   %ELSE %DO;
      , column_headers = EZN 120 mg|(week 1-12)| n (%) # Placebo|(week 1-12)| n (%) # Percent # Risk &tit.|(95% CI) # Risk &tit.|(95% CI) # P-value
   %END;
   , columns       = pct1 pct2 <figure> &effect._ci <x2_figure> &effect._ci_dfdr_p_val
   , columnweights = 0.24 0.12 0.12 0.205 0.11 0.15 0.055
   , overall       = 'Overall'
   , style         = presentation
   , dotsymbol     = CircleFilled Circle
   , legend        = YES BIG_N
   , yoffset       = 0.05
   , filename      = &prog._dotplot_&effect._$page$
 );

%MEND dotplot_risk;

%dotplot_risk(effect = rd, tit = difference);
%dotplot_risk(effect = rr, tit = ratio, ftn=%str(For the risk ratio, a treatment-arm-size adjusted zero cell correction with zero term = 0.5 was applied.));

%symdel gral_width;

%endprog;