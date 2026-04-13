/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = d_adlb);
/*
 * Purpose          : Derivation of ADLB
 * Programming Spec :
 * Validation Level : 2 - Verification by Double Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gkbkw (Ashutosh Kumar) / date: 01SEP2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/d_adlb.sas (gkbkw (Ashutosh Kumar) / date: 01SEP2023)
 ******************************************************************************/
/* Changed by       : gmrnq (Susie Zhang) / date: 07DEC2023
 * Reason           : Update AVISITN to Unscheduled for collected baseline safety data, if the date is after randomization date;
 ******************************************************************************/
/* Changed by       : eokcw (Vijesh Shrivastava) / date: 11DEC2023
 * Reason           : Removed CCRIT14 and CCRIT15 PARAMCD as its not needed.
 ******************************************************************************/



%let adsDomain = ADLB;
%early_ads_processing(adsDat = &adsDomain.)

%m_visit2avisit(indat=&adsDomain.,outdat=&adsDomain.,EOT=EOT);

*** Custom Derivation;
DATA &adsDomain.;
    set &adsDomain.;

    where LBTESTCD ne "LBALL";
      /* apply rule for aval values below LLOQ acc. to SAP using LBLLOQ variable:
       * "Values below the lower limit of quantification (LLOQ) will be set to LLOQ/2.
       *  Values above the upper limit of quantification (ULOQ) will be set to ULOQ."*/
    %createCustomVars(adsDomain = &adsDomain., vars = aval avalc ANRIND parcat2)
    aval = lbstresn;
    avalc= lbstresc;
    IF index(lbstresc,'<')>0 THEN do;
        aval= input(substr(lbstresc,2),best.)/2;
        avalc=strip(put(aval,best.));
    end;

    IF index(lbstresc,'>')>0 THEN do;
        aval= input(substr(lbstresc,2),best.);
        avalc=strip(put(aval,best.));
    end;

      /* keep parcat2 blank for  CLOSE LIVER OBSERVATION to remove p21 warning as per Team decision*/
    if not missing(lbscat) then  parcat2=lbscat;
    if parcat2 eq "CLOSE LIVER OBSERVATION" then parcat2="";

     *Analysis Reference Range Indicator derivation;
    IF NMISS(ANRLO,ANRHI, AVAL) = 0 AND ANRLO<=AVAL<= ANRHI THEN ANRIND = "NORMAL";
    ELSE IF NMISS(ANRLO,ANRHI, AVAL) = 0 AND AVAL < ANRLO THEN ANRIND = "LOW";
    ELSE IF NMISS(ANRLO,ANRHI, AVAL) = 0 AND AVAL > ANRHI THEN ANRIND = "HIGH";
    ELSE IF MISSING(ANRIND) AND NOT MISSING(LBNRIND) THEN ANRIND=LBNRIND;

    *Criterion Flag derivation;
    %createCustomVars(adsDomain = &adsDomain., vars =CRIT1 CRIT1FL CRIT2 CRIT2FL CRIT3 CRIT3FL CRIT4 CRIT4FL CRIT5 CRIT5FL CRIT6 CRIT6FL  CRIT7 CRIT7FL CRIT8 CRIT8FL
                    CRIT9 CRIT9FL CRIT10 CRIT10FL CRIT11 CRIT11FL CRIT12 CRIT12FL )
    IF paramcd IN ('SGOTSP' 'SGPTSP' 'BILITOSP' 'ALKPHOSP' 'PTINR') AND NOT missing(aval) AND NOT missing(anrhi) THEN DO;
        IF aval >=20*anrhi THEN DO;
            CRIT1 =">=20 x ULN" ;
            CRIT1FL="Y";
        END;

        IF aval >=10*anrhi  THEN DO;
            CRIT2 =">=10 x ULN";
            CRIT2FL="Y";
        END;

        IF aval >=8*anrhi  THEN DO;
            CRIT3 =">=8 x ULN" ;
            CRIT3FL="Y";
        END;

        IF aval >=5*anrhi  THEN DO;
            CRIT4 =">=5 x ULN" ;
            CRIT4FL="Y";
        END;

        IF aval >=3*anrhi  THEN DO;
            CRIT5 =">=3 x ULN" ;
            CRIT5FL="Y";
        END;

        IF aval >=2*anrhi  THEN DO;
            CRIT6 =">=2 x ULN" ;
            CRIT6FL="Y";
        END;

        IF aval >=1.5*anrhi  THEN DO;
            CRIT7 =">=1.5 x ULN" ;
            CRIT7FL="Y";
        END;

        IF aval >=1*anrhi  THEN DO;
           CRIT8 =">=1 x ULN" ;
           CRIT8FL="Y";
        END;

        IF aval <2*anrhi  THEN DO;
           CRIT9 ="<2 x ULN" ;
           CRIT9FL="Y";
        END;

        IF aval <3*anrhi  THEN DO;
           CRIT10 ="<3 x ULN" ;
           CRIT10FL="Y";
        END;

        if paramcd eq "PTINR" then do;
            IF aval >=2  THEN DO;
                CRIT12 =">=2" ;
                CRIT12FL="Y";
            END;

            IF aval >=1.5 THEN DO;
                CRIT11 =">=1.5" ;
                CRIT11FL="Y";
            END;
        END;

        END;

