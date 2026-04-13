/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = d_adcm);
/*
 * Purpose          : Derivation of ADCM
 * Programming Spec : 21652 Statistical analysis plan_v1.0.docx
 * Validation Level : 2 - Verification by Double programming
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gmrnq (Susie Zhang) / date: 27OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/d_adcm.sas (gmrnq (Susie Zhang) / date: 27OCT2023)
 ******************************************************************************/


%let adsDomain = ADCM;
%early_ads_processing(adsDat = adcm)

Data adsl;
    set ADS.adsl;
    keep usubjid trtsdt trtedt randdt saffl ph1: ph2: trt01:;
RUN;

proc sort data=adsl;
    by usubjid;
run;

proc sort data=adcm;
    by usubjid cmseq;
run;

data adcm;
    merge adcm (in=_in_adcm)
          adsl ;
    by usubjid;
    if _in_adcm;
run;

Proc sort data=adcm;
    by usubjid cmseq;
RUN;


*< Impute start date as specified in SAP;
%m_impute_astdt(
         indat    = adcm
       , sp_stdtc = cmstdtc
       , outdat   = adcm3
)


*< Derive study day and flags for prior med, con med and posttrt med;
data adcm4;
    set adcm3;

    * Derive relative study days ;
    %createCustomVars(adsDomain=adcm, vars=astdy aendy);
    if nmiss(astdt, randdt) = 0 then do;
        if randdt <= astdt then astdy = astdt - randdt + 1;
                           else astdy = astdt - randdt;
    end;
    if nmiss(aendt, randdt) = 0 then do;
        if randdt <= aendt then aendy = aendt - randdt + 1;
                           else aendy = aendt - randdt;
    end;

    * Derive Conmeds Timing Variables;
    if not missing(trtsdt) and CMCAT NE 'MEDICATION OF INTEREST' then do;

        ** Prior Medication;
        %createCustomVars(adsDomain=adcm, vars=prefl);
        if missing(astdt) or (.z < astdt < trtsdt) then prefl = "Y";

        ** Concomitant Medication;
        * Concomitant medication: Medication taken during treatment phase;
        * i.e. between first  and last study drug intake (regardless of when it started or ended).;
        %createCustomVars(adsDomain=adcm, vars=confl);
        if not missing(trtedt) then do;
            if    (trtsdt <= astdt <= trtedt)
               or (astdt < trtsdt and (trtsdt <= aendt or missing(aendt))) /* includes missing astdt */
               then confl = 'Y';
        end;
        else do; /* Only for development, trtedt will be present after data base lock */
            if    (trtsdt <= astdt)
               or (astdt < trtsdt and (trtsdt <= aendt or missing(aendt))) /* includes missing astdt */
               then confl = 'Y';
        end;

         ** Medication started after study treatment;
         %createCustomVars(adsDomain=adcm, vars=fupfl);
         if astdt > trtedt > .z then fupfl = "Y";
    end;
run;


*< VMS treatment flag;
* Select alternative VMS treatment by drug grouping;
** As per Table 2-1 Final list of alternative VMS treatment by drug grouping;
data vms_group(keep=drecno dseq1 dseq2 dgcodel: dgname:);
    set whoddsdg.sdg_bdg_dtoi;
    if    (                      dgcodel1 =   "5"  and dgcodel2 =   "2")      /* Oestrogens */
       or (                      dgcodel1 =   "5"  and dgcodel2 =   "3")      /* Progestogens */
       or (dgcodel0 = "1633" and dgcodel1 = "111"  and dgcodel2 = "113")      /* Selective serotonin reuptake inhibitors (SSRI) */
       ;
RUN;

* Sort and remove duplicates, we only need recno and seq1 for identifying VMS treatment;
proc sort data=vms_group(rename=(drecno=cmdrecno dseq1=cmdseq1)) out=vms_group2(keep=cmdrecno cmdseq1) nodupkey;
    by cmdrecno cmdseq1;
RUN;

proc sort data=adcm4;
    by cmdrecno cmdseq1 cmdseq2;
run;

* Merge with ADCM and flag VMS for the records in VMS drug group list;
data adcm4_vms1;
    merge adcm4      (in=_in_cm)
          vms_group2 (in=_in_vms);
    by cmdrecno cmdseq1;
    if _in_cm;

    %createCustomVars(adsDomain=adcm, vars=VMSFL);
    if CMCAT NE 'MEDICATION OF INTEREST' and _in_vms then vmsfl = "Y";
run;

