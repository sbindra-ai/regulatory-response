%MACRO m_create_qs_ice(indata=adqs,
                      outdata=adqs)
/ DES = 'Add ICE flag and relevant reasons/sub-reasons for derived parameters in ADQS';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: pure SAS
 *******************************************************************************
 * Purpose          : Add ICE flag and relevant reasons/sub-reasons for derived parameters in ADQS
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * Parameters       :
 *                    indata: input dataset name
 *                    outdata: output dataset name
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
 * Author(s)        : gmrnq (Susie Zhang) / date: 24OCT2023
 *******************************************************************************
 * Change History   :
 ******************************************************************************/

/*******************************************************************************
 * Examples         : %m_create_qs_ice();
 ******************************************************************************/



*<******************************************************************************;
*< ANL01FL: ICE flag for Permanent Discontinuation;
*<******************************************************************************;

* Get ICE flag for Permanent Discontinuation from study drug in ADDS ;
proc sort data=ads.adds out=ds1(keep=studyid usubjid icereas icestwk astdt aphase ice01fl);
    where ice01fl='Y';
    by studyid usubjid;
RUN;

* Select the latest date for each subject;
proc sql noprint;
    create table ds2 as
           select *
           from ds1
           group by studyid, usubjid
           having astdt=max(astdt)
           order by studyid, usubjid;
QUIT;


* Merge QS records with permanent discontinuation info;
proc sort data=ads.adsl out=adsl; by studyid usubjid; run;
proc sort data=&indata.; by studyid usubjid adt ady; RUN;

data ice1_ds;
    merge &indata.(in=a) ds2(rename=(astdt=astdt_ds)) adsl(keep=studyid usubjid saffl randfl);
    by studyid usubjid;
    if a;
RUN;


* Flag permanent discontinuation ICE records till week 12;
data final_ice1_ds;
    set ice1_ds;
    %createCustomVars(adsDomain=adqs, vars=ANL01FL ICEDSRS );
    if 10<=avisitn<=120 then comwk=avisitn/10;
    else comwk=.;
    * For permanent discontinuation ICE flag, only to check week, no need to check day;
    if paramtyp="DERIVED" and 10<=avisitn<=120 and
       (find(parcat1, 'MENOPAUSE-SPECIFIC QUALITY-OF-LIFE QUESTIONNAIRE')>0 or parcat1='PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0')
       and ice01fl="Y" and . < icestwk <= comwk and find(paramcd, "MENB8")=0 then do;
        anl01fl = "Y";
        icedsrs = icereas;
    END;
    drop icereas icestwk astdt_ds aphase ice01fl;
RUN;



*<******************************************************************************;
*< ANL02FL: ICE flag for Temporary Treatment Interruption;
*<******************************************************************************;

* Get ICE flag for temporary treatment interruption from ADEX;
data ex(keep=studyid usubjid ice01fl icereas astdt_ex astdy_ex comwk);
    set ads.adex;
    if ice01fl = "Y" and aphase = 'Week 1-12' and astdt ne .;
    comwk=input(compress(paramcd,'','kd'), best.);
    rename astdt=astdt_ex astdy=astdy_ex;
RUN;

proc sort data=ex; by studyid usubjid comwk; run;

proc sort data=final_ice1_ds; by studyid usubjid comwk; RUN;

data ice2_ex;
    merge final_ice1_ds(in=a) ex;
    by studyid usubjid comwk;
    if a;
RUN;

* Flag temporary treatment interruption ICE records till week 12;
data final_ice2_ex;
    set ice2_ex;
    length iceintrs $200.;
    if paramtyp="DERIVED" and 10<=avisitn<=120 and
       (find(parcat1, 'MENOPAUSE-SPECIFIC QUALITY-OF-LIFE QUESTIONNAIRE')>0 or parcat1='PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0')
       and ice01fl="Y" and comwk ne . and (.<astdt_ex<=adt or adt=.)
       and find(paramcd, "MENB8")=0 then do;
        anl02fl = "Y";
        iceintrs = icereas;
    END;
    drop ice01fl icereas astdt_ex astdy_ex;
