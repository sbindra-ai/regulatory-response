/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = tf_adsl_iss_discon_km);
/*
 * Purpose          : Create table: Time to premature discontinuation of study drug by integrated analysis treatment group: Descriptive statistics (safety analysis set)
 *                    Create figure: Time to premature discontinuation of study drug up to week 12 by integrated analysis treatment group (safety analysis set)
                                     Time to premature discontinuation of study drug up to week 52 by integrated analysis treatment group (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gltlk (Rui Zeng) / date: 08FEB2024
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 14FEB2024
 * Reason           : # Update table / plot footnotes as of Spec updates
 *                    # Use _trtgrp_ns_notsplitted. (instead of _trtgrp_ns.)
 *                    # Use &timelist_week52_table.
 ******************************************************************************/
/* Changed by       : gltlk (Rui Zeng) / date: 18MAR2024
 * Reason           : update footnotes
 *                    update the derivation rule for EZN 120 mg (week 1-12) and Placebo (week 1-12)
 *                    update the condition for SWITCH-1 premature discontinuation of study drug
 ******************************************************************************/

%LET mosto_param_class = %scan(&extend_var_disp_12_52_nt_a., 1, '@');

**get data and select only relevant population;
%load_ads_dat(
    adsl_view
  , adsDomain = adsl
  , where     = &saf_cond.
);

**For SWITCH-1 study, 5 subjects dsscat = "END OF STUDY TREATMENT" with EPOCH = 'FOLLOW-UP', so use condition dsscat = "END OF STUDY TREATMENT";
%load_ads_dat(
    adds_view
  , adsDomain = adds
  , where     = dsscat ne 'INFORMED CONSENT' and dsterm ne 'LAST DB DOSE' and (epoch = 'TREATMENT' or dsscat = "END OF STUDY TREATMENT") and dsdecod ne 'COMPLETED'
  , keep      = studyid usubjid dscat epoch dsdecod aphase dsnext astdy astdt
  , adslVars  =
);

DATA adsl_view2;
    MERGE adsl_view(IN=a) adds_view;
    BY studyid usubjid;
RUN;

*Extend treatment group as needed;
%extend_data(
    indat       = adsl_view2
  , outdat      = adsl_ext
  , var         = &extend_var_disp_12_52_nt_a.
  , extend_rule = &extend_rule_disp_12_52_nt_a.
);

DATA adsl;
    SET adsl_ext END=eof;

    IF missing(trtedt) THEN DO;
        trtedt = rfxendt;
        miss_trtedt = 1;
    END;
    IF eof AND miss_trtedt = 1 THEN PUT "WARN" "ING: There are missing TRTEDT due to ongoing subjects. Missing TRTEDT is being replaced with RFXENDT";

    * The term 'premature discontinuation of the study drug' refers to the early discontinuation of taking the study drug.;
    * Time to premature discontinuation refers to the first 12 weeks for treatment groups EZN 120 mg (week 1-12) and Placebo (week 1-12);
    * EZN 120 mg (week 1-12) & Placebo (week 1-12):  The time until the last respective treatment at the end of placebo-controlled period or by day 84 (this is considered censored)
    * or the time until the first event of premature discontinuation of actual treatment during the respective treatment is presented (this is considered an event), whatever comes first.;
    * EZN 120 mg (week 1-12), Placebo (week 1-12);
    IF &mosto_param_class. IN (&trt_ezn_12., &trt_pla_12.) THEN DO;
        dur = min(trtedt, tr01edt)-trtsdt+1;
        *use condition TRTEDT - TRTSDT +1 <= 84 for week 1-12 which cut-off at day 84;
        IF NOT missing(dsdecod) and (trtedt - trtsdt +1 <= 84) THEN cnsr = 0;
        ELSE cnsr = 1;
    END;

    * Time to premature discontinuation refers to the complete 52 weeks for All EZN 120 mg (week 1-52) and All Placebo (week 1-52);
    * All EZN 120 mg (week 1-52);
    IF &mosto_param_class. = &trt_ezn_52. THEN DO;
        IF missing(trt02an) THEN dur = max(trtedt, tr01edt)-trtsdt+1;     *non-switcher;
        ELSE                     dur = max(trtedt, tr02edt)-tr02sdt+1;    *switcher;

        IF missing(trt02an) THEN DO;
            IF NOT missing(dsdecod) THEN cnsr = 0;      *use DSDECOD due to SWITCH-1 study APHASE is not populated for "END OF STUDY TREATMENT" records;
            ELSE cnsr = 1;
        END;
        ELSE DO;
            IF aphase = 'After week 12' THEN cnsr = 0;
            ELSE cnsr = 1;
        END;
    END;

    * All Placebo (week 1-52);
    IF &mosto_param_class. = &trt_pla_52. THEN DO;
        IF missing(trt02an) THEN dur = max(trtedt, tr01edt)-trtsdt+1;    *non-switcher;
        ELSE                     dur = min(trtedt, tr01edt)-trtsdt+1;    *switcher;

        IF missing(trt02an) THEN DO;
            IF NOT missing(dsdecod) THEN cnsr = 0;      *use DSDECOD due to SWITCH-1 study APHASE is not populated for "END OF STUDY TREATMENT" records;
            ELSE cnsr = 1;
        END;
        ELSE DO;
            IF aphase = 'Week 1-12' THEN cnsr = 0;
            ELSE cnsr = 1;
        END;
    END;

    aval = dur;

    * If "premature discontinuation of actual treatment" did not occur by day 84, the participant will be censored at week 12.;
    * the decision is to truncate it at day 84;
    IF &mosto_param_class. IN (&trt_ezn_12., &trt_pla_12.) AND dur > 84 THEN DO;
        aval = 84;
        cnsr = 1;
    END;

    * If "premature discontinuation of actual treatment" did not occur by day 364, the participant will be censored at week 52.;
    IF &mosto_param_class. IN (&trt_ezn_52., &trt_pla_52.) AND dur > 364 THEN DO;
        aval = 364;
        cnsr = 1;
    END;

    KEEP studyid usubjid trt01an trt02an arm ph1sdt ph1edt tr01edt tr02edt trtedt ph2sdt ph2edt dur aval cnsr dsdecod aphase astdy astdt;
