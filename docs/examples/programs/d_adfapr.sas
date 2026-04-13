/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(
       name     = d_adfapr
     , log2file = Y
   );
/*
 * Purpose          : Derivation of ADVS
 * Programming Spec :
 * Validation Level : 2 - Verification by Double Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gnrty (Ashu Pandey) / date: 17NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/d_adfapr.sas (gkbkw (Ashutosh Kumar) / date: 07SEP2023)
 ******************************************************************************/
/* Changed by       : gmrnq (Susie Zhang) / date: 27DEC2023
 * Reason           : Remove basetypn that is no needed
 ******************************************************************************/

%let adsDomain = ADFAPR;
%early_ads_processing(
    adsDat = &adsDomain.
  , adsLib = work
)

%m_visit2avisit(indat=&adsDomain.,outdat=&adsDomain.,EOT=EOT);

DATA &adsDomain.;
  set &adsDomain.;

  %createCustomVars(adsDomain = adfapr, vars = parcat1 parcat2 paramcd avalc) ;
  avalc=FASTRESC;
  parcat1=FACAT;
  parcat2=FASCAT;
  if fatestcd eq "PROCFIND" and facat eq "LIVER EVENT" then paramcd = "LIVERFIN"; else paramcd = paramcd;
RUN;


** baseline - code adapted from %m_create_saf_baseline;

proc sort data=ads.adsl out=adsl (keep=usubjid trtsdt randdt);
    by usubjid;
RUN;

proc sort data=adfapr;
    by usubjid;
RUN;

data adfapr;
    merge adfapr(in=a) adsl ;
    by usubjid ;
    if a ;
RUN;
/*Baseline flag only need to derived for paramcd eq "ENDTHCK"*/
proc sort data=adfapr out=baseline;
    by usubjid paramcd   avisitn adt ;
    where aval ne .  and adt ne . and randdt ne . and (adt le randdt) and avisitn ne 900000 and paramcd eq "ENDTHCK";
run;

data baseline;
    set baseline;
    by usubjid paramcd   avisitn adt ;
    if last.adt then blfl='Y';

    if blfl="Y" then do;
        base=aval;
        base_adt=adt;
        format base_adt date9.;
    end;
RUN;

proc sort data=baseline;
    by usubjid paramcd falat avisitn adt faseq;
RUN;

proc sort data=adfapr;
    by usubjid paramcd falat avisitn adt faseq;
RUN;

data adfapr_base;
    merge adfapr baseline(in=b where = (blfl='Y') keep= usubjid paramcd falat avisitn adt blfl faseq);
    by usubjid paramcd falat avisitn adt faseq;
    if b then do;
        %createCustomVars(adsDomain=adfapr, vars=ABLFL);
        ablfl='Y';
    end;
    drop blfl;
run;

* merging again to have base values populated for each records;

proc sort data=adfapr_base;
    by usubjid paramcd falat avisitn;
RUN;

data adfapr_all;
    merge adfapr_base baseline(where = (blfl='Y') keep= usubjid paramcd falat base base_adt blfl);
    by usubjid paramcd falat ;
    IF adt >= base_adt AND NOT MISSING(aval) AND NOT MISSING(base) THEN chg = aval - base;
RUN;


** analysis flag - code adapted from %m_create_saf_anlflag;

DATA master;
    set adfapr_all;

    _pretrt = (fastrf in ('BEFORE', ''));
    IF LENGTH(Fadtc) = 10 THEN DO;
        _dtm = INPUT(CATS(fadtc, 'T00:00:00'), ?? E8601DT19.);
    END;
    ELSE DO;
        _dtm = INPUT(fadtc, ?? E8601DT19.);
    END;
    _valid = (NOT MISSING(_dtm) AND NOT MISSING(avisitn) AND (NOT MISSING(aval)  or avalc ne "") and avisitn ne 900000 );
RUN;

PROC SORT DATA=master;
    BY usubjid paramcd  falat FAEVALID _valid  avisitn _dtm  faseq;
RUN;

/******************************************************************************
 * NOTE: Earliest non-missing in-treatment assessment per visit is flagged
 *       Pre-treatment assessment flagged as baseline is also flagged
 ******************************************************************************/

DATA adfapr;
    SET master;
    BY usubjid paramcd  falat FAEVALID _valid  avisitn _dtm  faseq;
    %createCustomVars(adsDomain=adfapr, vars=anl01fl);

    IF _valid    OR ablfl = 'Y' THEN anl01fl = 'Y';

        /*We are analysis unscheduled visit for ENDOMETRIAL BIOPSY with Adequate Endometrial Tissue  */
    if FAOBJ eq "ENDOMETRIAL BIOPSY" and avisitn eq 900000 then anl01fl ="Y";

