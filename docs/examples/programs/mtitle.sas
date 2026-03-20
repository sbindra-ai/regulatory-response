%MACRO mtitle(tableno=1)
/ DES = 'Create titles and footnotes for the study';
/*******************************************************************************
 * Bayer Healthcare
 * Macro rely on: pure SAS
 *******************************************************************************
 * Purpose        : Create titles and footnotes for the study
 * Parameters     :
 *                :
 * Validation Level : 1
 * SAS Version    : HP-UX 9.2
 *******************************************************************************
 * Preconditions  :
 *     Macrovar. needed:
 *     Datasets  needed:
 *     Ext.Prg/Mac used:
 * Postconditions :
 *     Macrovar created:
 *     Output   created:
 *     Datasets created:
 * Comments       :
 ******************************************************************************
 * Author(s)        : erjli (Yosia Hadisusanto) / date: 02JAN2024
 * Reference prog   : /var/swan/root/bhc/3427080/21651/stat/main01/prod/analysis/macros/mtitle.sas
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 16FEB2024
 * Reason           : Update footnotes for IA
 ******************************************************************************/


%LOCAL macro mversion _starttime macro_parameter_error;
%LET macro    = &sysmacroname.;
%LET mversion = 1.0;

%LET _starttime = %SYSFUNC(floor(%SYSFUNC(datetime())));
%PUT - &macro.: Version &mversion started %SYSFUNC(date(),worddate.) %SYSFUNC(time(),hhmm.);

%LOCAL l_opts l_notes;
%LET l_notes = %SYSFUNC(getoption(notes,keyword));

%LET l_opts = %SYSFUNC(getoption(source,keyword))
              %SYSFUNC(getoption(notes,keyword))
              %SYSFUNC(getoption(fmterr,keyword));

OPTIONS NONOTES NOSOURCE NOFMTERR;
title;
footnote;

ods escapechar="^";

/* 8.2 Efficacy */
%IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_1_1_1_hfss_mhf_s) AND &tableno = 1 %THEN %DO;
    title1 "Table: $&param.$: summary statistics and change from baseline by treatment group";
    title2 "<cont> &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'In case data was missing for more than 2 days within a week, the value for that particular week was set to missing.';
    footnote3 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote4 'SD = Standard Deviation.' ;
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_1_1_1_hfss_mhf_p) AND &tableno = 1 %THEN %DO;
    title1 "Table: $&param.$: summary statistics and relative change (%) from baseline";
    title2 "<cont>by treatment group &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'In case data was missing for more than 2 days within a week, the value for that particular week was set to missing.';
    footnote3 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote4 'SD = Standard Deviation.' ;
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_1_2_1_hfss_shf_s) AND &tableno = 1 %THEN %DO;
    title1 "Table: $&param.$: summary statistics and change from baseline by treatment group";
    title2 "<cont> &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'In case data was missing for more than 2 days within a week, the value for that particular week was set to missing.';
    footnote3 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote4 'SD = Standard Deviation.' ;
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_1_2_1_hfss_shf_p) AND &tableno = 1 %THEN %DO;
    title1 "Table: $&param.$: summary statistics and relative change (%) from baseline";
    title2 "<cont>by treatment group &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'In case data was missing for more than 2 days within a week, the value for that particular week was set to missing.';
    footnote3 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote4 'SD = Standard Deviation.' ;
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_1_3_1_adqs_ts_s) AND &tableno = 1 %THEN %DO;
    title1 "Table: PROMIS SD SF 8b total T-score: summary statistics and change from baseline by treatment group";
    title2 "<cont> &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'Total score converted as T-score.';
    footnote3 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote4 'SD = Standard Deviation.' ;
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_1_3_1_adqs_trs_s) AND &tableno = 1 %THEN %DO;
    title1 "Table: PROMIS SD SF 8b total raw score: summary statistics and change from baseline by treatment group ";
    title2 "<cont> &fas_label";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'SD = Standard Deviation.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_1_3_1_adqs_rs_f) AND &tableno = 1 %THEN %DO;
    title1 "Table: PROMIS SD SF 8b raw item score: number of subjects by treatment group &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_1_4_1_adqs_ms_s) AND &tableno = 1 %THEN %DO;
    title1 "Table: MENQOL total score: summary statistics and change from baseline by treatment group";
    title2 "<cont> &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'SD = Standard Deviation.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_2_adqs_bdi_s) AND &tableno = 1 %THEN %DO;
    title1 "Table: BDI-II total score: summary statistics and change from baseline by treatment group &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'SD = Standard Deviation.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_2_adqs_bdi_t) AND &tableno = 1 %THEN %DO;
    title1 "Table: Transitions from baseline by time in BDI-II-total-score: number of subjects &fas_label";
    footnote1 'Only subjects with valid values at both baseline and after start of treatment are included.' ;
    footnote2 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote3 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote4 &idfoot ;
