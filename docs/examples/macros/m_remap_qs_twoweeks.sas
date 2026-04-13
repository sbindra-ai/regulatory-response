%MACRO m_remap_qs_twoweeks(cond=, week_schedule=)
/ DES = 'Remap the previous week to the scheduled week if the scheduled week assessment is missing in ADQS';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: pure SAS
 *******************************************************************************
 * Purpose          : Remap the previous week to the scheduled week if the scheduled week assessment is missing in ADQS
 *                    e.g. Remap week 7 to week 8 only if Week 8 assessment is missing
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * Parameters       :
 *                    cond:  the condition to select the dataset
 *                    week_schedule:  the scheduled week
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Preconditions    :
 *     Macrovar. needed:
 *     Datasets  needed:
 *     Ext.Prg/Mac used:
 * Postconditions   :
 *     Macrovar created:
 *     Output   created:
 *     Datasets created:
 * Comments         :
 *******************************************************************************
 * Author(s)        : gmrnq (Susie Zhang) / date: 25JUL2023
 * Reference prog   :
 *******************************************************************************
 * Change History   :
 ******************************************************************************/
/* Changed by       : gmrnq (Susie Zhang) / date: 17OCT2023
 * Reason           : Update QSCAT=MENQOL and BDI since it might be changed
 ******************************************************************************/

/*******************************************************************************
 * Examples         : Map week 7 to week 8 only if Week 8 assessment is missing;
   %m_remap_qs_twoweeks(cond=%str(visitnum in (600000)), week_schedule=8);
 ******************************************************************************/



/** Get full set of avisitn;*/
proc sort data=&adsDomain. out=&adsDomain._subj(keep=studyid usubjid qscat qsscat) nodupkey;
    by studyid usubjid qscat qsscat;
RUN;

proc sort data=&adsDomain. out=&adsDomain._avisitn(keep=studyid avisitn) nodupkey;
    by studyid avisitn;
RUN;

proc sql noprint;
    create table full_visitn as
        select a.*, b.avisitn
        from &adsDomain._subj as a, &adsDomain._avisitn as b
        where a.studyid=b.studyid;
QUIT;

/** Check avisitn in the actual dataset;*/
proc sort data=full_visitn;
    by studyid usubjid qscat qsscat avisitn;
run;

proc sort data=&adsDomain. out=&adsDomain._act;
    where qsstat ^="NOT DONE";
    by studyid usubjid qscat qsscat avisitn;
run;

data &adsDomain._ck;
    merge full_visitn(in=a) &adsDomain._act(in=b);
    by studyid usubjid qscat qsscat avisitn;
    if a;
    if b then _ck_wk='Y';
RUN;

* Check the scheduled week;
data ck_week_ck(keep=studyid usubjid qscat qsscat _ck_wk_sch avisitn);
    set &adsDomain._ck;
    if _ck_wk="Y" then _ck_wk_sch="Y";
        else _ck_wk_sch="N";
RUN;

proc sql noprint;
    select count(*) into:n_wk from ck_week_ck
           where avisitn=10*&week_schedule.;
QUIT;

