/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_8_3_advs_phy_exm);
/*
 * Purpose          : Physcial Examination
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 21NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_8_3_advs_phy_exm.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/

%m_create_ads_view(adsDomain = advs, outDat = advsall)

%extend_data(indat = advsall, outdat = advs)

*************************< creating listing dates  ******************************;

DATA advsall_1;
    SET advs;
    newdate= input(VSDTC, yymmdd10.);
    WHERE NOT missing (&treat_var.) AND
          NOT missing (paramcd) AND
          paramcd IN ('BMI' 'HEIGHT' 'HIPCIR' 'WAISTHIP' 'WEIGHT' 'WSTCIR') ;
    KEEP SASR USUBJID VISIT AVISITN TRT01AN ADT PARAMCD AVALC VSDTC newdate;
RUN;

%m_create_dtl(inputds=advsall_1, varname= VSDTL);

****************************<  creating listing variable  *************************;

PROC SORT DATA= advsall_1 OUT= advsall_2 NODUPKEY;
 BY SASR USUBJID newdate AVISITN  ADT TRT01AN PARAMCD AVALC VSDTL ;
RUN;

PROC TRANSPOSE DATA =advsall_2 OUT = advsall_3  (DROP =_NAME_ _LABEL_);
    BY SASR USUBJID newdate AVISITN ADT TRT01AN VSDTL NOTSORTED;
    ID PARAMCD;
    VAR AVALC;
    IDLABEL PARAMCD;
RUN;

DATA advs_final;
    SET advsall_3;
    LABEL AVISITN = 'Visit'
          TRT01AN= 'Actual Treatment Group'
          VSDTL      = 'Measurement Date'
          Body_Mass_Index__kg_m2_ = 'Body Mass Index (kg/m2)'
          Height__cm_  = 'Height (cm)'
          Weight__kg_    = 'Weight (kg)'
          Hip_Circumference__cm_ = 'Hip circumference (cm)'
          Waist_Circumference__cm_ = 'Waist circumference(cm)'
          Waist_to_Hip_Ratio = 'Waist to Hip Ratio';
RUN;

PROC SORT DATA =advs_final ;
    BY SASR AVISITN  ;
RUN;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = advs_final
  , page     = &treat_var.
  , by       = SASR AVISITN newdate VSDTL
  , var      = Body_Mass_Index__kg_m2_ Height__cm_  Weight__kg_ Waist_to_Hip_Ratio Hip_Circumference__cm_   Waist_Circumference__cm_
  , order    = newdate
  , optimal  = y
  , maxlen   = 30
  , split    =
  , hsplit   = #
  , bylen    = 16
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();