RUN;

*******************************************************************************;
*< Data checks: START ;
*******************************************************************************;

*< Duplicates in biopsy data - investigating different scenarios ;


/* Checking duplicate part I : biopsies per study, subject, parameter category,  biopsy date, visit, reader, additional read and parameter */

/* Parameters with possibility to tick only one result per sample */
DATA chk_dup_one;
    SET  &adsDomain(WHERE=(paramcd IN ('ADQENDO1' 'BENIGEN1' 'BENIGEN2' 'ENDHYP4Y' 'ENDOHYP4' 'ENDHYP3Y' 'ENDOHYP3'
                                           'MALNEOP1' 'MALNEOP2' 'ENDOPOL1' 'ENDOPOL2' 'TSFPAEC' 'PAEC1' 'OTHPFIND')));
    KEEP studyid usubjid parcat1 ADT AVISITN VISITNUM visit FAREFID FAEVALID  paramcd FADTC aval avalc;
RUN;


PROC SORT DATA = chk_dup_one OUT = chk_dup_one_1 NODUPKEY DUPOUT=dup_one_1;
    BY studyid usubjid parcat1 ADT AVISITN visit FAEVALID  paramcd ;
RUN;

DATA _NULL_;
    SET dup_one_1;
    PUT "WARNING: %upcase(&adsDomain.)  duplicate per sample  " studyid= usubjid= FAREFID= ADT= AVISITN= visit= FAEVALID=  ;
RUN;

/*< "It should only be possible to tick only one of the combined endpoint with YES
   Combined endpoint includes parameters 'BENIGEN1' 'ENDHYP4Y' 'MALNEOP1'.
   See Operational Manual for Pathology Reads */

/* Remove possible duplicates for combined endpoint - use XGREFID for identification */
PROC SORT DATA = &adsDomain. (WHERE = (paramcd IN ('BENIGEN1' 'ENDHYP4Y' 'MALNEOP1') AND avalc='Y' ))
          OUT = chk_comb1(KEEP= studyid usubjid parcat1 FAREFID adt FADTC visitnum visit AVISITN FAEVALID paramcd aval avalc) NODUPKEY DUPOUT=dup_comb;
    BY studyid usubjid parcat1 FAREFID paramcd ;
RUN;

DATA chk_comb2;
    SET chk_comb1;
    BY studyid usubjid parcat1 FAREFID paramcd ;
    IF NOT LAST.FAREFID;
RUN;

DATA _NULL_;
    SET chk_comb2;
    PUT "WARNING: %upcase(&adsDomain.) Several combined endpoint ticked YES for " studyid= usubjid= farefid= adt= visitnum= visit= FAEVALID= AVISITN= ;
RUN;


/*< Checking missing dates for other than 'NOT DONE' samples. For 'NOT DONE' samples date is not collected
    but VISITNUM should be available in order to merge date from ADSV (in section
    PREPARATIONS BEFORE FURTHER DERIVATIONS') */
/**/
/*DATA _NULL_;*/
/*    SET &adsDomain.(WHERE=(missing(adt) AND FATESTCD NOT IN ("FAALL") OR missing(adt) AND missing(visitnum)));*/
/*    PUT 'W' 'ARNING: Missing date and/or visit:' studyid= usubjid= paramcd= adt= visitnum= visit=;*/
/*RUN;*/



*******************************************************************************;
*< Data checks: END ;
*******************************************************************************;

proc sort data=&adsDomain. out=&adsDomain._RD(keep=studyid usubjid EPOCH adt avisitn visitnum visit FASTRESC FASTRF rename=(FASTRESC=RESNRD));
   BY studyid usubjid   avisitn visitnum visit  ;
   where paramcd eq "REUNSEB";
RUN;

    PROC SQL;
        CREATE TABLE &adsDomain._1 AS SELECT a.*,b.RESNRD    from &adsDomain. as a
               left join &adsDomain._RD as b   on ( a.usubjid =b.usubjid and a.avisitn=b.avisitn and  a.FASTRF=b.FASTRF);

    QUIT;

proc sort data=&adsDomain._1 nodupkey;
    BY studyid usubjid paramcd parcat1  parcat2 adt  avisitn visitnum visit FAEVALID FAOBJ FASEQ FASTRESC;
RUN;
*******************************************************************************;
*<  MAJORITY CONSENSUS DIAGNOSIS: START;
*******************************************************************************;


