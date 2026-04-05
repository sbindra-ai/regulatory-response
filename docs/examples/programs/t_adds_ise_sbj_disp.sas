/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adds_ise_sbj_disp);
/*
 * Purpose          : Create table: Disposition: flow of subjects through study epochs (all enrolled subjects)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gltlk (Rui Zeng) / date: 21DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_1_3_adds_sbj_disp.sas (enpjp (Prashant Patel) / date: 12SEP2023)
 ******************************************************************************/

%LET mosto_param_class = &mosto_param_class_eff.;

%load_ads_dat(adsl_view, adsDomain = adsl, where = &enr_cond.)
%load_ads_dat(adds_view, adsDomain = adds, where = dscat in ('DISPOSITION EVENT' " ") and dsscat ne 'INFORMED CONSENT', keep = studyid usubjid dscat dsscat epoch dsdecod dsnext aphase, adslVars =  );

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext (drop = studyid_ori usubjid_ori extend_cond)
  , var         = &extend_var_disp_eff.
  , extend_rule = &extend_rule_disp_eff.
);

%extend_data(
    indat       = adds_view
  , outdat      = adds_ext
  , var         = &extend_var_disp_eff.
  , extend_rule = &extend_rule_disp_eff.
);

data epoch(keep= studyid usubjid flag);
    set adds_ext;
    flag=1;
    where EPOCH in ("POST-TREATMENT" "FOLLOW-UP");
RUN;

data fup;
    set adds_ext( where = (epoch = "TREATMENT" and dsnext = "FOLLOW-UP" /*and aphase = "Week 1-12"*/));
    keep studyid usubjid fup;
    if aphase = "Week 1-12" then fup=1;
    if aphase = "After week 12" then fup=2;
RUN;

data adslds;
    merge adsl_ext(in=in_adsl) adds_ext fup epoch;
    by studyid usubjid;
    if in_adsl;
    reason=upcase(substr(dsdecod,1,1))||lowcase(substr(dsdecod,2));
    if DSNEXT ne " " and flag=. then DSNEXT = " ";/*To adjust subject supposed to start post treatment or follow up but never started that epoch*/
run;

%set_titles_footnotes(
    tit1 = "Table: Disposition: flow of subjects through study epochs &enr_label."
  , ftn1 = "&foot_placebo_ezn. (*ESC*)n Number of subjects enrolled is the number of subjects who signed informed consent."
  , ftn2 = "Week 1-12 represents the placebo controlled period of the study. (*ESC*)n Week 13-26 represents the period at which all participants are treated with elinzanetant."
  , ftn3 = "a Primary reason for premature discontinuation of study drug during Week 1-26. (*ESC*)n b Prematurely discontinued study drug before Week 12, and continued with scheduled visits/procedures in a post-treatment period."
  , ftn4 = 'c Prematurely discontinued study drug, and entered directly follow-up. (*ESC*)n d Premature withdrawal from the study at the time of discontinuation of study drug without further follow-up.'
  , ftn5 = 'e These reasons are a subset of the primary reason for premature discontinuation of study drug.'
  , ftn6 = 'f This includes participants who completed the treatment phase and had a 4-week safety follow-up period or participants who started follow-up after discontinuation of study drug.'
  , ftn7 = '<cont>If a participant discontinued from study drug before Week 12 but agreed to stay in the study (i.e., in a post-treatment period),'
  , ftn8 = '<cont>the next scheduled in person visit covered the assessments expected to be performed during the follow-up visit, and therefore no follow-up visit was needed after end of treatment visit.'
);

*< Enrolled and screening part ;
%overview_tab(
    data            = adslds
  , class           =
  , groups          = "&enr_cond."           *'Enrolled'     /* Number of subjects enrolled is the number of subjects who signed informed consent */
                      'SCRNFLFL = "Y"' *'Screening failures'*'reason'*'Primary reason'
                      '<DEL>'                         *''
  , groupstxt       = Number of subjects
  , n_group         = 1
  , complete        = none
  , outdat          = out_table1
  , maxlen          = 30
  , freeline        =
  , total           = YES
)

ods escapechar="^";