RUN;

*** Baseline flag;
%m_create_saf_baseline(data=adlb);

*** Crit 13-15;
Data &adsDomain.;
    set &adsDomain.;
    /*remapping screening to baseline in case baseline visit is not available and screening visit used as baseline*/
    if ablfl eq "Y" then do;
        if visitnum eq 0 then avisitn =5;
    END;

    %createCustomVars(adsDomain = &adsDomain., vars =CRIT13 CRIT13FL CRIT14 CRIT14FL  CRIT15 CRIT15FL )
    IF paramcd IN ('SGOTSP' 'SGPTSP' 'BILITOSP' 'ALKPHOSP') AND NOT missing(aval) AND NOT missing(BASE) THEN DO;
        IF aval >=2*base  THEN DO;
           CRIT13 =">=2 x BL" ;
           CRIT13FL="Y";
        END;
        IF aval >=3*base  THEN DO;
           CRIT14 =">=3 x BL" ;
           CRIT14FL="Y";
        END;
        IF aval >=5*base  THEN DO;
           CRIT15 =">=5 x BL" ;
           CRIT15FL="Y";
        END;
    END;
RUN;


*** Analysis flag;
%m_create_saf_anlflag(data=adlb);


*** Treatment emergent flag;
data &adsDomain.;
    merge &adsDomain.(in=inlb drop=trtsdt) ads.adsl(keep=usubjid randdt trtsdt trtedt);
    by usubjid;
    if inlb;

    %createCustomVars(adsDomain = &adsDomain., vars=TRTEMFL);

    format lbdt date9.;
    lbdt=input(scan(lbdtc,1,'T'),?? yymmdd10.);
    if trtedt ne . then trtedtw=trtedt+14;
    if trtedt ne . then do;
    if (anrind = 'HIGH' and base_anrind in("NORMAL" "LOW") and nmiss(lbdt, trtsdt, trtedtw)=0 and  trtsdt <= lbdt <= trtedtw)
       or (anrind = 'LOW' and base_anrind in("NORMAL" "HIGH") and nmiss(lbdt, trtsdt, trtedtw)=0 and  trtsdt <= lbdt <= trtedtw) then trtemfl='Y';
    end;
    else  if trtedt eq . then do;
       if (anrind = 'HIGH' and base_anrind in("NORMAL" "LOW") and nmiss(lbdt, trtsdt)=0 and  trtsdt <= lbdt )
        or (anrind = 'LOW' and base_anrind in("NORMAL" "HIGH") and nmiss(lbdt, trtsdt)=0 and  trtsdt <= lbdt ) then trtemfl='Y';
    END;
    drop base_anrind trtedtw;