PROC SQL;
    CREATE TABLE count_reader AS
           SELECT DISTINCT studyid, usubjid, parcat1, adt,avisitn, visitnum, visit, FASTRF,FAEVALID,FAOBJ, count(DISTINCT FAEVALID) AS count_reader
           FROM &adsDomain._1  where FAEVALID ne "" and avalc eq "Y"
           GROUP BY studyid, usubjid, parcat1, avisitn, visitnum, visit;
QUIT;


/* Include Unscheduled Biopsy Sample due to Inadequate Endometrial Tissue */

DATA &adsDomain._multir_prep;

   SET  &adsDomain._1 (WHERE = (parcat1 eq "ENDOMETRIAL BIOPSY"  ));

   if RESNRD eq "REPEAT BIOPSY DUE TO INSUFFICIENT TISSUE" then do;
   if VISITNUM eq 900000 then do;
      if ADT < TRTSDT  then AVISITN = 5;
      else if  ADT> TRTSDT  then AVISITN = 600010 ;
   END;
   END;
   *< In case several additional read per subject, date and reader before majority read assessment
   - choose worst case selection when possible;
      if avalc eq "N" then _aval=0;
      else if avalc eq "Y" then _aval=1 ;


   * Most severe diagnosis is "no" for benign endometrium;
   IF paramcd = "BENIGEN1" THEN __aval = _aval*(-1);
   ELSE __aval = _aval;
RUN;



PROC SORT DATA = &adsDomain._multir_prep;
    BY studyid usubjid parcat1  adt   visitnum visit FAEVALID FAOBJ ;
RUN;

DATA &adsDomain._multireader;
    MERGE &adsDomain._multir_prep(in=a)  count_reader(drop=avisitn FASTRF);
    BY studyid usubjid parcat1  adt   visitnum visit FAEVALID FAOBJ;
    IF a and count_reader in ( 3,2);

RUN;

/* Checking if there are more than 1 EB sample analysed by subject, date, visit, parameter, reader and additional read*/

/* First dropping duplicates so same results */
PROC SORT DATA = &adsDomain._multireader NODUPKEY OUT=majcons_prep_ini1 dupout=majcons_prep_dup;
    BY studyid usubjid parcat1 adt avisitn visitnum visit paramcd  FAEVALID aval;
RUN;




DATA majcons_prep_ini2;
    SET majcons_prep_ini1;


RUN;


PROC SORT DATA = majcons_prep_ini2;
    BY studyid usubjid parcat1 adt avisitn visitnum visit   FAEVALID paramcd __aval ;
RUN;


/*  ADQENDO1 (Adequate endometrial tissue for diagnosis) :
count majority and remove respective main and subcategories tests if answer is 'NO' */


PROC SQL;
    CREATE TABLE ade_suf_calc AS SELECT ADSNAME,studyid, usubjid, parcat1, FASTRF, FAOBJ,avisitn,visitnum, visit,adt,paramcd,parcat2,_aval,avalc,
                 count(DISTINCT FAEVALID) AS adsu_n
           FROM &adsDomain._multir_prep (WHERE = (paramcd IN ("ADQENDO1")))
           GROUP BY studyid, usubjid,FALNKID, parcat1,  avisitn,visitnum, visit, parcat2, paramcd, _aval, avalc
           ORDER BY studyid, usubjid, parcat1, ADT, avisitn,visitnum, visit, parcat2, paramcd, adsu_n, _aval, avalc;
QUIT;


DATA ade_suf_no;
    SET ade_suf_calc;
    BY studyid usubjid parcat1 adt avisitn visitnum visit  paramcd parcat2  adsu_n _aval avalc;
    IF   (avalc='N'  and adsu_n in (2,3)) or (avalc eq "Y" and adsu_n eq 1) THEN OUTPUT;
RUN;
proc sort data=majcons_prep_ini2;
     BY studyid usubjid parcat1  avisitn visitnum visit adt ;
RUN;
proc sort data=ade_suf_no(keep=studyid usubjid parcat1 FAOBJ avisitn visitnum visit FASTRF adt adsu_n  );
     BY studyid usubjid parcat1  avisitn visitnum visit adt ;
RUN;
DATA majcons_prep ;
    MERGE majcons_prep_ini2 ade_suf_no(IN=b drop=FAOBJ FASTRF);
no_maj=b;

    BY studyid usubjid parcat1  avisitn visitnum visit adt  ;