* Select alternative VMS treatment by drug names;
** As per Table 2-2 Final list of alternative VMS treatment by drug names;
data vms_drug(keep=cmdrecno cmdseq1 cmdseq2);
    set whodd.whodrug;
    if  drecno="005389" and dseqno1="02" and dseqno2="057" ;         /* Oxybutin */
    rename drecno=cmdrecno dseqno1=cmdseq1 dseqno2=cmdseq2;
RUN;

proc sort data=vms_drug;
    by cmdrecno cmdseq1 cmdseq2;
RUN;

proc sort data=adcm4_vms1;
    by cmdrecno cmdseq1 cmdseq2;
RUN;

* Merge with ADCM and flag VMS for the records in VMS drug list;
data adcm4_vms2;
    merge adcm4_vms1 (in=_in_cm)
          vms_drug   (in=_in_vms);
    by cmdrecno cmdseq1 cmdseq2;
    if _in_cm;

    %createCustomVars(adsDomain=adcm, vars=VMSFL);
    if CMCAT NE 'MEDICATION OF INTEREST' and _in_vms then vmsfl = "Y";
run;


*< Prohibited medication flag;
* Select prohibited concomitant medication by drug names;
** As per Table 2-4 Final list of prohibited concomitant medication by drug;
data add_prohib_med;
    attrib cmdrecno length = $6 label = 'WHODrug Drug Record Number' ;
    attrib cmdseq1  length = $2 label = 'WHODrug Sequence Number 1' ;
    attrib cmdseq2  length = $3 label = 'WHODrug Sequence Number 2' ;

    cmdrecno="000537"; cmdseq1="01"; cmdseq2="011"; _ck_dur='Y'; output; /* ARMOUR THYROID         */
    cmdrecno="000537"; cmdseq1="01"; cmdseq2="027"; _ck_dur='Y'; output; /* NATURE THROID          */
    cmdrecno="000680"; cmdseq1="01"; cmdseq2="001"; _ck_dur='Y'; output; /* LEVOTHYROXINE          */
    cmdrecno="000680"; cmdseq1="01"; cmdseq2="006"; _ck_dur='Y'; output; /* L-THYROXINE            */
    cmdrecno="000680"; cmdseq1="01"; cmdseq2="014"; _ck_dur='Y'; output; /* L-THYROXIN             */
    cmdrecno="000680"; cmdseq1="02"; cmdseq2="002"; _ck_dur='Y'; output; /* LEVAXIN                */
    cmdrecno="000680"; cmdseq1="02"; cmdseq2="005"; _ck_dur='Y'; output; /* SYNTHROID              */
    cmdrecno="000680"; cmdseq1="02"; cmdseq2="007"; _ck_dur='Y'; output; /* EUTHYROX               */
    cmdrecno="000680"; cmdseq1="02"; cmdseq2="014"; _ck_dur='Y'; output; /* THYROXIN               */
    cmdrecno="000680"; cmdseq1="02"; cmdseq2="020"; _ck_dur='Y'; output; /* LEVOTHYROXINE [LEVOTHYROXINE SODIUM] */
    cmdrecno="000680"; cmdseq1="02"; cmdseq2="028"; _ck_dur='Y'; output; /* THYREX                 */
    cmdrecno="000680"; cmdseq1="02"; cmdseq2="029"; _ck_dur='Y'; output; /* THYROHORMONE           */
    cmdrecno="000680"; cmdseq1="02"; cmdseq2="031"; _ck_dur='Y'; output; /* T4                     */
    cmdrecno="000680"; cmdseq1="02"; cmdseq2="046"; _ck_dur='Y'; output; /* LETROX                 */
    cmdrecno="000680"; cmdseq1="02"; cmdseq2="052"; _ck_dur='Y'; output; /* UNITHROID              */
    cmdrecno="000680"; cmdseq1="02"; cmdseq2="054"; _ck_dur='Y'; output; /* LEVOTIROXINA [LEVOTHYROXINE SODIUM]  */
    cmdrecno="000680"; cmdseq1="02"; cmdseq2="058"; _ck_dur='Y'; output; /* L-THYROXIN HENNING     */
    cmdrecno="000680"; cmdseq1="02"; cmdseq2="062"; _ck_dur='Y'; output; /* TIROXIN [LEVOTHYROXINE SODIUM]       */
    cmdrecno="000680"; cmdseq1="02"; cmdseq2="070"; _ck_dur='Y'; output; /* L THYROXIN             */
    cmdrecno="000680"; cmdseq1="02"; cmdseq2="074"; _ck_dur='Y'; output; /* EUTIROX                */
    cmdrecno="000680"; cmdseq1="02"; cmdseq2="081"; _ck_dur='Y'; output; /* LEVOTHYROXIN           */
    cmdrecno="000680"; cmdseq1="02"; cmdseq2="087"; _ck_dur='Y'; output; /* TIROSINT               */
    cmdrecno="000680"; cmdseq1="02"; cmdseq2="138"; _ck_dur='Y'; output; /* EUTHYROX N             */
    cmdrecno="000680"; cmdseq1="02"; cmdseq2="145"; _ck_dur='Y'; output; /* LEVOTIROXIN            */
    cmdrecno="000680"; cmdseq1="02"; cmdseq2="163"; _ck_dur='Y'; output; /* L THYROX               */
    cmdrecno="000680"; cmdseq1="02"; cmdseq2="219"; _ck_dur='Y'; output; /* TIROSINT SOL           */
    cmdrecno="001433"; cmdseq1="01"; cmdseq2="001"; _ck_dur='Y'; output; /* LIOTHYRONINE           */
    cmdrecno="001433"; cmdseq1="02"; cmdseq2="020"; _ck_dur='Y'; output; /* LIOTHYRONIN            */

    cmdrecno="001711"; cmdseq1="01"; cmdseq2="001"; _ck_dur=''; add_dur=4*7; output; /* CLONIDINE              */
    cmdrecno="001711"; cmdseq1="02"; cmdseq2="001"; _ck_dur=''; add_dur=4*7; output; /* CLONIDINE HYDROCHLORIDE*/
    cmdrecno="001711"; cmdseq1="02"; cmdseq2="002"; _ck_dur=''; add_dur=4*7; output; /* DIXARIT                */
    cmdrecno="001711"; cmdseq1="02"; cmdseq2="048"; _ck_dur=''; add_dur=4*7; output; /* CLONIDINE HCL          */
    cmdrecno="002377"; cmdseq1="01"; cmdseq2="001"; _ck_dur=''; add_dur=4*7; output; /* CANNABIS SATIVA        */
    cmdrecno="002377"; cmdseq1="01"; cmdseq2="002"; _ck_dur=''; add_dur=4*7; output; /* MARIJUANA              */
    cmdrecno="002377"; cmdseq1="08"; cmdseq2="003"; _ck_dur=''; add_dur=4*7; output; /* CBD OEL                */
    cmdrecno="005389"; cmdseq1="02"; cmdseq2="057"; _ck_dur=''; add_dur=4*7; output; /* OXYBUTIN               */
    cmdrecno="005389"; cmdseq1="02"; cmdseq2="126"; _ck_dur=''; add_dur=4*7; output; /* DRIPTAN                */
    cmdrecno="010030"; cmdseq1="01"; cmdseq2="001"; _ck_dur=''; add_dur=4*7; output; /* GABAPENTIN             */
    cmdrecno="010030"; cmdseq1="01"; cmdseq2="002"; _ck_dur=''; add_dur=4*7; output; /* NEURONTIN [GABAPENTIN] */
    cmdrecno="010030"; cmdseq1="01"; cmdseq2="024"; _ck_dur=''; add_dur=4*7; output; /* GABRION                */
    cmdrecno="010030"; cmdseq1="01"; cmdseq2="045"; _ck_dur=''; add_dur=4*7; output; /* GABAPENTINE            */
    cmdrecno="010030"; cmdseq1="01"; cmdseq2="226"; _ck_dur=''; add_dur=4*7; output; /* GABA [GABAPENTIN]      */
    cmdrecno="016141"; cmdseq1="01"; cmdseq2="001"; _ck_dur=''; add_dur=4*7; output; /* PREGABALIN             */
    cmdrecno="016141"; cmdseq1="01"; cmdseq2="002"; _ck_dur=''; add_dur=4*7; output; /* LYRICA                 */
    cmdrecno="016141"; cmdseq1="01"; cmdseq2="249"; _ck_dur=''; add_dur=4*7; output; /* PRAGIOLA               */
    cmdrecno="016141"; cmdseq1="01"; cmdseq2="314"; _ck_dur=''; add_dur=4*7; output; /* EGZYSTA                */
    cmdrecno="016141"; cmdseq1="01"; cmdseq2="722"; _ck_dur=''; add_dur=4*7; output; /* PREATO                 */
    cmdrecno="079492"; cmdseq1="01"; cmdseq2="001"; _ck_dur=''; add_dur=4*7; output; /* CANNABIDIOL            */

    cmdrecno="109689"; cmdseq1="02"; cmdseq2="006"; _ck_dur='Y'; output; /* THYRONAJOD             */
    cmdrecno="109689"; cmdseq1="03"; cmdseq2="001"; _ck_dur='Y'; output; /* LEVOTHYROXINE;POTASSIUM IODIDE       */
    cmdrecno="131345"; cmdseq1="01"; cmdseq2="008"; _ck_dur='Y'; output; /* LEVOTHYROXINE AND LIOTHYRONINE [LEVOTHYROXINE;LIOTHYRONINE] */
    cmdrecno="131345"; cmdseq1="03"; cmdseq2="007"; _ck_dur='Y'; output; /* NOVOTHYRAL             */
