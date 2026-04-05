/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adds_iss_sbj_disp);
/*
 * Purpose          : Disposition: flow of subjects through study epochs (all randomized subjects)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gltlk (Rui Zeng) / date: 08APR2024
 * Reference prog   :
 ******************************************************************************/

%LET mosto_param_class = %scan(&extend_var_disp_12_ezn_52., 1, '@');

%load_ads_dat(adsl_view, adsDomain = adsl, where = &rand_cond.)

%load_ads_dat(
    adds_view
  , adsDomain = adds
  , where     = dscat='DISPOSITION EVENT' and dsscat ne 'INFORMED CONSENT' and dsterm ne 'LAST DB DOSE' and epoch in ('TREATMENT' 'POST-TREATMENT' 'FOLLOW-UP')
  , keep      = studyid usubjid dscat epoch dsdecod aphase dsnext dsterm dsscat
  , adslVars  =
);

*Post-treatment and follow-up period are only available for OASIS 1-3.;
data epoch(keep= studyid usubjid flag);
    set adds_view;
    flag=1;
    where EPOCH in ("POST-TREATMENT" "FOLLOW-UP") and missing(dsscat);
RUN;

DATA post;
    SET adds_view( WHERE = (epoch = "TREATMENT" AND dsnext = "POST-TREATMENT"));
    KEEP studyid usubjid post;
    if aphase = "Week 1-12" then post=1;
    if aphase = "After week 12" then post=2;
RUN;

DATA fup;
    SET adds_view( WHERE = (epoch = "TREATMENT" AND dsnext = "FOLLOW-UP"));
    KEEP studyid usubjid fup;
    if aphase = "Week 1-12" then fup=1;
    if aphase = "After week 12" then fup=2;
RUN;

DATA adslds;
    MERGE adsl_view(IN=in_adsl) adds_view post fup epoch;
    BY studyid usubjid;
    IF in_adsl;
    %M_PropIt(Var=dsdecod);
    reason = dsdecod_prop;
    if DSNEXT ne " " and flag=. then DSNEXT = " "; /*To adjust subject supposed to start post treatment or follow up but never started that epoch*/
RUN;

*Extend treatment group as needed;
%extend_data(
    indat       = adslds
  , outdat      = adslds_ext0
  , var         = &extend_var_disp_12_ezn_52.
  , extend_rule = &extend_rule_disp_12_ezn_52.
);

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_12_ezn_52.
  , extend_rule = &extend_rule_disp_12_ezn_52.
);

*For All EZN 120 mg (week 1-52), only consider subjects who have treated with EZN;
* subject 21652360022002 has different ARM vs. ACTARM: ARM = 'Placebo - Elinzanetant 120mg', ACTARM = 'Elinzanetant 120mg', so we need to use ACTARMCD in the condition.;
DATA adslds_ext;
    SET adslds_ext0;
    IF &mosto_param_class. = &trt_ezn_52. AND &mosto_param_class._ori = 9901 AND actarmcd = 'PLA_ELIN120' THEN trtsdt_drug = tr02sdt;
    ELSE                                                                                                       trtsdt_drug = tr01sdt;
    IF &mosto_param_class. = &trt_ezn_52. AND missing(trtsdt_drug) THEN DELETE;
RUN;

*Randomized phase;
%LET groups_cond1 = "&rand_cond."                                                               *'Randomized/ Assigned to treatment'                    /* Use this to calculate the percentage based on randomized subjects */
                    'exnyovln = 0'                                                              *'Study drug never administered'
                    'exnyovln = 1'                                                              *'Treated'
                    '<DEL>'                                                                     *''
                    '<DEL>'                                                                     *'Treatment phase'
                    ;

%overview_tab(
    data      = adslds_ext(WHERE=(&mosto_param_class. in (&trt_ezn_12., &trt_pla_12.)))
  , class     = &mosto_param_class.
  , subject   = studyid usubjid
  , total     = NO
  , groups    = &groups_cond1.
  , groupstxt = Number of subjects
  , n_group   = 1
  , complete  = none
  , outdat    = out_table1
  , freeline  =
)

