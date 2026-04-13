/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = d_adds, print2file = N);
/*
 * Purpose          : Derivation of ADDS
 * Programming Spec :
 * Validation Level : 2 - Verification by Double Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gnrty (Ashu Pandey) / date: 03OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/d_adds.sas (gnrty (Ashu Pandey) / date: 03OCT2023)
 ******************************************************************************/
/* Changed by       : eokcw (Vijesh Shrivastava) / date: 27DEC2023
 * Reason           : Removed unwanted ICESREAS to avoide warning in log.
 ******************************************************************************/

%let adsDomain = ADDS;
%early_ads_processing(adsDat = &adsDomain.)

/**** Sorting all the required domains for analysis*/

    proc sort data = &adsDomain. out = ds; by studyid usubjid dsseq; run;
    proc sort data = ads.adsl out = adsl(keep = studyid usubjid trtsdt trtedt randdt ph1sdt ph1edt ph2sdt ph2edt scrnflfl saffl) nodupkey; by studyid usubjid ; run;
    proc sort data = ads.adcm out = adcm(keep = studyid usubjid usubjid cmtrt astdt aendt cmenrtpt confl prefl cmseq astdtf astdy
                    rename = (astdt = cmstdt aendt = cmendt astdy = cmstdy));
        by studyid usubjid cmseq cmtrt;
    run;

    proc sort data = sp.cm out = cm(keep = studyid usubjid cmseq cmstdtc cmendtc cmtrt cmdrecno cmdseq1 cmdseq2); by studyid usubjid cmseq cmtrt; run;
    proc sort data = sp.sv out = sv_records(keep = studyid usubjid visitnum visit svstdtc svstdy svendy svendtc svoccur) nodupkey dupout = bb ;
        by usubjid;
        where visitnum eq 30 and svoccur ne "N";
    run;

