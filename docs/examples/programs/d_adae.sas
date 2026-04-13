/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(
    name     = d_adae
  , log2file = Y
);
/*
 * Purpose          : Derivation of ADAE
 * Programming Spec :
 * Validation Level : 2 - Verification by Double Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gkbkw (Ashutosh Kumar) / date: 13SEP2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/d_adae.sas (gkbkw (Ashutosh Kumar) / date: 13SEP2023)
 ******************************************************************************/
/* Changed by       : gmrpb (Fiona Yan) / date: 19DEC2023
 * Reason           : sort sp.ex and output ex by STUDYID USUBJID
 ******************************************************************************/


%let adsDomain = ADAE;

%early_ads_processing(adsDat = &adsDomain.)

data adsl(keep=usubjid USUBJID RFSTDT PH1EDT TRTSDT TRTEDT PH1SDT PH2SDT PH2EDT TRT01AN);

    set ads.adsl;
    where TRTSDT ne .;

RUN;
proc sort data=&adsDomain. out=&adsDomain.1;
    by usubjid;
RUN;
proc sort data=adsl ;
    by usubjid;
RUN;
data &adsDomain.2;
    merge &adsDomain.1(in=a) adsl;
    by usubjid;
    if a;
RUN;
%m_impute_astdt(
    indat    = adae2
  , sp_stdtc = AESTDTC
  , outdat   = ADAE3
)
*** Custom Derivation;
DATA &adsDomain.4;
    set &adsDomain.3;

    %createCustomVars(adsDomain = adae, vars = asevn)
    ;
    asevn = WHICHC(aesev, 'MILD', 'MODERATE', 'SEVERE');

    if ASEVN eq 0 then ASEVN=.;
    %createCustomVars(adsDomain = adae, vars = ARELN)
    ;

    if AEREL ne "" then ARELN  = IFN(AEREL  EQ 'Y',1,0);

    ** As per SAP  If the drug relationship is missing, the event will be considered as being related to the study drug**;
    else ARELN = 1;
    %createCustomVars(adsDomain = adae, vars = adurn)
    ;
    IF NMISS(astdt, aendt) = 0 THEN DO;
        adurn =(aendt - astdt)+1;
    END;

RUN;

data &adsDomain.5;
    set &adsDomain.4;
    by usubjid ;

    %createCustomVars(adsDomain = &adsDomain., vars = prefl)
    ;
    if n(astdt,trtsdt)=2 and ((astdt < trtsdt )) then prefl = 'Y';
    %createCustomVars(adsDomain = adae, vars = postfl)
    ;
    if n(astdt,trtedt)=2 and (astdt > (trtedt +14)) then postfl = 'Y';
    %createCustomVars(adsDomain = adae, vars = aphase)
    ;
    if n(astdt,ph1sdt,ph1edt)=3 and ph1sdt <= astdt <= ph1edt+14  then aphase = "Week 1-12";
    ELSE IF  MISSING(ph1edt) AND n(astdt,ph1sdt)=2  AND astdt>= ph1sdt THEN aphase = "Week 1-12" ;
    else if astdt eq . and ph2sdt eq . then aphase = "Week 1-12"  ;

     if  n(astdt,ph2sdt,ph2edt)=3 and (ph2sdt <= astdt <= ph2edt+14 ) then aphase = "Week 13-26";
      ELSE IF  MISSING(ph2edt) AND n(astdt,ph2sdt)=2  AND astdt>= ph2sdt THEN aphase = "Week 13-26" ;
      else if astdt eq . and ph2sdt ne . then aphase = "Week 13-26"  ; ;
/*removing Phase for POSTFL*/
     if postfl eq "Y" then aphase ="";
RUN;
*< TRTEMFL;
data TS;
    set sp.ts;
    if TSPARMCD eq 'TIMEW' then tsval='14';
run;


data adsl1;
    set ads.adsl;
    by STUDYID USUBJID;
    keep STUDYID USUBJID TRTSDT TRTEDT;
     where not missing(TRTSDT);
RUN;

proc sort data=sp.ex out=ex;
     by STUDYID USUBJID;
     where not missing(EXSTDTC);
RUN;

data EX1;
    merge EX adsl1;
    by STUDYID USUBJID;
    /*ongoing subject should have missing ENDTC as per ADSL */
    if  not missing(EXENDTC) and TRTEDT eq .  then EXENDTC="" ;
