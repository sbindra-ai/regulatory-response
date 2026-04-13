%MACRO m_create_qs_daily_awake()
/ DES = 'add Mean frequency of night time awakening paramcd';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: pure SAS
 *******************************************************************************
 * Purpose          : add Mean frequency of night time awakening paramcd in ADQSHFSS
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
 * Author(s)        : eokcw (Vijesh Shrivastava) / date: 14JUN2022
 *******************************************************************************
 * Change History   :
 ******************************************************************************/
/* Changed by       : gmrpb (Fiona Yan) / date: 22JUL2023
 * Reason           : add comments and update macro title part to Bayer standard
 *                    add one more overall parameter (removed)
 ******************************************************************************/

/*******************************************************************************
 * Examples         :
   %m_create_qs_daily_awake();
 ******************************************************************************/

    proc sql;
        create table night_awake as
        select *, sum(aval) as night_awake, count (distinct adt) as awake_day from &adsDomain.
        where qstestcd="HFDB201" and avisitn ne . and dupfl^='Y'
        group by usubjid,avisitn;

    QUIT;

    proc sort data=night_awake;
        by usubjid avisitn ady;
    RUN;

    data night_awake;
        set night_awake;
        by usubjid avisitn ady;
        if last.avisitn;
    RUN;

    ** FY: ADT for derived PARAMCDs is updated to theoretical end of week in d_adqshfss per stat request;
    data night_awake2 (drop=night_awake awake_day);
        set night_awake;
        by usubjid avisitn;
        QSTESTCD = 'HFDB995';
        PARAMTYP = 'DERIVED';
        QSORRES  = " ";
        QSTEST   = " ";
        AVALC    = " ";
        atptn    = .;
        QSDTC    = " ";

        AVAL = night_awake/ awake_day;

        if avisitn=5 then do;
            if awake_day < 11 then do;
                AVAL=.;
            END;
        END;

        if avisitn ne 5 then do;
            if awake_day < 5 then do;
                AVAL=.;
            END;
        END;
    RUN;

    data &adsDomain.;
        set &adsDomain. night_awake2;
    RUN;

    proc datasets nolist lib=work;
        delete night_awake night_awake2;
    quit;

%MEND m_create_qs_daily_awake;