run;


*** Compound crit flags;
PROC SORT DATA=&adsDomain. out=adlb_sort;
    by &subj_var adt paramcd;
    where ADY>1;
RUN;

*< CCRIT1 flag for >=3xULN of ALT or AST and >=1.5xULN of TBL;
%m_create_lb_critparam(
    indat           = adlb_sort
  , byvars          = usubjid adt
  , copyvars        = adsname studyid avisitn atm
  , crit1_selection = paramcd in ('SGOTSP', 'SGPTSP')
  , crit1_cond      = cmiss(aval, anrhi)=0 and aval >= 3 * anrhi
  , crit2_selection = paramcd in ('BILITOSP')
  , crit2_cond      = cmiss(aval, anrhi)=0 and aval >= 1.5 * anrhi
  , outdat          = adlb_crit1
 , paramcd_out     = CCRIT1
 )


*< CCRIT2 flag for >=3xULN of ALT or AST and >=2xULN of TBL;
%m_create_lb_critparam(
 indat           = adlb_sort
, byvars          = usubjid adt
, copyvars        = adsname studyid avisitn atm
, crit1_selection = paramcd in ('SGOTSP', 'SGPTSP')
, crit1_cond      = cmiss(aval, anrhi)=0 and aval >= 3 * anrhi
, crit2_selection = paramcd in ('BILITOSP')
, crit2_cond      = cmiss(aval, anrhi)=0 and aval >= 2 * anrhi
, outdat          = adlb_crit2
, paramcd_out     = CCRIT2
)


*< CCRIT3 flag for >=3xULN of ALT or AST followed by >=2xULN Total bilirubin (within 30 days afterwards);
data adlb_crit3_bili (keep= usubjid _adt SGOPTFL paramcd);
    set adlb_sort;

    if paramcd in ('SGPTSP' 'SGOTSP') then do;
    /*create all possible dates of >=3xULN for 'SGPTSP''SGOT' +30 days*/

    if cmiss(aval, anrhi)=0 and aval >= anrhi*3 then SGOPTFL = 1;
    do i = 0 to 30 by 1;
        _adt=adt+i;
        format _adt date9.;
        output;
    END;
    end;
RUN;

proc sort data=adlb_sort  out=adlb_sort_3 nodupkey;
    by &subj_var paramcd adt;
RUN;

proc sort data=adlb_crit3_bili(rename=(_adt=adt) ) nodupkey;
    by &subj_var paramcd adt;
RUN;

DATA adlb_crit3;
    merge adlb_sort_3(in=a) adlb_crit3_bili;
    by &subj_var paramcd adt;
    if a;
    retain BILIFL;
    if first.adt then call missing(BILIFL);

    if paramcd in('BILITOSP') then do;
        if cmiss(aval,anrhi) = 0  THEN DO;
            * > 3xULN of ALT/AST accompanied by > 2xULN of TBL;
            if  aval >= anrhi*2 then BILIFL = 1;
        end;
    END;
    if paramcd in('BILITOSP''SGPTSP' 'SGOTSP') then do;
        if last.adt then do;
            paramcd = "CCRIT3";
            paramtyp = "DERIVED";
            call missing(aval);
            if SGOPTFL eq 1 and BILIFL=1 then avalc="Y";
            else avalc='N';
            output;
        END;
    END;
    if paramcd="CCRIT3";
  keep &subj_var adt adsname studyid avisitn atm paramcd paramtyp aval avalc;
RUN;


*< CCRIT4 flag for >=3xULN of ALT or AST and >=1.5xULN INR;
%m_create_lb_critparam(
 indat           = adlb_sort
, byvars          = usubjid adt
, copyvars        = adsname studyid avisitn  atm
, crit1_selection = paramcd in ('SGOTSP', 'SGPTSP')
, crit1_cond      = cmiss(aval, anrhi)=0 and aval >= 3 * anrhi
, crit2_selection = paramcd in ('PTINR')
, crit2_cond      = cmiss(aval, anrhi)=0 and aval >= 1.5
, outdat          = adlb_crit4
, paramcd_out     = CCRIT4
)