DATA m_all_subjects1;
    SET _mm_subject;
RUN;

%m_wrap_risk_difference(
    indat           = out_table1
  , indat_adsl      = adsl_ext (WHERE=(&mosto_param_class. in (&trt_ezn_12., &trt_pla_12.)))
  , m_all_subjects  = m_all_subjects1
  , active          = &trt_ezn_12.
  , compare         = &trt_pla_12.
  , outdat          = out_table_riskdiff1
)

*Treatment phase;
*Stats confirmed: Discontinued during the first 12 weeks includes subjects enter post-treatment/follow-up;
*For SWITCH-1 study, the number of participants who discontinued during the first 12 weeks = the number of participants who discontinued treatment at any time.;
*For SWITCH-1 study, 5 subjects dsscat = "END OF STUDY TREATMENT" with EPOCH = 'FOLLOW-UP', so use condition dsscat = "END OF STUDY TREATMENT" for 'TREATMENT' phase subjects numbers.;
%LET groups_cond2 = '(epoch = "TREATMENT" or dsscat = "END OF STUDY TREATMENT") and trtsdt NE .'                                        *'Started'                    /* Use this to calculate the percentage based on treated subjects */
                    '(epoch = "TREATMENT" or dsscat = "END OF STUDY TREATMENT") and dsdecod EQ "COMPLETED" and trtsdt NE .'             *'Completed'
                    '(epoch = "TREATMENT" or dsscat = "END OF STUDY TREATMENT") and dsdecod NE "COMPLETED" and trtsdt NE . '            *'Did not complete'*'reason'*"Primary reason (a)"
                    '<DEL>'   *''

                    '((epoch = "TREATMENT" and aphase = "After week 12") or (dsscat = "END OF STUDY TREATMENT" and dsdecod EQ "COMPLETED")) and trtsdt NE .  '    *"Completed placebo-controlled period week 1-12"
                    '(epoch = "TREATMENT" and aphase = "Week 1-12" or dsscat = "END OF STUDY TREATMENT") and dsdecod NE "COMPLETED" and trtsdt NE . '             *'Permanent discontinuation of the study drug during the placebo-controlled period week 1-12'*'reason'*"Primary reason (b)"
                    '<DEL>'                                                                                                             *' '
                    '<DEL>'                                                                                                             *'Post-treatment (c)'
                    ;

%overview_tab(
    data      = adslds_ext
  , class     = &mosto_param_class.
  , subject   = studyid usubjid
  , total     = NO
  , groups    = &groups_cond2.
  , groupstxt = Number of subjects
  , n_group   = 1
  , complete  = none
  , outdat    = out_table2
  , freeline  =
)

DATA m_all_subjects2;
    SET _mm_subject;
RUN;

%m_wrap_risk_difference(
    indat           = out_table2 (DROP = _col_03)
  , indat_adsl      = adslds_ext (WHERE=(&mosto_param_class. in (&trt_ezn_12., &trt_pla_12.) and (epoch = "TREATMENT" or dsscat = "END OF STUDY TREATMENT") and trtsdt NE .))
  , m_all_subjects  = m_all_subjects2
  , active          = &trt_ezn_12.
  , compare         = &trt_pla_12.
  , outdat          = out_table_riskdiff2
)

*Post-treatment for placebo-controlled period week 1-12;
%LET groups_cond3 = 'epoch = "POST-TREATMENT" and post = 1 and dsdecod NE " "'                               *'Started'         /* Use this to calculate the percentage based on Post-treatment subjects */
                    'epoch = "POST-TREATMENT" and post = 1 and dsdecod EQ "COMPLETED" '                      *'Completed'
                    'epoch = "POST-TREATMENT" and post = 1 and dsdecod NE "COMPLETED"'                       *'Did not complete'*'reason'*'Primary reason'
                    '<DEL>'                                                                                  *''

                    '<DEL>'                                                                                  *'Follow-up (d)'
                    ;

