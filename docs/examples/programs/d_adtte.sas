/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = d_adtte);
/*
 * Purpose          : Derivation of ADTTE
 * Programming Spec :
 * Validation Level : 2 - Verification by Double Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gmrpb (Fiona Yan) / date: 21AUG2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/d_adtte.sas (gmrpb (Fiona Yan) / date: 03AUG2023)
 ******************************************************************************/
/* Changed by       : eokcw (Vijesh Shrivastava) / date: 05SEP2023
 * Reason           : Updated "SGPT" testcdoe to "SGPTSP" due to change in SP domain code.
 ******************************************************************************/
/* Changed by       : gmrpb (Fiona Yan) / date: 26OCT2023
 * Reason           : remove the part for T2FPCM randomized but not treated special deal
 ******************************************************************************/

%let adsDomain = ADTTE;

** get FAS and SAF population;
proc sort data=ads.adsl out=fas(keep=usubjid saffl lvdt rfpendt randdt);
    where fasfl="Y";
    by usubjid;
RUN;

*<*********************************************************************************************;
*< T2ALT: Time to ALT >= 3xULN (Days)       T2ALP: Time to ALP >= 3xULN (Days)
*< Calculated as days from randomization to first occurrence of event.
*< If no such increase is observed, the observation is censored at the last visit date.
*< If a participant does not have any post-baseline data, she will be censored at baseline (further confirm by stat, use randomization date).
*<*********************************************************************************************;

** safety population;
data t2lb_pop;
    set fas(where=(saffl="Y"));
    %createCustomVars(adsDomain = adtte, vars = paramcd);
    paramcd="ALKPHOSP"; output;
    paramcd="SGPTSP"; output;
RUN;

** subjects who have post-baseline data for each PARAMCD;
proc sort data=ads.adlb out=t2lb_pbase(keep=paramcd usubjid) nodupkey;
    where paramcd in ("SGPTSP" "ALKPHOSP") and ady>=1 and ablfl^="Y" and not missing(aval);
    by usubjid paramcd;
RUN;

** subjects who have a event;
proc sort data=ads.adlb out=t2lb_event(keep=paramcd usubjid adt ady);
    where paramcd in ("SGPTSP" "ALKPHOSP") and ady>=1 and aval>=3*anrhi>.z;
    by usubjid paramcd adt;
RUN;

data t2lb_event(keep=usubjid paramcd adt ady);
    set t2lb_event;
    by usubjid paramcd adt;
    if first.paramcd;
RUN;

data t2lb;
    merge t2lb_pop(in=a) t2lb_pbase(in=pbase) t2lb_event(in=event rename=(adt=event_date ady=event_ady));
    by usubjid paramcd;
    if a;
    %createCustomVars(adsDomain = adtte, vars = cnsr srcdom srcvar evntdesc adt aval);

    if event then do;
        cnsr=0;
        srcdom="ADLB";
        srcvar="ADT";
        if paramcd="SGPTSP" then evntdesc="ALT >= 3xULN";
        if paramcd="ALKPHOSP" then evntdesc="ALP >= 3xULN";
        adt=event_date;
        aval=event_ady;
    END;
    else do;
        cnsr=1;
        if pbase then do;
            if not missing(lvdt) then do;
                srcdom="ADSL";
                srcvar="LVDT";
                evntdesc="No such increase was observed and subject censored at the last visit date";
                adt=lvdt;
                aval=lvdt-randdt+1;
            END;
            else if not missing(rfpendt) then do;
                srcdom="ADSL";
                srcvar="RFPENDT";
                evntdesc="No such increase was observed and subject censored at the end of participation date";
                adt=rfpendt;
                aval=rfpendt-randdt+1;
            END;
            else do;
                put "WAR" "NING: USUBJID=" usubjid "PARAMCD=" paramcd "miss censor date. May due to ongoing subject. Use today's date for now.";
                srcdom="TEMP";
                srcvar="TEMP";
                evntdesc="TEMP: No event so far. Due to ongoing subject, the date is set to program running date.";
                adt=today();
                aval=today()-randdt+1;
            END;
        END;
        else do;
            srcdom="ADSL";
            srcvar="RANDDT";
            evntdesc="Subject didn't have any post-baseline data and censored at randomization";
            adt=randdt;
            aval=1;
        END;
    END;
RUN;

data t2lb;
    set t2lb;
    if paramcd="SGPTSP" then paramcd="T2ALT";
    if paramcd="ALKPHOSP" then paramcd="T2ALP";
RUN;

*<*********************************************************************************************;
*< T2DISC: Time to permanent discontinuation of randomized treatment (Weeks)
*< Calculated as weeks from randomization to permanent discontinuation of randomized treatment;
*< If event did not occur by day 84, the participant will be censored at week 12;
*< For randomized but not treated subject, it censored on week 1.;
*<*********************************************************************************************;

** subject with ICE of ADDS on or before week 12;
proc sort data=ads.adds out=t2disc_event(keep=usubjid astdt icestwk);
    where ice01fl="Y" and icestwk<=12;
    by usubjid;
RUN;

** full analysis set;
data t2disc;
    merge fas(in=a) t2disc_event(in=event);
    by usubjid;
    if a;
    %createCustomVars(adsDomain = adtte, vars = paramcd cnsr srcdom srcvar evntdesc adt aval);
    paramcd="T2DISC";

    if saffl^="Y" then do;
        cnsr=0;
        srcdom="ADSL";
        srcvar="RANDDT";
        evntdesc="Permanent discontinuation of randomized treatment";
        adt=randdt;
        aval=0;  *per stat: randomization will manually be set to week 0;
    END;
    else if saffl='Y' then do;
        if event then do;
            cnsr=0;
            srcdom="ADDS";
            srcvar="ASTDT";
            evntdesc="Permanent discontinuation of randomized treatment";
            adt=astdt;
            aval=icestwk;
        END;
        else do;
            cnsr=1;
            evntdesc="No event and censored on week 12";
            adt=randdt+83;
            aval=12;
        END;
    END;
