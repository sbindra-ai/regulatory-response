/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_5_spda, log2file = Y, print2file = N);
/*
 * Purpose          : Drug accountability
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 20NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_5_spda.sas (egavb (Reema S Pawar) / date: 07JUN2023)
 ******************************************************************************/

PROC SORT DATA=sp.da    OUT = da ;    BY USUBJID STUDYID; RUN;
PROC SORT DATA=ads.adsl OUT = sl ;    BY USUBJID STUDYID; RUN;

DATA da_sl;
    MERGE da (IN=a) sl (IN=b);
    BY usubjid studyid;
    IF a;
    KEEP USUBJID SASR DASEQ VISIT DASPID DASMNUM DATEST DAORRES DASTRESN DADTC DADY EXNYOVLN TRT01AN DAORRESU;
RUN;

*********************< creating listing dates ************************;

%m_create_dtl(inputds=da_sl, varname=DADTL);

*****************<*deriving DATAKEN ********************;

PROC SORT DATA=da_sl  OUT=da_sort;
    BY usubjid SASR TRT01AN dasmnum DASPID DASEQ DADTL VISIT;
RUN;

PROC TRANSPOSE DATA= da_sort OUT= dispo_trans (DROP=_NAME_ _LABEL_);
    BY usubjid SASR TRT01AN dasmnum DASPID ;
    ID DATEST;
    VAR DASTRESN;
RUN;

PROC TRANSPOSE DATA= da_sort OUT= da_date_trans(RENAME= (Dispensed_Amount = disp_dt Returned_Amount= rtn_dt)DROP=Lost_Amount _NAME_ _LABEL_);
    BY usubjid SASR TRT01AN dasmnum DASPID /*EXNYOVLN DAORRESU*/;
    ID DATEST;
    VAR DADTL;
RUN;

PROC TRANSPOSE DATA= da_sort OUT= da_visit_trans(RENAME= (Dispensed_Amount = disp_visit Returned_Amount= rtn_visit)DROP=Lost_Amount _NAME_ _LABEL_);
    BY usubjid SASR TRT01AN dasmnum DASPID EXNYOVLN DAORRESU;
    ID DATEST;
    VAR VISIT;
RUN;

DATA da3;
    SET dispo_trans;
    FORMAT Dispensed_Amount 8.  Returned_Amount 8. Lost_Amount 8. dataken 8.;
        IF nmiss(Dispensed_Amount, Lost_Amount, Returned_Amount) = 0 THEN DO;
        dataken = sum(Dispensed_Amount) - sum(Returned_Amount)- sum(Lost_Amount);
        END;
    LABEL    dataken = 'Number Taken'
             Returned_Amount = 'Returned Amount'
             Dispensed_Amount = 'Dispensed Amount'
             Lost_Amount = 'Lost Amount';
RUN;

DATA da_final;
    MERGE da3 (IN=a) da_date_trans (IN=b) da_visit_trans (IN=c);
    BY usubjid SASR TRT01AN dasmnum DASPID ;
    IF a OR b OR c;
    IF EXNYOVLN = 1 THEN EXNYOVL='YES';
    ELSE EXNYOVL=' ';
    LABEL disp_dt = 'Dispense Visit Date'
          rtn_dt = 'Return Visit Date'
          DAORRESU = 'Unit'
          disp_visit = 'Dispense Visit'
          rtn_visit = 'Return Visit'
          Returned_Amount = 'Returned Amount'
          Dispensed_Amount = 'Dispensed Amount'
          Lost_Amount = 'Lost Amount'
          TRT01AN = 'Actual Treatment Group'
          EXNYOVL = 'Subject Took All Study Drug Not Returned';
RUN;


*<TLF shell :CRF fields "Subject took all study drug not returned" and "Number taken" are no longer included in the CRF.
*Include those columns in listing only if collected. visit name information is not collected in eCRF page#85 -
*that's why Visit name is not populated in listing taking reference from SP.CO domain for'For any known discrepancies,
*As per Catalog explanations and table options:CRF fields "Subject took all study drug not returned" and "Number taken" are no longer included in the CRF. Include those columns in listing only if collected.*;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = da_final
  , page     = &treat_var.
  , by       = SASR DASPID
  , var      = DASMNUM disp_dt rtn_dt DAORRESU Dispensed_Amount Returned_Amount Lost_Amount
  , order    = DASPID
  , freeline = SASR
  , optimal  = NO
  , maxlen   = 10
  , space    = 1
  , hsplit   = #
  , bylen    = 10
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();