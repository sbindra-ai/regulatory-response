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
 * Author(s)       : enpjp (Prashant Patel) / date: 04MAR2024
 * Reason           : Initiated the macro
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
%IF %QUPCASE(&prog.) = %QUPCASE(t_8_1_1_adsl_smpsz) AND &tableno = 1 %THEN %DO;
    title1 "Table: Study sample sizes by trial unit &enr_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'Number of subjects enrolled is the number of subjects who signed informed consent.';
    footnote3 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_1_1_adsl_sbj_reg) AND &tableno = 1 %THEN %DO;
    title1 "Table: Number of subjects by pooled region and country/region &rand_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_1_1_adsl_site_reg) AND &tableno = 1 %THEN %DO;
    title1 "Table: Number of sites by pooled region and country/region &rand_label";
    footnote1 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_1_1_addv_pdsf_tunt) AND &tableno = 1 %THEN %DO;
    title1 "Table: Protocol deviations and screen failures by trial unit &enr_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'Number of subjects enrolled is the number of subjects who signed informed consent.';
    footnote3 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_1_1_addv_sbj_imppd) AND &tableno = 1 %THEN %DO;
    title1 "Table: Number of subjects with important protocol deviations &rand_label";
    footnote1 'Subjects may have more than one protocol deviation but are only counted once within each deviation category.';
    footnote2 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant120 mg for 14 weeks.';
    footnote3 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_1_2_adsl_sbj_vlty_fnds) AND &tableno = 1 %THEN %DO;
    title1 "Table: Analysis sets and validity findings &rand_label";
    footnote1 'If a subject has more than one validity finding that excludes her from an analysis set, all of the findings are displayed.';
    footnote2 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote3 'SAF = Safety analysis set, FAS = Full analysis set, SLAS = Sleep analysis set.';
    footnote4 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_1_3_adds_sbj_disp) AND &tableno = 1 %THEN %DO;
    title1 "Table: Disposition: flow of subjects through study epochs &enr_label";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by Elinzanetant 120 mg for 14 weeks. &newline Number of subjects enrolled is the number of subjects who signed informed consent.";
    footnote2 "Week 1-12 represents the placebo controlled period of the study. &newline Week 13-26 represents the period at which all participants are treated with elinzanetant.";
    footnote3 "^&s_a.Primary reason for premature discontinuation of study drug during Week 1-26.";
    footnote4 "^&s_b.Prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period.";
    footnote5 "^&s_c.Prematurely discontinued study drug and directly entered follow-up. &newline ^&s_d.Premature withdrawal from the study without further follow-up.";
    footnote6 "^&s_e.These reasons are a subset of the primary reason for premature discontinuation of study drug.";
    footnote7 "^&s_f.This includes participants who completed the treatment phase and had a 4-week safety follow-up period or participants who started follow-up after discontinuation of study drug.";
    footnote8 "If a participant discontinued from study drug before week 12 but agreed to stay in the study (i.e., in a post-treatment period), the next scheduled in person visit covered";
    footnote9 "the assessments expected to be performed during the follow-up visit, and therefore no follow-up visit was needed after end of treatment visit.";
    footnote10 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_1_3_adds_disp_ovrl) AND &tableno = 1 %THEN %DO;
    title1 "Table: Disposition in overall study &enr_label";
    footnote1 'Definition of completed study = completed all phases of the study including the last visit.';
    footnote2 'Number of subjects enrolled is the number of subjects who signed informed consent.';
    footnote3 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by Elinzanetant 120 mg for 14 weeks.';
   /* footnote4 "Missing disposition reasons are of those subjects, who discontinued study treatment but did not come for follow-up.";*/
    footnote4 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_1_3_adsv_sbj_vist) AND &tableno = 1 %THEN %DO;
    title1 "Table: Number of subjects in study by visit &saf_label";
    footnote1 '"Subjects in study" includes all subjects irrespective of study drug status.';
    footnote2 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_1_4_adsl_demo_ovrl) AND &tableno = 1 %THEN %DO;
    title1 "Table: Demographics &pop_label1";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 "SD = Standard Deviation.";
    footnote3 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_1_4_adsl_demo_sub) AND &tableno = 1 %THEN %DO;
    title1 "Table: Demographics &pop_label1";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 "SD = Standard Deviation.";
    footnote3 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_1_5_admh_socpt) AND &tableno = 1 %THEN %DO;
    title1 "Table: Medical history: number of subjects with findings by primary system organ class and preferred term &saf_labeL";
    footnote1 "A subject is counted only once within each primary SOC/preferred term.";
    footnote2 "Medical history terms are sorted by alphabetical order of the SOC and by frequency of the PTs.";
    footnote3 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
    footnote4 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_1_5_adqs_hist_menoht) AND &tableno = 1 %THEN %DO;
    title1 "Table: History of menopause hormone therapy &poplabel";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_1_5_adrp_rpmens_hist) AND &tableno = 1 %THEN %DO;
    title1 "Table: Reproductive and menstrual history &poplabel";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
    footnote2 "^&super_a.Based on Medical History. PTs considered for hysterectomy are: Hysterectomy, Hysterosalpingectomy, Hysterosalpingo-oophorectomy and Radical hysterectomy.";
    footnote3 "^&super_b.Based on Medical History. PTs considered for oophorectomy are: Hysterosalpingo-oophorectomy, Oophorectomy,";
    footnote4 "Oophorectomy bilateral, Salpingo-oophorectomy, Salpingo-oophorectomy bilateral, Salpingo-oophorectomy unilateral.";
    footnote5 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_1_6_adcm_sbj_prior_cm) AND &tableno = 1 %THEN %DO;
    title1 "Table: Prior medication: number of subjects &saf_label" ;
    footnote1 "Medications taken before the start of study drug (regardless of when they ended) are included in this table.";
    footnote2 "Multiple ATC codes per drug are possible. Therefore, the same drug may be counted in more than one category for an individual subject.";
    footnote3 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote4 "Medications are displayed in alphabetical order by ATC class and in decreasing frequency by ATC subclass.";
    footnote5 "ATC = Anatomical Therapeutic Chemical";
    footnote6 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_1_6_adcm_sbj_cm) AND &tableno = 1 %THEN %DO;
    title1 "Table: Concomitant medication: number of subjects &saf_label" ;
    footnote1 "Medications taken within the treatment period are included in this table.";
    footnote2 "Multiple ATC codes per drug are possible. Therefore, the same drug may be counted in more than one category for an individual subject.";
    footnote3 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote4 "Medications are displayed in alphabetical order by ATC class and in decreasing frequency by ATC subclass.";
    footnote5 "ATC = Anatomical Therapeutic Chemical";
    footnote6 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_1_6_adcm_sbj_psttrtmed) AND &tableno = 1 %THEN %DO;
    title1 "Table: Post-treatment medication: number of subjects &saf_label" ;
    footnote1 "Post-treatment medication is defined as medications started after last day of study drug intake.";
    footnote2 "Multiple ATC codes per drug are possible. Therefore, the same drug may be counted in more than one category for an individual subject.";
    footnote3 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote4 "Medications are displayed in alphabetical order by ATC class and in decreasing frequency by ATC subclass.";
    footnote5 "ATC = Anatomical Therapeutic Chemical";
    footnote6 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_1_7_ice_adds_rsn) AND &tableno = 1 %THEN %DO;
        title1 "Table: Intercurrent events - Permanent discontinuation of randomized treatment up to Week 12: number of subjects by reason &fas_label";
        footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
        footnote2 "Percentages within sub-categories use the total number within this sub-category as denominator.";
        footnote3 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_1_7_ice_adex_rsn) AND &tableno = 1 %THEN %DO;
    title1 "Table: Intercurrent events - Temporary treatment interruption up to Week 12: number of subjects by reason  &fas_label";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
    footnote2 "A participant could have single day treatment interruptions without reason.";
    footnote3 "^&super_a.There can be several reasons for temporary treatment interruptions per subject and considered time. Therefore, one subject can be counted in more than one reason category.";
    footnote4 "The reason for a temporary treatment interruption is only collected if a subject interrupted treatment for more than 2 consecutive days.";
    footnote5 "Percentages within sub-categories use the total number within this sub-category as denominator.";
    footnote6 "&idfoot";
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_1_7_ice_adcm_rsn) AND &tableno = 1 %THEN %DO;
    title1 "Table: Intercurrent events - Intake of prohibited concomitant medication having impact on efficacy up to Week 12: number of subjects  &fas_label";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
    footnote2 "^&super_a.Subjects who took more than one prohibited concomitant medication per considered time are counted once. ";
    footnote3 "Any intake of prohibited medication is counted for all the time where it is considered as an intercurrent event, i.e. including the pre-defined washout time period.";
    footnote4 "Percentages within sub-categories use the total number within this sub-category as denominator.";
    footnote5 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_1_7_ice_adex) AND &tableno = 1 %THEN %DO;
    title1 "Table: Non-compliance related to temporary treatment interruption (estimand definition) up to Week 12 &fas_label";
    footnote1 "A 'Yes' means the subject had a temporary treatment interruption or has not been compliant.";
    footnote2 "Placebo  - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
    footnote3 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_1_7_adtte_km_ds) AND &tableno = 1 %THEN %DO;
    title1 "Table: Time from randomization to permanent discontinuation of randomized treatment up to Week 12: Descriptive statistics &fas_label";
    footnote1 "^&super_a.censored observation.";
    footnote2 "A: Value cannot be estimated due to censored data.";
    footnote3 "Median, percentile and other 95% CIs computed using Kaplan-Meier estimates.";
    footnote4 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
    footnote5 "CI = Confidence Interval.";
    footnote6 "If 'Permanent discontinuation of randomized treatment' did not occur by day 84, the participant is censored at week 12.";
    footnote7 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_1_7_adtte_km_cm) AND &tableno = 1 %THEN %DO;
    title1 "Table: Time from randomization to first intake of prohibited concomitant medication having impact on efficacy up to Week 12: Descriptive statistics &fas_label";
    footnote1 "^&super_a.censored observation.";
    footnote2 "A: Value cannot be estimated due to censored data.";
    footnote3 "Median, percentile and other 95% CIs computed using Kaplan-Meier estimates.";
    footnote4 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
    footnote5 "CI = Confidence Interval.";
    footnote6 "If 'Intake of prohibited concomitant medication having impact on efficacy' did not occur by day 84, the participant is censored at week 12 or at the time of dropping out of the study, whichever occurs earlier.";
    footnote7 "&idfoot";
%END;

/*8.3 ==> SAFETY*/

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_1_adex_trtdurtrtgrp) AND &tableno = 1 %THEN %DO;
    title1 "Table: Treatment duration by treatment group &poplabel" ;
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
    footnote2 "SD = Standard Deviation.";
    footnote3 "Overall duration of treatment is defined as the number of days from the day of first study drug intake up to and including the day of last study drug intake.";
    footnote4 "Week 1-12 represents the placebo controlled period of the study.";
    footnote5 "Week 13-26 represents the period at which all participants are treated with elinzanetant.";
    footnote6 "According protocol, the Visit T6/End of treatment was allowed to be Week 26 - 7 days (i.e. at day 176 to 182).";
    footnote7 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_1_adex_durstdrg) AND &tableno = 1 %THEN %DO;
    title1 "Table: Treatment duration by study drug &poplabel" ;
    footnote1 "Duration of treatment is defined as the number of days from the day of first study drug intake up to and including the day of last study drug intake.";
    footnote2 "SD = Standard Deviation.";
    footnote3 "Week 1-12 represents the placebo controlled period of the study.";
    footnote4 "Week 13-26 represents the period at which all participants are treated with elinzanetant.";
    footnote5 "&idfoot";
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_1_adex_comptrtgrp) AND &tableno = 1 %THEN %DO;
    title1 "Table: Treatment compliance by treatment group  &poplabel" ;
    footnote1 "Compliance (%) = 100 * Number of capsules taken / Number of planned capsules per protocol.";
    footnote2 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
    footnote3 "SD = Standard Deviation.";
    footnote4 "Week 1-12 represents the placebo controlled period of the study.";
    footnote5 "Week 13-26 represents the period at which all participants are treated with elinzanetant.";
    footnote6 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_1_adex_compstdrg) AND &tableno = 1 %THEN %DO;
    title1 "Table: Treatment compliance by study drug &poplabel";
    footnote1 "Compliance (%) = 100 * Number of capsules taken / Number of planned capsules per protocol.";
    footnote2 "SD = Standard Deviation.";
    footnote3 "Week 1-12 represents the placebo controlled period of the study.";
    footnote4 "Week 13-26 represents the period at which all participants are treated with elinzanetant.";
    footnote5 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_1_adex_avgdos) AND &tableno = 1 %THEN %DO;
    title "Table: Treatment dose of Elinzanetant per day by treatment group &poplabel";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
    footnote2 "SD = Standard Deviation.";
    footnote3 "Week 1-12 represents the placebo controlled period of the study.";
    footnote4 "Week 13-26 represents the period at which all participants are treated with elinzanetant.";
    footnote5 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_1_adex_totdos) AND &tableno = 1 %THEN %DO;
    title "Table: Total dose of Elinzanetant by treatment group &poplabel";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
    footnote2 "SD = Standard Deviation.";
    footnote3 "Week 1-12 represents the placebo controlled period of the study.";
    footnote4 "Week 13-26 represents the period at which all participants are treated with elinzanetant.";
    footnote5 "&idfoot";