*< Randomized, Treatment and Follow-up part ;
%overview_tab(
    data      = adslds(where=(&rand_cond.))
  , groups    = "&rand_cond."                  *'Randomized/assigned to treatment'                    /* Use this to calculate the correct percentage based on randomized subjects */
                'exnyovln = 0'                 *'Study drug never administered'
                'exnyovln = 1'                 *'Treated'
                '<DEL>'                        *''

                '<DEL>'                        *'Treatment phase '
                'epoch = "TREATMENT" and trtsdt ne .   '       *'Started'
                'epoch = "TREATMENT" and dsdecod EQ "COMPLETED" and trtsdt ne . ' *'Completed 26 weeks of treatment'
                'epoch = "TREATMENT" and dsdecod NE "COMPLETED" and trtsdt ne . ' *'Did not complete'*'reason'*"Primary reason^&super_a"
                '<DEL>'   *''

                'epoch = "TREATMENT" and aphase = "After week 12" and trtsdt ne .  ' *"Completed placebo-controlled period Week 1-12"
                'epoch = "TREATMENT" and aphase = "Week 1-12" and dsdecod NE "COMPLETED" and trtsdt ne . ' *"Permanent discontinuation of study drug during placebo-controlled period Week 1-12"
                 '<DEL>'   *''

                '<DEL>'                        *"Post-treatment^&super_b"
                /*epoch = "POST-TREATMENT"*/'dsnext="POST-TREATMENT" and dsdecod ne " " and trtsdt ne .'                 *'Started'
                'epoch = "POST-TREATMENT" and dsdecod EQ "COMPLETED" and trtsdt ne . '    *'Completed'
                'epoch = "POST-TREATMENT" and dsdecod NE "COMPLETED" and trtsdt ne .' *'Did not complete'*'reason'*'Primary reason'
                '<DEL>'                    *''

                '<DEL>'                                                                         *"Follow-up^&super_c"
                'epoch = "FOLLOW-UP" and fup=1 and trtsdt ne . '                                *'Started'
                'epoch = "FOLLOW-UP" and dsdecod EQ "COMPLETED" and fup=1 and trtsdt ne .'      *'Completed'
                'epoch = "FOLLOW-UP" and dsdecod NE "COMPLETED" and fup=1 and trtsdt ne .'               *'Did not complete'*'reason'*'Primary reason'
                '<DEL>'  *''

                'epoch = "TREATMENT" and aphase = "Week 1-12" and dsdecod NE "COMPLETED" and dsnext = " " and trtsdt ne . ' *"Withdrawal from study during placebo-controlled period Week 1-12^&super_d"
                         *'reason'*"Primary reason^&super_e"
                '<DEL>'   *''

                'epoch = "TREATMENT" and aphase = "After week 12" and dsdecod NE "COMPLETED" and trtsdt ne . ' *"Permanent discontinuation of study drug during period Week 13-26"
                 '<DEL>'   *''

                 '<DEL>'                       *"Follow-up^&super_c"
                 'epoch = "FOLLOW-UP" and fup=2  and trtsdt ne .'       *'Started'
                 'epoch = "FOLLOW-UP"  and fup=2 and dsdecod EQ "COMPLETED" and trtsdt ne . '  *'Completed'
                 'epoch = "FOLLOW-UP"  and dsdecod NE "COMPLETED" and fup=2 and trtsdt ne .'   *"Did not complete"
                          *'reason'*"Primary reason"
                 '<DEL>'   *''

                'epoch = "TREATMENT" and aphase = "After week 12" and dsdecod NE "COMPLETED" and dsnext = " " and trtsdt ne . ' *"Withdrawal from study during period Week 13-26^&super_d"
                          *'reason'*"Primary reason^&super_e"
                '<DEL>'   *''

                '<DEL>'                        *"Follow-up phase^&super_f"
                'epoch = "FOLLOW-UP" and trtsdt ne .'                 *'Started'
                'epoch = "FOLLOW-UP" and dsdecod EQ "COMPLETED" and trtsdt ne .'    *'Completed'
                'epoch = "FOLLOW-UP" and dsdecod NE "COMPLETED" and trtsdt ne .'    *'Did not complete'*'reason'*'Primary reason'
                '<DEL>'  *''
  , groupstxt = Number of subjects
  , n_group   = 1
  , complete  = none
  , outdat    = out_table2
  , freeline  =
  , total     = YES
)

data out_table2;
    set out_table2;
    if 13 <= fline <=22 then _name_ =  "         " || _name_;
    if 23 <= fline <=24 then _name_ =  "    " || _name_;
    if 27 <= fline <=31 then _name_ =  "         " || _name_;
    if 32 <= fline <=33 then _name_ =  "    " || _name_;
RUN;

/*< Combine tables and fix the trailing space for the first row */
data out_table;
    set out_table1(in=a drop = _col1_) out_table2(in=b);

    if _order_=1 then _name_=strip(_name_);     /* Remove trailing space for Enrolled and Randomized category */
    if b then _order_=_order_+ 10;
RUN;

/*< Using tableinp from randomized part */
data out_tableinp;
    set out_table2inp;
    if keyword="DATA" then value=tranwrd(value, "out_table2", "out_table");
RUN;

%mosto_param_from_dat(data=out_tableinp, var=parameters);
%datalist(&parameters);

/* Use %endprog at the end of each study program */
%endprog;