if no_maj eq 1 /*AND paramcd NOT IN("ADQENDO1" )*/ THEN DELETE ;
if RESNRD eq "REPEAT BIOPSY DUE TO INSUFFICIENT TISSUE" then do;
   if VISITNUM eq 900000 then do;
       if ADT < TRTSDT  then AVISITN = 5;
       else if  ADT> TRTSDT  then AVISITN = 600010 ;
   END;

END;
RUN;

/*< MAJORITY CONSENSUS DIAGNOSIS: All except for the combined endpoint*/
/* Derive a majority consensus diagnosis for all parameters except for the combined
   endpoint for the Part II diagnosis ("BENIGEN1" "ENDHYP4Y" "MALNEOP1").
   ADQENDO1: select majority
   Endometrial Polyp,  and other observation:
   in case no majority result is possible (2 different results from 2 readers and
   insufficient tissue for diagnosis from the 3rd reader), the most severe diagnosis,
   i.e. "yes" will be used.
   Sub-features:
   For 'select one'-parameters the majority result will be used. In case no majority
   result is possible, the result "no concensus' will be used:
   "BENIGEN2" "ENDOHYP3" "ENDOHYP4" "MALNEOP2" "ENDOPOL2"
*/



PROC SQL;
    CREATE TABLE majcons_wout_part2_prep AS SELECT adsname,studyid, usubjid, parcat1, parcat2, FALNKID,avisitn, visitnum, visit, paramcd, _aval, avalc,
                 count(DISTINCT FAEVALID) AS cnt
           FROM majcons_prep (WHERE = (paramcd NOT IN ("BENIGEN1" "ENDHYP4Y" "MALNEOP1")))
           GROUP BY studyid, usubjid, parcat1,avisitn, visitnum, visit, paramcd, _aval, avalc
           ORDER BY studyid, usubjid, parcat1, avisitn, visitnum,  paramcd, cnt, _aval, avalc;
QUIT;

/* Type of majority: created same way as in Asteroid 2 (majority of 1 not used anymore):
  0.000 = Worst case
  2.000 = Majority of 2
  3.000 = Majority of 3

*/

data majcons_wout_part2_prep;
    set majcons_wout_part2_prep;
    by studyid usubjid parcat1  avisitn visitnum visit paramcd  cnt _aval avalc;
    if first.paramcd then number_cnt = .;
    number_cnt +1;

RUN;


DATA majcons_wout_part2 ;*(drop = cnt);
    SET majcons_wout_part2_prep;
    BY studyid usubjid parcat1  avisitn visitnum visit paramcd  cnt _aval avalc;
   * %createcustomvars(metadat=adsmeta.&_ads_domain, vars=primtypn);
   /* Adequate endometrial tissue for diagnosis - ADQENDO1 : select majority */
    IF paramcd IN ("ADQENDO1") THEN DO;
        /* Type of  majority: majority of 3 or majority of 2*/
        primtypn=cnt;
        /* Adequate endometrial tissue for diagnosis: select majority */
        IF last.paramcd THEN OUTPUT;
    END;
    ELSE IF paramcd IN ("BENIGEN2" "MALNEOP2")  THEN DO;
        /* Type of  majority: majority of 3 or majority of 2 or no consensus */
        primtypn=cnt;
        IF cnt >=2  and last.paramcd THEN OUTPUT;
        IF cnt < 2 THEN do ;
            primtypn=0;
            aval  = .;
            avalc = "No consensus";
            if last.paramcd then OUTPUT;
            end;
        /* For 'select one'-parameters the majority result will be used. In case no majority
           result is possible, the result "no consensus' will be used.
           The approach to present those features which are ticked by more than one reader
           is the preferred one so it is possible to have more than one sub-feature selected
           due to multiple biopsies on the same day and visit*/

    END;

    ELSE IF paramcd IN ("ENDOPOL2")  THEN DO;
        /* Type of  majority: majority of 3 or majority of 2 or no consensus */
        primtypn=cnt;
        IF cnt >= 2  and last.paramcd THEN OUTPUT;
        IF cnt < 2 and number_cnt gt 1 THEN do ;
            primtypn=0;
            aval  = .;
            avalc = "No consensus";
            if last.paramcd then OUTPUT;
            end;
        /* For 'select one'-parameters the majority result will be used. In case no majority
           result is possible, the result "no consensus' will be used.
           The approach to present those features which are ticked by more than one reader
           is the preferred one so it is possible to have more than one sub-feature selected
           due to multiple biopsies on the same day and visit*/

    END;

    ELSE IF paramcd IN ("ENDOPOL1")  THEN DO;
        /* Type of  majority: majority of 3 or majority of 2 or worst case */
        primtypn=cnt;
        IF cnt >=2  and last.paramcd THEN OUTPUT;
        IF cnt < 2 THEN do ;
            primtypn=0;
            aval  = .;
            avalc = "Y";
            if last.paramcd then OUTPUT;
            end;
        /* Endometrial Polyp, PAEC and other observation:
           in case no majority result is possible (2 different results from 2 readers and
           insufficient tissue for diagnosis from the 3rd reader), the most severe diagnosis,
           i.e. "yes" will be used.
           */

    END;
    ELSE IF paramcd IN ("ENDOHYP4")  THEN DO;
        /* Type of  majority: majority of 3 or majority of 2 or worst case */
        primtypn=cnt;

        IF cnt >=2  and last.paramcd THEN OUTPUT;
        IF cnt < 2 THEN do ;
            primtypn=0;
            aval  = .;
            avalc = "Atypical hyperplasia / Endometrioid Intraepithelial Neoplasia (EIN)";
            if last.paramcd then OUTPUT;
            end;
        /* Endometrial Hyperplasia (WHO 2014) :
           in case no majority result is possible (2 different results from 2 readers and
           insufficient tissue for diagnosis from the 3rd reader), the most severe diagnosis,
           i.e. "Atypical hyperplasia / Endometrioid Intraepithelial Neoplasia (EIN)" will be used.
           5 = HYPERPLASIA WITHOUT ATYPIA, 6 = ATYPICAL HYPERPLASIA / EIN
           */

    END;
