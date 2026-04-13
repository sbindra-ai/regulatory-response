/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_1_7_adsl_rand);
/*
 * Purpose          : Randomization Scheme and Codes
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gniiq (Mayur Parchure) / date: 13OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/l_10_1_7_adsl_rand.sas (gniiq (Mayur Parchure) / date: 13OCT2023)
 ******************************************************************************/

%create_ads_view(
    adsDomain = adsl
  , outDat    = adsl_view
)

%extend_data(indat = adsl_view, outdat = adsl)

*<*****************************************************************************************;
*< Create listing Randomization scheme and codes out of ADSL dataset                       ;
*<*****************************************************************************************;
DATA adsl_final (RENAME=(randdt=randtl));
     *** Include only randomized patients ***;
     SET adsl(WHERE = (&rand_cond));
     *** TLF spec: Listing is sorted by randomization number ***;
     randno_sort = randno;
     LABEL SUBJID     = 'Subject#Identifier';
     LABEL RANDNO     = 'Randomization#Number';
     LABEL RANDDT     = 'Date of Randomization';
     LABEL &treat_var_listings_part = 'Planned Treatment Group';
     FORMAT COUNTRY $3.;
     KEEP SUBJID RANDNO  RANDNO_SORT COUNTRY &treat_var_listings_part RANDDT RANDFL;
RUN;

PROC SORT DATA=adsl_final;
    BY randno_sort subjid ;
RUN;

%MTITLE;

*** AS IN TLF: Listing is sorted by randomized number ***;
%datalist(
    data     = adsl_final
  , by       = RANDNO_SORT SUBJID RANDNO
  , var      = COUNTRY &treat_var_listings_part RANDTL
  , order    =  RANDNO_SORT
  , optimal  = NO
  , maxlen   = 20
  , hsplit   = "#"
  , bylen    = 20
  , hc_align = CENTER
  , hn_align = CENTER
);

OPTIONS MISSING=.;

%endprog();