RUN;

*<********************************************************************************************************************************;
*< T2FPCM: Time to first intake of prohibited concomitant medication having impact on efficacy (Weeks)
*< Calculated as weeks from randomization to first intake of prohibited concomitant medication having impact on efficacy;
*< If event did not occur by day 84, the participant will be censored at week 12 or at the time of dropping out of the study,
**< whichever occurs earlier.
*<********************************************************************************************************************************;

** subject with ICE of ADCM on or before week 12;
proc sort data=ads.adcm out=t2fpcm_event(keep=usubjid astdt icestwk);
    where ice01fl="Y" and icestwk<=12;
    by usubjid astdt;
RUN;

data t2fpcm_event;
    set t2fpcm_event;
    by usubjid astdt;
    if first.usubjid;
RUN;

** full analysis set;
data t2fpcm;
    merge fas(in=a) t2fpcm_event(in=event);
    by usubjid;
    if a;
    %createCustomVars(adsDomain = adtte, vars = paramcd cnsr srcdom srcvar evntdesc adt aval);
    paramcd="T2FPCM";

    if event then do;
        cnsr=0;
        srcdom="ADCM";
        srcvar="ASTDT";
        evntdesc="First intake of prohibited concomitant medication having impact on efficacy";
        adt=astdt;
        aval=icestwk;
    END;
    else do;
        if not missing(rfpendt) then rfpendy=rfpendt-randdt+1;
        if not missing(rfpendt) and rfpendy<84 then do;
            cnsr=1;
            srcdom="ADSL";
            srcvar="RFPENDT";
            evntdesc="No event and censored at the time of dropping out of the study";
            adt=rfpendt;
            if 2<=rfpendy<=6 then aval=0;
            else aval=min(ceil((rfpendy+2)/7)-1,12);
        END;
        else do;
            cnsr=1;
            evntdesc="No event and censored on week 12";
            adt=randdt+83;
            aval=12;
        END;
    END;
RUN;

*<********************************************************************************************************************************;
*< T50RMDF: Time to treatment response - reduction of 50% mean daily frequency of moderate to severe hot flashes (Weeks)
*< Calculated as weeks from randomization to first occurrence of reduction of 50% mean daily frequency of moderate to severe hot flashes;
*< If the required treatment reduction by week 12 is not observed, the participant will be censored at week 12.
*< Similarly, participants that drop out of the study before achieving the required reduction, will be censored at the time of dropping out
*< (i.e., at the last evaluable week, defined as a week with at least 5 days of diary data, before dropping out).
*<********************************************************************************************************************************;
** subjects who have a event;
proc sort data=ads.adqshfss out=t50rmdf_event(keep=usubjid adt ady avisitn);
    where paramcd="HFDB998" and CRIT1FL="Y" and avisitn<=120;
    by usubjid adt;
RUN;

data t50rmdf_event;
    set t50rmdf_event;
    by usubjid adt;
    if first.usubjid;
RUN;

** last evaluable week info;
proc sort data=ads.adqshfss out=t50rmdf_lst(keep=usubjid adt ady avisitn);
    where paramcd="HFDB998" and not missing(aval) and avisitn<700000;
    by usubjid adt;
RUN;

data t50rmdf_lst;
    set t50rmdf_lst;
    by usubjid adt;
    if last.usubjid;
RUN;

data t50rmdf;
    merge fas(in=a) t50rmdf_event(in=event rename=(adt=event_date ady=event_ady avisitn=event_avisitn)) t50rmdf_lst(rename=(adt=lst_date ady=lst_ady avisitn=lst_avisitn));
    by usubjid;
    if a;
    %createCustomVars(adsDomain = adtte, vars = paramcd cnsr srcdom srcvar evntdesc adt aval);
    paramcd="T50RMDF";

    if event then do;
        cnsr=0;
        srcdom="ADQSHFSS";
        srcvar="ADT";
        evntdesc="Treatment response - reduction of 50% mean daily frequency of moderate to severe hot flashes";
        adt=event_date;
        aval=event_avisitn/10;
    END;
    else do;
        if lst_avisitn=5 then do;
            cnsr=1;
            srcdom="ADSL";
            srcvar="RANDDT";
            evntdesc="No event and censored at randomization";
            adt=randdt;
            aval=0; *if the last evaluable week is baseline week, then censored at randomization (week 0);
        END;
        else if lst_avisitn<=120 then do;
            cnsr=1;
            srcdom="ADQSHFSS";
            srcvar="ADT";
            evntdesc="No event and censored at last evaluable week";
            adt=max(randdt,lst_date);
            aval=lst_avisitn/10;
        END;
        else do;
            cnsr=1;
            evntdesc="No event and censored on week 12";
            adt=randdt+83;
            aval=12;
        END;
    END;
RUN;

data &adsDomain.;
    set t2lb t2disc t2fpcm t50rmdf;
    %createCustomVars(adsDomain = adtte, vars = paramtyp ADSNAME startdt);
    paramtyp="DERIVED";
    ADSNAME="ADTTE";
    STUDYID="&STUDY";
    startdt=randdt;
RUN;

*<*****************************************************************************;
*< Late ADS processing;
*<*****************************************************************************;

%late_ads_processing(adsDat = &adsDomain.)

%endprog();