%END;


/*<------------------------------------------>*
*Figures Title and footnotes*
*<------------------------------------------>*/

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_1_1_hfss_mhf_s) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Line plot of change from baseline in mean daily frequency of moderate to severe hot flashes by treatment group &fas_label. ";
    footnote1  "Placebo  - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'CI = Confidence Interval.';
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_1_1_hfss_mhf_p) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Line plot of relative change (%) from baseline in mean daily frequency of moderate to severe hot flashes by treatment group &fas_label. ";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'CI = Confidence Interval.';
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_2_1_hfss_shf_s) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Line plot of change from baseline in mean daily severity of moderate to severe hot flashes by treatment group &fas_label. ";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'CI = Confidence Interval.';
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_2_1_hfss_shf_p) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Line plot of relative change (%) from baseline in mean daily severity of moderate to severe hot flashes by treatment group &fas_label. ";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'CI = Confidence Interval.';
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_3_1_adqs_line) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Line plot of change from baseline in PROMIS SD SF 8b total T-score by treatment group &fas_label. ";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'CI = Confidence Interval.';
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_3_1_adqs_rbar) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Bar chart illustrating PROMIS SD SF 8b raw score of item $paramcd$ by treatment group over time &fas_label. ";

  footnote1'E=Elinzanetant 120 mg.';
  footnote2 'P-E=Placebo for 12 weeks followed by Elinzanetant 120mg for 14 weeks.';
  footnote3 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
  footnote4 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_4_1_adqs_line) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Line plot of change from baseline in MENQOL total score by treatment group &fas_label. ";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'CI = Confidence Interval.';
    footnote4 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_3_1_adqs_cum) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Cumulative percent of subjects by change from baseline in PROMIS SD SF 8b total T-score at $avisitn$ &fas_label. ";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
    footnote2 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_4_1_adqs_cum) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Cumulative percent of subjects by change from baseline in MENQOL total score at $avisitn$ &fas_label. ";

    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
    footnote2 &idfoot ;
%END;


/* 8.2 MMRM Efficacy */

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_1_2_hfss_scat ) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Scatterplot of residuals and predicted values from MMRM on change from baseline in mean daily frequency of moderate to severe hot flashes &fas_label";
    footnote1 "Study effect and study*treatment interaction are added for MMRM analysis.";
    footnote2 "MMRM = Mixed Model Repeated Measures.";
    footnote3 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_1_2_hfss_qq) AND &tableno = 1 %THEN %DO;
    title1 "Figure: QQ-plot from MMRM on change from baseline in mean daily frequency of moderate to severe hot flashes &fas_label";
    footnote1 "Study effect and study*treatment interaction are added for MMRM analysis.";
    footnote2 "QQ plot= Quantile-Quantile plot, MMRM= Mixed Model Repeated Measures.";
    footnote3 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(i_8_2_1_1_2_hfss_np) AND &tableno = 1 %THEN %DO;
    title1 "Table: Change from baseline in mean daily frequency of moderate to severe hot flashes - non-parametric analysis - by treatment group &fas_label";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'Study effect is added for ANCOVA analysis.';
    footnote3 'P-value is based on non-parametric rank ANCOVA, n = number of subjects with observed value for this timepoint and considered in the analysis model.';
    footnote4 'SE = Standard Error, CI = Confidence Interval.' ;
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_2_2_shf_scat ) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Scatterplot of residuals and predicted values from MMRM on change from baseline in mean daily severity of moderate to severe hot flashes &fas_label";
    footnote1 "Study effect and study*treatment interaction are added for MMRM analysis.";
    footnote2 "MMRM = Mixed Model Repeated Measures";
    footnote3 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_2_2_shf_qq ) AND &tableno = 1 %THEN %DO;
    title1 "Figure: QQ-Plot from MMRM on change from baseline in mean daily severity of moderate to severe hot flashes &fas_label";
    footnote1 "Study effect and study*treatment interaction are added for MMRM analysis.";
    footnote2 "QQ plot= Quantile-Quantile plot, MMRM= Mixed Model Repeated Measures.";
    footnote3 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_3_2_pr_scat ) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Scatterplot of residuals and predicted values from MMRM on change from baseline in PROMIS SD SF 8b total T-score &fas_label";
    footnote1 "Study effect and study*treatment interaction are added for MMRM analysis.";
    footnote2 "MMRM = Mixed Model Repeated Measures.";
    footnote3 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_3_2_pr_qq ) AND &tableno = 1 %THEN %DO;
    title1 "Figure: QQ-Plot from MMRM on change from baseline in PROMIS SD SF 8b total T-score &fas_label";
    footnote1 "Study effect and study*treatment interaction are added for MMRM analysis.";
    footnote2 "QQ plot= Quantile-Quantile plot, MMRM= Mixed Model Repeated Measures.";
    footnote3 &idfoot ;