*< CCRIT5 flag for >=5xULN of ALT or AST for more than 2 weeks;
proc sort data=adlb_sort out=_adlb_crit5;
    by &subj_var paramcd adt;
RUN;

data _adlb_crit5_lag;
    set _adlb_crit5;
    by &subj_var paramcd adt;

    if paramcd in('SGPTSP' 'SGOTSP') and lbdt >= randdt;

    *lag adt and avalca2n to see if two consecutive records both have >=5xULN ALT or AST;
    if not first.paramcd then do;
        lag_adt=lag(adt);
        format lag_adt date9.;
        lag_aval=lag(aval);
        lag_anrhi=lag(anrhi);
    end;
    if paramcd in('SGPTSP' 'SGOTSP') then do;
        *if current record and lagged record have >=5xULN ALT or AST then flag;
        if cmiss(aval, anrhi,lag_aval,lag_anrhi)=0 and aval >= anrhi*5 and lag_aval >= lag_anrhi*5 then altast5fl=1;
    end;
    *keep only flagged records;
    if altast5fl=1;
RUN;
proc sort data=_adlb_crit5_lag;
    by &subj_var paramcd lag_adt;
RUN;
data _adlb_crit5_diff(keep=usubjid paramcd adt avisitn orig_adt);
    set _adlb_crit5_lag;
    by &subj_var paramcd lag_adt;
    retain orig_adt;

    *keep first date to see if >2 weeks criteria met;
    if first.paramcd then orig_adt=lag_adt;
    format orig_adt date9.;

    *calculate difference between first date of >5xULN and current records date;
    if nmiss(adt,orig_adt) = 0 then diff=adt-orig_adt;

    *keep only records that meet >2 weeks criteria;
    if diff > 14;
RUN;

proc sort data=_adlb_crit5_diff;
    by usubjid  adt paramcd avisitn;
RUN;

proc sort data=adlb_sort;
    by usubjid  adt paramcd avisitn;
RUN;

*merge back in with all data;
data adlb_crit5;
    merge adlb_sort(in=a) _adlb_crit5_diff(in=diff);
    by usubjid  adt paramcd avisitn;
    where paramcd in('SGPTSP' 'SGOTSP');
    if a;
    if last.adt then do;
        paramcd = "CCRIT5";
        paramtyp = "DERIVED";
        call missing(aval);
        if DIFF then avalc="Y";
        else avalc='N';
        output;
    END;

    if paramcd="CCRIT5";
    keep &subj_var adt adsname studyid avisitn atm paramcd paramtyp aval avalc;
RUN;


*< CCRIT6 flag for >=8xULN of ALT or AST;
%m_create_lb_critparam(
 indat           = adlb_sort
, byvars          = usubjid adt
, copyvars        = adsname studyid avisitn atm
, crit1_selection = paramcd in ('SGOTSP', 'SGPTSP')
, crit1_cond      = cmiss(aval, anrhi)=0 and aval >= 8 * anrhi
, crit2_selection =
, crit2_cond      =
, outdat          = adlb_crit6
, paramcd_out     = CCRIT6
)

*< CCRIT7 flag for >=3xULN of ALT or AST with appearance of clinical signs/symptoms*;
data ce;
    set sp.ce;
    where CEOCCUR="Y";
RUN;

proc sort data=ce;
    by usubjid ceterm ;
RUN;

proc sort data=ce nodupkey;
    by usubjid ;
RUN;

proc sort data=adlb_sort out=_adlb_crit6;
    by usubjid adt;
     where paramcd in('SGPTSP' 'SGOTSP') ;
RUN;