RUN;

/*< MAJORITY CONSENSUS DIAGNOSIS: Combined endpoint */
/* One combined endpoint for the Part II diagnosis is collected. Only one of the
   following entries can be ticked with "yes" from one reader for one subject's visit:
   Benign Endometrium, Endometrial Hyperplasia (WHO 2014), Malignant Neoplasm
   (ordered by severity, from low to high).*/

PROC SORT DATA=majcons_prep nodupkey;
    BY adsname studyid usubjid parcat1  parcat2  avisitn visitnum visit  paramcd FAEVALID FALNKID _aval;
RUN;

PROC TRANSPOSE DATA = majcons_prep (WHERE = (paramcd IN ("BENIGEN1" "ENDHYP4Y" "MALNEOP1")))
               OUT = majcons_part2_prep1 (DROP = _:);
    BY adsname studyid usubjid parcat1 parcat2 avisitn visitnum visit FALNKID;
    VAR _aval;
    ID paramcd FAEVALID;
    format paramcd;
RUN;


DATA majcons_part2_prep2;
    SET majcons_part2_prep1;

    * CHECK if only one of the above mentioned endpoints was ticked by one reader
      ("1" is added to avoid notes about missing values);
    IF   sum(of BENIGEN1READER_2, ENDHYP4YREADER_2, MALNEOP1READER_2, 1) > 2
      OR sum(of BENIGEN1READER_3, ENDHYP4YREADER_3, MALNEOP1READER_3, 1) > 2
      OR sum(of BENIGEN1READER_1, ENDHYP4YREADER_1, MALNEOP1READER_1, 1) > 2
      THEN PUT 'WAR' 'NING: More than one endpoint for Part II diagnosis was selected by the same reader: '
               studyid= usubjid= visitnum= visit=;

    IF n(of BENIGEN1R:) ^= n(of ENDHYP4YR:) OR n(of BENIGEN1R:) ^= n(of MALNEOP1R:)
      THEN PUT 'WAR' 'NING: Inconsistent number of endpoints for Part II diagnosis: '
             studyid= usubjid=  visitnum= visit=;

    IF n(of BENIGEN1R:) < 2
      THEN PUT 'WAR' 'NING: Insufficient number of endpoints for Part II diagnosis: '
           studyid= usubjid=  visitnum= visit=;

    MALNEOP1 = 0;
    ENDHYP4Y = 0;
    BENIGEN1 = 0;

    IF sum(of MALNEOP1R:) >= 2 OR sum(of MALNEOP1R:) = 1 AND n(of MALNEOP1R:) = 2 THEN MALNEOP1 = 1;
    ELSE IF sum(of ENDHYP4YR:) >= 2 OR sum(of ENDHYP4YR:) = 1 AND n(of ENDHYP4YR:) = 2 THEN ENDHYP4Y = 1;
    ELSE IF sum(of BENIGEN1R:) >= 2 THEN BENIGEN1 = 1;
