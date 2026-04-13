/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name     = l_10_2_4_adcm_demo);
/*
 * Purpose          : Listing for Prior and concomitant medications
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gniiq (Mayur Parchure) / date: 13OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/l_10_2_4_adcm_demo.sas (gniiq (Mayur Parchure) / date: 13OCT2023)
 ******************************************************************************/

%m_create_ads_view(
    adsDomain = adcm
  , outDat    = adcmall
)

%extend_data(indat = adcmall, outdat = adcm)

%m_create_dtl(inputds=adcm, varname= CMSTDTL);

%m_create_dtl(inputds=adcm, varname= CMENDTL);

DATA adcm2;
     LENGTH  CMDOSE_UNI_FREQ $200 SUB_ASR $40;
     SET adcm;
      SUB_ASR = SASR;
     LABEL sub_asr                  = "Subject#Identifier#/Age/Sex/Race";
     LABEL CMTRT                   = "Reported#Name#of Drug,#Medication, or#Therapy";
     LABEL CMROUTE                  = "Route#of Administration";
     LABEL cmdose_uni_freq          = "Dose,#Unit,#Frequency";
     LABEL cmstdtl                  = "Start#Date of#Medication";
     LABEL cmendtl                  = "End#Date of#Medication";
     LABEL cmenrtpt                 = "End#Relative#to Last Visit";
     LABEL &treat_var_listings_part = "Planned Treatment Group";
     LABEL CMSTRF                   = "Start#Relative#to#Treatment";
     LABEL CMENRF                   = "End#Relative#to#Treatment";

     CMDOSE_UNI_FREQ = catx(' ',CMDOSE,CMDOSU,CMDOSFRQ);
     CMINDC=upcase(CMINDC);
     IF CMINDC = 'OTHER' THEN CMINDC=catx(": ", CMINDC, CMINDCO);
     CMTRT = upcase(CMTRT);
RUN;

%MTITLE;

*** As in TLF: Exclude Start Time and End Time (not reported) ***;
%datalist(
    data     = adcm2
  , page     = &treat_var_listings_part.
  , by       = SUB_ASR ASEQ
  , var      = CMTRT CMDOSE_UNI_FREQ CMROUTE CMSTRF CMENRF CMSTDTL CMENDTL CMENRTPT CMINDC
  , order    = ASEQ
  , freeline = ASEQ
  , optimal  = N
  , maxlen   = 10
  , split    = '/*'
  , hsplit   = '#'
  , bylen    = 15
  , hc_align = CENTER
  , hn_align = CENTER
)

%endprog()

