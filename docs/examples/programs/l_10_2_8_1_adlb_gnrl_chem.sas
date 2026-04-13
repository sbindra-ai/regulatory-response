/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_8_1_adlb_gnrl_chem);
/*
 * Purpose          : Clinical laboratory data: General chemistry
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 21NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_8_1_adlb_gnrl_chem.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/


%m_create_ads_view(adsDomain = adlb, outDat = adlball)

%extend_data(indat = adlball, outdat = adlb)

*****************< creating listing dates  ******************************;

DATA adlball_1;
    SET adlb;
    WHERE PARCAT1 = 'GENERAL CHEMISTRY' and &saf_cond;
RUN;

%m_create_dtl(inputds=adlball_1, varname= LBDTL);

********************<  creating listing variable  ***************************;
***<"Specimen collection end date" and "Fasting" information not collected  *;

PROC SQL;
    CREATE TABLE adlb_chem AS
    SELECT SASR,PARAMN, &treat_var. 'Actual Treatment Group',AVISITN 'Visit',
        LBDTL       'Specimen Collection Date',PARAMCD,
        LBTEST 'Laboratory Test',AVALC 'Value',
        ANRIND   'Flag',
        ANRLO   'Normal Range Lower Limit' ,
        ANRHI   'Normal Range Upper Limit' ,
        LBSTRESU  'Standard Unit'
        FROM adlball_1
        ORDER BY &treat_var.,&subj_var.,AVISITN ,PARAMN;
RUN;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = adlb_chem
  , page     = &treat_var.
  , by       = SASR AVISITN
  , var      = LBDTL LBTEST AVALC ANRIND ANRLO ANRHI LBSTRESU
  , optimal  = Y
  , split    =
  , layout   = Standard
  , bylen    = 22
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();