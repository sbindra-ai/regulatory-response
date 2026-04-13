/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/Pool  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = d_adxk);
/*
 * Purpose          : Derivation of ADXK
 * Programming Spec : 21651 Statistical analysis plan_v1.0.docx
 * Validation Level : 2 - Verification by Double Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : epjgw (Roland Meizis) / date: 29AUG2023
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : gmrpb (Fiona Yan) / date: 19OCT2023
 * Reason           : used randdt instead of rfstdt to calculate ADY
 *                    in order to deal with randomized but not treated subjects;
 ******************************************************************************/


*******************************************************************************;
*< Early ADS processing ;
*******************************************************************************;

%early_ads_processing(adsDat = adxk)


*******************************************************************************;
*< Derive daily aggregates;
*******************************************************************************;

proc sort data=adxk
          out=adxk_sort;
    by usubjid xkdtc xkendtc xkcat xktestcd;
run;

/* Transpose parameters for daily summaries */
proc transpose data=adxk_sort (where=(XKCAT = "DAILY SUMMARY"))
               out=adxk_dailysum_t
               prefix=aval_;
    by usubjid xkdtc xkendtc xkcat visitnum visit; /* Add visitnum only for error checks, avisitn derivation is not based on visit */
    var aval;
    format xktestcd; /* Drop format */
    id xktestcd;
    idlabel xktest;
run;

/* Derive ADT */
data adxk_dailysum_t;
    set adxk_dailysum_t;
    %createCustomVars(adsDomain=adxk, vars=ADT);
    by usubjid;

    adt = datepart(input(XKDTC, is8601dt.));
run;

/* Transpose parameters for sleep periods */
proc transpose data=adxk_sort (where=(XKCAT = "SLEEP MEASURES"))
               out=adxk_sleepmeas_t
               prefix=aval_;
    by usubjid xkdtc xkendtc xkcat;
    var aval;
    format xktestcd; /* Drop format */
    id xktestcd;
    idlabel xktest;
run;

/* Derive start and end of 24h measurement period for every sleep period */
data adxk_sleepmeas_t;
    set adxk_sleepmeas_t;

    attrib startdtm                     format=is8601dt.
           startdt                      format=date9.
           starttm                      format=time5.
           enddtm                       format=is8601dt.
           enddt                        format=date9.
           endtm                        format=time5.
           measurement_period_24h_start format=E8601DT19. label="Start of 24h measurement period in which start of sleep period falls"
           measurement_period_24h_end   format=E8601DT19. label="End of 24h measurement period in which start of sleep period falls";

    /* Derive numeric date and time variables */
    startdtm = input(XKDTC, is8601dt.);
    startdt  = datepart(startdtm);
    starttm  = timepart(startdtm);
    enddtm = input(XKENDTC, is8601dt.);
    enddt  = datepart(enddtm);
    endtm  = timepart(enddtm);

    /* The measurement period are the 24h from 18:00 to 17:59 in which the sleep period starts */
    if starttm < (18*60*60) then do;
        measurement_period_24h_start =  DHMS(startdt - 1, 18, 0, 0);
    end;
    else do;
        measurement_period_24h_start =  DHMS(startdt    , 18, 0, 0);
    end;

    measurement_period_24h_end = DHMS(datepart(measurement_period_24h_start) + 1, 17, 59, 59);

    /* Derive adt as end day of the 24h measurement period */
    %createCustomVars(adsDomain=adxk, vars=ADT);
    adt = datepart(measurement_period_24h_start) + 1; /* 24 hours measurement period will be labeled by the latter date */
run;

proc sort data=adxk_sleepmeas_t;
    by usubjid measurement_period_24h_start adt;
run;


/*< Calculate daily aggregates for all sleeping periods within 24h */

/* Group together all sleeping periods starting in the same 24h measurement period and derive sum, mean, etc. */
proc sql;
    /* Derive all daily sleep aggregates */
    create table daily_aggregates_pre1 as
        select unique usubjid
                    , measurement_period_24h_start
                    , measurement_period_24h_end
                    , adt
                    , count(*)                                                as n_sleep_periods        label="Number of sleep periods in 24h measurement period"
                    , max(aval_TMSLSE)                                        as max_sleep_period_time  label="Time (min) of longest sleeping period during 24h measurement period"
                    , sum(aval_TMSLSE)                                        as sum_sleep_period_times label="Total length of all sleep periods during 24h measurement period"
                    , sum(aval_TMASLP)                                        as param_total_sleep      label="Total sleep time"
                    , sum(aval_RATTSLSE * aval_TMSLSE)/sum(aval_TMSLSE) * 100 as param_efficiency       label="Sleep Efficiency (%)" /* weighted average for sleep efficiency */
                    , sum(aval_NMAWKSE)                                       as param_wake_after_onset label="Wake after Sleep Onset"
                    , sum(aval_NOAWKSP) / (sum(aval_TMSLSE)/60)               as param_avg_num_awake    label="Average Number of Awakenings per Hour of Sleep"
                    , mean(aval_AVLENAWK)                                     as param_avg_len_awake    label="Average Length of Awakenings during Sleep"
        from adxk_sleepmeas_t
        group by usubjid, measurement_period_24h_start /* Group all sleeping periods starting in the same 24h measurement period */
    ;
