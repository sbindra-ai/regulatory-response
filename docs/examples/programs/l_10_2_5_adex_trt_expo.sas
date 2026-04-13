/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_5_adex_trt_expo);
/*
 * Purpose          : Treatment exposure
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 17OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_5_adex_trt_expo.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/

%create_ads_view(adsDomain = adex, outDat = adexall)
%extend_data(indat = adexall, outdat = adex)

********************< creating listing dates ****************;

PROC SORT DATA=adex OUT=adexall_1 (KEEP=sasr epoch TRT01AN ASTDT AENDT EXSTDTC EXENDTC);
    BY usubjid epoch TRT01AN;
    WHERE paramcd = "TRT";
RUN;

DATA adex_start(KEEP=sasr epoch TRT01AN exstdtc);
    SET adexall_1;
    BY sasr epoch TRT01AN;
   IF FIRST.sasr;
RUN;

DATA adex_end(KEEP=sasr epoch TRT01AN exendtc);
    SET adexall_1;
    BY sasr epoch TRT01AN;
   IF LAST.sasr;
RUN;

DATA all;
    MERGE adex_start adex_end;
    BY sasr epoch TRT01AN;
RUN;

%m_create_dtl(inputds=all, varname= EXENDTL);
%m_create_dtl(inputds=all, varname= EXSTDTL);

DATA adex_trt_final;
    SET all;
    LABEL EXSTDTL = 'Date of First Exposure to Treatment';
    LABEL EXENDTL = 'Date of Last Exposure to Treatment';
    LABEL TRT01AN = 'Actual Treatment Group' ;
RUN;

PROC SORT DATA =adex_trt_final ;
    BY &treat_var. SASR EPOCH EXSTDTC EXENDTC;
RUN;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = adex_trt_final
  , page     = &treat_var.
  , by       = SASR epoch
  , var      = EXSTDTL EXENDTL
  , optimal  = y
  , maxlen   = 50
  , space    = 10
  , split    =
  , layout   = Standard
  , bylen    = 16
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();