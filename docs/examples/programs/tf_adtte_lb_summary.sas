/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
%iniprog(name = tf_adtte_lb_summary)
;
/*
 * Purpose          : Cumulative incidence for ALT/AST to 3xULN by integrated analysis treatment group: Descriptive statistics
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : ereiu (Katharina Meier) / date: 04MAR2024
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : gdcpl (Derek Li) / date: 26MAR2024
 * Reason           : use real maximum day as the last day
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 27MAR2024
 * Reason           : add censored info in the figure
 *                    Update footnotes for plot
 ******************************************************************************/

%LET mosto_param_class = %scan(&extend_var_disp_12_ezn_52_a_nsa, 1, '@');

* Load and extend data;
%load_ads_dat(
    adtte_view
  , adsDomain = adtte
  , where     = paramcd in ('T2ALP' 'T2ALT')
  , adslWhere = &saf_cond.
)
;
%load_ads_dat(adsl_view, adsDomain = adsl, where = &saf_cond.)
;

%extend_data(
    indat       = adtte_view
  , outdat      = adtte_ext
  , subj_var    = USUBJID
  , var         = &extend_var_disp_12_ezn_52_a_nsa.
  , extend_rule = &extend_rule_disp_12_ezn_52_a_tte.
)
;
%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , subj_var    = USUBJID
  , var         = &extend_var_disp_12_ezn_52_a_nsa.
  , extend_rule = &extend_rule_disp_12_ezn_52_a.
)
;

DATA adtte_ext;
    SET adtte_ext;
    *format &mosto_param_class _trtgrp_nsa.;
    ATTRIB param_tit LENGTH = $200. LABEL = "%varlabel(adtte_ext, paramcd)";
    param_tit = scan(substr(vvalue(paramcd),9), 1, "(");

    LENGTH param_ftn $200.;
    IF paramcd = "T2ALT" THEN param_ftn = "ALT = Alanine Aminotransferase";
    IF paramcd = "T2ALP" THEN param_ftn = "ALP = Alkaline Phosphatase";
RUN;
* For time list in proc lifetest;
PROC SQL NOPRINT;
    SELECT max(aval) INTO : max_day FROM adtte_ext;
QUIT;

DATA km_interval;
    /*? limit/interval per study design/requirement */
    DO interval= 0,1,28 TO floor(&max_day/28)*28 BY 28,&max_day;
        timelist=interval;
        OUTPUT;
    END;
RUN;

%LET timelist = %getDataValueList(km_interval, timelist);
%LET timelist = %sysfunc(tranwrd(&timelist., %str(168), %str(168 182)));
%PUT &=timelist;

*< Table;
%MACRO _tab(
       parameter =
     , param_ftn =
);

    DATA _tab;
        SET adtte_ext(WHERE = (paramcd = "&parameter."));
    RUN;

    %LET param_tit = %getDataValueList(_tab, param_tit, distinct = Y);
    %LET param_ftn = %getDataValueList(_tab, param_ftn, distinct = Y);

    %set_titles_footnotes(
        tit1 = "Table: Cumulative incidence for &param_tit. by integrated analysis treatment group: Descriptive statistics &saf_label."
      , ftn1 = "Relative days refer to the number of days after first intake of the respective study drug."
      , ftn2 = "For treatment switchers, the days relative to start of EZN 120 mg are presented in &lbl_ezn_w26_52.."
      , ftn3 = "&foot_cens_sap."
      , ftn4 = "n = cumulative number of subjects with events up to the day, inclusive. N = number of subjects at risk at start of time point."
      , ftn5 = "Cum. inc = Cumulative Incidence. Cum. inc (%) = Kaplan-Meier estimates of the cumulative probability for an event, calculated as 100*(1 minus the Kaplan-Meier estimates of the survival function)."
      , ftn6 = "Unscheduled visits were included in the analysis. &param_ftn."
      , ftn7 = "CI = Confidence Interval. Kaplan-Meier confidence limits are calculated using the complementary log-log transformation for estimating the standard error."
    )
    ;

    %m_cum_inc(
        indat            = _tab
      , pop_cond         = &saf_cond.
      , timelist         = &timelist.
      , timelist_display = &timelist_week12_table. - &trt_ezn_12.
                             # &timelist_week12_table. - &trt_pla_12.
      , outtype          = table
      , class_fmt        = _trtgrp_nsa.
    )
    ;

