/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_8_2_adcm_liv_evnt);
/*
 * Purpose          : Medication of Interest - Liver Event - CLO
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 21NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_8_2_adcm_liv_evnt.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/

%m_create_ads_view(adsDomain = adcm, outDat = adcmall)

%extend_data(indat = adcmall, outdat = adcm)

*********************<  creating listing dates  *********************;
DATA adcmall_1;  SET adcm; RUN;

%m_create_dtl(inputds=adcmall_1, varname= CMSTDTL);

********************< creating listing variable  **********************;

DATA adcm_final;
    SET adcmall_1;
    CMDECOD_new = propcase(CMDECOD);
    LABEL CMTRT   = 'Medication of interest'
          TRT01AN = 'Actual Treatment Group';
    WHERE CMCAT = 'MEDICATION OF INTEREST'
          AND CMOCCUR = 'Y'
          and &saf_cond;
RUN;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = adcm_final
  , page     = &treat_var.
  , by       = SASR
  , var      = CMTRT
  , optimal  = y
  , maxlen   = 80
  , space    = 20
  , split    =
  , layout   = Standard
  , bylen    = 20
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();