run;

proc sort data=add_prohib_med;
    by cmdrecno cmdseq1 cmdseq2;
run;

proc sort data=adcm4_vms2;
    by cmdrecno cmdseq1 cmdseq2;
run;

* Merge with ADCM and flag prohibited meds impacting efficacy ;
data adcm5;
    merge adcm4_vms2     (in=_in_cm)
          add_prohib_med (in=_in_add_prohib_med);
    by cmdrecno cmdseq1 cmdseq2;
    if _in_cm;

    %createCustomVars(adsDomain=adcm, vars=PROHIBFL);
    if CMCAT NE 'MEDICATION OF INTEREST' and _in_add_prohib_med then do;
        if _ck_dur ='Y' then do;
            * These drug to be considered as prohibited and intercurrent event only up to day 82;
            if 0<astdy<=82 then prohibfl = "Y";
            else prohibfl = "";
        END;
        else prohibfl = "Y";
    END;
run;


* Select prohibited concomitant medication by drug grouping;
** As per Table 2-3 Final list of prohibited concomitant medication by drug grouping ;
data whodd (keep=drecno dseq1 dseq2 dgcodel: dgname:);
    set whoddsdg.sdg_bdg_dtoi;
    if    (                      dgcodel1 = "108"  and dgcodel2 = "109")      /* GnRH agonists */
       or (                      dgcodel1 = "108"  and dgcodel2 = "110")      /* GnRH antagonists */
       or (                      dgcodel1 =   "5"  and dgcodel2 =   "2")      /* Oestrogens */
       or (                      dgcodel1 =   "5"  and dgcodel2 =   "3")      /* Progestogens */
       or (                      dgcodel1 = "772"  and dgcodel2 = "738")      /* Endocrine antineoplastic therapy */
       or (dgcodel0 = "1633" and dgcodel1 = "111"  and dgcodel2 = "114")      /* Monoamine oxidase (MAO) inhibitors, non-selective */
       or (dgcodel0 = "1633" and dgcodel1 = "111"  and dgcodel2 = "115")      /* Monoamine oxidase A (MAO-A) inhibitors */
       or (dgcodel0 = "1633" and dgcodel1 = "111"  and dgcodel2 = "112")      /* Non-selective monoamine reuptake inhibitors */
       or (dgcodel0 = "1633" and dgcodel1 = "111"  and dgcodel2 = "113")      /* Selective serotonin reuptake inhibitors (SSRI) */
       or (dgcodel0 =   "45" and dgcodel1 = "240"  and dgcodel2 = "225")      /* Moderate CYP3A inducers */
       or (dgcodel0 =   "45" and dgcodel1 = "240"  and dgcodel2 = "265")      /* Strong CYP3A inducers */
       or (dgcodel0 = "1633" and dgcodel1 = "111"  and dgcodel2 = "1830")     /* Antidepressant Serotonin Norepinephrine Reuptake Inhibitors (SNRI) */
       ;
