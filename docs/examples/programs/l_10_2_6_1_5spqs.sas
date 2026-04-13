/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_6_1_5spqs);
/*
 * Purpose          : All Questionnaires
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 21NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_6_1_5spqs.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/

*****************************<  calling data as per requirement ******************************;

%load_ads_dat(adsl_view , adsDomain = adsl , where =  &fas_cond )
%extend_data(indat = adsl_view, outdat = adsl)

DATA QS;
    SET sp.qs;
     QSDTC = substr(QSDTC,1, 10);
      newdate= input(QSDTC, yymmdd10.);
     WHERE QSCAT = "PATIENT GLOBAL IMPRESSION VASOMOTOR SYMPTOMS V1.0"
              AND QSSCAT= "VASOMOTOR SYMPTOMS-FREQUENCY OF MODERATE TO SEVERE HOT FLASHES" ;
     KEEP usubjid VISITNUM VISIT QSDTC QSCAT QSSCAT QSTEST QSORRES newdate;
RUN;

%extend_data(indat = qs, outdat = qs_all)

*****************************<  creating listing dates  ******************************;

%m_create_dtl(inputds=qs_all, varname= QSDTL);

*****************************<  preparing data ******************************;

PROC SORT DATA = adsl (KEEP = &subj_var. SASR &treat_var_listings_part. );    BY &subj_var. ;RUN;
PROC SORT DATA = qs_all ; BY &subj_var. VISITNUM QSDTC;;RUN;

DATA qs_final;
    MERGE  adsl (IN=a) qs_all(IN=b) ;
    BY &subj_var.  ;
    IF b;
    ATTRIB n_ans FORMAT = $200. ;
    n_QSTEST = strip(scan(QSTEST, 2, "-"));
    IF QSSCAT = ' ' THEN QSSCAT = 'NA';
        IF find( QSORRES, ':' ) THEN
            n_ans =strip( substr(QSORRES, 4, 100));
           ELSE n_ans = QSORRES;
        IF n_ans = 'Y' THEN n_ans = 'YES';
        IF n_ans = 'N' THEN n_ans = 'NO';
    LABEL QSSCAT ='Category of Question'
          QSDTL = 'Date of Completion'
          SASR = 'Subject Identifier/# Age/ Sex/ Race'
          VISIT = 'Visit'
          n_QSTEST ='Question'
          n_ans  ='Response'
          &treat_var_listings_part. = 'Planned treatment group';
RUN;

*****************************<  creating macro******************************;

PROC SORT DATA = qs_final OUT = final ;
        BY &treat_var_listings_part. &subj_var. newdate VISIT QSDTL;
        WHERE QSCAT = "PATIENT GLOBAL IMPRESSION VASOMOTOR SYMPTOMS V1.0"
              AND QSSCAT= "VASOMOTOR SYMPTOMS-FREQUENCY OF MODERATE TO SEVERE HOT FLASHES" ;
RUN;

%LET label ='Patient Global Impression of Change (PGI-C)';

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = final
  , page     = &treat_var_listings_part.
  , by       = SASR newdate VISIT QSDTL QSSCAT
  , var      = n_QSTEST n_ans
  , order    = newdate
  , optimal  = Y
  , maxlen   = 35
  , split    = '/*'
  , hsplit   = #
  , layout   = Standard
  , bylen    = 15
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();

