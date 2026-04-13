/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_8_2_adqs_lsmb);
/*
 * Purpose          : Liver Safety Monitoring Board
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 17OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_8_2_adqs_lsmb.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/
/* Changed by       : gniiq (Mayur Parchure) / date: 26MAR2024
 * Reason           : programming updated for truncated values in n_ans
 ******************************************************************************/

*close liver monitoring;

*****************************<  calling data as per requirement ******************************;

%load_ads_dat(adsl_view , adsDomain = adsl , where =  &saf_cond )
%extend_data(indat = adsl_view, outdat = adsl)

DATA QS;
    SET sp.qs;
     QSDTC = substr(QSDTC,1, 10);
      newdate= input(QSDTC, yymmdd10.);
     WHERE QSCAT = 'CLOSE LIVER OBSERVATION CASE REVIEW (V1.0)';
     KEEP usubjid VISITNUM VISIT QSDTC QSCAT QSSCAT QSTEST QSORRES QSEVALID newdate ;
RUN;

%extend_data(indat = qs, outdat = qs_all)

*****************************<  creating listing dates  ******************************;

%m_create_dtl(inputds=qs_all, varname= QSDTL);

*****************************<  preparing data ******************************;

PROC SORT DATA = adsl (KEEP = USUBJID SASR &treat_var. );    BY usubjid ;RUN;
PROC SORT DATA = qs_all ; BY usubjid VISITNUM newdate;;RUN;

DATA qs_final;
    MERGE  adsl (IN=a) qs_all(IN=b) ;
    BY usubjid  ;
    IF b;
    ATTRIB n_ans FORMAT = $200. ;
    n_QSTEST = strip(scan(QSTEST, 2, "-"));
    IF QSSCAT = ' ' THEN QSSCAT = 'NA';
        n_ans = QSORRES;
        IF n_ans = 'Y' THEN n_ans = 'YES';
        IF n_ans = 'N' THEN n_ans = 'NO';
    LABEL QSSCAT ='Category of Question'
          QSDTL = 'Date of Completion'
          VISIT = 'Visit'
          n_QSTEST ='Question'
          n_ans  ='Response'
          &treat_var. = 'Actual treatment group'
          QSEVALID= 'Reader';
RUN;

*****************************<  creating macro******************************;

PROC SORT DATA = qs_final OUT = final ;
        BY  USUBJID newdate VISIT ;
RUN;

%LET label ='Close liver observation case review';

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data      = final
  , page      = &treat_var.
  , by        = SASR newdate QSDTL
  , var       = n_QSTEST n_ans QSEVALID
  , order     = newdate
  , order_var =
  , optimal   = Y
  , maxlen    = 35
  , split     = '/*'
  , hsplit    = #
  , layout    = Standard
  , bylen     = 15
  , hc_align  = CENTER
  , hn_align  = CENTER
);

%endprog();