data adlb_crit7;
    merge _adlb_crit6(in=lb) ce(in=ce keep=usubjid CEOCCUR CETERM );
    by usubjid ;
    if lb;

    if ce then AEREQ = "Y";
    retain SGOPTFL;
    if first.USUBJID then call missing(SGOPTFL);

    if paramcd in('SGPTSP' 'SGOTSP') then do;
        if cmiss(aval,anrhi) = 0  THEN DO;
            * > 3xULN of ALT/AST ;
            if  aval >= anrhi*3 then SGOPTFL = 1;
        end;
    end;

    if last.USUBJID then do;
        paramcd = "CCRIT7";
        paramtyp = "DERIVED";
        call missing(aval);
        if SGOPTFL eq 1 and AEREQ eq "Y" then avalc="Y";
        else avalc='N';
        output;
    END;
    if paramcd="CCRIT7";
    keep &subj_var adt adsname studyid avisitn atm paramcd paramtyp aval avalc AEREQ;
RUN;


*< CCRIT8 flag for >=2xULN of ALP and >=2xULN Total bilirubin;
%m_create_lb_critparam(
 indat           = adlb_sort
, byvars          = usubjid adt
, copyvars        = adsname studyid avisitn atm
, crit1_selection = paramcd in ('ALKPHOSP')
, crit1_cond      = cmiss(aval, anrhi)=0 and aval >= 2 * anrhi
, crit2_selection = paramcd in ('BILITOSP')
, crit2_cond      = cmiss(aval, anrhi)=0 and aval >= 2 * anrhi
, outdat          = adlb_crit8
, paramcd_out     = CCRIT8
)


*< CCRIT9 flag for >=3xBL of ALT or AST and >=2xBL Total bilirubin;
%m_create_lb_critparam(
 indat           = adlb_sort
, byvars          = usubjid adt
, copyvars        = adsname studyid avisitn atm
, crit1_selection = paramcd in ('SGOTSP', 'SGPTSP')
, crit1_cond      = cmiss(aval, base) =0 and aval >= 3 * base
, crit2_selection = paramcd in ('BILITOSP')
, crit2_cond      = cmiss(aval, base) =0 and aval >= 2 * base
, outdat          = adlb_crit9
, paramcd_out     = CCRIT9
)


*< CCRIT10 flag for >=3xBL of ALT or AST;
%m_create_lb_critparam(
 indat           = adlb_sort
, byvars          = usubjid adt
, copyvars        = adsname studyid avisitn atm
, crit1_selection = paramcd in ('SGOTSP', 'SGPTSP')
, crit1_cond      = cmiss(aval, base) =0 and aval >= 3 * base
, crit2_selection =
, crit2_cond      =
, outdat          = adlb_crit10
, paramcd_out     = CCRIT10
)


*< CCRIT11 flag for >=5xBL of ALT or AST;
%m_create_lb_critparam(
 indat           = adlb_sort
, byvars          = usubjid adt
, copyvars        = adsname studyid avisitn atm
, crit1_selection = paramcd in ('SGOTSP', 'SGPTSP')
, crit1_cond      = cmiss(aval, base) =0 and aval >= 5 * base
, crit2_selection =
, crit2_cond      =
, outdat          = adlb_crit11
, paramcd_out     = CCRIT11
)


*< CCRIT12 flag for >=2xBL of ALT or AST and >=2xBL Total bilirubin;
%m_create_lb_critparam(
 indat           = adlb_sort
, byvars          = usubjid adt
, copyvars        = adsname studyid avisitn atm
, crit1_selection = paramcd in ('SGOTSP', 'SGPTSP')
, crit1_cond      = cmiss(aval, base) =0 and aval >= 2 * base
, crit2_selection = paramcd in ('BILITOSP')
, crit2_cond      = cmiss(aval, base) =0 and aval >= 2 * base
, outdat          = adlb_crit12
, paramcd_out     = CCRIT12
)