%MEND _tab;
%_tab(parameter = T2ALT)
;
%_tab(parameter = T2ALP)
;

*< Plot;
DATA adtte_plot;
    SET adtte_ext;
    IF find(paramcd, "ALT") > 0 THEN order_param = 1;
    ELSE IF find(paramcd, "ALP") > 0 THEN order_param = 2;
RUN;

DATA ezn_pla_1_12;
    SET adtte_plot(WHERE = (&cond_actual_w12_nsa.));
RUN;* EZN / PLA week 1-12;
DATA all_ezn_1_52;
    SET adtte_plot(WHERE = (&cond_actual_w26_52_nsa.));
RUN;* All EZN week 1-52;

%LET timelist_plot = %trim(0 %substr(&timelist.,4));
%PUT timelist_plot&=timelist_plot;* remove Day 1 from plot;

%MACRO _plot(
       i         =
     , _data     =
     , _week     =
     , _timelist =
     , _suffix   =
);

/*    %do i = 1 %to 2;*/
    DATA _plot;
        SET &_data.(WHERE = (order_param = &i.));
        %IF %upcase(_suffix) = ALL_EZN %THEN %DO;
            IF &cond_excl_eot.;
        %END;
    RUN;

    %LET param_tit = %getDataValueList(_plot, param_tit, distinct = Y);
    %LET param_ftn = %getDataValueList(_plot, param_ftn, distinct = Y);

    %set_titles_footnotes(
        tit1 = "Figure: Cumulative incidence curve of time to &param_tit. by &_week. &saf_label."
      , ftn1 = "Relative days refer to the number of days after first intake of the respective study drug."
      , ftn2 = "Subjects at risk were calculated at start of timepoint."
      , ftn4 = "&foot_cens_sap."
      , ftn5 = "Unscheduled visits were included in the analysis."
      , ftn6 = "ULN = Upper Limit of Normal. &param_ftn.. IA= Integrated Analysis"
    %IF %lowcase(&_data.) = all_ezn_1_52 %THEN %DO;
        , ftn3 = "For treatment switchers, the days relative to start of EZN 120 mg are presented in &lbl_ezn_w26_52.."
    %END;
    );

    %m_cum_inc(
        indat        = _plot
      , pop_cond     = &saf_cond.
      , page         = PARAMCD
      , timelist     = &_timelist.
      , title_fig_ny = no
      , outtype      = FIGURE
      , yend         = 0.040
      , fig_file     = &prog._&_suffix._&i.
      , class_fmt    = _trtgrp_nsa.
      , show_censored= YES
    )
    /*    %end;*/

%MEND _plot;
* ALT;
%_plot(
    i         = 1
  , _data     = ezn_pla_1_12
  , _week     = EZN 120 mg (week 1-12) and Placebo (week 1-12)
  , _timelist = &timelist_week12_figure
  , _suffix   = ezn_pla
)
;* PLA (week 1-12)/ EZN (week 1-12);
%_plot(
    i         = 1
  , _data     = all_ezn_1_52
  , _week     = &lbl_ezn_w26_52.
  , _timelist = &timelist_plot.
  , _suffix   = all_ezn
)
;* All EZN (week 1-52);
* ALP;
%_plot(
    i         = 2
  , _data     = ezn_pla_1_12
  , _week     = EZN 120 mg (week 1-12) and Placebo (week 1-12)
  , _timelist = &timelist_week12_figure
  , _suffix   = ezn_pla
)
;* PLA (week 1-12)/ EZN (week 1-12);
%_plot(
    i         = 2
  , _data     = all_ezn_1_52
  , _week     = &lbl_ezn_w26_52.
  , _timelist = &timelist_plot.
  , _suffix   = all_ezn
)
;* All EZN (week 1-52);

%SYMDEL timelist max_day;
%endprog()
;
