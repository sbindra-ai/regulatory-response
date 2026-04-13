/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_8_3_speg_fnd);
/*
 * Purpose          : Electrocardiogram findings
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 17OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_8_3_speg_fnd.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/
%load_ads_dat(adsl_view , adsDomain = adsl , where =  &saf_cond  )
%extend_data(indat = adsl_view, outdat = adsl)

PROC SQL;
    CREATE TABLE eg1 AS
           SELECT a.*, b.SASR, b.TRT01AN
           FROM sp.eg AS a LEFT JOIN ads.adsl AS b
           ON a.USUBJID = b.USUBJID;
QUIT;

%extend_data(indat = eg1, outdat = eg2)

**********************< creating listing dates  *************************;

%m_create_dtl(inputds=eg2, varname= EGDTL);
%m_create_dtl(inputds=eg2, varname= EGRFTDTL);

**********************< merge with adsl *************************;

PROC SORT DATA = adsl (KEEP = &subj_var. SASR &treat_var_listings_part. &treat_var. );
    BY &treat_var. &subj_var. SASR;RUN;
PROC SORT DATA = eg2 ;
    BY &treat_var. &subj_var. SASR VISITNUM EGDTC;;RUN;

DATA eg_final;
MERGE  adsl (IN=a) eg2(IN=b) ;
BY  &treat_var. &subj_var. SASR;
IF b;
RUN;

**********************< creating listing variable  ********************;

DATA eg3;
    SET eg_final;
    FORMAT EGCLSIG $x_ny.;
    KEEP TRT01AN SASR VISIT EGDTL EGTEST EGORRES EGCLSIG;
RUN;

PROC SORT DATA = eg3 OUT = eg4 NODUPKEY;
    BY TRT01AN SASR VISIT EGDTL EGCLSIG EGTEST EGORRES   ;
RUN;

PROC TRANSPOSE DATA =eg4 OUT=new_eg  ;
    ID EGTEST;
    VAR EGORRES ;
    BY TRT01AN SASR VISIT EGDTL EGCLSIG ;
    IDLABEL EGTEST;
RUN;

DATA eg_final;
    SET new_eg;
    IF Sinus_Node_Rhythms_and_Arrhythmi = 'SINUS RHYTHM' THEN SN_RHM = 'YES';
    LABEL EGDTL = 'Electrocardiogram Date/ Time'
          EGCLSIG = 'If abnormal, clinically significant'
          VISIT = 'Visit'
          Interpretation = 'ECG Finding Interpretation'
          TRT01AN = 'Actual Treatment Group'
          SN_RHM = 'Sinus rhythm';
RUN;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = eg_final
  , page     = &treat_var.
  , by       = SASR VISIT
  , var      = EGDTL SN_RHM Interpretation EGCLSIG
  , optimal  = y
  , maxlen   = 30
  , space    = 5
  , split    =
  , hsplit   = #
  , bylen    = 22
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();