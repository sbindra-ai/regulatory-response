/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_8_3_advs);
/*
 * Purpose          : Listing for Vital signs
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 21NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_8_3_advs.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/

%m_create_ads_view(adsDomain = advs, outDat = advsall)

%extend_data(indat = advsall, outdat = advs)

*******************************< creating listing dates  **************************;

DATA advsall_1;
    SET advs;
    WHERE NOT missing (&treat_var.) AND
          NOT missing (paramcd) AND
          paramcd IN ('HR' 'SYSBP' 'DIABP') ;
RUN;

%m_create_dtl(inputds=advsall_1, varname= VSDTL);

******************************<  creating listing variable  ****************************;

DATA advsall_2;
    SET advsall_1;
    format vital _vit. ;
     newdate= input(VSDTC, yymmdd10.);
     vital = input(PARAMCD, _vitn. );
    LABEL VSDTL     = 'Measurement Date'
          AVISITN = 'Visit'
          VSTEST = 'Vital Sign Test Name'
          AVALC     = 'Result'
          TRT01AN   = 'Actual Treatment Group'
          VSSTRESU  = 'Standard Unit'          ;
RUN;

PROC SORT DATA= advsall_2 OUT= advs_final;
    BY &treat_var. USUBJID AVISITN ADT vital AVAL;
RUN;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = advs_final
  , page     = &treat_var.
  , by       = SASR  newdate AVISITN VSDTL vital VSTEST
  , var      = AVALC VSSTRESU
  , order    = newdate vital
  , optimal  = y
  , split    =
  , hsplit   = #
  , bylen    = 16
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();