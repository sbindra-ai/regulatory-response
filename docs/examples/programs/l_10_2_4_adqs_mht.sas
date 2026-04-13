/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_4_adqs_mht);
/*
 * Purpose          : History of menopause hormone therapy
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gniiq (Mayur Parchure) / date: 07DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/l_10_2_4_adqs_mht.sas (gniiq (Mayur Parchure) / date: 13OCT2023)
 ******************************************************************************/


%m_create_ads_view(adsDomain = adqs, outDat = adqsall)

**********************<  creating listing dates  *****************************;

DATA adqsall_1;
    SET adqsall;
    WHERE PARCAT1 = 'HISTORY OF MENOPAUSE HORMONE THERAPY BAYER V1.0';
RUN;

%extend_data(indat = adqsall_1, outdat = adqs)

%m_create_dtl(inputds=adqs, varname= QSDTL);

************************<  creating listing variable  ************************;

DATA adqsall_final;
    SET adqs;
    LABEL QSSTAT = 'Assessment performed'
          QSREASND = 'Reason not performed'
          QSDTL = 'Date of assessment'
          PARAM = 'Question'
          AVALC = 'Response'
          &TREAT_VAR_LISTINGS_PART. = "Planned Treatment Group";;
RUN;

%MTITLE;

%datalist(
    data     = adqsall_final
  , page     = &TREAT_VAR_LISTINGS_PART.
  , by       = SASR
  , var      = QSDTL PARAM AVALC
  , optimal  = N
  , maxlen   = 15
  , split    =
  , hsplit   = "#"
  , layout   = Standard
  , bylen    = 15
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();
