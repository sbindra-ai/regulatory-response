/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_8_2_spce_liv_enzm);
/*
 * Purpose          : Clinical Signs and Symptoms with elevated liver enzymes
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 17OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_8_2_spce_liv_enzm.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/

PROC SORT DATA=sp.ce    OUT = ce ;    BY USUBJID STUDYID; RUN;
PROC SORT DATA=ads.adsl OUT = sl ;    BY USUBJID STUDYID; RUN;

DATA ce_sl;
    MERGE ce (IN=a) sl (IN=b);
    BY usubjid studyid;
    IF a;
    FORMAT CEOCCUR $x_ny.;
    KEEP USUBJID SAFFL SASR CETERM CESEQ VISIT VISITNUM CEDTC CESTDTC CESPID CEOCCUR CEBODSYS CECAT EXNYOVLN TRT01AN ;
RUN;

*********************<  creating listing dates  **************************;

%m_create_dtl(inputds=ce_sl, varname= CEDTL);
%m_create_dtl(inputds=ce_sl, varname= CESTDTL);

*************************<  creating listing variable  ************************;

DATA adce_final;
    SET ce_sl;
        WHERE CECAT = 'DRUG INDUCED LIVER INFLAMMATION'
              and VISITNUM ^= 700000
              and &saf_cond;
    LABEL CETERM = 'Clinical Signs or Symptoms'
          CEOCCUR = 'Present'
          CESTDTL = 'Start Date of Clinical Signs or Symptoms'
          TRT01AN = 'Actual Treatment Group';
RUN;

proc sort data = adce_final out = final;
    by &treat_var. &subj_var. CETERM ;
RUN;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = final
  , page     = &treat_var.
  , by       = SASR CETERM
  , var      = CEOCCUR CESTDTL
  , optimal  = y
  , maxlen   = 30
  , space    = 5
  , split    =
  , layout   = Standard
  , bylen    = 20
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();