/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_8_1_adlb_preg);
/*
 * Purpose          : Clinical laboratory data: URIN Pregnancy Test
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 21NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_8_1_adlb_preg.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/

%m_create_ads_view(adsDomain = adlb, outDat = adlball)

%extend_data(indat = adlball, outdat = adlb)

********************< creating listing dates  ****************************;

DATA adlball_1;
    SET adlb;
    newdate= input(LBDTC, yymmdd10.);
    WHERE PARCAT1 = 'URINALYSIS' AND PARAMCD = "UPREG_A" AND &saf_cond;
    LABEL AVISITN = 'Visit'
          AVALC = 'Pregnancy'
          &treat_var. = 'Actual treatment group';
RUN;

%m_create_dtl(inputds=adlball_1, varname= LBDTL);


**********************< creating listing variable  *************************;

PROC SORT DATA = adlball_1 out = adlb_preg;
    BY SASR AVISITN ADT PARAMN;
RUN;

data adlb_preg;
    set adlb_preg;
    LABEL  LBDTL = 'Specimen Collection Date';
RUN;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

/*%set_titles_footnotes(tit1 = "Listing 10.2.8.1/8: Clinical laboratory data: Urine Pregnancy Test");*/

%MTITLE;

%datalist(
    data     = adlb_preg
  , page     = &treat_var.
  , by       = SASR AVISITN newdate LBDTL
  , var      = AVALC
  , order    = newdate
  , optimal  = y
  , maxlen   = 30
  , space    = 10
  , split    =
  , layout   = Standard
  , bylen    = 22
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();