RUN;
/*< NOTE: summary has to be used when calculating majority type assessment */
/* Type of majority: majority of 3 or majority of 2 or worst case */
DATA majcons_part2_prep3;
    SET majcons_part2_prep2;

    /* In case overall = yes, then calculate number of 1:s (summary)*/
    IF BENIGEN1 = 1 THEN CNT_BENIGEN1=sum(of BENIGEN1R:) ;
    /* In case overall = no, then calculate number of 0:s - (not missing values of 0 and 1 -  number of 1:s) */
    IF BENIGEN1 = 0 THEN CNT_BENIGEN1=n(of BENIGEN1R:)-sum(of BENIGEN1R:) ;

    IF ENDHYP4Y = 1 THEN CNT_ENDHYP4Y=sum(of ENDHYP4YR:);
    IF ENDHYP4Y = 0 THEN CNT_ENDHYP4Y= n(of ENDHYP4YR:)-sum(of ENDHYP4YR:);

    IF MALNEOP1 = 1 THEN CNT_MALNEOP1=sum(of MALNEOP1R:) ;
    IF MALNEOP1 = 0 THEN CNT_MALNEOP1=n(of MALNEOP1R:)-sum(of MALNEOP1R:) ;

RUN;

PROC SORT DATA=majcons_part2_prep3;
    BY studyid usubjid parcat1 parcat2 avisitn visitnum visit FALNKID;
RUN;

* Transpose the results back to the BDS structure;;
PROC TRANSPOSE DATA = majcons_part2_prep3 OUT = majcons_part2_prep4;
    VAR benigen1 endhyp4y malneop1 ;
    BY adsname studyid usubjid parcat1 parcat2 avisitn visitnum visit FALNKID;
RUN;

DATA majcons_part2_prep5 (DROP = _NAME_ COL1);
    SET majcons_part2_prep4;
    %createCustomVars(adsDomain=adfapr, vars=paramcd aval avalc)
    paramcd = upcase(_NAME_);
    aval    = COL1;
    avalc   = put(aval, NY.);
RUN;

PROC TRANSPOSE DATA = majcons_part2_prep3 OUT = majcons_part2_prep6;
    VAR cnt_benigen1 cnt_endhyp4y cnt_malneop1 ;
    BY studyid usubjid parcat1 parcat2 avisitn  visitnum visit FALNKID;
RUN;

DATA majcons_part2_prep7(DROP = _NAME_ COL1);
    SET majcons_part2_prep6;
    %createcustomvars(adsDomain=adfapr, vars= paramcd);
    paramcd=strip(tranwrd(_name_,'CNT_',''));
    primtypn=COL1;
    IF COL1 < 2 THEN primtypn=0;
RUN;

PROC SORT DATA=majcons_part2_prep5;
    BY studyid usubjid parcat1 parcat2 avisitn visitnum visit  FALNKID paramcd;
RUN;

PROC SORT DATA=majcons_part2_prep7;
    BY studyid usubjid parcat1 parcat2 avisitn visitnum visit  FALNKID paramcd;
RUN;

DATA majcons_part2 ;
    MERGE majcons_part2_prep5 majcons_part2_prep7;
    BY studyid usubjid parcat1 parcat2 avisitn visitnum visit  FALNKID paramcd;
RUN;


/*< MAJORITY CONSENSUS DIAGNOSIS: Final */
DATA majcons_main_sub;
    SET majcons_part2 majcons_wout_part2;
    if paramcd="ENDOPOL1" then aval=_aval;
RUN;

PROC SORT DATA=majcons_main_sub;
    BY studyid usubjid parcat1 parcat2 avisitn visitnum visit  FALNKID paramcd;
RUN;

* Transpose the data of main categories to harmonize the endpoints;
PROC TRANSPOSE DATA = majcons_main_sub (WHERE = (paramcd IN ("BENIGEN1" "ENDHYP4Y"  "MALNEOP1"  "ENDOPOL1")))
               OUT  = majcons_main;
    BY studyid usubjid parcat1 parcat2 avisitn visitnum visit FALNKID;
    VAR aval;
    ID paramcd;
    format paramcd;
RUN;


