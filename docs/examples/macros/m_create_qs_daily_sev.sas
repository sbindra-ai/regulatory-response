%MACRO m_create_qs_daily_sev()
/ DES = 'add Mean daily HF severity paramcd';
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
   %m_create_qs_daily_sev();
 ******************************************************************************/
    proc sql;
        create table mild_hf as
        select *, sum(aval) as mild_hf from &adsDomain.
        where qstestcd="HFDB202A" and avisitn ne . and dupfl^='Y'
        group by usubjid,ADT,avisitn;

        create table mod_hf as
        select *, sum(aval) as mod_hf from &adsDomain.
        where qstestcd="HFDB202B" and avisitn ne . and dupfl^='Y'
        group by usubjid,ADT,avisitn;

        create table sev_hf as
        select *, sum(aval) as sev_hf from &adsDomain.
        where qstestcd="HFDB202C" and avisitn ne . and dupfl^='Y'
        group by usubjid,ADT,avisitn;

        create table all_day as
        select usubjid, avisitn, count (distinct adt) as days_all from &adsDomain.
        where qstestcd="HFDB202" and avisitn ne . and dupfl^='Y'
        group by usubjid, avisitn;

    QUIT;

    proc sort data=&adsDomain. out=any_hf nodupkey;
        where qstestcd="HFDB202" and avisitn ne . and dupfl^='Y';
        by usubjid adt avisitn;
    RUN;

    proc sort data=mild_hf out=mild_hf (keep=usubjid ADT mild_hf avisitn) nodupkey;
        by usubjid ADT avisitn;
    RUN;

    proc sort data=mod_hf out=mod_hf (keep=usubjid ADT mod_hf avisitn)  nodupkey;
        by usubjid ADT avisitn;
    RUN;

    proc sort data=sev_hf out=sev_hf (keep=usubjid ADT sev_hf avisitn) nodupkey;
        by usubjid ADT avisitn;
    RUN;

    data all_hf;
        merge any_hf mild_hf mod_hf sev_hf;
        by usubjid adt avisitn;
    RUN;

    proc sort data=all_hf;
        by usubjid avisitn;
    RUN;

    data all_sev;
        merge all_hf all_day;
        by usubjid avisitn;

        if AVISITN=5 then do;
            if nmiss(mod_hf,sev_hf)<2 then do;
                num = (2* mod_hf + 3* sev_hf);
                denom= (mod_hf + sev_hf);
                if denom > 0 then do;
                    daily_sev = (2* mod_hf + 3* sev_hf) / (mod_hf + sev_hf);
                end;
            END;
            else if not missing(days_all) then daily_sev=0;
        END;

        if AVISITN ne 5 then do;
            if nmiss(mild_hf,mod_hf,sev_hf)<3 then do;
                num = (1*mild_hf + 2* mod_hf + 3* sev_hf) ;
                denom= (mild_hf + mod_hf + sev_hf) ;
                if denom > 0 then do;
                    daily_sev = (1*mild_hf + 2* mod_hf + 3* sev_hf)/ (mild_hf + mod_hf + sev_hf);
                end;
            END;
            else if not missing(days_all) then daily_sev=0;
        END;
    RUN;

    proc sql;
        create table mean_sev as
               select * , sum(daily_sev) as tot_daily_sev from all_sev
               group by usubjid,avisitn;
    QUIT;

    data mean_sev;
        set mean_sev;
        mean_daily_sev = tot_daily_sev/ days_all;
    RUN;

    proc sort data=mean_sev;
        by usubjid avisitn ady;
    RUN;

    data mean_sev;
        set mean_sev;
        by usubjid avisitn ady ;
        if last.avisitn;
    RUN;

    ** FY: ADT for derived PARAMCDs is updated to theoretical end of week in d_adqshfss per stat request;
    data all_sev2 (drop= mild_hf mod_hf sev_hf days_all num denom daily_sev tot_daily_sev mean_daily_sev);
        set mean_sev;
        by usubjid avisitn;
        QSTESTCD = 'HFDB999';
        PARAMTYP = 'DERIVED';
        QSORRES  = " ";
        QSTEST   = " ";
        AVALC    = " ";
        atptn    = .;
        QSDTC    = " ";

        if avisitn=5 then do;
            if days_all >= 11 then do;
                AVAL=mean_daily_sev;
            END;
            else do;
                AVAL=.;
            END;
        END;

        if avisitn ne 5 then do;
            if days_all >= 5 then do;
                AVAL=mean_daily_sev;
            END;
            else do;
                AVAL=.;
            END;
        END;
    RUN;

    data &adsDomain.;
        set &adsDomain. all_sev2;
    RUN;

    proc datasets nolist lib=work;
        delete mild_hf mod_hf sev_hf all_day all_hf all_sev2 all_sev mean_sev ;
    quit;

%MEND m_create_qs_daily_sev;