%END;




%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_4_2_mq_scat ) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Scatterplot of residuals and predicted values from MMRM on change from baseline in MENQOL total score &fas_label";
    footnote1 "Study effect and study*treatment interaction are added for MMRM analysis.";
    footnote2 "MMRM = Mixed Model Repeated Measures.";
    footnote3 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_4_2_mq_qq ) AND &tableno = 1 %THEN %DO;
    title1 "Figure: QQ-Plot from MMRM on change from baseline in MENQOL total score &fas_label";
    footnote1 "Study effect and study*treatment interaction are added for MMRM analysis.";
    footnote2 "QQ plot= Quantile-Quantile plot, MMRM= Mixed Model Repeated Measures.";
    footnote3 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(i_8_2_1_2_2_shf_np) AND &tableno = 1 %THEN %DO;
    title1 "Table: Change from baseline in mean daily severity of moderate to severe hot flashes - non-parametric analysis - by treatment group &fas_label";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'Study effect is added for ANCOVA analysis.';
    footnote3 'P-value is based on non-parametric rank ANCOVA, n = number of subjects with observed value for this timepoint and considered in the analysis model.';
    footnote4 'SE = Standard Error, CI = Confidence Interval.' ;
    footnote5 &idfoot ;

%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(i_8_2_1_3_2_pr_np) AND &tableno = 1 %THEN %DO;
    title1 "Table: Change from baseline in PROMIS SD SF 8b total T-score - non-parametric analysis - by treatment group &fas_label";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'Study effect is added for ANCOVA analysis.';
    footnote3 'P-value is based on non-parametric rank ANCOVA, n = number of subjects with observed value for this timepoint and considered in the analysis model.';
    footnote4 'SE = Standard Error, CI = Confidence Interval.' ;
    footnote5 &idfoot ;

%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(i_8_2_1_4_2_mq_np) AND &tableno = 1 %THEN %DO;
    title1 "Table: Change from baseline in MENQOL total score - non-parametric analysis - by treatment group &fas_label";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'Study effect is added for ANCOVA analysis.';
    footnote3 'P-value is based on non-parametric rank ANCOVA, n = number of subjects with observed value for this timepoint and considered in the analysis model.';
    footnote4 'SE = Standard Error, CI = Confidence Interval.' ;
    footnote5 &idfoot ;