RUN;


* SAP: AEs are considered to be treatment-emergent if they have started or worsened after administration of study intervention
       up to 11days after administration of study intervention.;
%setteaeflag(
    aeDat         = &adsDomain.5
  , trtDat        = EX1
  , timeWindowDat = ts(WHERE= (tsparmcd = 'TIMEW'))
  , aeGroupVar    =
  , nonTeaeCrfVar =
  , outDat        = &adsDomain.6
  , doPreSteps    = N
)

DATA &adsDomain.7;
    SET &adsDomain.6;

    IF trtemfl = 'N' THEN call missing(trtemfl);
    IF trtemfl = 'Y' THEN trtemfn = 1;
    IF aetrtem NE trtemfl AND aetrtem NE 'N' THEN DO;
        PUT "WAR" "NING: Please check AETERMN vs TRTEMFL " &subj_var. aetrtem= TRTEMFL=;
    END;

    IF  trtemfl eq "Y" AND ( POSTFL EQ 'Y' or PREFL eq "Y" ) THEN DO;
        PUT "WAR" "NING: Please check POSTFL vs TRTEMFL " &subj_var. PREFL= POSTFL= TRTEMFL=;
    END;
    /*as per Vijesh and Semi confirmation on 12 Sep 2023 Record with missing AETERM will not be deleted */
    if  AETERM eq "" then do;
        trtemfl = "";
        ARELN =.;
        APHASE="";
        end;
RUN;

/* Select SMQs/PTs for AESI */
/* See SAP 6.8 Appendix 8: Coding conditions applicable for AESI */
%smq_select(
    outdat    = smq4aesi_2
  , smqcode   = SMQ_90000101 20000009 20000007 20000008 20000015 SMQ_90001186 SMQ_90001246 SMQ_90000142
  , smqtype   = SMQ BMQ MLG
  , smqsearch = _ALL_
)



/* SAP: In addition to MLGs above, include  PT Sleep disorder due to general medical condition, hypersomnia type*/
data pt_sleepdis;
    set meddra.meddra (where=(m_pt eq '10040985'));
run;

data smq4aesi_3;
    set smq4aesi_2
        pt_sleepdis (obs=1 /* We only need one record with pt_code and name, ignore LLT */
                     in=_in_pt_sleepdis);

    if _in_pt_sleepdis then do;
        pt_code = strip(M_PT);
        pt_name = strip(MT_PT);
    end;
run;

/* Join SMQ information to ADAE */
PROC SQL;
    CREATE TABLE &adsDomain.9 AS
       SELECT l.*,r1.smq_name,r1.SMQ_CODE,r1.PT_SMQ_DEF_ID, CASE WHEN NOT missing(r1.pt_code) THEN "Y" ELSE "" END AS aesi

       FROM           &adsDomain.7 AS l
            LEFT JOIN smq4aesi_3 AS r1
                   ON l.aeptcd=input(r1.pt_code,best.)
           ;

QUIT;

data  &adsDomain.10(drop=aesi);
    set  &adsDomain.9;
    %createCustomVars(adsDomain = adae, vars = ASSINY)
    ;
    ASSINY=aesi;

    /* as per study stats "In addition to MGLs select individual" PT Sleep disorder due to general medical condition,
    ! hypersomnia type".*/
    if aeptcd eq 10040985 or AESSINY eq "Y" then ASSINY= "Y";

    %createCustomVars(adsDomain = adae, vars = CQ01CD  CQ02CD  CQ03CD  CQ04CD)
    ;
    if smq_code in( 'SMQ_90001246')  then do;
        CQ04CD=4;/* Post-menopausal uterine bleeding*/
    END;
    if smq_code in( 'SMQ_90000142')  then do;
        CQ03CD=3;/* Photosensitivity reaction*/
    END;
    if smq_code in( 'SMQ_90000101' 'SMQ_90001186') or aeptcd eq 10040985 then do;
        CQ02CD=2;/* Somnolence or fatigue*/
    END;
    if smq_code in( '20000009' '20000007' '20000008' '20000015' ) or  AESSINY eq "Y" then do;

        CQ01CD=1;/* Any condition triggering close liver observation*/
    END;

RUN;

%late_ads_processing(adsDat = &adsDomain.10)

%endprog()