RUN;

* Sort and remove duplicates, we only need recno and seq1 for identifying prohib. med;
proc sort data=whodd (rename=(drecno=cmdrecno dseq1=cmdseq1)) nodupkey;
    by cmdrecno cmdseq1;
RUN;

* Merge with ADCM and flag prohibited meds impacting efficacy;
data adcm6;
    merge adcm5 (in=_in_cm)
          whodd (in=_in_whodd);
    by cmdrecno cmdseq1;
    if _in_cm;
    if CMCAT NE 'MEDICATION OF INTEREST' and _in_whodd then do;
        if dgcodel0 =   "45" and dgcodel1 = "240"  and dgcodel2 = "225" and cmroute in ("AURICULAR (OTIC)", "OPHTHALMIC") then prohibfl = "";
        else prohibfl = "Y";
    end;
run;


*< Derive ICE variables;
data adcm7;
    set adcm6;

    %createCustomVars(adsDomain=adcm, vars=ICE01FL ICEENWK ICESTWK);
    attrib add_dur label="Additional duration for impacting efficacy after CM end";

    if prohibfl = "Y" then do;
        * Only flag ICE until day 82;
        * Events at day 83 and 84 are not flagged because these events are considered to have started in week 13 (as per SAP);
        * and we are displaying only events up to week 12 in tables ;
        if (not missing(randdt) and 1 <= astdy <= 82) then do;
            ice01fl="Y";

            * Derive add_dur as the "additional duration of impacting the efficacy after the last dose" from SAP table in section 6.5.3 ;
            if dgcodel1="108" and dgcodel2="109" then add_dur = 12*7; /* GnRH agonists */
            if dgcodel1="108" and dgcodel2="110" then add_dur = 12*7; /* GnRH antagonists */
            if dgcodel1=  "5" and dgcodel2 in ("2", "3") then do; /* Oestrogens, Progestogens */
                if      CMROUTE in ("VAGINAL", "INTRAVAGINAL", "CUTANEOUS", "NASAL", "TRANSDERMAL") then add_dur =  4*7;
                else if CMROUTE in ("ORAL", "SUBLINGUAL", "INTRAUTERINE")                           then add_dur =  8*7;
                else if CMROUTE in ("SUBCUTANEOUS", "INTRADERMAL")                                  then add_dur = 12*7;
                else do;
                    put "WARNING: new route of administration, to be discussed how long effective duration is " usubjid= CMSEQ= CMDECOD= CMROUTE= astdy= aendy= ;
                    tbd_fn = 1; /* Flag special cases that are not specified in SAP and need to be discussed with team */
                end;
             end;
             if                     dgcodel1="772" and dgcodel2="738"  then add_dur = 12*7; /* Endocrine antineoplastic therapy */
             if dgcodel0="1633" and dgcodel1="111" and dgcodel2="114"  then add_dur =  4*7; /* Monoamine oxidase (MAO) inhibitors, non-selective */
             if dgcodel0="1633" and dgcodel1="111" and dgcodel2="115"  then add_dur =  4*7; /* Monoamine oxidase A (MAO-A) inhibitors */
             if dgcodel0="1633" and dgcodel1="111" and dgcodel2="112"  then add_dur =  4*7; /* Non-selective monoamine reuptake inhibitors */
             if dgcodel0="1633" and dgcodel1="111" and dgcodel2="113"  then add_dur =  4*7; /* Selective serotonin reuptake inhibitors (SSRI) */
             if dgcodel0=  "45" and dgcodel1="240" and dgcodel2="225"  then do;             /* Moderate CYP3A inducers */
                 if cmroute not in ("AURICULAR (OTIC)", "OPHTHALMIC") then add_dur =  4*7;
             end;
             if dgcodel0=  "45" and dgcodel1="240" and dgcodel2="265"  then add_dur =  4*7; /* Strong CYP3A inducers */
             if dgcodel0="1633" and dgcodel1="111" and dgcodel2="1830" then add_dur =  4*7; /* Antidepressant Serotonin Norepinephrine Reuptake Inhibitors (SNRI) */

            * Add duration of impact for prohibited concomitant medication that is newly started or dose modified during the first 12 weeks;
            if _ck_dur='Y' then add_dur =  12*7;

            * Derive ICE start and end week as defined in SAP section 5.1.2 ;
            * ICE start week ;
            if      missing(astdy) then call missing(icestwk);
            else if     astdy  = 1 then icestwk = 0; /* Day 1 events should be counted for Week 0. As per discussion with stats */
            else if 1 < astdy <= 6 then icestwk = 1; /* Week 1 consists of days 2-8; day 6 is the 5th day of this week */
            else                        icestwk = ceil((astdy+2) / 7);
            * ICE end week ;
            if      nmiss(aendy, add_dur) > 0 then call missing(iceenwk);
            else if (aendy + add_dur) <= 9      then iceenwk = 1 ;
            else                                     iceenwk = ceil(((aendy + add_dur)-2) / 7);
            end;
    end;
RUN;


*< Finalize and save in ADS lib;
%late_ads_processing(
    adsDat   = adcm7
  , finalise = Y /* Save in ADS */
)


%endprog()