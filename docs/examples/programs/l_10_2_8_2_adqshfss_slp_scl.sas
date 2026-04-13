/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_8_2_adqshfss_slp_scl);
/*
 * Purpose          : Sleepiness Scale
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 21NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_8_2_adqshfss_slp_scl.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/

*****************************<  calling data as per requirement ******************************;
%load_ads_dat(adsl_view , adsDomain = adsl , where =  &saf_cond  )
%extend_data(indat = adsl_view, outdat = adsl)

DATA QS;
    SET sp.qs;
     QSDTC = substr(QSDTC,1, 10);
      newdate= input(QSDTC, yymmdd10.);

     WHERE QSCAT IN ('SLEEPINESS SCALE V1.0')      ;
     KEEP &subj_var. VISITNUM VISIT QSDTC QSTESTCD QSCAT QSSCAT QSTEST QSEVINTX QSORRES newdate;
RUN;

%extend_data(indat = qs, outdat = qs_all)

*****************************<  creating listing dates  ******************************;

%m_create_dtl(inputds=qs_all, varname= QSDTL);

*****************************<  preparing data ******************************;

PROC SORT DATA = adsl (KEEP = &subj_var. SASR &treat_var. &treat_var_listings_part. );
    BY &subj_var. &treat_var.;RUN;

PROC SORT DATA = qs_all (KEEP = &subj_var. QSTEST qstestcd QSCAT QSSCAT QSEVINTX QSORRES QSDTL VISIT newdate) OUT= qs_sort ;
    BY &subj_var. newdate VISIT QSDTL QSCAT QSSCAT  ;;RUN;

DATA adqshfss_final;
    MERGE  adsl (IN=a) qs_sort(IN=b) ;
    BY &subj_var.   ;
    FORMAT qsn $200.;
test = substr(QSTEST,8);
    qsn = compbl( propcase(test )||lowcase(QSEVINTX));
    Response = lowcase(QSORRES);
    LABEL VISIT = 'Visit'
          QSDTL = 'Date of Completion'
          qsn = 'Question'
          Response= 'Response';
RUN;

PROC SORT DATA = adqshfss_final NODUPKEY;
    BY SASR newdate VISIT  QSTEST QSEVINTX;
RUN;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = adqshfss_final
  , page     = &treat_var.
  , by       = SASR newdate
  , var      = QSDTL qsn Response
  , order    = newdate
  , optimal  = Y
  , maxlen   = 25
  , split    = '/*'
  , hsplit   = #
  , layout   = Standard
  , bylen    = 16
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();