quit;

/* Merge wear time */
data daily_aggregates_pre2;
    merge daily_aggregates_pre1 (in=_in_dailysleep)
          adxk_dailysum_t (keep=usubjid adt aval_: visitnum visit);
    by usubjid adt;
run;

/* Bring in reference data for day 1 from adsl*/
** FY 20231019: to deal with potential randomized but not treated subject, use randomization date instead;
proc sort data=ads.adsl
          out=randdt (keep=usubjid randdt);
    by usubjid;
RUN;

/* Derive ADY (to compare with study days of visits)*/
data daily_aggregates_pre2;
    merge daily_aggregates_pre2 (in=_in_daily)
          randdt;
    by usubjid;

    if _in_daily;

    if not missing(randdt) then do;
        /* Derive ady */
        if not missing(adt) then do;
            if randdt <= adt then ady = adt - randdt + 1;
            else ady = adt - randdt;
        end;
    end;
run;


/*< Merge SV data and derive AVISITN */

proc sort data=sp.sv (where=(visitnum NE 900000)) /* Exclude unscheduled visits */
          out=sv;
    by usubjid svstdtc svendtc;
run;

/* Transpose visit start and end days separately and remerge to get all visits dates as variables  */
proc transpose data=sv
               out=sv_st_t
               prefix=visitnum_
               suffix=_start;
    by usubjid;
    var svstdy;
    format visitnum 6.;
    id visitnum;
    idlabel visit;
run;
proc transpose data=sv
               out=sv_en_t
               prefix=visitnum_
               suffix=_end;
    by usubjid;
    var svendy;
    format visitnum 6.;
    id visitnum;
    idlabel visit;
run;
data sv_t;
    merge sv_st_t (drop=_NAME_ _LABEL_)
          sv_en_t (drop=_NAME_ _LABEL_);
    by usubjid;
run;

/* Merge visit dates and derive AVISITN for periods as specified in SAP */
data daily_aggregates_pre2;
    merge daily_aggregates_pre2 (in=_in_daily_aggregates)
          sv_t;
    by usubjid;

    if _in_daily_aggregates;

    /* Impute missing visits with last possible relative day (according to protocol) */
    if missing(visitnum_5_start     ) then visitnum_5_start      =   1;
    if missing(visitnum_10_end      ) then visitnum_10_end       =  28;
    if missing(visitnum_20_start    ) then visitnum_20_start     =  56;
    if missing(visitnum_20_end      ) then visitnum_20_end       =  56;
    if missing(visitnum_30_start    ) then visitnum_30_start     =  90;
    if missing(visitnum_50_end      ) then visitnum_50_end       = 140;
    if missing(visitnum_600000_start) then visitnum_600000_start = 182;

    %createCustomVars(adsDomain=adxk, vars=AVISITN);
    if      nmiss(visitnum_0_end , visitnum_5_start     ) = 0 and (visitnum_0_end  < ADY < visitnum_5_start     ) then avisitn =      5; /* "prior baseline" */
    else if nmiss(visitnum_10_end, visitnum_20_start    ) = 0 and (visitnum_10_end < ADY < visitnum_20_start    ) then avisitn =     40; /* "after T1" */
    else if nmiss(visitnum_20_end, visitnum_30_start    ) = 0 and (visitnum_20_end < ADY < visitnum_30_start    ) then avisitn =    120; /* "prior T3" */
    else if nmiss(visitnum_50_end, visitnum_600000_start) = 0 and (visitnum_50_end < ADY < visitnum_600000_start) then avisitn =    200; /* "after T5" */
    else                                                                                                               avisitn = 900000; /* Unscheduled  */
run;


/*< Create new records for derived parameters */

/* Create new record for each parameter */
data daily_aggregates;
    merge daily_aggregates_pre2;
    by usubjid adt;

    %createCustomVars(adsDomain=adxk, vars=PARAMTYP PARCAT1 PARAMCD);
    paramtyp = "DERIVED";
    PARCAT1 = "DAILY AGGREGATION";

    /* Total sleep time */
    paramcd = "TSTD";
    if (aval_WRTMCHO >= 1200 or sum_sleep_period_times >= 240) then aval = coalesce(param_total_sleep, 0); /* Use 0 if weartime above threshold but no sleep period */
    else call missing(aval);
    output;

    /* Sleep efficiency */
    paramcd = "SLED";
    if max_sleep_period_time >= 60 then aval = param_efficiency;
    else call missing(aval);
    output;

    /* Wake after Sleep Onset */
    paramcd = "SLWD";
    if (aval_WRTMCHO >= 1200 or sum_sleep_period_times >= 240) then aval = param_wake_after_onset;
    else call missing(aval);
    output;

    /* Average Number of Awakenings per Hour of Sleep */
    paramcd = "AACD";
    if max_sleep_period_time >= 60 then aval = param_avg_num_awake;
    else call missing(aval);
    output;

    /* Average Length of Awakenings during Sleep (min) */
    paramcd = "AAVD";
    if max_sleep_period_time >= 60 then aval = param_avg_len_awake;
    else call missing(aval);
    output;