%END;

/*8.3.2 Adverse events including deaths*/

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_2_1_adae_ovrl_pretrt) AND &tableno = 1 %THEN %DO;
    title1 "Table: Pre-treatment adverse events: overall summary of number of subjects &saf_label" ;
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
    footnote2 "For AEs of special safety interest, following AEs are considered: potential AESI liver event (i.e., any condition triggering close liver";
    footnote3 "observation according to protocol Section 10.5. results in true AESIs of liver events. The search used here is beyond the protocol";
    footnote4 "definition of the AESI and will be considered together with the assessment by the Liver Safety Monitoring Board to determine a true";
    footnote5 "AESI.), somnolence or fatigue, phototoxicity, and post-menopausal uterine bleeding";
    footnote6 "AESI = Adverse events of special interest";
    footnote7 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_2_1_adae_pretrtsocpt) AND &tableno = 1 %THEN %DO;
    title1 "Table: Pre-treatment adverse events: number of subjects by primary system organ class and preferred term &saf_label" ;
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
    footnote2 "Adverse events are sorted by alphabetical order of the SOC and by frequency of the PTs.";
    footnote3 "A subject is counted only once within each primary SOC and preferred term.";
    footnote4 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_2_1_adae_ovrlpsttrt) AND &tableno = 1 %THEN %DO;
    title1 "Table: Post-treatment adverse events: overall summary of number of subjects &saf_label" ;
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
    footnote2 "Post-treatment adverse events are defined as AEs that started 14 days after the stop of study treatment.";
    footnote3 "For AEs of special safety interest, following AEs are considered: potential AESI liver event (i.e., any condition triggering close liver";
    footnote4 "observation according to protocol Section 10.5. results in true AESIs of liver events. The search used here is beyond the protocol";
    footnote5 "definition of the AESI and will be considered together with the assessment by the Liver Safety Monitoring Board to determine a true";
    footnote6 "AESI.), somnolence or fatigue, phototoxicity, and post-menopausal uterine bleeding";
    footnote7 "AESI = Adverse events of special interest";
    footnote8 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_2_1_adae_psttrtsocpt) AND &tableno = 1 %THEN %DO;
    title1 "Table: Post-treatment adverse events: number of subjects by primary system organ class and preferred term &saf_label" ;
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
    footnote2 "Adverse events are sorted by alphabetical order of the SOC and by frequency of the PTs";
    footnote3 "A subject is counted only once within each primary SOC and preferred term.";
    footnote4 "Post-treatment adverse events are defined as AEs that started 14 days after the stop of study treatment.";
    footnote5 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_2_2_adae_sae_socpt) AND &tableno = 1 %THEN %DO;
    title1 "Table: Serious adverse events: number of subjects by primary system organ class and preferred term &saf_label" ;
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
    footnote2 "Adverse events are sorted by alphabetical order of the SOC and by frequency of the PTs";
    footnote3 "A subject is counted only once within each primary SOC and preferred term.";
    footnote4 "Week 1-12 represents the placebo controlled period of the study.";
    footnote5 "Week 13-26 represents the period at which all participants are treated with elinzanetant.";
    footnote6 "^&super_a.Reported AEs, during the exposure period Week 13 - 26 to elinzanetant, for the Elinzanetant 120 mg treatment group.";
    footnote7 "^&super_b.Reported AEs, during the exposure period to elinzanetant, for Placebo - Elinzanetant 120 mg treatment group.";
    footnote8 "^&super_c.Reported AEs, during the exposure period to elinzanetant, for both treatment groups.";
    footnote9 "&idfoot"
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_2_3_adae_teae_ovrl) AND &tableno = 1 %THEN %DO;
    title1 "Table: Treatment-emergent adverse events: overall summary of number of subjects &saf_label" ;
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks; Treatment-emergent adverse events are shown for week 1-12, week 13-26 and overall (i.e week 1-26) by study drug.";
    footnote2 "Week 1-12 represents the placebo controlled period of the study; Week 13-26 represents the period at which all participants are treated with elinzanetant.";
    footnote3 "For AEs of special safety interest, following AEs are considered: potential AESI liver event (i.e., any condition triggering close liver observation";
    footnote4 "according to protocol Section 10.5. results in true AESIs of liver events. The search used here is beyond the protocol definition of the AESI and";
    footnote5 "will be considered together with the assessment by the Liver Safety Monitoring Board to determine a true AESI.), somnolence or fatigue, phototoxicity, and post-menopausal uterine bleeding.";
    footnote6 "^&super_a.Reported AEs, during the exposure period Week 13 - 26 to elinzanetant, for the Elinzanetant 120 mg treatment group.";
    footnote7 "^&super_b.Reported AEs, during the exposure period to elinzanetant, for Placebo - Elinzanetant 120 mg treatment group.";
    footnote8 "^&super_c.Reported AEs, during the exposure period to elinzanetant, for both treatment groups.";
    footnote9 "AESI = Adverse events of special interest";
    footnote10 "&idfoot";
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_2_3_adae_teae_socpt) AND &tableno = 1 %THEN %DO;
    title1 "Table: Treatment-emergent adverse events: number of subjects by primary system organ class and preferred term &saf_label" ;
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
    footnote2 "Adverse events are sorted by alphabetical order of the SOC and by frequency of the PTs";
    footnote3 "A subject is counted only once within each primary SOC and preferred term.";
    footnote4 "Week 1-12 represents the placebo controlled period of the study.";
    footnote5 "Week 13-26 represents the period at which all participants are treated with elinzanetant.";
    footnote6 "^&super_a.Reported AEs, during the exposure period Week 13 - 26 to elinzanetant, for the Elinzanetant 120 mg treatment group.";
    footnote7 "^&super_b.Reported AEs, during the exposure period to elinzanetant, for Placebo - Elinzanetant 120 mg treatment group.";
    footnote8 "^&super_c.Reported AEs, during the exposure period to elinzanetant, for both treatment groups.";
    footnote9 "&idfoot"
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_2_3_adae_teae_sdr) AND &tableno = 1 %THEN %DO;
    title1 "Table: Treatment-emergent study drug-related adverse events: number of subjects by primary system organ class and preferred term &saf_label";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 "Adverse events are sorted by alphabetical order of the SOC and by frequency of the PTs.";
    footnote3 "A subject is counted only once within each primary SOC and preferred term.";
    footnote4 "Week 1-12 represents the placebo controlled period of the study.";
    footnote5 "Week 13-26 represents the period at which all participants are treated with elinzanetant";
    footnote6 "^&super_a.Reported AEs, during the exposure period Week 13 - 26 to elinzanetant, for the Elinzanetant 120 mg treatment group.";
    footnote7 "^&super_b.Reported AEs, during the exposure period to elinzanetant, for Placebo - Elinzanetant 120 mg treatment group.";
    footnote8 "^&super_c.Reported AEs, during the exposure period to elinzanetant, for both treatment groups.";
    footnote9 "&idfoot"
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_2_3_adae_tesi_socpt) AND &tableno = 1 %THEN %DO;
    title1 "Table: Treatment-emergent adverse events of special interest &label.: number of subjects by primary system organ class and preferred term &saf_label";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 "Adverse events are sorted by alphabetical order of the SOC and by frequency of the PTs.";
    footnote3 "A subject is counted only once within each primary SOC and preferred term.";
    footnote4 "Week 1-12 represents the placebo controlled period of the study.";
    footnote5 "Week 13-26 represents the period at which all participants are treated with elinzanetant";
    footnote6 "^&super_a.Reported AEs, during the exposure period Week 13 - 26 to elinzanetant, for the Elinzanetant 120 mg treatment group.";
    footnote7 "^&super_b.Reported AEs, during the exposure period to elinzanetant, for Placebo - Elinzanetant 120 mg treatment group.";
    footnote8 "^&super_c.Reported AEs, during the exposure period to elinzanetant, for both treatment groups.";
    footnote9 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_2_3_adae_tesi_socpt) AND &tableno = 2 %THEN %DO;
    title1 "Table: &label.: number of subjects by primary system organ class and preferred term &saf_label";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 "Adverse events are sorted by alphabetical order of the SOC and by frequency of the PTs, A subject is counted only once within each primary SOC and preferred term.";
    footnote3 "Week 1-12 represents the placebo controlled period of the study. &newline Week 13-26 represents the period at which all participants are treated with elinzanetant.";
    footnote4 "^&super_a.Reported AEs, during the exposure period Week 13 - 26 to elinzanetant, for the Elinzanetant 120 mg treatment group.";
    footnote5 "^&super_b.Reported AEs, during the exposure period to elinzanetant, for Placebo - Elinzanetant 120 mg treatment group.";
    footnote6 "^&super_c.Reported AEs, during the exposure period to elinzanetant, for both treatment groups.";
    footnote7 "Any condition triggering close liver observation according to protocol Section 10.5. results in true AESIs of liver events.";
    footnote8 "Cases in this table are identified by defined Standardised MedDRA Querys and are beyond the protocol definition. &newline AESI = Adverse events of special interest.";
    footnote9 "^&super_d.This case should not be reported in this table as the participant had a normal liver function throughout the study (Listing 10.2.8.1/2). Adverse Event of Special Safety Interest for";
    footnote10 "ALT and/or AST >8x ULN OR ALT and/or AST >3x ULN with total bilirubin >2x ULN was ticked by mistake in eCRF. &newline &idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_2_3_adae_si_bld) AND &tableno = 1 %THEN %DO;
    title1 "Table: Treatment-emergent adverse events of special interest - post-menopausal uterine bleeding: number of subjects by primary system organ class and preferred term &saf_label";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
    footnote2 "Adverse events are sorted by alphabetical order of the SOC and by frequency of the PTs.";
    footnote3 "A subject is counted only once within each primary SOC and preferred term.";
    footnote4 "N = number of subjects with uterus.";
    footnote5 "Week 1-12 represents the placebo controlled period of the study.";
    footnote6 "Week 13-26 represents the period at which all participants are treated with elinzanetant.";
    footnote7 "^&super_a.Reported AEs, during the exposure period Week 13 - 26 to elinzanetant, for the Elinzanetant 120 mg treatment group.";
    footnote8 "^&super_b.Reported AEs, during the exposure period to elinzanetant, for Placebo - Elinzanetant 120 mg treatment group.";
    footnote9 "^&super_c.Reported AEs, during the exposure period to elinzanetant, for both treatment groups.";
    footnote10 "AESI = Adverse events of special interest. &newline &idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_2_3_adae_tesdd_socpt) AND &tableno = 1 %THEN %DO;
    title1 "Table: Treatment-emergent adverse events resulting in discontinuation of study drug: number of subjects by primary system organ class and preferred term &saf_label";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
    footnote2 "Adverse events are sorted by alphabetical order of the SOC and by frequency of the PTs.";
    footnote3 "A subject is counted only once within each primary SOC and preferred term.";
    footnote4 "Week 1-12 represents the placebo controlled period of the study.";
    footnote5 "Week 13-26 represents the period at which all participants are treated with elinzanetant.";
    footnote6 "^&super_a.Reported AEs, during the exposure period Week 13 - 26 to elinzanetant, for the Elinzanetant 120 mg treatment group.";
    footnote7 "^&super_b.Reported AEs, during the exposure period to elinzanetant, for Placebo - Elinzanetant 120 mg treatment group.";
    footnote8 "^&super_c.Reported AEs, during the exposure period to elinzanetant, for both treatment groups.";
    footnote9 "&idfoot"
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_2_3_adae_teaemisocpt) AND &tableno = 1 %THEN %DO;
     title1 "Table: Treatment-emergent adverse events by maximum intensity: number of subjects by primary system organ class and preferred term &saf_label";
     footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
     footnote2 "Only the most severe intensity is counted for multiple occurrences of the same AE in one individual.";
     footnote3 "Adverse events are sorted by alphabetical order of the SOC and by frequency of the PTs.";
     footnote4 "A subject is counted only once within each primary SOC and preferred term,""Missing"" is considered to be the minimum category of intensity.";
     footnote5 "Week 1-12 represents the placebo controlled period of the study.";
     footnote6 "Week 13-26 represents the period at which all participants are treated with elinzanetant.";
     footnote7 "^&super_a.Reported AEs, during the exposure period Week 13 - 26 to elinzanetant, for the Elinzanetant 120 mg treatment group.";
     footnote8 "^&super_b.Reported AEs, during the exposure period to elinzanetant, for Placebo - Elinzanetant 120 mg treatment group.";
     footnote9 "^&super_c.Reported AEs, during the exposure period to elinzanetant, for both treatment groups.";
     footnote10 "&idfoot"
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_2_3_adae_tesdmisocpt) AND &tableno = 1 %THEN %DO;
     title1 "Table: Treatment-emergent study drug-related adverse events by maximum intensity: number of subjects by primary system organ class and preferred term &saf_label";
     footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
     footnote2 "Only the most severe intensity is counted for multiple occurrences of the same AE in one individual.";
     footnote3 """Missing"" is considered to be the minimum category of intensity.";
     footnote4 "Adverse events are sorted by alphabetical order of the SOC and by frequency of the PTs. A subject is counted only once within each primary SOC and preferred term.";
     footnote5 "Week 1-12 represents the placebo controlled period of the study.";
     footnote6 "Week 13-26 represents the period at which all participants are treated with elinzanetant.";
     footnote7 "^&super_a.Reported AEs, during the exposure period Week 13 - 26 to elinzanetant, for the Elinzanetant 120 mg treatment group.";
     footnote8 "^&super_b.Reported AEs, during the exposure period to elinzanetant, for Placebo - Elinzanetant 120 mg treatment group.";
     footnote9 "^&super_c.Reported AEs, during the exposure period to elinzanetant, for both treatment groups.";
     footnote10 "&idfoot"
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_2_3_adae_tmrel_socpt) AND &tableno = 1 %THEN %DO;
     title1 "Table: Treatment-emergent study drug-related adverse events resulting in discontinuation of study drug: number of subjects by primary system organ class and preferred term &saf_label";
     footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
     footnote2 "Adverse events are sorted by alphabetical order of the SOC and by frequency of the PTs";
     footnote3 "A subject is counted only once within each primary SOC and preferred term.";
     footnote4 "Week 1-12 represents the placebo controlled period of the study.";
     footnote5 "Week 13-26 represents the period at which all participants are treated with elinzanetant.";
     footnote6 "^&super_a.Reported AEs, during the exposure period Week 13 - 26 to elinzanetant, for the Elinzanetant 120 mg treatment group.";
     footnote7 "^&super_b.Reported AEs, during the exposure period to elinzanetant, for Placebo - Elinzanetant 120 mg treatment group.";
     footnote8 "^&super_c.Reported AEs, during the exposure period to elinzanetant, for both treatment groups.";
     footnote9 "&idfoot"
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_2_3_ae_gt5_socpt) AND &tableno = 1 %THEN %DO;
     title1 "Table: Treatment-emergent adverse events in >= 5% participants: number of subjects by preferred term &saf_label";
     footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
     footnote2 "Week 1-12 represents the placebo controlled period of the study.";
     footnote3 "Week 13-26 represents the period at which all participants are treated with elinzanetant.";
     footnote4 "The entries are sorted by decreasing frequency of the PTs.";
     footnote5 "^&super_a.Reported AEs, during the exposure period Week 13 - 26 to elinzanetant, for the Elinzanetant 120 mg treatment group.";
     footnote6 "^&super_b.Reported AEs, during the exposure period to elinzanetant, for Placebo - Elinzanetant 120 mg treatment group.";
     footnote7 "^&super_c.Reported AEs, during the exposure period to elinzanetant, for both treatment groups.";
     footnote8 "&idfoot"
%END;

/*8.3.2.4 Treatment-emergent serious adverse events*/

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_2_4_adae_tesaesocpt) AND &tableno = 1 %THEN %DO;
      title1 "Table: Treatment-emergent serious adverse events: number of subjects by primary system organ class and preferred term &saf_label";
       footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
       footnote2 "Adverse events are sorted by alphabetical order of the SOC and by frequency of the PTs.";
       footnote3 "A subject is counted only once within each primary SOC and preferred term.";
       footnote4 "Week 1-12 represents the placebo controlled period of the study.";
       footnote5 "Week 13-26 represents the period at which all participants are treated with elinzanetant.";
       footnote6 "^&super_a.Reported AEs, during the exposure period Week 13 - 26 to elinzanetant, for the Elinzanetant 120 mg treatment group.";
       footnote7 "^&super_b.Reported AEs, during the exposure period to elinzanetant, for Placebo - Elinzanetant 120 mg treatment group.";
       footnote8 "^&super_c.Reported AEs, during the exposure period to elinzanetant, for both treatment groups.";
       footnote9 "&idfoot"
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_2_4_adae_tesaemi) AND &tableno = 1 %THEN %DO;
     title1 "Table: Treatment-emergent serious adverse events by maximum intensity: number of subjects by primary system organ class and preferred term &saf_label";
     footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
     footnote2 "Only the most severe intensity is counted for multiple occurrences of the same AE in each subjects.";
     footnote3 """Missing"" is considered to be the minimum category of intensity.";
     footnote4 "Adverse events are sorted by alphabetical order of the SOC and by frequency of the PTs.";
     footnote5 "A subject is counted only once within each primary SOC and preferred term.";
     footnote6 "^&super_a.Reported AEs, during the exposure period Week 13 - 26 to elinzanetant, for the Elinzanetant 120 mg treatment group.";
     footnote7 "^&super_b.Reported AEs, during the exposure period to elinzanetant, for Placebo - Elinzanetant 120 mg treatment group.";
     footnote8 "^&super_c.Reported AEs, during the exposure period to elinzanetant, for both treatment groups.";
     footnote9 "&idfoot"
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_2_4_adae_tesdsocpt) AND &tableno = 1 %THEN %DO;
      title1 "Table: Treatment-emergent study drug-related serious adverse events: number of subjects by primary system organ class and preferred term &saf_label";
       footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
       footnote2 "Adverse events are sorted by alphabetical order of the SOC and by frequency of the PTs.";
       footnote3 "A subject is counted only once within each primary SOC and preferred term.";
       footnote4 "Week 1-12 represents the placebo controlled period of the study.";
       footnote5 "Week 13-26 represents the period at which all participants are treated with elinzanetant.";
       footnote6 "^&super_a.Reported AEs, during the exposure period Week 13 - 26 to elinzanetant, for the Elinzanetant 120 mg treatment group.";
       footnote7 "^&super_b.Reported AEs, during the exposure period to elinzanetant, for Placebo - Elinzanetant 120 mg treatment group.";
       footnote8 "^&super_c.Reported AEs, during the exposure period to elinzanetant, for both treatment groups.";
       footnote9 "&idfoot"
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_2_4_adae_tesdmisocpt) AND &tableno = 1 %THEN %DO;
     title1 "Table: Treatment-emergent study drug-related serious adverse events by maximum intensity: number of subjects by primary system organ class and preferred term &saf_label";
     footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
     footnote2 "Only the most severe intensity is counted for multiple occurrences of the same AE in each subjects.";
     footnote3 """Missing"" is considered to be the minimum category of intensity.";
     footnote4 "Adverse events are sorted by alphabetical order of the SOC and by frequency of the PTs.";
     footnote5 "Week 1-12 represents the placebo controlled period of the study.";
     footnote6 "Week 13-26 represents the period at which all participants are treated with elinzanetant.";
     footnote7 "^&super_a.Reported AEs, during the exposure period Week 13 - 26 to elinzanetant, for the Elinzanetant 120 mg treatment group.";
     footnote8 "^&super_b.Reported AEs, during the exposure period to elinzanetant, for Placebo - Elinzanetant 120 mg treatment group.";
     footnote9 "^&super_c.Reported AEs, during the exposure period to elinzanetant, for both treatment groups.";
     footnote10 "&idfoot"
%END;

/*8.3.2.5 Deaths*/

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_2_5_adae_dth_socpt) AND &tableno = 1 %THEN %DO;
      title1 " Table: Deaths: number of subjects with adverse events with fatal outcome by primary system organ class and preferred term &saf_label";
      footnote1 "&idfoot"
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_2_5_adae_teaedth) AND &tableno = 1 %THEN %DO;
    title1 "Table: Deaths: number of subjects with treatment-emergent adverse event with fatal outcome by primary system organ class and preferred term &saf_label";
    footnote1 "&idfoot"
%END;


/*8.3.3 Physical examinations*/


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_3_advs_ph_sbase) AND &tableno = 1 %THEN %DO;
    title1 "Table: Physical examination: summary statistics and change from baseline by treatment group - $paramcd$";
    title2 "<cont> &saf_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'SD = Standard Deviation.';
    footnote3 &idfoot ;
%END;

/*8.3.4 Vital signs*/

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_4_advs_sbase) AND &tableno = 1 %THEN %DO;
    title1 "Table: Vital signs: summary statistics and change from baseline by treatment group - $paramcd$";
    title2 " <cont> &saf_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'SD = Standard Deviation.';
    footnote3 &idfoot ;
%END;

/*8.3.6 Mammogram*/

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_6_adpr_mmo_frq) AND &tableno = 1 %THEN %DO;
    title1 "Table: Number of subjects with mammogram results";
    title2 " <cont> &saf_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'Percentages for main result are based on subjects having a mammogram performed.' ;
    footnote3 &idfoot ;
%END;

/*8.3.7 Gynecological ultrasound*/

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_7_gyn_ult_frq) AND &tableno = 1 %THEN %DO;
    title1 "Table: Number of subjects with gynecological ultrasound performed ";
    title2 " <cont> &saf_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'n = Number of subjects at visit.' ;
    footnote3 'Percentages for main result are based on subjects having a ultrasound performed.';
    footnote4 "^&super_a.multiple answers possible.";
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_7_adfapr_endo_sbase) AND &tableno = 1 %THEN %DO;
    title1 "Table: Endometrial thickness (mm): summary statistics and change from baseline by treatment ";
    title2 " <cont> &saf_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'SD = Standard Deviation.' ;
    footnote3 'Only subjects without hysterectomy are considered. n = Number of subjects at visit (without hysterectomy).' ;
    footnote4 'Endometrial thickness measured in the medio-sagittal section as double-layer in millimeters.' ;
    footnote5 'If endometrium was just visible as a thin line and not measurable, sites were instructed to enter 0.' ;
    footnote6 'Screening measurements are considered as baseline.' ;
    footnote7 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_7_adfapar_cyst_frq) AND &tableno = 1 %THEN %DO;
    title1 "Table: Number of subjects with cyst like structures in ovary by visit and by treatment group";
    title2 " <cont> &saf_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 &idfoot ;
%END;

/*8.3.8 Cervical cytology*/

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_8_adpr_crv_ct_frq) AND &tableno = 1 %THEN %DO;
    title1 "Table: Number of subjects with cervical cytology results ";
    title2 " <cont> &saf_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'FU = follow-up.';
    footnote3 'Percentages for main result are based on subjects having cervical cytology collected.';
    footnote4 &idfoot ;
%END;

/*8.3.9 Endometrial biopsy*/

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_9_adpr_end_bio_frq) AND &tableno = 1 %THEN %DO;
    title1 "Table: Number of subjects with endometrial biopsy information";
    title2 " <cont> &saf_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'Subjects are counted for the category "All reader results", if at least one record from each reader is available,i.e. readers 1,2,3 even if tissues are not adequate.' ;
    footnote3 'Subjects are counted for the category "At least one reader result, but not all reader results",if they are not counted' ;
    footnote4 'to the category above and at least one record from at least one reader, i.e. reader 1,2, or 3 is available.';
    footnote5 'Percentages are based on subjects belonging to the corresponding higher level,' ;
    footnote6 'e.g. percentages for biopsy sample obtained are based on the number of subjects who had a endometrial biopsy performed.' ;
    footnote7 'Only subjects without hysterectomy are considered.' ;
    footnote8 'Unscheduled biopsy is performed in case of an abnormal finding in the transvaginal ultrasound and/or if the participant has experienced post-menopausal bleeding during the study.' ;
    footnote9 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_9_adfapr_enbio) AND &tableno = 1 %THEN %DO;
    title1 "Table: Number of subjects by endometrial biopsy main results";
    title2 " <cont> &saf_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'Percentages for "Adequate endometrial tissue" are based on subjects with successful biopsies taken and sample was sent for assessment.' ;
    footnote3 'Main diagnosis is based on majority read.' ;
    footnote4 'Only participants without hysterectomy are considered.' ;
    footnote5 'A biopsy is considered non-benign in case "Benign endometrium" = "No" or "Hyperplasia (2014)" = "Yes" or "Malignant Neoplasm" = "Yes".';
    footnote6 'Measurement for baseline can also take place at screening.' ;
    footnote7 'Unscheduled biopsy is performed in case of an abnormal finding in the transvaginal ultrasound and/or if the participant has experienced post-menopausal bleeding during the study.' ;
    footnote8 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_9_adfapr_enbiof) AND &tableno = 1 %THEN %DO;
    title1 "Table: Number of biopsies by endometrial biopsy main results including subcategories based on majority read ";
    title2 " <cont> &saf_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'Percentages are based on biopsies with adequate tissue (in reader 1, 2, and 3 for "Majority read")' ;
    footnote3 'Only participants without hysterectomy are considered.' ;
    footnote4 'Unscheduled biopsy is performed in case of an abnormal finding in the transvaginal ultrasound and/or if the participant has experienced post-menopausal bleeding during the study.';
    footnote5 &idfoot ;
%END;

/*8.3.10 Sleepiness scale*/

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_10_hfss_sleep) AND &tableno = 1 %THEN %DO;
    title1 "Table: Sleepiness scale: summary statistics and change from baseline by treatment group - $paramcd$";
    title2 "<cont> &saf_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'The assessment of sleepiness is based on a 5-point verbal rating scale ("0"=not at all; "4"=very much).' ;
    footnote3 '7-day averages can be derived, if daily score is available on at least 5 out of 7 days, otherwise average score was set as missing.' ;
    footnote4 'SD = Standard Deviation' ;
    footnote5 &idfoot ;
%END;

/*8.3.11 Electronic Columbia-suicide severity rating scale*/

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_11_qscssrs_frq) AND &tableno = 1 %THEN %DO;
    title1 "Table: Number of subjects with suicidal ideation and behavior based on the eC-SSRS";
    title2 "<cont> &saf_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'For the composite endpoint of suicidal ideation (Categories 1-5), n and (%) refer to the number and percent of subjects' ;
    footnote3 'who experience any one of the five suicidal ideation events at least once during corresponding time period.';
    footnote4 'For the composite endpoint of suicidal behavior (Categories 6-10), n and (%) refer to the number and percent of subjects' ;
    footnote5 'who experience any one of the five suicidal behavior events at least once during corresponding time period.';
    footnote6 'For the composite endpoint of suicidal ideation or behavior (Categories 1-10), n and (%) refer to the number and percent of subjects ';
    footnote7 'who experience any one of the ten suicidal ideation or behavior events at least once during corresponding time period.' ;
    footnote8 'Percentages are based on number of subjects having the assessment done at the respective time point.';
    footnote9 &idfoot ;
%END;







/* 8.2 Efficacy */
%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_1_1_1_hfss_mhf_s) AND &tableno = 1 %THEN %DO;
    title1 "Table: $&param.$: summary statistics and change from baseline by treatment group";
    title2 "<cont> &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case data was missing for more than 2 days within a week, the value for that particular week was set to missing.';
    footnote3 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote4 'SD = Standard Deviation' ;
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_1_1_1_hfss_mhf_p) AND &tableno = 1 %THEN %DO;
    title1 "Table: $&param.$: summary statistics and relative change (%) from baseline";
    title2 "<cont>by treatment group &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case data was missing for more than 2 days within a week, the value for that particular week was set to missing.';
    footnote3 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote4 'SD = Standard Deviation' ;
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_1_2_1_hfss_shf_s) AND &tableno = 1 %THEN %DO;
    title1 "Table: $&param.$: summary statistics and change from baseline by treatment group";
    title2 "<cont> &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case data was missing for more than 2 days within a week, the value for that particular week was set to missing.';
    footnote3 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote4 'SD = Standard Deviation' ;
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_1_2_1_hfss_shf_p) AND &tableno = 1 %THEN %DO;
    title1 "Table: $&param.$: summary statistics and relative change (%) from baseline";
    title2 "<cont>by treatment group &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case data was missing for more than 2 days within a week, the value for that particular week was set to missing.';
    footnote3 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote4 'SD = Standard Deviation' ;
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_3_1_adtte_km_qs) AND &tableno = 1 %THEN %DO;
    title1 "Table: Time to treatment response reduction of 50% in the first 12 weeks in mean daily frequency of moderate to severe hot flashes by treatment group: Descriptive statistics";
    title2 "<cont> &fas_label";
    footnote1 "^&super_a.censored observation.";
    footnote2 'A: Value cannot be estimated due to censored data.';
    footnote3 'Median, percentile and other 95% CIs computed using Kaplan-Meier estimates.' ;
    footnote4 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks' ;
    footnote5 'Time to treatment response =  the first week after baseline at which the baseline value of a participant was reduced by 50%';
    footnote6 'CI = Confidence Interval.';
    footnote7 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_1_3_1_adqs_ts_s) AND &tableno = 1 %THEN %DO;
    title1 "Table: PROMIS SD SF 8b total T-score: summary statistics and change from baseline by treatment group";
    title2 "<cont> &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'Total score converted as T-score.';
    footnote3 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote4 'SD = Standard Deviation' ;
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_1_3_1_adqs_trs_s) AND &tableno = 1 %THEN %DO;
    title1 "Table: PROMIS SD SF 8b total raw score: summary statistics and change from baseline by treatment group ";
    title2 "<cont> &fas_label";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'SD = Standard Deviation' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_1_3_1_adqs_rs_f) AND &tableno = 1 %THEN %DO;
    title1 "Table: PROMIS SD SF 8b raw item score: number of subjects by treatment group &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_1_4_1_adqs_ms_s) AND &tableno = 1 %THEN %DO;
    title1 "Table: MENQOL total score: summary statistics and change from baseline by treatment group";
    title2 "<cont> &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'SD = Standard Deviation' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_2_adqs_bdi_s) AND &tableno = 1 %THEN %DO;
    title1 "Table: BDI-II total score: summary statistics and change from baseline by treatment group &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'SD = Standard Deviation' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_2_adqs_bdi_t) AND &tableno = 1 %THEN %DO;
    title1 "Table: Transitions from baseline by time in BDI-II-total-score: number of subjects &fas_label";
    footnote1 'Only subjects with valid values at both baseline and after start of treatment are included.' ;
    footnote2 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote3 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_3_1_hfss_mdhf_s) AND &tableno = 1 %THEN %DO;
    title1 "Table: $&param.$: summary statistics and change from baseline by treatment group";
    title2 "<cont> &fas_label";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case data was missing for more than 2 days within a week, the value for that particular week was set to missing. ';
    footnote3 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote4 'SD = Standard Deviation' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_3_1_hfss_nta_s) AND &tableno = 1 %THEN %DO;
    title1 "Table: Mean frequency of nighttime awakenings: summary statistics and change from baseline by treatment group";
    title2 "<cont> &fas_label";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case data was missing for more than 2 days within a week, the value for that particular week was set to missing.' ;
    footnote3 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote4 'SD = Standard Deviation' ;
    footnote5 &idfoot ;

%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_3_1_hfss_sd_s) AND &tableno = 1 %THEN %DO;
    title1 "Table: Proportion of days (%) with participants having reported 'quite a bit' or 'very much' sleep disturbance due to HF:";
    title2 "<cont> summary statistics and change from baseline by treatment group &fas_label";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'SD = Standard Deviation' ;
    footnote4 &idfoot ;

%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_3_2_adqs_ind_s) AND &tableno = 1 %THEN %DO;
    title1 "Table: MENQOL - $paramcd1$ score: summary statistics and change from baseline by treatment group";
    title2 "<cont> &fas_label";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'SD = Standard Deviation' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_3_2_adqs_vas_s) AND &tableno = 1 %THEN %DO;
    title1 "Table: MENQOL - Vasomotor score: summary statistics and change from baseline by treatment group";
    title2 "<cont> &fas_label";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'SD = Standard Deviation' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_3_2_adqs_psy_s) AND &tableno = 1 %THEN %DO;
    title1 "Table: MENQOL - Psychosocial score: summary statistics and change from baseline by treatment group";
    title2 "<cont> &fas_label";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'SD = Standard Deviation' ;
    footnote4 &idfoot ;
%END;
%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_3_2_adqs_phy_s) AND &tableno = 1 %THEN %DO;
    title1 "Table: MENQOL - Physical score: summary statistics and change from baseline by treatment group";
    title2 "<cont> &fas_label";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'SD = Standard Deviation' ;
    footnote4 &idfoot ;

%END;
%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_3_2_adqs_sex_s) AND &tableno = 1 %THEN %DO;
    title1 "Table: MENQOL - Sexual score: summary statistics and change from baseline by treatment group";
    title2 "<cont> &fas_label";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'SD = Standard Deviation' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_3_3_adqs_isits_s) AND &tableno = 1 %THEN %DO;
    title1 "Table: ISI total score: summary statistics and change from baseline by treatment group";
    title2 "<cont> &fas_label";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'SD = Standard Deviation' ;
    footnote4 &idfoot ;
%END;
%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_3_3_adqs_isi_sev) AND &tableno = 1 %THEN %DO;
    title1 "Table: Severity ISI categories: number of subjects by treatment group &fas_label";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 '0-7 no clinically significant insomnia, 8-14 subthreshold insomnia,15-21 clinical insomnia (moderate severity), 22-28 clinical insomnia (severe).' ;
    footnote3 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_3_3_adqs_isitst) AND &tableno = 1 %THEN %DO;
    title1 "Table: Transitions from baseline in Severity ISI categories by time: number of subjects &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'Only subjects with valid values at both baseline and after start of treatment are included.';
    footnote3 '0-7 no clinically significant insomnia, 8-14 subthreshold insomnia,15-21 clinical insomnia (moderate severity), 22-28 clinical insomnia (severe).' ;
    footnote4 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_3_5_adqs_eq5d_s) AND &tableno = 1 %THEN %DO;
    title1 "Table: EQ-5D-5L VAS: summary statistics and change from baseline by treatment group &fas_label";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'SD = Standard Deviation' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_5_hfss_mdhfssf_s) AND &tableno = 1 %THEN %DO;
    title1 "Table: Mean daily frequency of moderate to severe hot flashes: summary statistics and change";
    title2 "<cont> from baseline by treatment group  &fas_label";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'SD = Standard Deviation' ;
    footnote3 &idfoot ;

%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_5_hfss_mdhfsss_s) AND &tableno = 1 %THEN %DO;
    title1 "Table: Mean daily severity of moderate to severe hot flashes: summary statistics and change";
    title2 "<cont> from baseline by treatment group  &fas_label";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'SD = Standard Deviation' ;
    footnote3 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_5_adqs_psdtss_s) AND &tableno = 1 %THEN %DO;
    title1 "Table: PROMIS SD SF 8b total T-score: summary statistics and change from baseline by treatment group";
    title2 "<cont> &fas_label";

    footnote1 'Total score converted as T-score';
    footnote2 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote3 'SD = Standard Deviation' ;

    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_5_adqs_psdtsi_s) AND &tableno = 1 %THEN %DO;
    title1 "Table: PROMIS SD SF 8b total T-score: summary statistics and change from baseline by treatment group";
    title2 "<cont> &fas_label";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'SD = Standard Deviation' ;
    footnote3 'Total score converted as T-score.';
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_5_adqs_ments_s) AND &tableno = 1 %THEN %DO;
    title1 "Table:  MENQOL total score: summary statistics and change from baseline by treatment group";
    title2 "<cont> &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'SD = Standard Deviation' ;
    footnote3 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_6_adpr_frq) AND &tableno = 1 %THEN %DO;
    title1 "Table: Number of subjects with gynecological ultrasound performed";
    title2 " <cont> &saf_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'SD = Standard Deviation' ;
    footnote3 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_6_2_adpr_sbase) AND &tableno = 1 %THEN %DO;
    title1 "Table: Endometrial thickness: summary statistics and change from baseline by treatment group";
    title2 " <cont> &saf_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_3_advs_pe) AND &tableno = 1 %THEN %DO;
    title1 "Table: Physical examination: summary statistics and changes from baseline by treatment group ";
    title2 " <cont> $paramcd$ &saf_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'SD = Standard Deviation' ;
    footnote3 'EoT = End of Treatment' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_5_1_adlb_sbase) AND &tableno = 1 %THEN %DO;
    title1 "Table: Laboratory data: summary statistics and change from baseline by visit-";
    title2 "<cont>$parcat1$, $paramn$ ";
    title3 "<cont> &saf_label ";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 "For laboratory values lower than a limit of detection X, which are given as <X , half the value of X was used for analysis.";
    footnote3 "For values higher than a limit of detection Y, which are >Y, the value of Y was used for analysis.";
    footnote4 'SD = Standard Deviation' ;
    footnote5 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_5_2_adlb_sbase) AND &tableno = 1 %THEN %DO;
    title1 "Table: Laboratory data: summary statistics and change from baseline by visit-";
    title2 "<cont>$parcat1$, $paramn$ ";
    title3 "<cont> &saf_label ";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 "For laboratory values lower than a limit of detection X, which are given as <X , half the value of X was used for analysis.";
    footnote3 "For values higher than a limit of detection Y, which are >Y, the value of Y was used for analysis.";
    footnote4 'SD = Standard Deviation' ;
    footnote5 "&idfoot";
%END;
%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_5_3_adlb_sbase) AND &tableno = 1 %THEN %DO;
    title1 "Table: Laboratory data: summary statistics and change from baseline by visit-";
    title2 "<cont>$parcat1$, $paramn$ ";
    title3 "<cont> &saf_label ";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 "For laboratory values lower than a limit of detection X, which are given as <X , half the value of X was used for analysis.";
    footnote3 "For values higher than a limit of detection Y, which are >Y, the value of Y was used for analysis.";
    footnote4 'SD = Standard Deviation' ;
    footnote5 "&idfoot";
%END;
%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_5_4_adlb_sbase) AND &tableno = 1 %THEN %DO;
    title1 "Table: Laboratory data: summary statistics and change from baseline by visit-";
    title2 "<cont>$parcat1$, $paramn$ ";
    title3 "<cont> &saf_label ";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 "For laboratory values lower than a limit of detection X, which are given as <X , half the value of X was used for analysis.";
    footnote3 "For values higher than a limit of detection Y, which are >Y, the value of Y was used for analysis.";
    footnote4 'SD = Standard Deviation' ;
    footnote5 "&idfoot";
%END;
%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_5_5_adlb_sbase) AND &tableno = 1 %THEN %DO;
    title1 "Table: Laboratory data: summary statistics and change from baseline by visit-";
    title2 "<cont>$parcat1$, $paramn$ ";
    title3 "<cont> &saf_label ";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 "For laboratory values lower than a limit of detection X, which are given as <X , half the value of X was used for analysis.";
    footnote3 "For values higher than a limit of detection Y, which are >Y, the value of Y was used for analysis.";
    footnote4 'SD = Standard Deviation' ;
    footnote5 "&idfoot";
%END;
%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_5_6_adlb_sbase) AND &tableno = 1 %THEN %DO;
    title1 "Table: Laboratory data: summary statistics and change from baseline by visit-";
    title2 "<cont>$parcat1$, $paramn$ ";
    title3 "<cont> &saf_label ";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 "For laboratory values lower than a limit of detection X, which are given as <X , half the value of X was used for analysis.";
    footnote3 "For values higher than a limit of detection Y, which are >Y, the value of Y was used for analysis.";
    footnote4 'SD = Standard Deviation' ;
    footnote5 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_5_6_adlb_frq) AND &tableno = 1 %THEN %DO;
    title1 "Table: Laboratory data: Number of subjects by $parcat1$, $paramn$ and visit by treatment group &saf_label";
    footnote1 'Placebo  - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg';
    footnote3 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_3_1_hfss_mdhf_fr) AND &tableno = 1 %THEN %DO;
    title1 'Table: Proportion of subjects with $crit$ of moderate to severe hot flashes by treatment ';
    title2 "<cont>group  &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_3_1_hfss_hf_s) AND &tableno = 1 %THEN %DO;
    title1 'Table: Proportion of subjects with at least a reduction of 50% in mean daily frequency of moderate to severe hot flashes';
    title2 "<cont> by treatment group &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_3_2_adqs_trs_s) AND &tableno = 1 %THEN %DO;
    title1 'Table: Proportion of subjects with $crit$ in PROMIS SD SF 8b total raw score';
    title2 "<cont> by treatment group  &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_1_4_1_adqs_rs1) AND &tableno = 1 %THEN %DO;
    title1 'Table: PROMIS SD SF 8b $paramcd$: number of subjects by treatment group';
    title2 "<cont>  &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_3_3_adqs_men_f) AND &tableno = 1 %THEN %DO;
    title1 'Table: Proportion of subjects with $crit$ in MENQOL total score by treatment group';
    title2 "<cont> by treatment group  &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_3_4_adqs_isits_fr) AND &tableno = 1 %THEN %DO;
    title1 'Table: Proportion of subjects with at least a reduction of $crit$';
    title2 "<cont>in ISI total score by treatment group  &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_3_4_adqs_pgic) AND &tableno = 1 %THEN %DO;
    title1 "Table:  PGI-C $paramcd$: number of subjects by treatment group ";
    title2 "<cont> &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_3_4_adqs_pgis) AND &tableno = 1 %THEN %DO;
    title1 "Table:  PGI-S $paramcd$: number of subjects by treatment group ";
    title2 "<cont> &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_3_4_adqs_pgit) AND &tableno = 1 %THEN %DO;
    title1 "Table: Transitions from baseline in PGI-S item $paramcd$ by time: number of subjects by treatment group";
    title2 "<cont> &fas_label";
    footnote1 "Only subjects with valid values at both baseline and after start of treatment are included.";
    footnote2 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote3 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote4 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_3_5_adqs_eq5d_f) AND &tableno = 1 %THEN %DO;
    title1 "Table:  EQ-5D-5L $paramcd$: number of subjects by treatment group  &fas_label";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_2_3_5_adqs_eq5d_t) AND &tableno = 1 %THEN %DO;
    title1 "Table: Transitions from baseline in EQ-5D-5L item &title. by time: number of subjects";
    title2 "<cont> &fas_label";
    footnote1 "Only subjects with valid values at both baseline and after start of treatment are included.";
    footnote2 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote3 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote4 &idfoot ;
%END;
/*Safety population*/
%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_5_8_1_adlb_frq) AND &tableno = 1 %THEN %DO;
    title1 "Table: Number of subjects by cumulative hepatic safety laboratory parameter category";
    title2 " <cont> &saf_label";
    footnote1 'Placebo  - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'ULN = Upper Limit of Normal';
    footnote3 'AST = Aspartate Aminotransferase, ALT = Alanine Transferase, ALP = Alkaline Phosphatase, INR = International Normalized Ratio.';
    footnote4 'n = number of subjects with parameter assessment done at respective time point.';

    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_5_8_2_adlb_frq) AND &tableno = 1 %THEN %DO;
    title1 "Table: Number of subjects by combined hepatic safety laboratory categories relative to ULN";
    title2 " <cont> &saf_label";

    footnote1 'Placebo  - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'ULN = Upper Limit of Normal';
    footnote3 'AST = Aspartate Aminotransferase, ALT = Alanine Transferase, ALP = Alkaline Phosphatase';
    footnote4 'INR = International Normalized Ratio.';

    footnote5 'n = number of subjects with parameter assessments done at respective time point.';
    footnote6 "^&super_a.as collected on the CRF page 'Clinical Signs and Symptoms  with elevated liver enzymes'";

   footnote7 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_5_8_3_adlb_frq) AND &tableno = 1 %THEN %DO;
    title1 "Table: Number of subjects by combined hepatic safety laboratory categories relative to baseline";
    title2 " <cont> &saf_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'AST = Aspartate Aminotransferase, ALT = Alanine Transferase, ALP = Alkaline Phosphatase, BL = Baseline.';
    footnote3 'n = Number of subjects with parameter assessments done at baseline and at post-baseline.';
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_5_8_adlb_alt_km) AND &tableno = 1 %THEN %DO;
    title1 "Table: Cumulative incidence for ALT >= 3xULN by treatment group: Descriptive statistics";
    title2 " <cont> &saf_label";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 "^&super_a.Relative days from first study drug administration. n = cumulative number of subjects with events up to the day, inclusive. N = number of subjects at risk at that day.";
    footnote3 'Cum. prob. (%) = Kaplan-Meier estimates of the cumulative probability for an event, calculated as 100*(1 minus the Kaplan-Meier estimates of the survival function).';
    footnote4 'CI = Confidence Interval. Kaplan-Meier confidence limits are calculated using the complementary log-log transformation for estimating the standard error.';
    footnote5 'ALT = Alanine Aminotransferase , ULN = Upper Limit of Normal';
    footnote6 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_5_8_adlb_alp_km) AND &tableno = 1 %THEN %DO;
    title1 "Table: Cumulative incidence for ALP >= 3xULN by treatment group: Descriptive statistics";
    title2 " <cont> &saf_label";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 "^&super_a.Relative days from first study drug administration. n = cumulative number of subjects with events up to the day, inclusive. N = number of subjects at risk at that day.";
    footnote3 'Cum. prob. (%) = Kaplan-Meier estimates of the cumulative probability for an event, calculated as 100*(1 minus the Kaplan-Meier estimates of the survival function).';
    footnote4 'CI = Confidence Interval. Kaplan-Meier confidence limits are calculated using the complementary log-log transformation for estimating the standard error.';
    footnote5 'ALP = Alkaline Phosphatase, ULN = Upper Limit of Normal';
    footnote6 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_5_adpr_frq) AND &tableno = 1 %THEN %DO;
    title1 "Table: Number of subjects with overview of collected mammogram results";
    title2 " <cont> &saf_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'EoT = End of Treatment.';
    footnote3 'Percentages for main result are based on subjects having a mammogram performed.';
    footnote4 &idfoot ;
%END;



%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_5_7_adlb_low) AND &tableno = 1 %THEN %DO;
  title1 "Table: Treatment-emergent low laboratory abnormalities by laboratory category and treatment: number of subjects &saf_label.";


  footnote1 "Placebo  - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
  footnote2 "The denominator (Den) represents the number of subjects at baseline with a normal or higher than normal laboratory assessment,";
  footnote3 "and at least one valid laboratory value after start of treatment. Subjects with missing or low abnormal values at baseline";
  footnote4 "are not included in the denominator.";
  footnote5 "The numerator (Num) represents the number of subjects with at least one low laboratory assessment after the start of treatment,";
  footnote6 "and a normal or higher than normal laboratory assessment at baseline.";
  footnote7 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_5_7_adlb_high) AND &tableno = 1 %THEN %DO;
    title1 "Table: Treatment-emergent high laboratory abnormalities by laboratory category and treatment: number of subjects &saf_label.";


    footnote1 "Placebo  - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 "The denominator (Den) represents the number of subjects at baseline with a normal or lower than normal laboratory assessment,";
    footnote3 "and at least one valid laboratory value after start of treatment. Subjects with missing or high abnormal values at baseline are";
    footnote4 "not included in the denominator.";
    footnote5 "The numerator (Num) represents the number of subjects with at least one high laboratory assessment after the start of treatment,";
    footnote6 "and a normal or lower than normal laboratory assessment at baseline.";
    footnote7 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_5_8_3_adlb_frq) AND &tableno = 1 %THEN %DO;
    title1 "Table: Number of subjects by combined hepatic safety laboratory categories relative to baseline &saf_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'AST = Aspartate Aminotransferase, ALT = Alanine Transferase, ALP = Alkaline Phosphatase';
    footnote3 'n = number of subjects with parameter assessment done at respective time point.';
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_5_8_adlb_liv_hy) AND &tableno = 1 %THEN %DO;
    title1 "Table: Number of subjects with potential hepatocellular  DILI by treatment group &saf_label";

    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 "This table is generated using maximum treatment-emergent liver test abnormalities.";
    footnote3 "n=number of subjects meeting criteria. ";
    footnote4 "DILI=Drug-Induced Liver Injury";
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_5_8_alb_liv_alp) AND &tableno = 1 %THEN %DO;
    title1 "Table: Number of subjects with potential Cholestatic DILI by treatment group &saf_label";

    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 "This table is generated using maximum treatment-emergent liver test abnormalities.";
    footnote3 "n=number of subjects meeting criteria. ";
    footnote4 "ALP = Alkaline Phosphatase , DILI=Drug-Induced Liver Injury, ULN = Upper Limit of Normal";
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_3_5_8_alb_cyst_nu) AND &tableno = 1 %THEN %DO;
    title1 "Table: Number of subjects fulfilling the liver injury criteria &saf_label";
    footnote1 "Placebo  - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 "n = the number of subjects meeting close liver observation criteria as per Table 10-2 of the protocol.";
    footnote3 "Percentage for Case Met Close Liver Observation is based on total number of subjects (N), percentage for Cases Met Liver Injury Criteria is based on total number of Case Met Close Liver Observation (n).";
    footnote4 &idfoot ;
%END;

/*<------------------------------------------>*
*Figures Title and footnotes*
*<------------------------------------------>*/

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_1_7_tte_dis_km) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Kaplan-Meier-Plot of the time from randomization to permanent discontinuation of randomized treatment up to Week 12 &fas_label.";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2  'If "Permanent discontinuation of randomized treatment" did not occur by day 84, the participant is censored at week 12.';
    footnote3 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_1_7_tte_pcm_km) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Kaplan-Meier-Plot of the time from  randomization to first intake of prohibited concomitant medication having impact on efficacy up to Week 12 &fas_label.";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'If "Intake of prohibited concomitant medication having impact on efficacy" did not occur by day 84, the participant is censored at week 12 or at the time of dropping out of the study, whichever occurs earlier.';
    footnote3 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_1_1_hfss_mhf_s) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Line plot of change from baseline in mean daily frequency of moderate to severe hot flashes by treatment group &fas_label. ";
    footnote1  "Placebo  - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'CI = Confidence Interval' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_1_1_hfss_mhf_p) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Line plot of relative change (%) from baseline in mean daily frequency of moderate to severe hot flashes by treatment group &fas_label. ";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'CI = Confidence Interval' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_2_1_hfss_shf_s) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Line plot of change from baseline in mean daily severity of moderate to severe hot flashes by treatment group &fas_label. ";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'CI = Confidence Interval' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_2_1_hfss_shf_p) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Line plot of relative change (%) from baseline in mean daily severity of moderate to severe hot flashes by treatment group &fas_label. ";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'CI = Confidence Interval' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_3_1_adqs_line) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Line plot of change from baseline in PROMIS SD SF 8b total T-score by treatment group &fas_label. ";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'CI = Confidence Interval' ;
    footnote4 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_3_1_adqs_rbar) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Bar chart illustrating PROMIS SD SF 8b raw score of item $paramcd$ by treatment group over time &fas_label. ";

  footnote1'E = Elinzanetant 120 mg';
  footnote2 'P-E = Placebo for 12 weeks followed by elinzanetant 120mg for 14 weeks';
  footnote3 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
  footnote4 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_4_1_adqs_line) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Line plot of change from baseline in MENQOL total score by treatment group &fas_label. ";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'CI = Confidence Interval' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_3_1_hfss_md_lin) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Line plot of change from baseline in mean daily frequency of mild, moderate, and severe hot flashes by treatment group &fas_label.";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'CI = Confidence Interval' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_3_1_hfss_nt_lin) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Line plot of change from baseline in frequency of nighttime awakenings by treatment group &fas_label. ";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'CI = Confidence Interval' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_3_1_hfss_sd_lin ) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Line plot of change from baseline in proportion of days (%) with participants having reported 'quite a bit' or 'very much' sleep disturbance due to HF by treatment group";
    title2 "<cont>  &fas_label";

    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'CI = Confidence Interval' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_3_1_advs_mdev) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Line plot for vital signs - $paramcd$ by treatment group and visit &saf_label. ";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 "Figure describes the time course of mean and 95% confidence interval.";
    footnote3 'CI = Confidence Interval' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_3_2_advs_mdev) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Line plot for vital signs - $paramcd$ by treatment group and visit &saf_label. ";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 "Figure describes the time course of mean and 95% confidence interval.";
    footnote3 'CI = Confidence Interval' ;
    footnote4 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_3_1_1_adlb_scat) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Scatterplot of value against baseline value of - $paramcd$ by treatment group and visit &saf_label. ";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_3_3_adpe_box) AND &tableno = 1 %THEN %DO;
    title1 "Figure:  Box plot of $paramcd$ by treatment group &saf_label. ";
    footnote1  "Placebo  - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 "Box: 25th to 75th percentile; horizontal line: median : vertical lines extend from the box to a distance of at most 1.5 interquartile ranges and any value more extreme";
    footnote3 "is plotted separately;connect lines join arithmetic means by treatment group.";
    footnote4 &idfoot ;

%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_3_4_advs_box) AND &tableno = 1 %THEN %DO;
    title1 "Figure:  Box plot of $paramcd$ by treatment group &saf_label. ";
    footnote1  "Placebo  - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 "Box: 25th to 75th percentile; horizontal line: median : vertical lines extend from the box to a distance of at most 1.5 interquartile ranges and any value more extreme";
    footnote3 "is plotted separately;connect lines join arithmetic means by treatment group. ";
    footnote4 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_3_5_1_adlb_box) AND &tableno = 1 %THEN %DO;
    title1 "Figure:  Box plot of $parcat1$, $paramn$  by treatment group &saf_label. ";
    footnote1  "Placebo  - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 "Box: 25th to 75th percentile; horizontal line: median : vertical lines extend from the box to a distance of at most 1.5 interquartile ranges and any value more extreme";
    footnote3 "is plotted separately;connect lines join arithmetic means by treatment group. ";
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_3_5_2_adlb_box) AND &tableno = 1 %THEN %DO;
    title1 "Figure:  Box plot of $parcat1$, $paramn$  by treatment group &saf_label. ";
    footnote1  "Placebo  - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 "Box: 25th to 75th percentile; horizontal line: median : vertical lines extend from the box to a distance of at most 1.5 interquartile ranges and any value more extreme";
    footnote3 "is plotted separately;connect lines join arithmetic means by treatment group. ";
    footnote4 &idfoot ;
%END;
%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_3_5_3_adlb_box) AND &tableno = 1 %THEN %DO;
    title1 "Figure:  Box plot of $parcat1$, $paramn$  by treatment group &saf_label. ";
    footnote1  "Placebo  - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 "Box: 25th to 75th percentile; horizontal line: median : vertical lines extend from the box to a distance of at most 1.5 interquartile ranges and any value more extreme";
    footnote3 "is plotted separately;connect lines join arithmetic means by treatment group. ";
    footnote4 &idfoot ;
%END;
%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_3_5_4_adlb_box) AND &tableno = 1 %THEN %DO;
    title1 "Figure:  Box plot of $parcat1$, $paramn$  by treatment group &saf_label. ";
    footnote1  "Placebo  - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 "Box: 25th to 75th percentile; horizontal line: median : vertical lines extend from the box to a distance of at most 1.5 interquartile ranges and any value more extreme";
    footnote3 "is plotted separately;connect lines join arithmetic means by treatment group. ";
    footnote4 &idfoot ;
%END;
%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_3_5_5_adlb_box) AND &tableno = 1 %THEN %DO;
    title1 "Figure:  Box plot of $parcat1$, $paramn$  by treatment group &saf_label. ";
    footnote1  "Placebo  - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 "Box: 25th to 75th percentile; horizontal line: median : vertical lines extend from the box to a distance of at most 1.5 interquartile ranges and any value more extreme";
    footnote3 "is plotted separately;connect lines join arithmetic means by treatment group. ";
    footnote4 &idfoot ;
%END;
%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_3_5_6_adlb_box) AND &tableno = 1 %THEN %DO;
    title1 "Figure:  Box plot of $parcat1$, $paramn$  by treatment group &saf_label. ";
    footnote1  "Placebo  - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 "Box: 25th to 75th percentile; horizontal line: median : vertical lines extend from the box to a distance of at most 1.5 interquartile ranges and any value more extreme";
    footnote3 "is plotted separately;connect lines join arithmetic means by treatment group. ";
    footnote4 &idfoot ;

%END;
%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_3_5_7_adlb_box) AND &tableno = 1 %THEN %DO;
    title1 "Figure:  Box plot of $parcat1$, $paramn$  by treatment group &saf_label. ";
    footnote1  "Placebo  - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 "Box: 25th to 75th percentile; horizontal line: median : vertical lines extend from the box to a distance of at most 1.5 interquartile ranges and any value more extreme";
    footnote3 "is plotted separately;connect lines join arithmetic means by treatment group. ";
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_3_5_2_adlb_line) AND &tableno = 1 %THEN %DO;
title1 "Figure: Line plot of change from baseline in $parcat1$, $paramn$  by treatment group &saf_label. ";
    footnote1  "Placebo  - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 'CI = Confidence Interval;EoT = End of Treatment' ;
    footnote3 'Y-axis presents the mean +/- 95% CI' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_3_5_3_adlb_line) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Line plot of change from baseline in $parcat1$, $paramn$  by treatment group &saf_label. ";
    footnote1  "Placebo  - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 'CI = Confidence Interval;EoT = End of Treatment' ;
    footnote3 'Y-axis presents the mean +/- 95% CI' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_3_5_4_adlb_line) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Line plot of change from baseline in $parcat1$, $paramn$  by treatment group &saf_label. ";
    footnote1  "Placebo  - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 'CI = Confidence Interval;EoT = End of Treatment' ;
    footnote3 'Y-axis presents the mean +/- 95% CI' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_10_2_8_2_adlb_over) AND &tableno = 1 %THEN %DO;
    title1 "Figure: ALT, AST, Total bilirubin, ALP relative to ULN over time in subject $USUBJID$ of $&treat_arm_a.$ &saf_label. ";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 "Only subjects meeting close liver observation criteria are presented.";
    footnote3 "AST = Aspartate Aminotransferase, ALT = Alanine Transferase, ALP = Alkaline Phosphatase, ULN = Upper Limit of Normal.";
    footnote4 "* Study drug with missing stop date of treatment is indicated by Arrow.";
    footnote5 &idfoot ;

%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_10_2_8_2_adlb_inr) AND &tableno = 1 %THEN %DO;
    title1 "Figure: INR over time in subject $USUBJID$ of $&treat_arm_a.$ &saf_label. ";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 "Only subjects meeting close liver observation criteria are presented.";
    footnote3 "INR = International Normalized Ratio.";
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_3_5_8_adlb_alt_km ) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Cumulative incidence curve of time to Time to ALT >= 3xULN by treatment group &saf_label. ";

   footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 "Observations without an event are censored at the date of last visit." ;
    footnote3 "Subjects at risk were calculated as at start of timepoint";
    footnote4 "ALT = Alanine Aminotransferase, ULN = Upper Limit of Normal";
    footnote5 &idfoot ;

%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_3_5_8_adlb_alp_km ) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Cumulative incidence curve of time to  Time to ALP >= 3xULN by treatment group &saf_label. ";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 "Observations without an event are censored at the date of last visit." ;
    footnote3 "Subjects at risk were calculated as at start of timepoint.";
    footnote4 "ALP = Alkaline Phosphatase, ULN = Upper Limit of Normal.";
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_3_4_advs_line) AND &tableno = 1 %THEN %DO;
    title1 "Figure:  Line plot of change from baseline in $paramcd$ by treatment group &saf_label. ";
    footnote1  "Placebo  - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 'CI = Confidence Interval;EoT = End of Treatment' ;
    footnote3 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_3_4_advs_scat) AND &tableno = 1 %THEN %DO;
    title1  "Figure:  Scatter plot of $paramcd$ by treatment group &saf_label.";
    footnote1"Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_3_2_adqs_phy_l) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Line plot of change from baseline in MENQOL Physical score by treatment group &fas_label";

    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'CI = Confidence Interval' ;
    footnote4 &idfoot ;

%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_3_2_adqs_psy_l) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Line plot of change from baseline in MENQOL Psychosocial score by treatment group &fas_label";

    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'CI = Confidence Interval' ;
    footnote4 &idfoot ;

%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_3_2_adqs_sex_l) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Line plot of change from baseline in MENQOL Sexual score by treatment group &fas_label";

    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'CI = Confidence Interval' ;
    footnote4 &idfoot ;

%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_3_2_adqs_vas_l) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Line plot of change from baseline in  MENQOL Vasomotor score by treatment group &fas_label";

    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'CI = Confidence Interval' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_4_1_adqs_mdev) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Line plot of change from baseline in $paramcd$ total score by treatment group &fas_label. ";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote3 'CI = Confidence Interval' ;
    footnote4 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_3_2_adqshfss_mdev) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Line plot of change from baseline in $paramcd$ by treatment group &fas_label. ";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 'CI = Confidence Interval' ;
    footnote3 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_3_3_adqshfss_mdev) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Line plot of change from baseline in $paramcd$ by treatment group &fas_label. ";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 'CI = Confidence Interval' ;
    footnote3 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_3_1_adqs_cum) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Cumulative percent of subjects by change from baseline in PROMIS SD SF 8b total T-score at $avisitn$ &fas_label. ";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_4_1_adqs_cum) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Cumulative percent of subjects by change from baseline in MENQOL total score at $avisitn$ &fas_label. ";

    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_3_1_hfss_hf_cum) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Cumulative percent of subjects by change from baseline in mean daily frequency of moderate to severe hot flashes at $avisitn$ &fas_label. ";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 &idfoot ;
%END;
%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_3_1_hfss_cg_cum) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Cumulative percent of subjects by relative change (%) from baseline in mean daily frequency of moderate to severe hot flashes at $avisitn$ &fas_label. ";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_3_1_shf_hf_cum) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Cumulative percent of subjects by change from baseline in mean daily severity of moderate to severe hot flashes at  $avisitn$ &fas_label. ";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_3_1_shf_cg_cum) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Cumulative percent of subjects by relative change (%) from baseline in mean daily severity of moderate to severe hot flashes at $avisitn$ &fas_label. ";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_3_1_adtte_km_cum) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Cumulative incidence plot of time to treatment response reduction of 50% in the first 12 weeks in mean daily frequency of moderate to severe hot flashes by treatment group &fas_label. ";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_3_1_hfss_nta_cum ) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Cumulative percent of subjects by change from baseline in mean frequency of nighttime awakenings  $avisitn$ &fas_label. ";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_1_7_tte_dis_km) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Kaplan-Meier-Plot of the time from randomization to permanent discontinuation of randomized treatment &fas_label.";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_1_7_tte_pcm_km) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Kaplan-Meier-Plot of the time from  randomization to first intake of prohibited concomitant medication having impact on efficacy &fas_label.";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_3_5_adlb_scat) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Scatterplot for maximum ALT (post-baseline) vs maximum AST (post-baseline)  &saf_label.";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks";
    footnote2 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_3_5_8_adlb_liv_hy) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Hepatocellular drug-induced liver injury screening plot  &saf_label";

    footnote1 "Each data point represents a subject  plotted by their maximum ALT or AST versus their maximum total bilirubin values in the post-baseline period." ;
    footnote2 "A potential Hy's Law case (red circle) was defined as having any post-baseline total bilirubin equal to or exceeding 2 x ULN within 30 days after a" ;
    footnote3 "post-baseline ALT or AST equal to or exceeding 3 x ULN, and ALP <2 x ULN (note ALP values are not circled). All patients with at least one" ;
    footnote4 "post-baseline ALT or AST and bilirubin are plotted." ;
    footnote5 "ALP =alkaline phosphatase, ALT=alanine aminotransferase, AST=aspartate aminotransferase, DILI=drug-induced liver injury, ULN=upper limit of normal." ;
    footnote6 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_3_5_8_alb_liv_alp) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Cholestatic drug-induced liver injury screening plot &saf_label";

    footnote1 "Each data point represents a subject plotted by their maximum ALT or AST versus their maximum total bilirubin values in the post-baseline period." ;
    footnote2 "A potential cholestatic drug-induced liver injury case (red circled) was defined as having a maximum postbaseline total bilirubin equal to or exceeding" ;
    footnote3 "2 x ULN within 30 days after postbaseline ALP became equal to or exceeding 2 x ULN." ;
    footnote4 "ALP =alkaline phosphatase, ULN=upper limit of normal." ;
    footnote5 &idfoot ;
%END;

/* 8.2 MMRM Efficacy */

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(i_8_2_1_gloss_endpt) AND &tableno = 1 %THEN %DO;
    title1 "Table: Glossary: Overview of estimands addressing the primary and key secondary efficacy";

    footnote1 "^&super_a.Primary endpoint for submission in the United States and key secondary endpoint for all other regions except regulatory submission in the United States";
    footnote2 'Population (and analysis set used representing the population): Post menopause women aged 40-65 with VMS (assigned to treatment: Full analysis set)';
    footnote3 'HF=Hot flashes, HFDD = Hot flash daily diary, MENQOL  = Menopause-specific quality of life questionnaire,';
    footnote4 'PROMIS SD SF 8b = Patient-Reported Outcomes Measurement Information System Sleep Disturbance short-form 8b, VMS = Vasomotor symptoms';
    footnote5 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_1_2_hfss_scat ) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Scatterplot of residuals and predicted values from MMRM on change from baseline in mean daily frequency of moderate to severe hot flashes &fas_label";
    footnote1 "MMRM = Mixed Model Repeated Measures";
    footnote2 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_1_2_hfss_qq) AND &tableno = 1 %THEN %DO;
    title1 "Figure: QQ-plot from MMRM on change from baseline in mean daily frequency of moderate to severe hot flashes &fas_label";
    footnote1 "MMRM = Mixed Model Repeated Measures";
    footnote2 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(i_8_2_1_1_2_hfss_np) AND &tableno = 1 %THEN %DO;
    title1 "Table: Change from baseline in mean daily frequency of moderate to severe hot flashes - non-parametric analysis - by treatment group &fas_label";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'P-value is based on non-parametric rank ANCOVA, n = number of subjects with observed value for this timepoint and considered in the analysis model.';
    footnote3 'SE = Standard Error, CI = Confidence Interval' ;
    footnote4 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(i_8_2_1_1_2_hfss_tp) AND &tableno = 1 %THEN %DO;
    title1 "Table: Tipping point analysis for change from baseline in mean daily frequency of moderate to severe hot flashes - MMRM analysis at $week$  &fas_label";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'LS-Means = Least Squares Means, MMRM = Mixed Model Repeated Measures, CI = Confidence Interval';
    footnote3 '+ x is the delta value added to the change in the tipping point analysis.' ;
    footnote4 &idfoot ;

%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_2_2_shf_scat ) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Scatterplot of residuals and predicted values from MMRM on change from baseline in mean daily severity of moderate to severe hot flashes &fas_label";
    footnote1 "MMRM = Mixed Model Repeated Measures";
    footnote2 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_2_2_shf_qq ) AND &tableno = 1 %THEN %DO;
    title1 "Figure: QQ-Plot from MMRM on change from baseline in mean daily severity of moderate to severe hot flashes &fas_label";
    footnote1 "MMRM = Mixed Model Repeated Measures";
    footnote2 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_3_2_pr_scat ) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Scatterplot of residuals and predicted values from MMRM on change from baseline in PROMIS SD SF 8b total T-score &fas_label";
    footnote1 "MMRM = Mixed Model Repeated Measures";
    footnote2 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_3_2_pr_qq ) AND &tableno = 1 %THEN %DO;
    title1 "Figure: QQ-Plot from MMRM on change from baseline in PROMIS SD SF 8b total T-score &fas_label";
    footnote1 "MMRM = Mixed Model Repeated Measures";
    footnote2 &idfoot ;
%END;




%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_4_2_mq_scat ) AND &tableno = 1 %THEN %DO;
    title1 "Figure: Scatterplot of residuals and predicted values from MMRM on change from baseline in MENQOL total score &fas_label";
    footnote1 "MMRM = Mixed Model Repeated Measures";
    footnote2 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(f_8_2_1_4_2_mq_qq ) AND &tableno = 1 %THEN %DO;
    title1 "Figure: QQ-Plot from MMRM on change from baseline in MENQOL total score &fas_label";
    footnote1 "MMRM = Mixed Model Repeated Measures";
    footnote2 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(i_8_2_1_2_2_shf_np) AND &tableno = 1 %THEN %DO;
    title1 "Table: Change from baseline in mean daily severity of moderate to severe hot flashes - non-parametric analysis - by treatment group &fas_label";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'P-value is based on non-parametric rank ANCOVA, n = number of subjects with observed value for this timepoint and considered in the analysis model.';
    footnote3 'SE = Standard Error, CI = Confidence Interval.' ;
    footnote4 &idfoot ;

%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(i_8_2_1_3_2_pr_np) AND &tableno = 1 %THEN %DO;
    title1 "Table: Change from baseline in PROMIS SD SF 8b total T-score - non-parametric analysis - by treatment group &fas_label";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'P-value is based on non-parametric rank ANCOVA, n = number of subjects with observed value for this timepoint and considered in the analysis model.';
    footnote3 'SE = Standard Error, CI = Confidence Interval' ;
    footnote4 &idfoot ;

%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(i_8_2_1_4_2_mq_np) AND &tableno = 1 %THEN %DO;
    title1 "Table: Change from baseline in MENQOL total score - non-parametric analysis - by treatment group &fas_label";

    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'P-value is based on non-parametric rank ANCOVA, n = number of subjects with observed value for this timepoint and considered in the analysis model.';
    footnote3 'SE = Standard Error, CI = Confidence Interval' ;
    footnote4 &idfoot ;

%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(i_8_2_1_2_2_shf_tp) AND &tableno = 1 %THEN %DO;
    title1 "Table: Tipping point analysis for change from baseline in mean daily severity of moderate to severe hot flashes - MMRM analysis at $week$  &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'LS-Means = Least Squares Means, MMRM = Mixed Model Repeated Measures, CI = Confidence Interval';
    footnote3 '+ x is the delta value added to the change in the tipping point analysis.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(i_8_2_1_3_2_pr_tp) AND &tableno = 1 %THEN %DO;
    title1 "Table: Tipping point analysis for change from baseline in PROMIS SD SF 8b total T-score - MMRM analysis at $week$  &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.';
    footnote2 'LS-Means = Least Squares Means, CI = Confidence Interval, MMRM = Mixed Model Repeated Measures';
    footnote3 '+ x is the delta value added to the change in the tipping point analysis.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(i_8_2_1_4_2_mq_tp) AND &tableno = 1 %THEN %DO;
    title1 "Table: Tipping point analysis for change from baseline in MENQOL total score - MMRM analysis at $week$  &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'LS-Means = Least Squares Means, CI = Confidence Interval, MMRM = Mixed Model Repeated Measures';
    footnote3 '+ x is the delta value added to the change in the tipping point analysis.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(i_8_2_1_3_1_pr) AND &tableno = 1 %THEN %DO;
    title1 "Table: PROMIS SD SF 8b total T-score change from baseline - MMRM analysis - by treatment group &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'n = number of subjects with observed value for this timepoint and considered in the analysis model.';
    footnote3 'Multiple imputation is used to impute missing values.' ;
    footnote4 'LS-Means = Least Squares Means, SE = Standard Error, MMRM = Mixed Model Repeated Measures, CI = Confidence Interval' ;
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(i_8_2_1_3_3_pr_sp1) AND &tableno = 1 %THEN %DO;
    title1 "Table: First supplementary estimand - change from baseline in PROMIS SD SF 8b total T-score - MMRM analysis - by treatment group &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'n = number of subjects with observed value for this timepoint and considered in the analysis model.';
    Footnote3 'Pattern mixture modelling using multiple imputation has been used to impute missing values or values discarded due to hypothetical strategy.';
    footnote4 'LS-Means = Least Squares Means, SE = Standard Error, MMRM = Mixed Model Repeated Measures, CI = Confidence Interval' ;
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(i_8_2_1_3_3_pr_sp2) AND &tableno = 1 %THEN %DO;
    title1 "Table: Second supplementary estimand - change from baseline in PROMIS SD SF 8b total T-score - MMRM analysis - by treatment group &fas_label";
        footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
        footnote2 'n = number of subjects with observed value for this timepoint and considered in the analysis model.';
        Footnote3 'Pattern mixture modelling using multiple imputation has been used to impute missing values or values discarded due to hypothetical strategy.';
        footnote4 'LS-Means = Least Squares Means, SE = Standard Error, MMRM = Mixed Model Repeated Measures, CI = Confidence Interval' ;
        footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(i_8_2_1_4_1_mq) AND &tableno = 1 %THEN %DO;
    title1 "Table: MENQOL total score change from baseline - MMRM analysis - by treatment group &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'n = number of subjects with observed value for this timepoint and considered in the analysis model.';
    footnote3 'Multiple imputation is used to impute missing values.' ;
    footnote4 'LS-Means = Least Squares Means, SE = Standard Error, MMRM = Mixed Model Repeated Measures, CI = Confidence Interval' ;
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(i_8_2_1_4_3_mq_sp1) AND &tableno = 1 %THEN %DO;
    title1 "Table: First supplementary estimand - change from baseline in MENQOL total score - MMRM analysis - by treatment group &fas_label";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'n = number of subjects with observed value for this timepoint and considered in the analysis model.';
    Footnote3 'Pattern mixture modelling using multiple imputation has been used to impute missing values or values discarded due to hypothetical strategy.';
    footnote4 'LS-Means = Least Squares Means, SE = Standard Error, MMRM = Mixed Model Repeated Measures, CI = Confidence Interval' ;
    footnote5- &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(i_8_2_1_4_3_mq_sp2) AND &tableno = 1 %THEN %DO;
    title1 "Table: Second supplementary estimand - change from baseline in MENQOL total score - MMRM analysis - by treatment group &fas_label";
        footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
        footnote2 'n = number of subjects with observed value for this timepoint and considered in the analysis model.';
        Footnote3 'Pattern mixture modelling using multiple imputation has been used to impute missing values or values discarded due to hypothetical strategy.';
        footnote4 'LS-Means = Least Squares Means, SE = Standard Error, MMRM = Mixed Model Repeated Measures, CI = Confidence Interval' ;
        footnote5 &idfoot ;
%END;

/*<------------------------------------------>*
*Listing  Title and footnotes*
*<------------------------------------------>*/


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_1_6_spda_batch) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Batch listing';
    footnote1 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_1_7_adsl_rand) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Randomization Scheme and Codes';
    footnote1 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_1_1_adds_screen) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Subjects who did not complete or pass screening';
    footnote1  'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_1_2_adds_discon) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Discontinued subjects';
    footnote1  'This listing displays information of discontinuation for each subject who started any study epoch (excluding screening), but did not complete it.';
    footnote2  'Sex is identified as: M = Male, F = Female.';
    footnote3 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote4 'The unit for "Age" is years.' ;
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_1_2_cvd) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Listing of subjects affected by COVID-19 pandemic related study disruption';
    footnote1 'Race: A = Asian B = Black W = White AI = American Indian or Alaska Native NH = Native Hawaiian or Other Pacific Islander NR = Not Reported MUL=Multiple.';
    footnote2  'Sex: F = female, M = male.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_2_addv_pd) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Protocol deviations';
    footnote1  'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, M=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 'Only important protocol deviations are listed.';
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_2_addv_imp_pd_cvd) AND &tableno = 1 %THEN %DO;
    title1 "Listing: Listing of important protocol deviations associated with COVID-19 pandemic";
    footnote1 'Race: A = Asian B = Black W = White AI = American Indian or Alaska Native NH = Native Hawaiian or Other Pacific Islander NR = Not Reported MUL=Multiple.';
    footnote2 'Sex: F = female, M = male.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_2_addv_cvd) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Listing of protocol deviations associated with COVID-19 pandemic';
    footnote1 'Race: A = Asian B = Black W = White AI = American Indian or Alaska Native NH = Native Hawaiian or Other Pacific Islander NR = Not Reported MUL=Multiple.';
    footnote2  'Sex: F = female, M = male.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_2_adsl_trt_grp) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Subjects whose actual treatment group was not the planned (randomized) treatment';
    footnote1  'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_3_adsl_analy_set) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Analysis sets';
    footnote1  'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_4_ie_demo) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Inclusion/exclusion criteria';
    footnote1 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_4_ie_demo_not_met) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Inclusion and exclusion criteria not met';
    footnote1  'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 'Listing is based on final eligibility assessment of protocol deviation for inclusion/exclusion criteria not met.' ;
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_4_adds_demo_cons) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Informed consent';
    footnote1  'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 'Protocol Amendment Number 0 refers to the original protocol.';
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_4_adds_demo_enr_rd) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Enrollment and randomization';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 'Only the first informed consent date is listed.';
    footnote5 'Protocol Amendment Number 0 refers to the original protocol.';
    footnote6 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_4_adsl_demo) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Demographics';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_4_adqs_mht) AND &tableno = 1 %THEN %DO;
    title1 'Listing: History of menopause hormone therapy';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.';
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_4_su_demo_smoke) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Smoking history';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_4_admh_demo) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Medical history';
    footnote1  'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_4_adcm_demo) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Prior and concomitant medications';
    footnote1  'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_4_adrp_demo) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Reproductive and menstrual history';
    footnote1  'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 'The unit for "How Long Has Subject Been Amenorrheic" is years.' ;
    footnote5 &idfoot ;
%END;

/*<------------------------------------------>*
*Listing _2 Title and footnotes*
*<------------------------------------------>*/



%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_5_spda) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Drug accountability';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_5_spec_intake) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Study drug intake documentation';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_5_adex_trt_expo) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Treatment exposure ';
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'Sex is identified as: M = Male, F = Female.';
    footnote3 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote4 'The unit for "Age" is years.' ;
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_5_adex_stdy_expo) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Study drug exposure';
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'Sex is identified as: M = Male, F = Female.';
    footnote3 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote4 'The unit for "Age" is years.' ;
    footnote5 '"Treatment Duration" is a derived variable that includes the time from the first day through the last day of treatment.';
    footnote6 'Week 1-12 represents the placebo controlled period of the study.';
    footnote7 'Week 13-26 represents the period at which all participants are treated with elinzanetant';
    footnote8 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_5_spec_trt_intr) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Treatment interruptions ';
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'Sex is identified as: M = Male, F = Female.';
    footnote3 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote4 'The unit for "Age" is years.' ;
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_6_1_1spqs) AND &tableno = 1 %THEN %DO;
    title1 "Listing: Questionnaires &label.";
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_6_1_2spqs) AND &tableno = 1 %THEN %DO;
    title1 "Listing: Questionnaires &label.";
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_6_1_3spqs) AND &tableno = 1 %THEN %DO;
    title1 "Listing: Questionnaires &label.";
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_6_1_4spqs) AND &tableno = 1 %THEN %DO;
    title1 "Listing: Questionnaires &label.";
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_6_1_5spqs) AND &tableno = 1 %THEN %DO;
    title1 "Listing: Questionnaires &label.";
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_6_1_6spqs) AND &tableno = 1 %THEN %DO;
    title1 "Listing: Questionnaires &label.";
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_6_1_7spqs) AND &tableno = 1 %THEN %DO;
    title1 "Listing: Questionnaires &label.";
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_6_1_8spqs) AND &tableno = 1 %THEN %DO;
    title1 "Listing: Questionnaires &label.";
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_6_2_sppc_plsm_cnct) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Concentrations for Elinzanetant in Plasma ';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_6_2_adds_info_const) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Clinical laboratory data: Subjects who signed Pharmacogenetics informed consent ';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_7_adae) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Adverse events';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 'AE = Adverse Event';
    footnote5 'Remedial drug therapy refers to concomitant medication given to treat the AE.';
    footnote6 'Relative Day is the day relative to the start or end of study drug.';
    footnote7 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_7_adae_meddra) AND &tableno = 1 %THEN %DO;
    title1 "Listing: Adverse event terms and associated reported terms coded by MedDRA version  &v_meddra";
    footnote5 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_7_adae_cvd) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Listing of subjects with COVID-19 adverse event';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit of "Age" is years';
    footnote4 'Relative Day is the day relative to the start and end of study drug.';
    footnote5 'A pre-treatment event is indicated with a minus sign, e.g. start date = -8' ;
    footnote6 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_7_adae_teae) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Treatment emergent adverse events';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 'AE = Adverse Event';
    footnote5 'Remedial drug therapy refers to concomitant medication given to treat the AE.';
    footnote6 'Relative Day is the day relative to the start or end of study drug.';
    footnote7 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_7_adae_tesae) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Treatment-emergent serious adverse events';
    footnote1 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote2 'SOC = System Organ Class.';
    footnote3 'Sex: F = female, M = male.';
    footnote4 'The unit for "Age" is years.' ;
    footnote5 'Relative to treatment start  = date of onset/stop of AE minus date of first study drug administration plus 1 day.';
    footnote6 'Relative to treatment stop = date of onset/stop of AE minus date of last study drug administration.';
    footnote7 '{In some countries, collection of ethnicity information is not permitted by law.}';
    footnote8 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_7_adae_dth_fatl) AND &tableno = 1 %THEN %DO;
    title1 "Listing: Deaths: adverse events with fatal outcome &saf_label" ;
    footnote1 "Race: A = Asian B = Black W = White AI = American Indian or Alaska Native NH = Native Hawaiian or Other Pacific Islander";
    footnote2 "NR = Not Reported MUL = Multiple.";
    footnote3 "Sex: F = female, M = male.";
    footnote4 'The unit for "Age" is years.' ;
    footnote5 "Relative to treatment start = date of death minus date of first study drug administration plus 1 day.";
    footnote6 "Relative to treatment stop = date of death minus date of last study drug administration.";
    footnote7 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_7_adae_dth) AND &tableno = 1 %THEN %DO;
    title1 "Listing: Deaths not attributed to an adverse event &saf_label" ;
    footnote1 "Race: A = Asian B = Black W = White AI = American Indian or Alaska Native NH = Native Hawaiian or Other Pacific Islander NR = Not Reported MUL = Multiple.";
    footnote2 "Sex: F = female, M = male.";
    footnote3 'The unit for "Age" is years.' ;
    footnote4 "Relative to treatment start = date of onset/stop of AE minus date of first study drug administration plus 1 day.";
    footnote5 "Relative to treatment stop = date of onset/stop of AE minus date of last study drug administration.";
    footnote6 "&idfoot";
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_1_adlb_hema) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Clinical laboratory data: Hematology';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_1_adlb_gnrl_chem) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Clinical laboratory data: General chemistry';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_1_adlb_coag) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Clinical laboratory data: Coagulation';
        footnote1 'Sex is identified as: M = Male, F = Female.';
        footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
        footnote3 'The unit for "Age" is years.' ;
        footnote4 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_1_adlb_horm) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Clinical laboratory data: Hormones';
        footnote1 'Sex is identified as: M = Male, F = Female.';
        footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
        footnote3 'The unit for "Age" is years.' ;
        footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_1_adlb_urin) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Clinical laboratory data: Urine Analysis';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_1_adlb_virol) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Clinical laboratory data: Immunology/ Virology';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_1_adlb_vitm) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Clinical laboratory data: Vitamin';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_1_adlb_immu) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Clinical laboratory data: Immunology/ Virology';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_1_adlb_preg) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Clinical laboratory data: Urine Pregnancy Test';
        footnote1 'Sex is identified as: M = Male, F = Female.';
        footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
        footnote3 'The unit for "Age" is years.';
        footnote4 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_2_adpr_fapr_mamo) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Mammogram';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.';
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_2_adfapr_ultra_gyn) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Ultrasound Gynecological';
        footnote1 'Sex is identified as: M = Male, F = Female.';
        footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
        footnote3 'The unit for "Age" is years.';
        footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_2_adfapr_ultra_ovr) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Ultrasound Ovaries visualized';
        footnote1 'Sex is identified as: M = Male, F = Female.';
        footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
        footnote3 'The unit for "Age" is years.';
        footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_2_adfapr_ult_utr) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Ultrasound Uterus';
        footnote1 'Sex is identified as: M = Male, F = Female.';
        footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
        footnote3 'The unit for "Age" is years.';
        footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_2_adfapr_crv_cyt) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Cervical Cytology';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.';
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_2_adpr_end_bps) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Endometrial biopsy';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.';
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_2_adqshfss_slp_scl) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Sleepiness Scale';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.';
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_2_adqs_ecssrs) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Electronic Columbia-suicide severity rating scale eC - SSRS';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.';
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_2_admh_liv_evnt) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Medical history of Interest - Liver Event';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.';
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_2_adcm_liv_evnt) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Medication of Interest - Liver Event - CLO';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.';
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_2_adlb_clo) AND &tableno = 1 %THEN %DO;
    title1 'Listing: General Chemistry for CLO';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.';
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_2_spce_liv_enzm) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Clinical Signs and Symptoms with elevated liver enzymes';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.';
    footnote4 'Present "Yes" means this Clinical Sign or Symptom occurred during the study and may be of relevance for the current liver event (elevated liver enzymes) of the subject.';
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_2_spce_liv_enzm_fu) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Clinical Signs and Symptoms with elevated liver enzymes (follow up)';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.';
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_2_adpr_adfapr_liv) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Procedure(s) - Liver Event ';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.';
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_2_adqs_lsmb) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Liver Safety Monitoring Board ';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.';
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_2_adlb_liv_hp) AND &tableno = 1 %THEN %DO;
    title1 "Listing: Subjects meeting lab elevation criteria for hepatic safety - subject listing on lab parameters";

    footnote1 "Only subjects meeting close liver observation criteria are presented.";
    footnote2 "Study day is defined as number of days after first study drug.";
    footnote3 "Sex is identified as: M = Male, F = Female.";
    footnote4 "Race: A = Asian B = Black or African American W = White AI = American Indian or Alaska Native NH = Native Hawaiian or Other Pacific Islander NR = Not Reported MUL=Multiple.";
    footnote5 'The unit for "Age" is years.';
    footnote6 "ALT = Alanine Aminotransferase, AST = Aspartate Aminotransferase, ALP = Alkaline Phosphatase, INR = International Normalized Ratio, GGT= gamma-glutamyl transferase, DB= direct bilirubin, CK= creatinine kinase, LDH= lactate dehydrogenase";
    footnote7 "ULN = Upper Limit of Normal";
    footnote8 &idfoot ;
%END;


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_3_advs_phy_exm) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Physcial Examination';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.';
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_3_advs) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Vital signs';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.';
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_3_speg_msmt) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Electrocardiogram measurements';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.';
    footnote4 "QTcB=QTC calculated using Bazett's formula; QTcF=QTC calculated using Fridericia's formula; QTcL = QTC calculated using linears regression techniques.";
/*   footnote3 "QTcB=QTC calculated using Bazett's formula";*/
/*    footnote4 "QTcF=QTC calculated using Fridericia's formula";*/
/*    footnote5 "QTcL=QTC calculated using linear method";*/
/*    footnote6 "[...] = Invalid measurement";*/
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(l_10_2_8_3_speg_fnd) AND &tableno = 1 %THEN %DO;
    title1 'Listing: Electrocardiogram findings';
    footnote1 'Sex is identified as: M = Male, F = Female.';
    footnote2 'Race is identified as: A = Asian, B = Black, W = White, AI = American Indian or Alaska Native, NH = Native Hawaiian or Other Pacific Islander, NR = Not Reported, MUL=Multiple.';
    footnote3 'The unit for "Age" is years.';
    footnote4 &idfoot ;
%END;

/****8.4****/


%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_4_1_subgrp_hf) AND &tableno = 1 %THEN %DO;
    title1 "Table: Mean daily frequency of moderate to severe hot flashes: summary statistics and change from baseline by treatment group - &pop_label1";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'SD = Standard Deviation';
    footnote3 'In case data was missing for more than 2 days within a week, the value for that particular week was set to missing.';
    footnote4 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_4_1_subgrp_shf) AND &tableno = 1 %THEN %DO;
    title1 "Table: Mean daily severity of moderate to severe hot flashes: summary statistics and change from baseline by treatment group - &pop_label1";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'SD = Standard Deviation';
    footnote3 'In case data was missing for more than 2 days within a week, the value for that particular week was set to missing.';
    footnote4 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_4_1_subgrp_pr) AND &tableno = 1 %THEN %DO;
    title1 "Table: PROMIS SD SF 8b total T-score: summary statistics and change from baseline by treatment group - &pop_label1";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'Total score converted as T-score';
    footnote3 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote4 'SD = Standard Deviation';
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_4_1_subgrp_pr_isi) AND &tableno = 1 %THEN %DO;
    title1 "Table: PROMIS SD SF 8b total T-score: summary statistics and change from baseline by treatment group - &pop_label1";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'Total score converted as T-score';
    footnote4 'SD = Standard Deviation';
    footnote3 'ISI categories: 0-14  = No clinically significant and subthreshold insomnia, 15-21 = Clinical insomnia (moderate severity). 22-28 = Clinical insomnia (severe)';
    footnote4 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote5 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_4_1_subgrp_mq) AND &tableno = 1 %THEN %DO;
    title1 "Table: MENQOL total score: summary statistics and change from baseline by treatment group - &pop_label1";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'SD = Standard Deviation' ;
    footnote4 &idfoot ;
%END;

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_4_1_subgrp_vmq) AND &tableno = 1 %THEN %DO;
    title1 "Table: MENQOL vasomotor symptoms subdomain score: summary statistics and change from baseline by treatment group - &pop_label1";
    footnote1 'Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks';
    footnote2 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.';
    footnote3 'SD = Standard Deviation' ;
    footnote4 &idfoot ;
%END;

/*8.4.2 Sleep efficiency measurement - Actigraphy*/

%ELSE %IF %QUPCASE(&prog.) = %QUPCASE(t_8_4_2_adxk_sleep_sbase) AND &tableno = 1 %THEN %DO;
    title1 "Table: Actigraphy - $paramcd$: summary statistics";
    title2 "<cont>and change from baseline by treatment group &slas_label";
    footnote1 "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.";
    footnote2 "SD = Standard Deviation." ;
    footnote3 "Actigraphy measurements were done for 24 hours on 7 days starting at Week 4 and Week 20 and prior to Week 12." ;
    footnote4 "Baseline measurements were done after Screening but before start of treatment." ;
    footnote5 'In case a subject prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period, available post-treatment data are considered under follow-up.' ;
    footnote6 &idfoot ;
%END;

%MEND mtitle;