RUN;


*<******************************************************************************;
*< ANL03FL: ICE flag for Prohibited Medication;
*<******************************************************************************;

* Get ICE flag for Concomitant medication interruption from ADCM;
data cm;
    set ads.adcm;
    if ice01fl = "Y" ;
    * Set to a large number for the ICE end week since it is still ongoing;
    if iceenwk eq .  and find(cmenrtpt,"ONGOING") then iceenwk=99;
    keep studyid usubjid ice01fl icestwk iceenwk;
RUN;

proc sort data=cm; by studyid usubjid icestwk iceenwk; run;

* Transpose data in case there are multiple CM records for the same subject;
proc transpose data=cm out=cm_st(drop=_:) prefix=ice_st_;
    by studyid usubjid ice01fl;
    var icestwk;
RUN;

proc transpose data=cm out=cm_en(drop=_:) prefix=ice_en_;
    by studyid usubjid;
    var iceenwk;
RUN;

* Flag Concomitant medication interruption ICE records till week 12;
proc sort data=final_ice2_ex; by studyid usubjid; RUN;

data ice3_cm;
    merge final_ice2_ex(in=a) cm_st cm_en;
    by studyid usubjid;
    if a;
run;

data final_ice3_cm;
    set ice3_cm;

    array start_cm (*) ice_st_:;
    array end_cm (*) ice_en_:;
    if paramtyp="DERIVED" and 10<=avisitn<=120 and
       (find(parcat1, 'MENOPAUSE-SPECIFIC QUALITY-OF-LIFE QUESTIONNAIRE')>0 or parcat1='PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0')
        and find(paramcd, "MENB8")=0 then do;
        do i=1 to dim(start_cm);
            if .< start_cm[i] <= comwk <= end_cm[i] then anl03fl = "Y";
        END;
    END;
    drop i ice01fl ice_st_: ice_en_: ;
RUN;


*<******************************************************************************;
*< ANL05FL: VMS flag;
*<******************************************************************************;

* Get VMS flag for VMS treatment from ADCM;
data cm_v;
    set ads.adcm;
    if ice01fl = "Y" and vmsfl = "Y";
    * Set to a large number for the ICE end week since it is still ongoing;
    if iceenwk eq .  and find(cmenrtpt,"ONGOING") then iceenwk=99;
    keep studyid usubjid ice01fl icestwk iceenwk;
RUN;

proc sort data=cm_v; by studyid usubjid icestwk iceenwk; run;

* Transpose data in case there are multiple CM records for the same subject;
proc transpose data=cm_v out=cm_v_st(drop=_:) prefix=ice_v_st_;
    by studyid usubjid ice01fl;
    var icestwk;
RUN;

proc transpose data=cm_v out=cm_v_en(drop=_:) prefix=ice_v_en_;
    by studyid usubjid;
    var iceenwk;
RUN;

* Flag VMS records till week 12;
proc sort data=final_ice3_cm; by studyid usubjid; RUN;

data ice3_cm_v;
    merge final_ice3_cm(in=a) cm_v_st cm_v_en;
    by studyid usubjid;
    if a;
run;

data final_ice3_cm_v;
    set ice3_cm_v;

    array start_cm (*) ice_v_st_:;
    array end_cm (*) ice_v_en_:;
    if paramtyp="DERIVED" and 10<=avisitn<=120 and
       (find(parcat1, 'MENOPAUSE-SPECIFIC QUALITY-OF-LIFE QUESTIONNAIRE')>0 or parcat1='PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0')
       and find(paramcd, "MENB8")=0 then do;
        do i=1 to dim(start_cm);
            if .< start_cm[i] <= comwk <= end_cm[i] then anl05fl = "Y";
        END;
    END;
    drop i ice01fl ice_v_st_: ice_v_en_: ;
RUN;


*<******************************************************************************;
*< Output data;
*<******************************************************************************;
data &outdata.;
    set final_ice3_cm_v;
RUN;

%MEND m_create_qs_ice;