%if &week_schedule=4 %then %do;
    %if &n_wk ne 0 %then %do;
        proc sort data=ck_week_ck out=ck_week_schedule(drop=avisitn) nodupkey;
            where avisitn=10*&week_schedule.;
            by studyid usubjid qscat qsscat _ck_wk_sch;
        RUN;

        /** Remap the last record of previous week to scheduled week if there is no scheduled week;*/
        data &adsDomain._m1;
            set &adsDomain.;
            _avisitn_ori=avisitn;
            _avisitn_new=avisitn;
            _ord=1;

            /** For categories in PROMIS SD SF 8b, EQ-5D-5L, PGI-S;*/
            if qscat in ('PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0', 'EQ-5D-5L')
               or (qscat ='PATIENT GLOBAL IMPRESSION VASOMOTOR SYMPTOMS V1.0' and qstestcd in ('PGVB101', 'PGVB102', 'PGVB103')) then do;
                /* Day 17 and 18 will be NOT mapped to week 3;
                * if one of the dates to be mapped to week 4, it will not need be duplicated;*/
                if &cond. and 17<=qsdy<=18 then _avisitn_new=30;
                output;

                /* Day 15 and 16 will be mapped to week 2. Day 19 and 23 will be mapped to week 3;
                * if one of the dates to be mapped to week 4, it needs be duplicated;*/
                if &cond. and (15<=qsdy<=16 or 19<=qsdy<=23) then do;
                    _avisitn_new=30;
                    _dupwk3="Y";
                    _ord=2;
                    output;
                end;
            END;

            /** For other categories expect PROMIS SD SF 8b, EQ-5D-5L, PGI-S;*/
            else do;
                output;
            END;

        RUN;

        proc sort data=&adsDomain._m1;
            by studyid usubjid qscat qsscat _avisitn_new qstestcd qsdy _ord;
        run;

        data &adsDomain._m2;
            set &adsDomain._m1;
            by studyid usubjid qscat qsscat _avisitn_new qstestcd qsdy _ord;
            if last.qstestcd then _wk_lastord="Y";
        RUN;

        proc sort data=&adsDomain._m2;
            by studyid usubjid qscat qsscat _avisitn_new qsdy _ord;
        run;

        data &adsDomain._lastday(keep=studyid usubjid qscat qsscat _avisitn_new qsdy);
            set &adsDomain._m2;
            by studyid usubjid qscat qsscat _avisitn_new qsdy;
            if last._avisitn_new;
        RUN;

        data &adsDomain._m3;
            merge &adsDomain._m2(in=a)
                  &adsDomain._lastday(in=b);
            by studyid usubjid qscat qsscat _avisitn_new qsdy;
            if a;
            if b and _wk_lastord="Y" then _wk_last="Y";
        RUN;

        data &adsDomain.;
            merge &adsDomain._m3(in=a) ck_week_schedule;
            by studyid usubjid qscat qsscat;
            if a;

            * For categories in PROMIS SD SF 8b, EQ-5D-5L, PGI-S, duplicate the last records from day 15-23 to week 4 if no week 4 assessment;
            if qscat in ('PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0', 'EQ-5D-5L')
               or (qscat ='PATIENT GLOBAL IMPRESSION VASOMOTOR SYMPTOMS V1.0' and qstestcd in ('PGVB101', 'PGVB102', 'PGVB103')) then do;
                if &cond. and _avisitn_new=10*(&week_schedule.-1) and _wk_last="Y" then do;
                    if _ck_wk_sch='Y' then do;
                        if 17<=qsdy<=18 or 24<=qsdy<=28 then avisitn=.;
                        if (15<=qsdy<=16 or 19<=qsdy<=23) and _dupwk3="Y" then delete;
                    end;
                    else do;
                        avisitn=10*&week_schedule.;
                        if 15<=qsdy<=23 then do;
                            dtype="LOCF";
                            _dup_to_wk4="Y";
                        end;
                    end;
                end;
                else if &cond. and _avisitn_new=10*(&week_schedule.-1) and _wk_last="" then do;
                    if 17<=qsdy<=18 or 24<=qsdy<=28 then avisitn=.;
                    if (15<=qsdy<=16 or 19<=qsdy<=23) and _dupwk3="Y" then delete;
                END;
            END;

            * For the categories in MENQOL, ISI, BDI-II, PGI-C, use regular 2-week mapping rule;
            else if find(qscat, 'MENOPAUSE-SPECIFIC QUALITY-OF-LIFE QUESTIONNAIRE')>0
                or qscat ='ISI'
                or find(qscat, 'BECK DEPRESSION INVENTORY')>0
                or (qscat ='PATIENT GLOBAL IMPRESSION VASOMOTOR SYMPTOMS V1.0' and qstestcd in ('PGVB104', 'PGVB105', 'PGVB106'))
            then do;
                if &cond. and _avisitn_ori=10*(&week_schedule.-1) then do;
                    if _ck_wk_sch='Y' then avisitn=.;
                    else avisitn=10*&week_schedule.;
                end;
                else avisitn=_avisitn_ori;
            END;
            else do;
                avisitn=_avisitn_ori;
            END;

            drop _avisitn_ori _avisitn_new _ord _ck_wk_sch;
        RUN;
    %END;
    %else %do;
        /** Remap the last record of previous week to scheduled week if there is no scheduled week;*/
        data &adsDomain._m1;
            set &adsDomain.;
            _avisitn_ori=avisitn;
            _avisitn_new=avisitn;
            _ord=1;

            /** For categories in PROMIS SD SF 8b, EQ-5D-5L, PGI-S;*/
            if qscat in ('PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0', 'EQ-5D-5L')
               or (qscat ='PATIENT GLOBAL IMPRESSION VASOMOTOR SYMPTOMS V1.0' and qstestcd in ('PGVB101', 'PGVB102', 'PGVB103')) then do;
                /* Day 17 and 18 will be NOT mapped to week 3;
                * if one of the dates to be mapped to week 4, it will not need be duplicated;*/
                if &cond. and 17<=qsdy<=18 then _avisitn_new=30;
                output;

                /* Day 15 and 16 will be mapped to week 2. Day 19 and 23 will be mapped to week 3;
                * if one of the dates to be mapped to week 4, it needs be duplicated;*/
                if &cond. and (15<=qsdy<=16 or 19<=qsdy<=23) then do;
                    _avisitn_new=30;
                    _dupwk3="Y";
                    _ord=2;
                    output;
                end;
            END;

            /** For other categories expect PROMIS SD SF 8b, EQ-5D-5L, PGI-S;*/
            else do;
                output;
            END;

        RUN;

        proc sort data=&adsDomain._m1;
            by studyid usubjid qscat qsscat _avisitn_new qstestcd qsdy _ord;
        run;

        data &adsDomain._m2;
            set &adsDomain._m1;
            by studyid usubjid qscat qsscat _avisitn_new qstestcd qsdy _ord;
            if last.qstestcd then _wk_lastord="Y";
        RUN;

        proc sort data=&adsDomain._m2;
            by studyid usubjid qscat qsscat _avisitn_new qsdy _ord;
        run;

        data &adsDomain._lastday(keep=studyid usubjid qscat qsscat _avisitn_new qsdy);
            set &adsDomain._m2;
            by studyid usubjid qscat qsscat _avisitn_new qsdy;
            if last._avisitn_new;
        RUN;

        data &adsDomain._m3;
            merge &adsDomain._m2(in=a)
                  &adsDomain._lastday(in=b);
            by studyid usubjid qscat qsscat _avisitn_new qsdy;
            if a;
            if b and _wk_lastord="Y" then _wk_last="Y";
        RUN;

        data &adsDomain.;
            set &adsDomain._m3;
            by studyid usubjid qscat qsscat;

            * For categories in PROMIS SD SF 8b, EQ-5D-5L, PGI-S, duplicate the last records from day 15-23 to week 4 if no week 4 assessment;
            if qscat in ('PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0', 'EQ-5D-5L')
               or (qscat ='PATIENT GLOBAL IMPRESSION VASOMOTOR SYMPTOMS V1.0' and qstestcd in ('PGVB101', 'PGVB102', 'PGVB103')) then do;
                if &cond. and _avisitn_new=10*(&week_schedule.-1) and _wk_last="Y" then do;
                    avisitn=10*&week_schedule.;
                    if 15<=qsdy<=23 then do;
                        dtype="LOCF";
                        _dup_to_wk4="Y";
                    end;
                end;
                else if &cond. and _avisitn_new=10*(&week_schedule.-1) and _wk_last="" then do;
                    if 17<=qsdy<=18 or 24<=qsdy<=28 then avisitn=.;
                    if (15<=qsdy<=16 or 19<=qsdy<=23) and _dupwk3="Y" then delete;
                END;
            END;

            * For the categories in MENQOL, ISI, BDI-II, PGI-C, use regular 2-week mapping rule;
            else if find(qscat, 'MENOPAUSE-SPECIFIC QUALITY-OF-LIFE QUESTIONNAIRE')>0
                or qscat ='ISI'
                or find(qscat, 'BECK DEPRESSION INVENTORY')>0
                or (qscat ='PATIENT GLOBAL IMPRESSION VASOMOTOR SYMPTOMS V1.0' and qstestcd in ('PGVB104', 'PGVB105', 'PGVB106'))
            then do;
                if &cond. and _avisitn_ori=10*(&week_schedule.-1) then avisitn=10*&week_schedule.;
                else avisitn=_avisitn_ori;
            END;
            else do;
                avisitn=_avisitn_ori;
            END;

            drop _avisitn_ori _avisitn_new _ord ;
        RUN;
    %END;


