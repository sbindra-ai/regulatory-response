%MACRO m_create_qs_ice_hfss(
       indata                    =adqshfss
     , outdata                   =ads.adqshfss
     , paramcd_cond              =%str(paramtyp="DERIVED")
)
/ DES = 'Add ICE flag and relevant reasons/sub-reasons for derived parameters in ADQSHFSS';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: pure SAS
 *******************************************************************************
 * Purpose          : Add ICE flag and relevant reasons/sub-reasons for derived parameters in ADQSHFSS
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * Parameters       :
 *                    indata: input dataset name
 *                    outdatt: output dataset name
 *                    paramcd_cond: condition to select PARAMCDs which need to be flagged for ICE
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
 * Author(s)        : gmrpb (Fiona Yan) / date: 06OCT2023
 *******************************************************************************
 * Change History   :
 ******************************************************************************/

/*******************************************************************************
 * Examples         :
   %m_create_qs_ice();
 ******************************************************************************/

    *================================================================================================================;
    * ICE: Permanent discontinuation of randomized treatment;
    * bring in ICE from ADDS;
    *================================================================================================================;
    proc sort data=ads.adds out=adds(keep=usubjid icereas ICESTWK);
        where ice01fl='Y';
        by usubjid;
    RUN;

    ** Merge with input data and flag the desired records - ICE: PD of rand trt;
    ** 1) Will be mapped to all weeks following the event, including the current one;
    ** 2) can happen only once for same subjects;
    ** 3) Should be only done until week 12 (day 84);

    data indata_adds;
        merge &indata.(in=a) adds;
        by usubjid;
        if a;

        if 10<=avisitn<=120 then period=1; * from week1 to week12;
        rename icereas=icedsrs;
    RUN;

    ** break the data step into two parts otherwise call missing statement will have wired performance;
    data indata_adds(drop=);
        set indata_adds;

        if &paramcd_cond. and period=1 and avisitn/10>=ICESTWK>.z then anl01fl='Y';
        else do;
            call missing(icedsrs);
        END;
    RUN;

    *================================================================================================================;
    * ICE: Temporary treatment interruption;
    * bring in ICE from ADEX;
    *================================================================================================================;
    data adex;
        set ads.adex(keep=usubjid astdy paramcd icereas ice01fl);
        where ice01fl="Y";
        if missing(icereas) then put "WARN" "ING: ADEX ICE record without a reason for USUBJID=" USUBJID "and ASTDY=" ASTDY;
    RUN;

    proc sort data=adex;
        by usubjid paramcd;
    RUN;

    data indata_adds;
        set indata_adds;
        length linkid $8.;
        if avisitn=10 then linkid="TRTINW1";
        else if avisitn=40 then linkid="TRTINW4";
        else if avisitn=80 then linkid="TRTINW8";
        else if avisitn=120 then linkid="TRTINW12";
    RUN;

    proc sort data=indata_adds;
        by usubjid linkid;
    RUN;

    data indata_adds_adex;
        merge indata_adds(in=a) adex(rename=(paramcd=linkid));
        by usubjid linkid;
        if a;

        length ICEINTRS $200.;
        if &paramcd_cond. and period=1 and ice01fl="Y" then do;
            anl02fl='Y';
            ICEINTRS=strip(icereas);
        END;
    RUN;

    *================================================================================================================;
    * ICE: Intake of prohibited medication having impact on efficacy;
    * bring in ICE from ADCM;
    *================================================================================================================;
    proc sort data=ads.adcm out=adcm(keep=usubjid ICESTWK ICEENWK);
        where ice01fl='Y';
        by usubjid;
    RUN;

    proc transpose data=adcm out=adcm_st(drop=_:) prefix=start_cm;
        by usubjid;
        var icestwk;
    RUN;

    proc transpose data=adcm out=adcm_ed(drop=_:) prefix=end_cm;
        by usubjid;
        var iceenwk;
    RUN;

    data indata_adds_adex_adcm;
        merge indata_adds_adex(in=a drop=icestwk) adcm_st adcm_ed;
        by usubjid;
        if a;
    RUN;

    ** break the data step into two parts otherwise wired performance;

    data indata_adds_adex_adcm;
        set indata_adds_adex_adcm;

        if &paramcd_cond. and period=1 then do;
            array start (*) start_cm: ;
            array end (*) end_cm: ;
            do j=1 to dim(start);
                if not missing(start[j]) then do;
                    if avisitn/10>=start[j]>.z and (avisitn/10<=end[j] or missing(end[j])) then anl03fl='Y';
                END;
            END;
        END;
    RUN;

    *================================================================================================================;
    * ICE: Intake of VMS treatment having impact on efficacy;
    * bring in event from ADCM;
    *================================================================================================================;
    proc sort data=ads.adcm out=adcm2(keep=usubjid ICESTWK ICEENWK);
        where vmsfl='Y' and ice01fl="Y";
        by usubjid;
    RUN;

    proc transpose data=adcm2 out=adcm2_st(drop=_:) prefix=start_cm;
        by usubjid;
        var icestwk;
    RUN;

    proc transpose data=adcm2 out=adcm2_ed(drop=_:) prefix=end_cm;
        by usubjid;
        var iceenwk;
    RUN;

    data indata_adds_adex_adcm2;
        merge indata_adds_adex_adcm(in=a drop= start_cm: end_cm:) adcm2_st adcm2_ed;
        by usubjid;
        if a;
    RUN;

    ** break the data step into two parts otherwise wired performance;

    data indata_adds_adex_adcm2;
        set indata_adds_adex_adcm2;

        if &paramcd_cond. and period=1 then do;
            array start (*) start_cm: ;
            array end (*) end_cm: ;
            do k=1 to dim(start);
                if not missing(start[k]) then do;
                    if avisitn/10>=start[k]>.z and (avisitn/10<=end[k] or missing(end[k])) then anl05fl='Y';
                END;
            END;
        END;
    RUN;

    data &outdata.;
        set indata_adds_adex_adcm2;
    RUN;

%MEND m_create_qs_ice_hfss;