RUN;

*< Table;
%set_titles_footnotes(
    tit1  = "Table: Time to premature discontinuation of study drug by integrated analysis treatment group: Descriptive statistics &saf_label."
    , ftn1 = "Relative days refer to the number of days after first intake of the respective study drug."
    , ftn2 = "For EZN 120 mg (week 1-12) and Placebo (week 1-12), time to premature discontinuation refers to the first 12 weeks."
    , ftn3 = "For EZN 120 mg (week 1-26/1-52) and Placebo (week 1-26/1-52), time to premature discontinuation refers to the complete 52 weeks."
    , ftn4 = "For treatment switchers, the event of premature discontinuation from placebo refers to the last placebo treatment for Placebo (week 1-12) and Placebo (week 1-26/1-52)."
    , ftn5 = "For treatment switchers, the event of premature discontinuation from elinzanetant refers to the last EZN 120 mg treatment for EZN 120 mg (week 1-26/1-52)."
    , ftn6 = "&foot_cens_sap. (*ESC*)n n = cumulative number of subjects with events up to the day, inclusive. N = number of subjects at risk at start of time point."
    , ftn7 = "Cum. inc = Cumulative Incidence. Cum. inc (%) = Kaplan-Meier estimates of the cumulative probability for an event, calculated as 100*(1 minus the Kaplan-Meier estimates of the survival function)."
    , ftn8 = "CI = Confidence Interval. Kaplan-Meier confidence limits are calculated using the complementary log-log transformation for estimating the standard error."
)

* timelist option is used, use atrisk option to get Number of subjects at risk at start of time point;
* conftype = loglog is default option in proc lifetest;
%m_cum_inc(
    indat     = adsl
  , class_fmt = _trtgrp_ns_notsplitted.
  , timelist  = &timelist_week52_table.
  , timelist_display = 0 1 28 56 84 - &trt_ezn_12.
                     # 0 1 28 56 84 - &trt_pla_12.
)

*< Figures;
* In the figure macro %KaplanMeierPlot, it uses lag(left) to get Number of subjects at risk when parameter at_risk = YES START_OF_TIMEPOINT, so timelist option should not be used;
%MACRO km_plot(week =, trtgrp =, xtick =);

    %set_titles_footnotes(
        tit1  = "Figure: Kaplan-Meier-Plot of the time to premature discontinuation of study drug up to week &week. by integrated analysis treatment group &saf_label."
       %IF &week = 12 %THEN %DO;
           , ftn1 = "Weeks represent the time since first intake of the respective study drug."
           , ftn2 = "Time to premature discontinuation refers to the first 12 weeks for treatment groups EZN 120 mg (week 1-12) and Placebo (week 1-12)."
           , ftn3 = "&foot_cens_sap."
           , ftn4 = "IA = Integrated Analysis"
        %END;
        %ELSE %DO;
           , ftn1 = "Weeks represent the time since first intake of the respective study drug."
           , ftn2 = "IA = Integrated Analysis"
           , ftn3 = "Time to premature discontinuation refers to the complete 52 weeks for EZN 120 mg (week 1-26/1-52) and Placebo (week 1-26/1-52)."
           , ftn4 = "&foot_cens_sap."
        %END;
    )

    %m_cum_inc(
        indat    = adsl (WHERE = (&mosto_param_class. IN (&trtgrp.)))
      , class_fmt = _trtgrp_ns_notsplitted.
      , timelist = &xtick.
       , xtime   = WEEKS
      , xlabel   = Weeks
      , ylabel   = Probability of no event
      , outtype  = FIGURE
      , km_type  = SURVIVAL
      , fig_file = &prog._w&week._
      , titfoot_scale = 0.98
      , show_censored = YES
    )

%MEND km_plot;

*Time to premature discontinuation of study drug up to week 12;
%km_plot(week = 12, trtgrp = %str(1, 2), xtick = 0 4 8 12)

*Time to premature discontinuation of study drug up to week 52;
%km_plot(week = 52, trtgrp = %str(6, 7), xtick = 0 4 8 12 16 20 24 26 28 32 36 40 44 48 52)

%endprog;