%END;
%else %do;

    %if &n_wk ne 0 %then %do;
        proc sort data=ck_week_ck out=ck_week_schedule(drop=avisitn) nodupkey;
            where avisitn=10*&week_schedule.;
            by studyid usubjid qscat qsscat _ck_wk_sch;
        RUN;

        * Remap the last record of previous week to scheduled week if there is no scheduled week;
        proc sort data=&adsDomain.;
            by studyid usubjid qscat qsscat avisitn qsdy;
        run;

        data &adsDomain._lastday(keep=studyid usubjid qscat qsscat avisitn qsdy);
            set &adsDomain.;
            by studyid usubjid qscat qsscat avisitn qsdy;
            if last.avisitn;
        RUN;

        data &adsDomain.;
            merge &adsDomain(in=a)
                  &adsDomain._lastday(in=b);
            by studyid usubjid qscat qsscat avisitn qsdy;
            if a;
            if b then _wk_last="Y";
        RUN;

        data &adsDomain.;
            merge &adsDomain.(in=a) ck_week_schedule;
            by studyid usubjid qscat qsscat;
            if a;
            _avisitn_ori=avisitn;
            * For the categories in MENQOL, ISI, BDI-II, PGI-C and for categories in PROMIS SD SF 8b, EQ-5D-5L, PGI-S;
            if find(qscat, 'MENOPAUSE-SPECIFIC QUALITY-OF-LIFE QUESTIONNAIRE')>0
              or find(qscat, 'BECK DEPRESSION INVENTORY')>0
              or qscat in ('ISI', 'PATIENT GLOBAL IMPRESSION VASOMOTOR SYMPTOMS V1.0','PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0', 'EQ-5D-5L')
            then do;
                if &cond. and _avisitn_ori=10*(&week_schedule.-1) and _wk_last="Y" then do;
                    if _ck_wk_sch='Y' then avisitn=.;
                    else avisitn=10*&week_schedule.;
                end;
                else if &cond. and _avisitn_ori=10*(&week_schedule.-1) and _wk_last="" then avisitn=.;
                else avisitn=_avisitn_ori;
            END;
            else do;
                avisitn=_avisitn_ori;
            END;

            drop _avisitn_ori _ck_wk_sch;
        RUN;

    %END;
    %else %do;
        * Remap the last record of previous week to scheduled week if there is no scheduled week;
        proc sort data=&adsDomain.;
            by studyid usubjid qscat qsscat avisitn qsdy;
        run;

        data &adsDomain._lastday(keep=studyid usubjid qscat qsscat avisitn qsdy);
            set &adsDomain.;
            by studyid usubjid qscat qsscat avisitn qsdy;
            if last.avisitn;
        RUN;

        data &adsDomain.;
            merge &adsDomain(in=a)
                  &adsDomain._lastday(in=b);
            by studyid usubjid qscat qsscat avisitn qsdy;
            if a;
            if b then _wk_last="Y";
        RUN;

        data &adsDomain.;
            set &adsDomain.;
            _avisitn_ori=avisitn;
            * For the categories in MENQOL, ISI, BDI-II, PGI-C and for categories in PROMIS SD SF 8b, EQ-5D-5L, PGI-S;
            if find(qscat, 'MENOPAUSE-SPECIFIC QUALITY-OF-LIFE QUESTIONNAIRE')>0
              or find(qscat, 'BECK DEPRESSION INVENTORY')>0
              or qscat in ('ISI', 'PATIENT GLOBAL IMPRESSION VASOMOTOR SYMPTOMS V1.0','PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0', 'EQ-5D-5L')
            then do;
                if &cond. and _avisitn_ori=10*(&week_schedule.-1) and _wk_last="Y" then avisitn=10*&week_schedule.;
                else if &cond. and _avisitn_ori=10*(&week_schedule.-1) and _wk_last="" then avisitn=.;
                else avisitn=_avisitn_ori;
            END;
            else do;
                avisitn=_avisitn_ori;
            END;

            drop _avisitn_ori;
        RUN;
    %END;


%END;

%MEND m_remap_qs_twoweeks;