%overview_tab(
    data      = adslds_ext(WHERE=(&mosto_param_class. in (&trt_ezn_12., &trt_pla_12.)))
  , class     = &mosto_param_class.
  , subject   = studyid usubjid
  , total     = NO
  , groups    = &groups_cond3.
  , groupstxt = Number of subjects
  , n_group   = 1
  , complete  = none
  , outdat    = out_table3
  , freeline  =
)

DATA m_all_subjects3;
    SET _mm_subject;
RUN;

%m_wrap_risk_difference(
    indat           = out_table3
  , indat_adsl      = adslds_ext (WHERE=(&mosto_param_class. in (&trt_ezn_12., &trt_pla_12.) and epoch = "POST-TREATMENT" and post = 1 and dsdecod NE " "))
  , m_all_subjects  = m_all_subjects3
  , active          = &trt_ezn_12.
  , compare         = &trt_pla_12.
  , outdat          = out_table_riskdiff3
)

*Follow-up for placebo-controlled period week 1-12;
%LET groups_cond4 = 'epoch = "FOLLOW-UP" and fup = 1 and dsdecod NE " "'                          *'Started'
                    'epoch = "FOLLOW-UP" and fup = 1 and dsdecod EQ "COMPLETED"'                  *'Completed'
                    'epoch = "FOLLOW-UP" and fup = 1 and dsdecod NE "COMPLETED"'                  *'Did not complete'*'reason'*'Primary reason'
                    '<DEL>'                                                                       *''
                    ;

%overview_tab(
    data      = adslds_ext(WHERE=(&mosto_param_class. in (&trt_ezn_12., &trt_pla_12.)))
  , class     = &mosto_param_class.
  , subject   = studyid usubjid
  , total     = NO
  , groups    = &groups_cond4.
  , groupstxt = Number of subjects
  , n_group   = 1
  , complete  = none
  , outdat    = out_table4
  , freeline  =
)

DATA m_all_subjects4;
    SET _mm_subject;
RUN;

%m_wrap_risk_difference(
    indat           = out_table4
  , indat_adsl      = adslds_ext (WHERE=(&mosto_param_class. in (&trt_ezn_12., &trt_pla_12.) and epoch = "FOLLOW-UP" and fup = 1 and dsdecod NE " "))
  , m_all_subjects  = m_all_subjects4
  , active          = &trt_ezn_12.
  , compare         = &trt_pla_12.
  , outdat          = out_table_riskdiff4
)

*Complete/Did not complete the treatment phase during week 13-52;
%LET groups_cond5 = 'epoch = "TREATMENT" and trtsdt NE .'                                                                 *'Started'     /* Use this to calculate the percentage based on treated subjects, will remove this row later. */
                    'epoch = "TREATMENT" and aphase = "After week 12" and dsdecod EQ "COMPLETED" and trtsdt NE . '        *'Completed the treatment phase during week 13-52'
                    'epoch = "TREATMENT" and aphase = "After week 12" and dsdecod NE "COMPLETED" and trtsdt NE . '        *'Permanent discontinuation of the treatment phase during week 13-52'
                    '<DEL>'                                                                                               *''

                    '<DEL>'                                                                                               *'Post-treatment (OASIS 3 only) (e)'
                    ;

%overview_tab(
    data      = adslds_ext(WHERE=(&mosto_param_class. in (&trt_ezn_12., &trt_pla_12.)))
  , class     = &mosto_param_class.
  , subject   = studyid usubjid
  , total     = NO
  , groups    = &groups_cond5.
  , groupstxt = Number of subjects
  , n_group   = 1
  , complete  = none
  , outdat    = out_table5
  , freeline  =
)

*Post-treatment for week 13-52;
%LET groups_cond6 = 'epoch = "POST-TREATMENT" and post = 2 and dsdecod NE " "'                               *'Started'         /* Use this to calculate the percentage based on Post-treatment subjects */
                    'epoch = "POST-TREATMENT" and post = 2 and dsdecod EQ "COMPLETED" '                      *'Completed'
                    'epoch = "POST-TREATMENT" and post = 2 and dsdecod NE "COMPLETED"'                       *'Did not complete'*'reason'*'Primary reason'
                    '<DEL>'                                                                                  *''

                    '<DEL>'                                                                                  *'Follow-up (f)'
                    ;

