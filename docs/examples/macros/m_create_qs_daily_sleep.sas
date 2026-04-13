%MACRO m_create_qs_daily_sleep()
/ DES = 'proportion of days with quite a bit or very much sleep disturbance due to HF paramcd';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: pure SAS
 *******************************************************************************
 * Purpose          : proportion of days with quite a bit or very much sleep disturbance due to HF paramcd in ADQSHFSS
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * Parameters       : N/A
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
 * Author(s)        : eokcw (Vijesh Shrivastava) / date: 22SEP2022
 *******************************************************************************
 * Change History   :
 ******************************************************************************/
/* Changed by       : gmrpb (Fiona Yan) / date: 22JUL2023
 * Reason           : add comments for pending issues
 *                    set AVAL to 0 if non-missing disturb_day and missing disturb_sleep
 *                    update macro title part to Bayer standard
 *                    add one more overall parameter (removed)
 ******************************************************************************/

/*******************************************************************************
 * Examples         :
   %m_create_qs_daily_sleep();
 ******************************************************************************/

    data &adsDomain.;
        set &adsDomain. ;
        if  AVALC ne '**' and qstestcd in ('HFDB202D') then do ;
            naval = input(avalc,best.);
        end;
    RUN;

    proc sql;
        create table disturb_sleep as
        select usubjid, avisitn, count (distinct adt) as disturb_sleep from &adsDomain.
        where qstestcd="HFDB202D" and avisitn ne . and naval in (4,5) and dupfl^='Y'
        group by usubjid,avisitn;
    QUIT;

    proc sql;
        create table disturb_days as
        select *, count (distinct adt) as disturb_day from &adsDomain.
        where qstestcd="HFDB202" and qsscat="MORNING HOT FLASH DIARY" and avisitn ne . and dupfl^='Y'
        group by usubjid,avisitn;
    QUIT;

    proc sort data=disturb_days;
        by usubjid avisitn ady;
    RUN;

    data disturb_days;
        set disturb_days;
        by usubjid avisitn ady;
        if last.avisitn;
    RUN;

    ** FY: ADT for derived PARAMCDs is updated to theoretical end of week in d_adqshfss per stat request;

    data sleep_disturb;
        merge  disturb_days  disturb_sleep;
        by usubjid avisitn;
        drop aval;
    RUN;

    data sleep_disturb2 (drop=disturb_sleep disturb_day naval);
        set sleep_disturb ;
        by usubjid avisitn;
        QSTESTCD = 'HFDB996';
        PARAMTYP = 'DERIVED';
        QSORRES  = " ";
        QSTEST   = " ";
        AVALC    = " ";
        atptn    = .;
        QSDTC    = " ";

        if nmiss(disturb_sleep, disturb_day)=0 then do;
            AVAL = disturb_sleep / disturb_day;
        end;

        if not missing(disturb_day) and missing(disturb_sleep) then AVAL=0;

        if avisitn=5 then do;
            if disturb_day < 11 then do;
                AVAL=.;
            END;
        END;

        if avisitn ne 5 then do;
            if disturb_day < 5 then do;
                AVAL=.;
            END;
        END;
    RUN;

    data &adsDomain.;
        set &adsDomain. sleep_disturb2;
    RUN;

    proc datasets nolist lib=work;
        delete sleep_disturb sleep_disturb2 disturb_days disturb_sleep;
    quit;

%MEND m_create_qs_daily_sleep;
