/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_7_adae_meddra);
/*
 * Purpose          : Adverse event terms and associated reported terms coded by MedDRA version
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 17OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_7_adae_meddra.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/

%load_ads_dat(adae_view, adsDomain = adae)

%extend_data(indat = adae_view, outdat = adae)

DATA adae_2;
SET adae;
    LABEL AEBODSYS_n = 'Primary System Organ Class'
          AEDECOD_n  = 'Preferred Term'
          AETERM_n   = 'Reported Term';
    AEBODSYS_n = upcase(AEBODSYS);
    AEDECOD_n  =upcase(AEDECOD)  ;
    AETERM_n =upcase(AETERM)  ;
RUN;

*< Sorting data alphabetically by primary system organ class and MedDRA preferred term.*;

PROC SORT DATA= adae_2 OUT= adae_med NODUPKEY;
    BY AEBODSYS_n AEDECOD_n ;
RUN;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = adae_med
  , by       = AEBODSYS_n AEDECOD_n
  , var      = AETERM_n
  , freeline = AEBODSYS_n
  , optimal  = y
  , maxlen   = 50
  , space    = 3
  , split    =
  , layout   = Standard
  , bylen    = 30
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();