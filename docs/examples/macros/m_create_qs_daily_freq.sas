%MACRO m_create_qs_daily_freq()
/ DES = 'add Mean daily HF frequency of mod to sev paramcd';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: pure SAS
 *******************************************************************************
 * Purpose          : add Mean daily HF frequency of mod to sev paramcd in ADQSHFSS
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
 * Reason           : add comments and update macro title part to Bayer standard
 *                    add one more overall parameter (removed)
 *                    update available days logic
 ******************************************************************************/

/*******************************************************************************
 * Examples         :
   %m_create_qs_daily_freq();
 ******************************************************************************/

    proc sql;
        create table mod_hf as
        select *, sum(aval) as mod_hf, count (distinct adt) as mod_day from &adsDomain.
        where qstestcd="HFDB202B" and avisitn ne . and dupfl^='Y'
        group by usubjid,avisitn;

        create table sev_hf as
        select *, sum(aval) as sev_hf, count (distinct adt) as sev_day from &adsDomain.
        where qstestcd="HFDB202C" and avisitn ne . and dupfl^='Y'
        group by usubjid,avisitn;

        create table days_all as
        select usubjid, avisitn, count (distinct adt) as days_all from &adsDomain.
        where qstestcd="HFDB202" and avisitn ne . and dupfl^='Y'
        group by usubjid, avisitn;

    QUIT;

    proc sort data=&adsDomain. out=any_hf;
        where qstestcd="HFDB202" and avisitn ne . and dupfl^='Y';
        by usubjid avisitn ady;
    RUN;

    data any_hf;
        set any_hf;
        by usubjid avisitn ady;
        if last.avisitn;
    RUN;

    ** FY: ADT for derived PARAMCDs is updated to theoretical end of week in d_adqshfss per stat request;

    proc sort data=mod_hf out=mod_hf (keep=usubjid avisitn mod_hf mod_day)  nodupkey;
        by usubjid avisitn;
    RUN;

    proc sort data=sev_hf out=sev_hf (keep=usubjid avisitn sev_hf sev_day) nodupkey;
        by usubjid avisitn;
    RUN;

    data freq_hf2 (drop=mod_hf mod_day sev_hf sev_day days_all);
        merge any_hf mod_hf(in=b) sev_hf(in=c) days_all;
        by usubjid avisitn;

        QSTESTCD = 'HFDB998';
        PARAMTYP = 'DERIVED';
        QSORRES  = " ";
        QSTEST   = " ";
        AVALC    = " ";
        atptn    = .;
        QSDTC    = " ";

        if nmiss(mod_hf,sev_hf)=2 and not missing(days_all) then AVAL=0;
        else if nmiss(mod_hf,sev_hf)<2 then AVAL = (mod_hf + sev_hf)/ days_all;

        if avisitn=5 then do;
            if days_all < 11 then do;
                AVAL=.;
            END;
        END;

        if avisitn ne 5 then do;
            if days_all < 5 then do;
                AVAL=.;
            END;
        END;

    RUN;

    data &adsDomain.;
        set &adsDomain. freq_hf2;
    RUN;

    proc datasets nolist lib=work;
        delete mod_hf sev_hf freq_hf2;
    quit;

%MEND m_create_qs_daily_freq;