%overview_tab(
    data      = adslds_ext(WHERE=(&mosto_param_class. in (&trt_ezn_12., &trt_pla_12.)))
  , class     = &mosto_param_class.
  , subject   = studyid usubjid
  , total     = NO
  , groups    = &groups_cond6.
  , groupstxt = Number of subjects
  , n_group   = 1
  , complete  = none
  , outdat    = out_table6
  , freeline  =
)

*Follow-up for week 13-52;
%LET groups_cond7 = 'epoch = "FOLLOW-UP" and fup = 2 and dsdecod NE " "'                          *'Started'
                    'epoch = "FOLLOW-UP" and fup = 2 and dsdecod EQ "COMPLETED"'                  *'Completed'
                    'epoch = "FOLLOW-UP" and fup = 2 and dsdecod NE "COMPLETED"'                  *'Did not complete'*'reason'*'Primary reason'
                    '<DEL>'                                                                       *''

                    '<DEL>'                                                                       *'Follow-up phase (g)'
                    ;

%overview_tab(
    data      = adslds_ext(WHERE=(&mosto_param_class. in (&trt_ezn_12., &trt_pla_12.)))
  , class     = &mosto_param_class.
  , subject   = studyid usubjid
  , total     = NO
  , groups    = &groups_cond7.
  , groupstxt = Number of subjects
  , n_group   = 1
  , complete  = none
  , outdat    = out_table7
  , freeline  =
)

*Follow-up phase;
*For SWITCH-1 study, 5 subjects dsscat = "END OF STUDY TREATMENT" with EPOCH = 'FOLLOW-UP', so use condition dsscat NE "END OF STUDY TREATMENT" for 'FOLLOW-UP' subjects numbers;
%LET groups_cond8 = 'epoch = "FOLLOW-UP" AND dsscat NE "END OF STUDY TREATMENT"'                                *'Started'                          /* Use this to calculate the percentage based on Follow-up subjects */
                    'epoch = "FOLLOW-UP" AND dsscat NE "END OF STUDY TREATMENT" and dsdecod EQ "COMPLETED"'     *'Completed'
                    'epoch = "FOLLOW-UP" AND dsscat NE "END OF STUDY TREATMENT" and dsdecod NE "COMPLETED" '    *'Did not complete'*'reason'*'Primary reason'
                    '<DEL>'                                                                                     *''
                    ;

%overview_tab(
    data      = adslds_ext
  , class     = &mosto_param_class.
  , subject   = studyid usubjid
  , total     = NO
  , groups    = &groups_cond8.
  , groupstxt = Number of subjects
  , n_group   = 1
  , complete  = none
  , outdat    = out_table8
  , freeline  =
)

DATA out_table_riskdiff;
    SET out_table_riskdiff1(IN=a) out_table_riskdiff2(IN =b) out_table_riskdiff3(IN=c) out_table_riskdiff4(IN=d);
    FORMAT _order_ best12.;

    IF a THEN _order_ = _order_;
    ELSE IF b THEN _order_ = _order_ + 100;
    ELSE IF c THEN _order_ = _order_ + 200;
    ELSE IF d THEN _order_ = _order_ + 300;

    KEEP _order_ rd_ci;
RUN;