/*< Removing subcategories in case respective main category does not exist according to majority assesment */
DATA majcons_ini /*(KEEP = adsname studyid usubjid parcat1 avisitn visitnum visit  paramcd aval avalc primtypn)*/;
    MERGE majcons_main_sub
          majcons_main;
    BY studyid usubjid parcat1 parcat2 avisitn visitnum visit FALNKID;
    * Individual sub-features will be provided for all parameters, i.e. benign endometrium,
      Endometrial Hyperplasia (WHO 2014), Malignant Neoplasm, Endometrial Hyperplasia (WHO 1994),
      Endometrial Polyp ;
    IF    paramcd = "BENIGEN2" AND BENIGEN1 ^= 1

       OR paramcd = "ENDOHYP4" AND ENDHYP4Y ^= 1
       OR paramcd = "MALNEOP2" AND MALNEOP1 ^= 1
       OR paramcd = "ENDOPOL2" AND ENDOPOL1 ^= 1 THEN DELETE;

RUN;

data majcons_wout_part3(drop=aval);
    set majcons_ini;
    %createCustomVars(adsDomain=adfapr, vars=DTYPE);
      if primtypn eq 0 then DTYPE="MAJCWOCI" ;
      else  DTYPE="MAJCON";
      anl01fl = 'Y';
RUN;





data  &adsDomain.1;
set  &adsDomain._1 majcons_wout_part3;
run;


proc sort data=&adsDomain.1;
   BY studyid usubjid FAOBJ  avisitn visitnum visit  adt;

RUN;

data &adsDomain._BSO &adsDomain._ADQ  ;
    set &adsDomain.1;
    if parcat1 eq "ENDOMETRIAL BIOPSIES" then output &adsDomain._BSO;
    else output  &adsDomain._ADQ;
RUN;

proc sort data= &adsDomain._BSO;
  BY studyid usubjid FAOBJ adt  visitnum visit  ;

RUN;


proc sort data=count_reader;
   BY studyid usubjid FAOBJ  adt  visitnum visit  ;

RUN;
proc sort data=ade_suf_no;
   BY studyid usubjid FAOBJ  adt  visitnum visit  ;

RUN;

proc sort data= &adsDomain._ADQ;
    BY studyid usubjid   visitnum visit FALNKID ;

RUN;

proc sort data=majcons_wout_part3 out=majority_sub(keep= studyid usubjid   visitnum visit FALNKID) nodupkey;
    BY studyid usubjid   visitnum visit FALNKID ;
RUN;



data &adsDomain._ADQ1;
    merge &adsDomain._ADQ(in=a) majority_sub(in=b);
    BY studyid usubjid   visitnum visit FALNKID ;

   if a;
   /*Main diagnosis with inadequate Endometrial Tissue or No majority will not be analysed*/
   if not b and parcat1 eq "ENDOMETRIAL BIOPSY" then ANL01FL="";
RUN;

proc sort data= &adsDomain._ADQ1;
    BY studyid usubjid FAOBJ adt  visitnum visit  ;

RUN;

data  &adsDomain.2_ adq_maj_(keep = usubjid paramcd visit adt  falnkid avaln avalc fady faevalid epoch where = (paramcd eq "ADQENDO1" and visit = "UNSCHEDULED" and fady gt 1 and avaln ne .))
     &adsDomain.2_1(keep = usubjid paramcd visit adt  falnkid avaln avalc falnkid_der fady faevalid epoch where = (paramcd eq "ADQENDO1" and visit = "UNSCHEDULED" and fady ne . and fady le 1 and avaln ne .));
    length falnkid_der $100.;
   set   &adsDomain._ADQ1  &adsDomain._BSO;
   BY studyid usubjid FAOBJ adt  visitnum visit  ;

   if paramcd in ('BISAMPOB' 'REUNSEB') then falnkid_der = strip(strip(put(visitnum,best.))||"_"||strip(scan(fadtc,1,"T")));
   else falnkid_der = falnkid;
/**/
/* *//* remap unscheduled visit  to Baseline/EOT base on date     for REPEAT BIOPSY DUE TO INSUFFICIENT TISSUE*/
 if RESNRD eq "REPEAT BIOPSY DUE TO INSUFFICIENT TISSUE" and  FAOBJ eq "ENDOMETRIAL BIOPSY"  then do;
     if avalc eq "Y" then avaln = 1;else avaln = 0;
/*        if VISITNUM eq 900000 then do;*/
/*            if ADT < TRTSDT  then AVISITN = 5;*/
/**//*            else if  ADT> TRTSDT  then AVISITN = 600010 ;*/
/*        END;*/
/**/
 END;

 /*remap all screening visit to baseline as per table requirement */

     if visitnum =0 then avisitn=5;


RUN;

data adq_maj_base(keep = usubjid falnkid_der tots);
    set  &adsDomain.2_1;
    by usubjid falnkid_der;
    if first.falnkid_der then tots = avaln;
    else tots+avaln;
    if last.falnkid_der;