run;


*******************************************************************************;
*< Derive weekly aggregates;
*******************************************************************************;


/*< Derive 7day periods according to SAP rules */

/* Flag "days with available data" */
data weekly_days_pre;
    set daily_aggregates_pre2;
    by usubjid;
    attrib validdayfn format=NY. label="Day with available data according to SAP?";

    /* SAP: Day with available data is defined as a day with at least 20 hours of device wear time or 4 hours of recorded total sleep time. */
    if (aval_WRTMCHO >= 1200 or sum_sleep_period_times >= 240) then validdayfn = 1;
    else validdayfn = 0;
run;

/* Flag closest 7 days with available data for periods "after T1" and "after T5" */
proc sort data=weekly_days_pre;
    by usubjid avisitn validdayfn adt;
run;
data weekly_days_pre2;
    set weekly_days_pre;
    by usubjid avisitn validdayfn adt;

    attrib part_of_7days_fn format=NY. label="Is day part of the closest 7 days with available data according to SAP?" ;
    attrib i_day_asc label="Number of day in by order (adt ascending)";

    retain i_day_asc;

    if first.validdayfn then i_day_asc = 0;

    i_day_asc = i_day_asc + 1;

    if (validdayfn = 1 and avisitn in (40, 200) and i_day_asc <= 7) then part_of_7days_fn = 1;
run;

/* Flag closest 7 days with available data for periods "prior baseline" and "prior T3" */
proc sort data=weekly_days_pre2;
    by usubjid avisitn validdayfn descending adt;
run;
data weekly_days;
    set weekly_days_pre2;
    by usubjid avisitn validdayfn descending adt;

    attrib i_day_desc label="Number of day in by order (adt descending)";

    retain i_day_desc;

    if first.validdayfn then i_day_desc = 0;

    i_day_desc = i_day_desc + 1;

    if (validdayfn = 1 and avisitn in (5, 120) and i_day_desc <= 7) then part_of_7days_fn = 1;
run;

/* Merge flags back to daily aggregate values */
proc sort data=weekly_days;
    by usubjid adt;
run;
proc sort data=daily_aggregates
          out=daily_aggregates_sort;
    by usubjid adt paramcd;
run;
data weekly_aggregates_pre;
    merge weekly_days (keep=usubjid adt validdayfn part_of_7days_fn /*visitnum_:*/)
          daily_aggregates_sort;
    by usubjid adt;
run;

/* Derive mean over 7day period (following the threshold rules) */
/* SAP: For each type of outcome, the weekly aggregates will be calculated only
if there are at least 4 days with non-missing daily outcome values in the 7-day period.
Otherwise, the weekly aggregate value will be missing. */
proc sql;
    create table weekly_aggregates_pre2 as
        select usubjid
             , paramcd as paramcd_old
             , avisitn
             , case
                  when (N(aval * part_of_7days_fn) >= 4) then mean(aval * part_of_7days_fn)
                  else .
               end as aval_mean
             , sum(part_of_7days_fn) as N_days_w_availabledata
             , N(aval * part_of_7days_fn) as N_nonmissing
        from weekly_aggregates_pre
        where not missing(avisitn) and avisitn NE 900000
        group by usubjid, paramcd, avisitn
    ;
quit;

/* Derive new paramcd values and other standard variables */
data weekly_aggregates;
    set weekly_aggregates_pre2;
    %createCustomVars(adsDomain=adxk, vars=PARAMCD PARAMTYP PARCAT1 AVAL ADT);

    paramcd = cats(substr(paramcd_old, 1, 3), "WAVG"); /* Derive new paramcd value (for weekly aggregations) */
    paramtyp = "DERIVED";
    PARCAT1 = "WEEKLY AGGREGATION";
    aval = aval_mean;
    call missing(adt);
run;


*******************************************************************************;
*< Concatenate daily and weekly records and derive standard variables;
*******************************************************************************;

data adxk_derived_records;
    set daily_aggregates
        weekly_aggregates;
run;

proc sort data=adxk_derived_records;
    by usubjid paramcd adt;
run;

data adxk_derived_records;
    %createCustomVars(adsDomain=adxk, vars=ADSNAME);
    %createCustomVars(adsDomain=adxk, vars=ABLFL);
    %createCustomVars(adsDomain=adxk, vars=WEEKDAYN);
    ATTRIB XKSEQ format=F8.;
    ATTRIB STUDYID length = $10;
    set adxk_derived_records (in=_in_adxk);
    by usubjid;

    studyid = "21651";
    adsname = 'ADXK';

    if not missing(adt) then weekdayn = weekday(adt);

    call missing(XKSEQ);

    /* Derive baseline flag */
    if avisitn = 5 and (not missing(aval)) and PARCAT1 = "WEEKLY AGGREGATION" then ablfl = 'Y';
run;


*******************************************************************************;
*< Late ADS processing ;
*******************************************************************************;

%late_ads_processing(
    adsDat    = work.adxk_derived_records
  , adsDomain = ADXK
  , finalise  = Y /* save in ADS */
)



%endprog()