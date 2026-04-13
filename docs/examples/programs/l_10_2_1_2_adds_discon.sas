/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(
       name     = l_10_2_1_2_adds_discon);
/*
 * Purpose          : Discontinued subjects
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gniiq (Mayur Parchure) / date: 13OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/l_10_2_1_2_adds_discon.sas (gniiq (Mayur Parchure) / date: 13OCT2023)
 ******************************************************************************/

%m_create_ads_view(
    adsDomain = adds
  , outDat    = addsall
)

%extend_data(indat = addsall, outdat = adds)

%m_create_dtl(inputds = adds, varname = DSSTDTL)

*<*****************************************************************************;
*< Split Dataset to have the correct value for Date of Last Visit for subjects ;
*<*****************************************************************************;

PROC SORT DATA=adds(WHERE=(DSDECOD NOT IN ('COMPLETED') AND
                               DSCAT EQ 'DISPOSITION EVENT' AND
                               EPOCH NOT IN ( 'SCREENING' '') AND ~missing(RANDFL)
                               AND DSTERM NE 'WITHDRAWAL OF:Informed consent for pharmacogenetic research')) OUT=adds1a;
      BY USUBJID;
RUN;

PROC SORT DATA=adds(WHERE=(DSDECOD = 'DATE OF LAST VISIT')) OUT=last(KEEP=USUBJID DSSTDTL RENAME=(DSSTDTL=_LASTVIS));
      BY USUBJID;
RUN;

 *<*****************************************************************************;
 *< Merge both datasets as a left join to have the date of last visit           ;
 *<*****************************************************************************;

DATA adds_final(WHERE=(missing(DSSCAT)));
          MERGE adds1a (IN=failu) last;
          BY usubjid;
          IF failu ;
          sub_asr=SASR;
          IF dsdecod = 'OTHER' AND NOT missing(dsterm)
             THEN _reason = 'OTHER: ' || dsterm;
          ELSE _reason = dsdecod;

           IF epoch ='SCREENING' THEN epochn=1;
           ELSE IF epoch ='TREATMENT' THEN epochn=2;
           ELSE IF epoch ='POST-TREATMENT' THEN epochn=3;
           ELSE IF epoch ='FOLLOW-UP' THEN epochn=4;

          LABEL _LASTVIS = "Date of#Last Visit";
          LABEL _REASON  = "Reason for#Discontinuation";
          LABEL TRTSDT   = "Date of#First Exposure#to Treatment";
          LABEL TRTEDT   = "Date of#Last Exposure#to Treatment";
          LABEL SUB_ASR  = "Subject Identifier/#Age/ Sex/ Race";
          LABEL &TREAT_VAR = "Actual Treatment Group";
RUN;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = adds_final
  , page     = &TREAT_VAR
  , by       = SUB_ASR EPOCHN EPOCH
  , var      = TRTSDT TRTEDT _LASTVIS _REASON
  , order    = SUBJID EPOCHN
  , freeline = SUB_ASR
  , together = SUB_ASR
  , optimal  = YES
  , maxlen   = 70
  , hsplit   = "#"
  , bylen    = 15
  , hc_align = CENTER
  , hn_align = CENTER
)

%endprog()
