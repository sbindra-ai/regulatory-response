/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_5_adex_stdy_expo);
/*
 * Purpose          : Study drug exposure
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 21NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_5_adex_stdy_expo.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/
%m_create_ads_view(
    adsDomain = adex
  , outDat    = adexall
  , adslVars  = EXNYOVLN SASR TRTEDT TRTSDT &treat_var.
);

%extend_data(indat = adexall, outdat = adex)

********************<creating listing dates ***************************;

PROC SORT DATA=adex OUT=adexall_1 (KEEP=SASR usubjid TRT01AN ASTDT AENDT APHASE aval EXSTDTC EXENDTC EXNYOVLN);
    BY usubjid TRT01AN ASTDT AENDT ;
    WHERE paramcd = "TRT" ;
RUN;

PROC SORT DATA=adex OUT=adexall_2 (KEEP=SASR usubjid TRT01AN ASTDT APHASE AENDT aval EXSTDTC EXENDTC EXNYOVLN);
    BY usubjid TRT01AN ASTDT AENDT ;
    WHERE paramcd = "DURWDR" AND APHASE ^= 'Overall';
RUN;

DATA adexall_3;
    SET adexall_2;
    EXSTDTC=put(ASTDT,date9.);
    EXENDTC=put(AENDT,date9.);
RUN;

%m_create_dtl(inputds=adexall_3, varname= EXENDTL);
%m_create_dtl(inputds=adexall_3, varname= EXSTDTL );

********************<creating final dataset***************************;

DATA ADEX_final;
    SET adexall_3;
    IF EXNYOVLN =1 THEN EXNYOVL ='YES' ; ELSE IF EXNYOVLN =0 THEN EXNYOVL =  'NO';
    R_aval = round(aval, 2.);
    LABEL EXNYOVL = 'Subject Took Study Drug';
    LABEL APHASE = 'Treatment phase';
    LABEL R_aval =  'Treatment Duration (weeks)';
    LABEL EXSTDTC = 'Start Date';
    LABEL EXENDTC = 'End Date';
    LABEL &treat_var. = 'Actual Treatment Group';
RUN;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = ADEX_final
  , page     = &treat_var.
  , by       = SASR APHASE EXNYOVL EXSTDTC EXENDTC
  , var      = R_aval
  , freeline = first.SASR
  , optimal  = y
  , maxlen   = 30
  , space    = 5
  , split    =
  , layout   = Standard
  , bylen    = 16
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();