DATA out_table;
    SET out_table1(IN=a) out_table2(IN=b) out_table3(IN=c) out_table4(IN=d) out_table5(IN=e) out_table6(IN=f) out_table7(IN=g) out_table8(IN=h);
    FORMAT _order_ best12.;

    IF a THEN _order_ = _order_;
    ELSE IF b THEN _order_ = _order_ + 100;
    ELSE IF c THEN _order_ = _order_ + 200;
    ELSE IF d THEN _order_ = _order_ + 300;
    ELSE IF e THEN _order_ = _order_ + 400;
    ELSE IF f THEN _order_ = _order_ + 500;
    ELSE IF g THEN _order_ = _order_ + 600;
    ELSE IF h THEN _order_ = _order_ + 700;

    IF 105 <= _order_ < 107 THEN CALL missing(_col_03);

    IF _order_= 1 THEN _name_=strip(_name_);                             * Remove trailing space for Randomized category;
    IF 108 <= _order_ < 400 THEN _name_ =  "         " || _name_;        * Add leading spaces for Post-treatment and Follow-up under Treatment phase;
    IF 405 <= _order_ < 604 THEN _name_ =  "         " || _name_;        * Add leading spaces for Post-treatment and Follow-up under Treatment phase;

    IF _order_ = 401 THEN DELETE;                                        * Start row to calculate the percentage based on treated subjects, not display to output;
    IF 102 <= _order_ <104 OR 202 <= _order_ <204 OR 302 <= _order_ <304 OR 502 <= _order_ <504 OR 602 <= _order_ <604 OR 702 <= _order_ <704 THEN _name_ =  "   " || _name_;   *Add leading spaces before "Completed" and rows following;

    IF _order_= 605 THEN _name_=strip(_name_);                                      * Remove trailing space for Follow-up phase;
    IF _order_= 101 then _col_03 = trim(_col_03) || '*';
RUN;

%mergeDat(baseDat = out_table, keyDat = out_table_riskdiff, by = _order_)

DATA out_table;
    SET out_table;
    IF _order_ in (2) or 102 <=_order_ < 104 THEN CALL missing(rd_ci);
    IF index(propcase(_name_),"Other") > 0 THEN _order_=_order_+ 0.99;       * Place 'Other' at the last;
    ATTRIB rd_ci LABEL="Risk Difference ** (%) #(95% CI)" LENGTH = $30;        * Add + in risk difference column header for footnote;
RUN;

DATA out_tableinp;
    SET out_table1inp;
    IF keyword = 'VAR' THEN value = '_COL_01 _COL_02 RD_CI _COL_03';
    IF keyword = 'DATA' THEN value = 'out_table';
RUN;

%set_titles_footnotes(
    tit1 = "Table: Disposition: flow of subjects through study phases &rand_label."
  , ftn1 = "* Participants randomized to EZN 120 mg or switched to EZN 120 mg at some point during the study."
  , ftn2 = "** Only shown up to wk 12 w. >= 5 participants w. the event in either grp due to non-comparability btw trt grps afterwards. CI = Confidence Interval. (*ESC*)n For SWITCH-1 only the treatment groups Elinzanetant 120 mg and Placebo are included."
  , ftn3 = "Post-treatment and follow-up period are only available for OASIS 1-3. (*ESC*)n (a) Primary reason for premature discontinuation of study drug during Week 1-12 for SWITCH-1, Week 1-26 for OASIS 1 and 2, and Week 1-52 for OASIS 3."
  , ftn4 = "(b) Primary reason for premature discontinuation of study drug during Week 1-12/ T3 visit date. (*ESC*)n (c) Prematurely discontinued study drug before Week 12/ T3 visit date, and continued with scheduled visits/procedures in a post-treatment period."
  , ftn5 = "(d) Prematurely discontinued study drug before Week 12/ T3 visit date, and entered directly follow-up. (*ESC*)n (e) Prematurely discontinued study drug during Week 13-52 and continued with scheduled visits/procedures in a post-treatment"
  , ftn6 = "<cont>period was only planned for OASIS 3. For OASIS 3, completed post-treatment is at Week 52. (*ESC*)n (f) Prematurely discontinued study drug during Week 13-26 for OASIS 1 and 2, Week 13-52 for OASIS 3, and entered directly follow-up."
  , ftn7 = "(g) This includes participants who completed the treatment phase and had a 4-week safety follow-up period or participants who started follow-up after discontinuation of study drug. If a participant discontinued from study drug before"
  , ftn8 = "<cont>Week 12 in OASIS 1 and 2 or at any time in OASIS 3 but agreed to stay in the study (i.e., in a post-treatment period), the next scheduled in person visit covered the assessments expected to be performed during the follow-up visit,"
  , ftn9 = "<cont>and therefore no follow-up visit was needed after end of treatment visit."
);

%mosto_param_from_dat(data = out_tableinp, var = config)
%datalist(&config)

%endprog;