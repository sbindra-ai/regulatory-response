/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_5_spec_trt_intr);
/*
 * Purpose          : Treatment interruptions
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 17NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_5_spec_trt_intr.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/

PROC SORT DATA=sp.ec    OUT = ec (KEEP = USUBJID EPOCH ECOCCUR ECADJ ECDOSMOD ECSTDTC ECENDTC ECSTDY ECENDY );
    BY USUBJID STUDYID;
    WHERE ECDOSMOD = 'DRUG INTERRUPTED';
RUN;

DATA ec1;
    SET ec;
    ECSTDTC = substr(ECSTDTC,1, 10);
    ECENDTC = substr(ECENDTC,1, 10);
    if ECDOSMOD = 'DRUG INTERRUPTED' then trt_int = "Yes";
RUN;

%m_create_dtl(inputds=ec1, varname= ECENDTL);
%m_create_dtl(inputds=ec1, varname= ECSTDTL );

PROC SORT DATA=ads.adsl OUT = sl ;    BY USUBJID STUDYID; RUN;

DATA ec_sl;
    MERGE ec1 (IN=a) sl (IN=b);
    BY usubjid ;
    IF a;
    FORMAT ECOCCUR $x_ny.;
    KEEP USUBJID SASR TRT01AN EPOCH ECOCCUR trt_int ECADJ ECDOSMOD ECSTDTC ECENDTC ECSTDTL ECENDTL ECSTDY ECENDY;
    LABEL &treat_var. = 'Actual Treatment Group'
          trt_int = 'Temporary Treatment Interruption'
          ECADJ = 'Corresponding reason'
          ECSTDTL = 'Start Date of Temporary Treatment Interruption'
          ECENDTL = 'End Date of Temporary Treatment Interruption'
          ECSTDY = 'Study Day of Start relative to Start of Treatment'
          ECENDY = 'Study Day of End relative to Start of Treatment';
RUN;

****need to add dates to specify the duplicates;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = ec_sl
  , page     = &treat_var.
  , by       = SASR
  , var      = EPOCH trt_int ECADJ ECSTDY ECSTDTL ECENDY ECENDTL
  , freeline = first.SASR
  , optimal  = y
  , maxlen   = 20
  , space    = 2
  , split    =
  , layout   = Standard
  , bylen    = 20
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();