RUN;

data adq_maj(keep = usubjid falnkid tots);
    set adq_maj_;
    by usubjid;
    if first.usubjid then tots = avaln;
    else tots+avaln;
    if last.usubjid;
RUN;

proc sql;
    create table baseline_merging as
           select a.*, b.tots
           from &adsDomain.2_ as a left join adq_maj_base as b on
           a.usubjid = b.usubjid and /*A.falnkid_der*/strip(scan(a.falnkid_der,1,"T")) = strip(scan(b.falnkid_der,1,"T"));
QUIT;

data  &adsDomain.2(drop = tots) ;
    set  baseline_merging;
    if avaln ne . and tots gt 1 and visitnum = 900000 and fady ne . and fady le 1 then avisitn = 5; else avisitn = avisitn;
RUN;

proc sort data = &adsDomain.2 out = valid_&adsDomain.2 nodupkey; by usubjid paramcd falnkid faevalid;
 where faobj eq 'ENDOMETRIAL BIOPSY' and visit = "UNSCHEDULED" and RESNRD eq "REPEAT BIOPSY DUE TO INSUFFICIENT TISSUE" and fady ge 1 ;
run;

data valid_&adsDomain.2;
    set valid_&adsDomain.2;
    if parcat1 eq "ENDOMETRIAL BIOPSIES" then faevalid ='READER 3'; else faevalid = faevalid;
run;

proc transpose data =valid_&adsDomain.2
     out = trans_re;
    by usubjid paramcd falnkid;
    var fastresc;
    id faevalid;
RUN;

proc sql;
    create table &adsDomain.2_up as
           select a.*, b.reader_1, b.reader_2, b.reader_3
           from &adsDomain.2 as a left join trans_re as b on
           a.usubjid = b.usubjid and a.falnkid = b.falnkid and a.paramcd = b.paramcd
           order by a.usubjid , a.falnkid;
QUIT;

data &adsDomain.2_up_ (DROP = TOTS);
    merge &adsDomain.2_up adq_maj;
    by usubjid falnkid;
     if RESNRD eq "REPEAT BIOPSY DUE TO INSUFFICIENT TISSUE" and  FAOBJ eq "ENDOMETRIAL BIOPSY" and tots gt 1
        and VISITNUM eq 900000 and ADT> TRTSDT  then AVISITN = 600010 ;
        else avisitn = avisitn;

RUN;


data &adsDomain.2_up ;
    merge &adsDomain.2_up_ adq_maj(drop = falnkid);
    by usubjid ;
     if RESNRD eq "REPEAT BIOPSY DUE TO INSUFFICIENT TISSUE" and  paramcd in ('BISAMPOB' 'REUNSEB') and tots gt 1
        and VISITNUM eq 900000 and ADT> TRTSDT  then AVISITN = 600010 ;
        else avisitn = avisitn;
RUN;

/*Deriving AVALC from FAREASND for "CERVICAL CYTOLOGY" "MAMMOGRAPHY" "GYNECOLOGICAL EXAMINATION" */

/*Deriving AVALC from FAREASND for "CERVICAL CYTOLOGY" "MAMMOGRAPHY" "GYNECOLOGICAL EXAMINATION" */

Proc sort data= &adsDomain.2_up out= &adsDomain.3(keep=ADSNAME studyid usubjid FALNKID PARAMCD FAREASND PARCAT1 PARCAT2  FAOBJ   ADT AVISITN  ANL01FL DTYPE);
    BY studyid usubjid FALNKID FATESTCD FACAT FADTC  visitnum visit ;
    where FACAT in ("CERVICAL CYTOLOGY" "MAMMOGRAPHY" "ULTRASOUND") and FAREASND eq "NOT ASSESSABLE" and visitnum ne 900000;
RUN;


data  &adsDomain.4(drop=FAREASND);
   set  &adsDomain.3;
  if  PARCAT1 eq "MAMMOGRAPHY" then  PARAMCD="PROCFIND";
  else if PARCAT1 eq "CERVICAL CYTOLOGY"  then  PARAMCD="CRFIND";
  else if PARCAT1 eq "ULTRASOUND" then  PARAMCD="FAINTP";

   DTYPE="COPY";
   ANL01FL="Y";
   AVALC=FAREASND;

RUN;
/* removed FAALL as not needed in Reporting*/
Data &adsDomain.5;
    set  &adsDomain.2_up(where=(FATESTCD ne "FAALL")) &adsDomain.4;

RUN;

%late_ads_processing(adsDat =  &adsDomain.5)

%endprog()