%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(i_8_2_1_3_1_pr) AND &tableno = 1 %THEN %DO;
    title1 "Table: PROMIS SD SF 8b total T-score change from baseline - MMRM analysis - by treatment group &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'Study effect and study*treatment interaction are added for MMRM analysis.';
    footnote3 'n = number of subjects with observed value for this timepoint and considered in the analysis model.';
    footnote4 'Multiple imputation is used to impute missing values.' ;
    footnote5 'LS-Means = Least Squares Means, SE = Standard Error, MMRM = Mixed Model Repeated Measures, CI = Confidence Interval.' ;
    footnote6 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(i_8_2_1_3_3_pr_sp1) AND &tableno = 1 %THEN %DO;
    title1 "Table: First supplementary estimand - change from baseline in PROMIS SD SF 8b total T-score - MMRM analysis - by treatment group &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'Study effect and study*treatment interaction are added for MMRM analysis.';
    footnote3 'n = number of subjects with observed value for this timepoint and considered in the analysis model.';
    Footnote4 'Pattern mixture modelling using multiple imputation has been used to impute missing values or values discarded due to hypothetical strategy.';
    footnote5 'LS-Means = Least Squares Means, SE = Standard Error, MMRM = Mixed Model Repeated Measures, CI = Confidence Interval.' ;
    footnote6 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(i_8_2_1_3_3_pr_sp2) AND &tableno = 1 %THEN %DO;
    title1 "Table: Second supplementary estimand - change from baseline in PROMIS SD SF 8b total T-score - MMRM analysis - by treatment group &fas_label";
        footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
        footnote2 'Study effect and study*treatment interaction are added for MMRM analysis.';
        footnote3 'n = number of subjects with observed value for this timepoint and considered in the analysis model.';
        Footnote4 'Pattern mixture modelling using multiple imputation has been used to impute missing values or values discarded due to hypothetical strategy.';
        footnote5 'LS-Means = Least Squares Means, SE = Standard Error, MMRM = Mixed Model Repeated Measures, CI = Confidence Interval.' ;
        footnote6 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(i_8_2_1_4_1_mq) AND &tableno = 1 %THEN %DO;
    title1 "Table: MENQOL total score change from baseline - MMRM analysis - by treatment group &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'Study effect and study*treatment interaction are added for MMRM analysis.';
    footnote3 'n = number of subjects with observed value for this timepoint and considered in the analysis model.';
    footnote4 'Multiple imputation is used to impute missing values.' ;
    footnote5 'LS-Means = Least Squares Means, SE = Standard Error, MMRM = Mixed Model Repeated Measures, CI = Confidence Interval.' ;
    footnote6 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(i_8_2_1_4_3_mq_sp1) AND &tableno = 1 %THEN %DO;
    title1 "Table: First supplementary estimand - change from baseline in MENQOL total score - MMRM analysis - by treatment group &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'Study effect and study*treatment interaction are added for MMRM analysis.';
    footnote3 'n = number of subjects with observed value for this timepoint and considered in the analysis model.';
    Footnote4 'Pattern mixture modelling using multiple imputation has been used to impute missing values or values discarded due to hypothetical strategy.';
    footnote5 'LS-Means = Least Squares Means, SE = Standard Error, MMRM = Mixed Model Repeated Measures, CI = Confidence Interval.' ;
    footnote6 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(i_8_2_1_4_3_mq_sp2) AND &tableno = 1 %THEN %DO;
    title1 "Table: Second supplementary estimand - change from baseline in MENQOL total score - MMRM analysis - by treatment group &fas_label";
        footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
        footnote2 'Study effect and study*treatment interaction are added for MMRM analysis.';
        footnote3 'n = number of subjects with observed value for this timepoint and considered in the analysis model.';
        Footnote4 'Pattern mixture modelling using multiple imputation has been used to impute missing values or values discarded due to hypothetical strategy.';
        footnote5 'LS-Means = Least Squares Means, SE = Standard Error, MMRM = Mixed Model Repeated Measures, CI = Confidence Interval.' ;
        footnote6 &idfoot ;
%END;

/****8.4****/


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_4_1_subgrp_hf) AND &tableno = 1 %THEN %DO;
    title1 "Table: Mean daily frequency of moderate to severe hot flashes: summary statistics and change from baseline by treatment group - &pop_label1";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'SD = Standard Deviation.';
    footnote3 'In case data was missing for more than 2 days within a week, the value for that particular week was set to missing.';
    footnote4 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_4_1_subgrp_shf) AND &tableno = 1 %THEN %DO;
    title1 "Table: Mean daily severity of moderate to severe hot flashes: summary statistics and change from baseline by treatment group - &pop_label1";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'SD = Standard Deviation.';
    footnote3 'In case data was missing for more than 2 days within a week, the value for that particular week was set to missing.';
    footnote4 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_4_1_subgrp_pr) AND &tableno = 1 %THEN %DO;
    title1 "Table: PROMIS SD SF 8b total T-score: summary statistics and change from baseline by treatment group - &pop_label1";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'Total score converted as T-score.';
    footnote3 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote4 'SD = Standard Deviation.';
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_4_1_subgrp_mq) AND &tableno = 1 %THEN %DO;
    title1 "Table: MENQOL total score: summary statistics and change from baseline by treatment group - &pop_label1";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'SD = Standard Deviation.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_4_1_subgrp_vmq) AND &tableno = 1 %THEN %DO;
    title1 "Table: MENQOL vasomotor symptoms subdomain score: summary statistics and change from baseline by treatment group - &pop_label1";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'SD = Standard Deviation.' ;
    footnote4 &idfoot ;
%END;

%MEND mtitle;