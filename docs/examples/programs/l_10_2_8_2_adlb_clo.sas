/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_8_2_adlb_clo);
/*
 * Purpose          : General Chemistry for CLO
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 17OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_8_2_adlb_clo.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/

%m_create_ads_view(adsDomain = adlb, outDat = adlball)

%extend_data(indat = adlball, outdat = adlb)

**********************< creating listing dates  ************************;

DATA adlball_1;
    SET adlb;
    WHERE PARCAT1 = 'GENERAL CHEMISTRY' AND AVISITN = 500000;
    LBDTC=substr(lbdtc,1,10);
RUN;

%m_create_dtl(inputds=adlball_1, varname= LBDTL);

***********************<  creating listing variable  *********************;

DATA lb_clo;
    SET adlball_1;
    Prm = put(PARAMCD, $x_lbpar.);
    DOST = put(ADT, date9.);
    LABEL LBDTL = 'Date of Sample taken'
          AVALC = 'Value'
          prm ='Parameter'
          AVISITN = 'Visit'
          TRT01AN = 'Actual Treatment Group'
          PARCAT1 = 'CLO';
RUN;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = lb_clo
  , page     = &treat_var.
  , by       = SASR
  , var      = Prm LBDTL AVALC
  , optimal  = y
  , maxlen   = 30
  , space    = 5
  , split    =
  , layout   = Standard
  , bylen    = 22
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();