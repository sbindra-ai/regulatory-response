%MACRO m_create_qs_sleepiness()
/ DES = 'Sleepiness scale paramcd';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: pure SAS
 *******************************************************************************
 * Purpose          : Add sleepiness scale paramcd in ADQSHFSS
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
 * Author(s)        : eokcw (Vijesh Shrivastava) / date: 13OCT2022
 *******************************************************************************
 * Change History   :
 ******************************************************************************/
/* Changed by       : gmrpb (Fiona Yan) / date: 22JUL2023
 * Reason           : add some comments for pending issues
 *                    update logic when deriving daily mean of the week
 *                    based on updated SAP, baseline SS need a minimum of 4 days
 *                    update macro title part to Bayer standard
 *                    add four more overall parameters (removed)
 *                    update available days logic
 ******************************************************************************/

/*******************************************************************************
 * Examples         :
   %m_create_qs_sleepiness();
 ******************************************************************************/

*** Get data from QS;
    data sleep;
        set &adsDomain. (where=(QSCAT in ('SLEEPINESS SCALE V1.0') and dupfl^='Y'));
        if  AVALCN = 'NOT AT ALL' then naval=0;
        else if  AVALCN = 'A LITTLE BIT' then naval=1;
        else if  AVALCN = 'SOMEWHAT' then naval=2;
        else if  AVALCN = 'QUITE A BIT' then naval=3;
        else if  AVALCN = 'VERY MUCH' then naval=4;
    RUN;

    **** Daily mean of morning, afternoon and evening (item 1 -3) ;
    proc sort data=sleep;
        by usubjid avisitn adt qsevintx;
    RUN;

    proc sql;
        create table mean_time as
        select *, mean(naval) as mean, count (distinct adt) as days from sleep
        where avisitn ne .
        group by usubjid,avisitn,qsevintx;

        create table days_all as
        select usubjid, avisitn, count (distinct adt) as days_all from sleep
        where avisitn ne .
        group by usubjid,avisitn;
    QUIT;

    proc sort data=mean_time;
        by usubjid avisitn qsevintx adt;
    RUN;

    data time_final;
        set mean_time;
        by usubjid avisitn qsevintx;
        if last.qsevintx then output;
    RUN;

    * mean daily total score ;
    proc sql;
        create table mean_daily as
        select *, mean(naval) as daily_mean from mean_time
        where avisitn ne .
        group by usubjid,avisitn,adt;
    QUIT;

    ** keep one record (of the daily mean) per day to calculate daily mean of the week;
    proc sort data=mean_daily;
        by usubjid avisitn adt descending days;
    RUN;

    data mean_daily2;
        set mean_daily;
        by usubjid avisitn adt;
        if first.adt then output;
    RUN;

    ** merge the overall available days for each week: days_all;
    data mean_daily2;
        merge mean_daily2(in=a) days_all;
        by usubjid avisitn;
        if a;
    RUN;

    proc sql;
        create table total_final as
        select *, mean(daily_mean) as total_mean from mean_daily2
        where avisitn ne .
        group by usubjid,avisitn;
    QUIT;

    proc sort data=total_final;
        by usubjid avisitn adt;
    RUN;

    data total_final(drop=mean);
        set total_final;
        by usubjid avisitn adt;
        if last.avisitn then output;
    RUN;

    ** FY: ADT for derived PARAMCDs is updated to theoretical end of week in d_adqshfss per stat request;

    **** Daily mean of morning, afternoon and evening (item 1 -3) ;

    data time_final2(drop=naval mean days);
        set time_final;
        if QSEVINTX="MORNING" then QSTESTCD = 'SLSB0996';
        else if QSEVINTX="AFTERNOON" then QSTESTCD = 'SLSB0997';
        else if QSEVINTX="EVENING" then QSTESTCD = 'SLSB0998';

        PARAMTYP = 'DERIVED';
        QSORRES  = " ";
        QSTEST   = " ";
        AVALC    = " ";
        atptn    = .;
        QSDTC    = " ";
        AVAL = mean;

        if avisitn=5 then do;
            if days < 11 then do;
                AVAL=.;
            END;
        END;

        if avisitn ne 5 then do;
            if days < 5 then do;
                AVAL=.;
            END;
        END;

    RUN;

    * mean daily total score ;
    data total_final2(drop=naval daily_mean days days_all);
        set total_final;

        QSTESTCD = 'SLSB0999';
        PARAMTYP = 'DERIVED';
        QSORRES  = " ";
        QSTEST   = " ";
        AVALC    = " ";
        atptn    = .;
        QSDTC    = " ";

        AVAL = total_mean;

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

    data sleep_final;
        set time_final2 total_final2;
    RUN;

    data &adsDomain.;
        set &adsDomain. sleep_final;
    RUN;

    proc datasets nolist lib=work;
        delete mean_daily mean_daily2 mean_time sleep sleep_final time_final total_final time_final2 total_final2 days_all;
    quit;

%MEND m_create_qs_sleepiness;
