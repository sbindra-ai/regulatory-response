/*******************************************************************************
 * Bayer AG
 * Study            : 21652 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_6_1_8spqs);
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
 * Author(s)        : eokcw (Vijesh Shrivastava) / date: 27DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/l_10_2_6_1_8spqs.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/

*****************************<  calling data as per requirement ******************************;
%load_ads_dat(adsl_view , adsDomain = adsl , where =  &fas_cond  )
%extend_data(indat = adsl_view, outdat = adsl)

DATA QS;
    SET sp.qs;
     QSDTC = substr(QSDTC,1, 10);
      newdate= input(QSDTC, yymmdd10.);
      if QSSCAT="MORNING HOT FLASH DIARY" then do;
          QSSCATN = 1;
      END;
      else do;
          QSSCATN = 2;
      END;

     WHERE QSCAT IN ('TWICE DAILY HOT FLASH DIARY V2.0')      ;
     KEEP &subj_var. VISITNUM VISIT QSDTC QSTESTCD QSCAT QSSCAT QSSCATN QSTEST QSORRES newdate;
RUN;

%extend_data(indat = qs, outdat = qs_all)

*****************************<  creating listing dates  ******************************;

%m_create_dtl(inputds=qs_all, varname= QSDTL);

*****************************<  preparing data ******************************;

PROC SORT DATA = adsl (KEEP = &subj_var. SASR &treat_var_listings_part. );
    BY &subj_var. ;RUN;

PROC SORT DATA = qs_all (KEEP = &subj_var. QSTEST qstestcd QSCAT QSSCAT QSSCATN QSORRES QSDTL VISIT newdate) OUT= qs_sort ;
    BY &subj_var. newdate VISIT QSDTL QSCAT QSSCAT  ;;RUN;


PROC TRANSPOSE DATA = qs_sort OUT= qs_trans(DROP = _NAME_ _LABEL_ );
    ID QSTESTCD QSSCATN;
    VAR QSORRES;
    BY &subj_var. newdate QSDTL QSCAT;
       IDLABEL QSTESTCD ;
RUN;



PROC SORT DATA = qs_trans ;    BY &subj_var. ;RUN;

DATA qs_final;
    MERGE  adsl (IN=a) qs_trans(IN=b) ;
    BY &subj_var.  ;
    IF b;
    ATTRIB n_ans FORMAT = $200. ;
            n_ans = substr(HFDB202D1, 3, 100);
        IF HFDB2021= 'Y' THEN HFDB2021 = 'YES';
        IF HFDB2021 = 'N' THEN HFDB2021 = 'NO';
        IF HFDB2022= 'Y' THEN HFDB2022 = 'YES';
        IF HFDB2022 = 'N' THEN HFDB2022 = 'NO';

    LABEL QSDTL = 'Date of Completion'
          SASR = 'Subject Identifier/# Age/ Sex/ Race'
          n_ans  ='Did Hot Flashes Disturb Sleep?'
          HFDB2021 = 'Have Any Hot Flashes'
          HFDB202B1 = 'Total Moderate Hot Flashes'
          HFDB202C1= 'Total Severe Hot Flashes'
          HFDB202A1 = 'Total Mild Hot Flashes'
          HFDB2011 = 'Total Times Woke Up'
          HFDB2022 = 'Have Any Hot Flashes'
          HFDB202B2 = 'Total Moderate Hot Flashes'
          HFDB202C2= 'Total Severe Hot Flashes'
          HFDB202A2 = 'Total Mild Hot Flashes'
          &treat_var_listings_part. = 'Planned treatment group';
RUN;

PROC SORT DATA = qs_final OUT = final ;
        BY &treat_var_listings_part. &subj_var.  QSDTL;
RUN;

%LET label ='Hot Flash Daily Diary (HFDD)';

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = final
  , page     = &treat_var_listings_part.
  , by       = SASR newdate QSDTL
  , var      = ('Morning Diary' HFDB2021 n_ans HFDB2011 HFDB202A1 HFDB202B1 HFDB202C1 ) ('Evening Diary' HFDB2022 HFDB202A2 HFDB202B2 HFDB202C2 )
  , order    = newdate
  , optimal  = y
  , maxlen   = 15
  , split    =
  , hsplit   = #
  , layout   = Standard
  , bylen    = 15
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();