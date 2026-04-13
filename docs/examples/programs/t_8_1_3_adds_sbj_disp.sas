/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_1_3_adds_sbj_disp);
/*
 * Purpose          : Disposition: flow of subjects through study epochs (all enrolled subjects)
 * Programming Spec :
 * Validation Level : 2 - Verification by Double Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : enpjp (Prashant Patel) / date: 20DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_1_3_adds_sbj_disp.sas (enpjp (Prashant Patel) / date: 13DEC2023)
 ******************************************************************************/

%load_ads_dat(adsl_view, adsDomain = adsl, where = &enr_cond.)
%load_ads_dat(adds_view, adsDomain = adds, where = dscat in('DISPOSITION EVENT' " "), keep = usubjid dscat dsscat epoch dsdecod dsnext aphase, adslVars =  );

%extend_data(indat = adsl_view, outdat = adsl)
%extend_data(indat = adds_view, outdat = adds)


data epoch(keep= studyid usubjid flag);
    set ADS.ADDS;
    flag=1;
    where EPOCH in ("POST-TREATMENT" "FOLLOW-UP") and DSSCAT ne "INFORMED CONSENT";
RUN;

data fup;
    set adds_view( where = (epoch = "TREATMENT" and  dsnext = "FOLLOW-UP" /*and aphase = "Week 1-12"*/));
    keep STUDYID usubjid fup;
    if aphase = "Week 1-12" then fup=1;
    if aphase = "Week 13-26" then fup=2;
RUN;

data adslds;
    merge adsl_view(in=in_adsl) adds_view fup epoch;
    by studyid usubjid;
    if in_adsl;
    if DSNEXT ne " " and flag=. then DSNEXT = " ";/*To adjust subject supposed to start post treatment or follow up but never started that epoch*/
run;


data adslds;
    set adslds;
    reason=upcase(substr(dsdecod,1,1))||lowcase(substr(dsdecod,2));
    where dsscat ne "INFORMED CONSENT";
RUN;

%mtitle
/*< Enrolled and screening part */
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
)

ods escapechar="^";

/*< Randomized, Treatment and Follow-up part */
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
)

ods escapechar="^";

/*< Randomized, Treatment and Follow-up part */
%overview_tab(
    data      = adslds(where=(&rand_cond.))
  , class     = &TREAT_ARM_P
  , groups    = "&rand_cond."                  *'Randomized/assigned to treatment'                    /* Use this to calculate the correct percentage based on randomized subjects */
                'exnyovln = 0'                 *'Study drug never administered'
                'exnyovln = 1'                 *'Treated'
                '<DEL>'                        *''

                '<DEL>'                        *'Treatment phase '
                'epoch = "TREATMENT" and trtsdt ne .   '       *'Started'
                'epoch = "TREATMENT" and dsdecod EQ "COMPLETED" and trtsdt ne . ' *'Completed 26 weeks of treatment'
                'epoch = "TREATMENT" and dsdecod NE "COMPLETED" and trtsdt ne . ' *'Did not complete'*'reason'*"Primary reason^&super_a"
                '<DEL>'   *''

                'epoch = "TREATMENT" and aphase = "Week 13-26" and trtsdt ne .  ' *"Completed placebo-controlled period Week 1-12"
                'epoch = "TREATMENT" and aphase = "Week 1-12" and dsdecod NE "COMPLETED" and trtsdt ne . ' *"Permanent discontinuation of study drug during placebo-controlled period Week 1-12"
                 '<DEL>'   *''

                '<DEL>'                        *"Post-treatment^&super_b"
                /*epoch = "POST-TREATMENT"*/'dsnext="POST-TREATMENT" and dsdecod ne " " and trtsdt ne .'                 *'Started'
                'epoch = "POST-TREATMENT" and dsdecod EQ "COMPLETED" and trtsdt ne . '    *'Completed'
                'epoch = "POST-TREATMENT" and dsdecod NE "COMPLETED" and trtsdt ne .' *'Did not complete'*'reason'*'Primary reason'
                '<DEL>'                    *''

                '<DEL>'                       *"Follow-up^&super_c"
                'epoch = "FOLLOW-UP" and fup=1 and trtsdt ne . '                  *'Started'
                'epoch = "FOLLOW-UP" and dsdecod EQ "COMPLETED" and fup=1 and trtsdt ne .'    *'Completed'
                'epoch = "FOLLOW-UP" and dsdecod NE "COMPLETED" and fup=1 and trtsdt ne .'    *'Did not complete'*'reason'*'Primary reason'
                '<DEL>'  *''

                'epoch = "TREATMENT" and aphase = "Week 1-12" and dsdecod NE "COMPLETED" and dsnext = " " and trtsdt ne . ' *"Withdrawal from study during placebo-controlled period Week 1-12^&super_d"
                         *'reason'*"Primary reason^&super_e"
                '<DEL>'   *''

                'epoch = "TREATMENT" and aphase = "Week 13-26" and dsdecod NE "COMPLETED" and trtsdt ne . ' *"Permanent discontinuation of study drug during period Week 13-26"
                 '<DEL>'   *''

                 '<DEL>'                       *"Follow-up^&super_c"
                 'epoch = "FOLLOW-UP" and fup=2  and trtsdt ne .'       *'Started'
                 'epoch = "FOLLOW-UP"  and fup=2 and dsdecod EQ "COMPLETED" and trtsdt ne . '  *'Completed'
                 'epoch = "FOLLOW-UP"  and dsdecod NE "COMPLETED" and fup=2 and trtsdt ne .'   *"Did not complete"
                          *'reason'*"Primary reason"
                 '<DEL>'   *''

                'epoch = "TREATMENT" and aphase = "Week 13-26" and dsdecod NE "COMPLETED" and dsnext = " " and trtsdt ne . ' *"Withdrawal from study during period Week 13-26^&super_d"
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
  , hb_align  = LEFT
  , hv_align  = LEFT
  , freeline  =
)

data out_table2;
    set out_table2;
    if 13 <= fline <=33 and fline not in (25) then _name_ =  "         " || _name_;
    *if fline in (29 30 31) then _name_ =  "      " || _name_;
RUN;

/*< Combine tables and fix the trailing space for the first row */
data out_table;
    set out_table1(in=a drop=_col2_ rename=(_col1_=_col3_)) out_table2(in=b);
    if _order_=1 then _name_=strip(_name_);     /* Remove trailing space for Enrolled and Randomized category */
    if b then _order_=_order_+3;
RUN;

/*< Using inptable from randomized part */
data out_tableinp;
    set out_table2inp;
    if keyword="DATA" then value=tranwrd(value, "out_table2", "out_table");
RUN;

* print table without showing . for missing values;

%let _miss = %sysfunc(getoption(missing));
option missing=' ';

%mosto_param_from_dat(data=out_tableinp, var=parameters);
%datalist(&parameters);

option missing="&_miss.";

/* Use %endprog at the end of each study program */
%endprog;