*< CCRIT13 flag for >=2xBL of ALP and >=2xBL Total bilirubin;
%m_create_lb_critparam(
 indat           = adlb_sort
, byvars          = usubjid adt
, copyvars        = adsname studyid avisitn atm
, crit1_selection = paramcd in ('ALKPHOSP')
, crit1_cond      = cmiss(aval, base) =0 and aval >= 2 * base
, crit2_selection = paramcd in ('BILITOSP')
, crit2_cond      = cmiss(aval, base) =0 and aval >= 2 * base
, outdat          = adlb_crit13
, paramcd_out     = CCRIT13
)


*** Combine data;
data _adlb_crit;
   set  adlb_crit1-adlb_crit13 ;
RUN;

proc sort data=_adlb_crit;
    by usubjid paramcd;
RUN;

data _adlb_crit1;
    set _adlb_crit;
    by usubjid paramcd;
    retain _avalc;
    if first.paramcd then call missing(_avalc);

    if avalc eq "Y" then _avalc=1;
    if last.paramcd then do;
        if _avalc=1 then avalc="Y";/*if any post baseline visit has yes then Overall Compound criteria will be flag as Yes*/
        avisitn=600020;
        ADT=.;
        ATM=.;
        anl01fl="Y";
        output;
    END;
   drop _avalc;
RUN;

proc sort data =&adsDomain.;
    by usubjid adt;
RUN;

data &adsDomain.;
    merge &adsDomain. ce(in=ce keep=usubjid CEOCCUR CETERM );
    by usubjid ;
    if PARAMCD  in ("SGPTSP" "SGOTSP") and CRIT5FL eq "Y"  then do;
        %createCustomVars(adsDomain = &adsDomain., vars =CRIT16 CRIT16FL )
        if CE then do;
            CRIT16FL = "Y";
            CRIT16="Pre-specified CE occurred";
        end;
    end;
RUN;

data adlb_final;
    set &adsDomain. _adlb_crit1;
    /* Populating ANL01FL  for Treatment emergent LBTEST as per Stats confirmation 24 July 2023*/
    if TRTEMFL eq "Y" then ANL01FL="Y";
    /*Unscheduled measurements used where categorizations compared to ULN are done and being analysed. 18 August 2023 */
    if ady >1 then do;
        if not missing(CRIT1) or not missing(CRIT2) or not missing(CRIT3) or not missing(CRIT4) or not missing(CRIT5) or
       not missing(CRIT6) or not missing(CRIT7) or not missing(CRIT8) or not missing(CRIT9) or not missing(CRIT10) or not missing(CRIT11) or not missing(CRIT12)
       or not missing(CRIT13) or not missing(CRIT14) or not missing(CRIT15) or not missing(CRIT16)then ANL01FL="Y" ;
    end;

    /* Populating PARAMN  for Compound criteria   PARAMCD */
    select(upcase(PARAMCD));
        when('CCRIT1')   PARAMN =95001000;
        when('CCRIT2')   PARAMN =95002000;
        when('CCRIT3')   PARAMN =95003000;
        when('CCRIT4')   PARAMN =95004000;
        when('CCRIT5')   PARAMN =95005000;
        when('CCRIT6')   PARAMN =95006000;
        when('CCRIT7')   PARAMN =95007000;
        when('CCRIT8')   PARAMN =95008000;
        when('CCRIT9')   PARAMN =95009000;
        when('CCRIT10')  PARAMN =95010000;
        when('CCRIT11')  PARAMN =95011000;
        when('CCRIT12')  PARAMN =95012000;
        when('CCRIT13')  PARAMN =95013000;
        otherwise   PARAMN =PARAMN;
    end;
RUN;

*** Update AVISITN to Unscheduled for collected baseline safety data, if the date is after randomization date;
data adlb_final;
    set adlb_final;
    if avisitn=5 and ady>1 then avisitn=900000;
RUN;

*** Finalize data;
%late_ads_processing(adsDat = adlb_final)

%endprog()