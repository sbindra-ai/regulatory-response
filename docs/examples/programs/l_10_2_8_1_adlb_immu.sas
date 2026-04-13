/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_8_1_adlb_immu);
/*
 * Purpose          : Clinical laboratory data: Immunology
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 21NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_8_1_adlb_immu.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/

%m_create_ads_view(adsDomain = adlb, outDat = adlball)

%extend_data(indat = adlball, outdat = adlb)

*****************< creating listing dates  *****************************;

DATA adlball_1;
    SET adlb;
    newdate= input(LBDTC, yymmdd10.);
    WHERE PARCAT1 = 'IMMUNOLOGY' AND PARAMCD NE " " and &saf_cond;
RUN;

%m_create_dtl(inputds=adlball_1, varname= LBDTL);

********************< creating listing variable  ***********************;

PROC SORT DATA = adlball_1 OUT = adlb_immu ;
    BY TRT01AN SASR AVISITN ADT LBDTL PARAMCD;
RUN;

PROC TRANSPOSE DATA =adlb_immu OUT = adlb_immu_2 (DROP=_name_ _LABEL_ ) ;
    BY TRT01AN SASR AVISITN ADT LBDTL newdate;
    ID PARAMCD;
    VAR avalc;
RUN;

DATA adlb_immu_final;
    SET adlb_immu_2;
    LABEL AVISITN = 'Visit'
          TRT01AN = 'Actual Treatment Group'
          Hepatitis_B_Virus_Surface_Antige = 'Hepatitis B Virus Surface Antibody'
          Hepatitis_C_Virus_Antibody_Surfa= 'Hepatitis C Virus Antibody'
          LBDTL = 'Specimen Collection Date'
          HCV_PCR_Viral_Load_in_Serum___Po = 'HCV-RNA';
RUN;

PROC SORT DATA =adlb_immu_final ;
    BY &treat_var. SASR  AVISITN ;
RUN;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = adlb_immu_final
  , page     = &treat_var.
  , by       = SASR AVISITN newdate LBDTL
  , var      = Hepatitis_B_Virus_Surface_Antige Hepatitis_C_Virus_Antibody_Surfa HCV_PCR_Viral_Load_in_Serum___Po
  , order    = newdate
  , optimal  = y
  , maxlen   = 16
  , space    = 5
  , split    =
  , layout   = Standard
  , bylen    = 22
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();