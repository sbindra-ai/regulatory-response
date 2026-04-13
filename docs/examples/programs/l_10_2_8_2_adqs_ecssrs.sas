/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_8_2_adqs_ecssrs);
/*
 * Purpose          : Electronic Columbia-suicide severity rating scale eC - SSRS
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 21NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_8_2_adqs_ecssrs.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/

*COLUMBIA-SUICIDE SEVERITY RATING SCALE (BAYER) BASELINE/SCREENING (ECOA);
*COLUMBIA-SUICIDE SEVERITY RATING SCALE (BAYER) SINCE LAST VISIT (ECOA);

%m_create_ads_view(adsDomain = adqs, outDat = adqsall)

%extend_data(indat = adqsall, outdat = adqs)

********************<  creating listing dates  ***********************;

DATA adqsall_1;
    SET adqs;
    newqsdtc = substr(QSDTc, 1,10);
    newdate=input(newqsdtc,yymmdd10.);
    IF QSEVLINT = '-P6M' THEN QSEVINTX = 'Last 6 months';
    IF QSEVLINT = '-P24M' THEN QSEVINTX = 'Last 24 months';
    WHERE PARCAT1 IN('COLUMBIA-SUICIDE SEVERITY RATING SCALE (BAYER) BASELINE/SCREENING (ECOA)'
          'COLUMBIA-SUICIDE SEVERITY RATING SCALE (BAYER) SINCE LAST VISIT (ECOA)')
          AND DTYPE not in ( 'COPY' 'LOCF') ;
    RUN;

%m_create_dtl(inputds=adqsall_1, varname= newqsdtl);

*********************< creating listing variable **************************;

DATA adqs_ss;
    SET adqsall_1;
    FORMAT new_AVALC $200.;
    DOC = put(ADT, date9.);
    intvl = propcase(QSEVINTX);
    ques_cat = propcase (PARCAT2);
    IF AVALC = 'Y' THEN new_AVALC = 'Yes';
    ELSE IF AVALC = 'N' THEN new_AVALC = 'No';
    ELSE new_AVALC = AVALC;
    rsp_stats= strip(propcase(new_AVALC))||strip(propcase(QSSTAT));
    LABEL newqsdtl   = 'Date of Completion'
          intvl      = 'Evalution Interval'
          ques_cat   = 'Category of Question'
          PARAMCD    = 'Question'
          rsp_stats  = 'Response/Completion status'
          AVISITN    = 'Visit'
          TRT01AN    = 'Actual Treatment Group';
RUN;

PROC SORT DATA =adqs_ss ;
    BY &treat_var. SASR newdate AVISITN QSEVINTX PARAMCD AVALC;
RUN;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = adqs_ss
  , page     = &treat_var.
  , by       = SASR AVISITN newdate newqsdtl
  , var      = intvl ques_cat PARAMCD rsp_stats
  , order    = newdate
  , optimal  = Y
  , maxlen   = 25
  , space    = 2
  , split    = '/*'
  , hsplit   = #
  , layout   = Standard
  , bylen    = 10
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();