/**** Preparing ADDS dataset*************/
    data adds_prepare(drop = astdt rename = (up_astdt = ASTDT));
        merge ds(in=a) adsl(in=b) sv_records;
        by studyid usubjid;
        if a;

        /*Date calculation , taking last exposure date for subject from adsl.trtedt.
        Also checking for which subjects there is impact and what's the difference of days between DS and EX*/

        format up_astdt  date9.;
        if lowcase(epoch) = "treatment" and astdt ne trtedt and trtedt ne . and dsscat eq "" then do;
            up_astdt = trtedt;
            check = "Y";
        end;
        else do ;check = ""; up_astdt = astdt;end;

        %createCustomVars(adsDomain = adds, vars = aphase astdy)

        /*DY calculation*/

        if nmiss(randdt,up_astdt) = 0 and up_astdt lt randdt then astdy = up_astdt - randdt ;
        else if nmiss(randdt,up_astdt) = 0 and up_astdt ge randdt then astdy = (up_astdt - randdt) + 1;
        else astdy = .;

        /*Subjects who discontinued prior to day 82 , day will be calculated ADSL.TRTEDT - ADSL.RANDT + 1*/

        if scrnflfl eq "N" and astdy ne . and astdy le 82 and dscat = "DISPOSITION EVENT" and dsscat eq "" and lowcase(epoch) = "treatment"
           and dsterm ne "COMPLETED" then ice = "Y";  else ice = "";

        /*Phase Calculation*/

        if  lowcase(epoch) = "treatment" and dsscat eq "" then do;
        if nmiss(up_astdt, ph1sdt, ph1edt) = 0 and up_astdt ge ph1sdt and up_astdt le ph1edt then aphase="Week 1-12";
        else if nmiss(up_astdt, ph2sdt, ph2edt) = 0 and up_astdt ge ph2sdt and up_astdt le ph2edt then aphase="Week 13-26";
        end;
        else do;aphase = "";end;
    RUN;

    proc sort ;by studyid usubjid astdt;run;

    /**********ADCM and CM merging********************/

    data for_vms;
        merge adcm(in =a) cm;
        if a;
        by studyid usubjid cmseq cmtrt;
    run;

    proc sql;
        create table adsl_cm as
        select a.*,b.randdt, b.trtsdt, b.trtedt, b.ph1sdt, b.ph1edt, b.ph2sdt, b.ph2edt
               from for_vms as a left join adsl as b
               on a.usubjid =b.usubjid;
    QUIT;

    proc sort;by  studyid cmdrecno cmdseq1;run;

    /******************************************************************************
    *VMS medication flag;
    ******************************************************************************/
    *< adding prohibited medication list based on the excel shared by stats;
    data sdg;
        set whoddsdg.sdg_bdg_dtoi;
        if (dgcodel1 ="5" and dgcodel2 in ("2", "3"))
           or (dgcodel0= "1633" and dgcodel1 = "111" and dgcodel2 = "113");
           rename drecno = cmdrecno dseq1 =cmdseq1;
        keep drecno dseq1;
    run;

    proc sort data=sdg out = medication nodupkey;by cmdrecno cmdseq1;run;

    data vmsfl_;
        merge adsl_cm(in=a) medication(in=b);
        by cmdrecno cmdseq1;
        if a;
        if b then vmsfl = "Y"; else if cmdrecno = "005389" and cmdseq1 = "02" and cmdseq1 = "057" then vmsfl = "Y";
        else vmsfl = "";
        if vmsfl ne "";
      if cmstdt ne . and randdt ne . and cmstdt ge randdt then drug_vms = "Y"; else drug_vms = "";
    keep studyid usubjid cmstdt cmendt cmstdy vmsfl drug_vms ph: randdt cmenrtpt;
    if drug_vms ne "";
    run;

        proc sort ;by studyid usubjid drug_vms;run;

     data vmsfl;
         set vmsfl_;
         by studyid usubjid drug_vms;
         if last.drug_vms;
     run;

    data adds_prepare2;
        merge adds_prepare(in=a) vmsfl( drop = randdt ph: where = (drug_vms ne ""));
        by studyid usubjid;
        if a;
        _dsdecod = strip(strip(substr(dsdecod,1,1))||strip(lowcase(substr(dsdecod,2))));
        %createCustomVars(adsDomain = adds, vars = ice01fl icereas astdt ICESTWK);

        /***************ICE flags*************************/

        if drug_vms ne "" and ice ne "" then do ;
             ice01fl="Y";
              icereas=(_dsdecod);
             icesreas="For participants who initiate alternative VMS treatment";
        end;

        else if drug_vms eq "" and ice ne "" then do ;
             ice01fl="Y";
             icereas=(_dsdecod);
             icesreas="For participants who remained untreated/on background therapy";
        end;

        else if find(lowcase(dsterm),"covid") lt 1 and dsdecod not in ("COMPLETED" "ADVERSE EVENT" "LACK OF EFFICACY")
                and ice ne "" then do ;
            ice01fl="Y";
             icereas=(_dsdecod);
        end;

        else if  find(lowcase(dsterm),"covid")  and ice ne "" then do ;
            ice01fl="Y";
             icereas=(_dsdecod);
        end;

        else do; ice01fl = ""; icereas= "";icesreas="";end;

        /*****Calculating duration what week*****/

        if ice01fl ne "" then do;
          if randdt ne . and astdt ne . then cal_week = ceil((astdy)/7); else cal_week = .;
          if randdt ne . and astdt ne . then rem_days = mod(astdy,7); else rem_days = .;

          if rem_days eq 6  and cal_week ne 1 then week = cal_week+1;
          else if rem_days eq 0 then week = cal_week +1;
          else if rem_days ne . and rem_days le 6 then week = cal_week;

        end;


        if week ne . and week le 1 and astdy gt 1 then ICESTWK = 1;
        else if week ne . and week le 1 and astdy eq 1 then ICESTWK = 0;
        else if week ne . then ICESTWK=  week;
    run;

    /* Finalize and save in ADS lib */

    %late_ads_processing(adsDat = adds_prepare2)

    %endprog()
