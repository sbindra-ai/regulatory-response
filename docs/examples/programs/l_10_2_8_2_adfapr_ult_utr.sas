/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_8_2_adfapr_ult_utr);
/*
 * Purpose          : Ultrasound Uterus
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 17OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_8_2_adfapr_ult_utr.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/

%load_ads_dat(adsl_view , adsDomain = adsl , where =  &saf_cond )
%extend_data(indat = adsl_view, outdat = adsl)

DATA PR;
    SET sp.pr;
     WHERE PRCAT = 'GYNECOLOGICAL EXAMINATION'
           AND PRSCAT = "ULTRASOUND UTERUS";
     KEEP USUBJID VISITNUM VISIT PRTRT PRLNKID PRSTDTC PROCCUR PRSTAT PRREASND PRSTDTC;
RUN;

%extend_data(indat = pr, outdat = pr_all)

DATA faPR;
    SET sp.fapr;
     WHERE FASCAT = 'ULTRASOUND UTERUS';
     KEEP USUBJID VISITNUM VISIT FALNKID FAREASND FACAT FASTAT FATESTCD FADTC FATEST FASCAT FAORRES FAEVALID;
RUN;
%extend_data(indat = fapr, outdat = fapr_all)

************************< creating listing dates  *********************************;

%m_create_dtl(inputds=fapr_all, varname= FADTL);
%m_create_dtl(inputds=pr_all, varname= PRSTDTL);

*****************************<  preparing data ******************************;

PROC SORT DATA = adsl (KEEP = &subj_var.  SASR  &treat_var. );    BY &subj_var. ;RUN;
PROC SORT DATA = pr_all ; BY &subj_var.  VISITNUM PRLNKID;RUN;
PROC SORT DATA = fapr_all ; BY &subj_var.  VISITNUM FALNKID;RUN;

DATA f_pr;
MERGE  pr_all (IN=a) adsl(IN=b) ;
FORMAT PROCCUR $x_ny.  ;
BY &subj_var.  ;
IF b;
RUN;

DATA f_fapr;
MERGE  fapr_all (IN=a) adsl(IN=b) ;
BY &subj_var.  ;
IF b;
RUN;

************************<   creating listing variables *****************************;

*******   PR - PRSTAT(Ultrasound performed), PRREASND (Reason not done) **********;
PROC SORT DATA=f_pr OUT = rsn_ndon
     (KEEP = TRT01AN SASR USUBJID VISITNUM VISIT PRLNKID PROCCUR PRSTAT PRREASND PRSTDTL);
    BY SASR USUBJID VISITNUM  PRSTDTL PRLNKID TRT01AN;
RUN;

*******   FAPR - Endometrium visualized, Thinkness  **********;

DATA adfapr_ul_ut;
    SET f_fapr;
    WHERE FATEST NOT IN( '' 'Findings About Events or Interventions'  );
RUN;

PROC SORT DATA = adfapr_ul_ut OUT=ul_ut_1;
    BY SASR USUBJID VISITNUM VISIT FAORRES FALNKID FADTL TRT01AN ;
RUN;

PROC TRANSPOSE DATA= ul_ut_1 OUT= ul_ut_2 (DROP = _NAME_ _LABEL_);
        BY SASR USUBJID VISITNUM VISIT FALNKID FADTL TRT01AN;
        VAR FAORRES ;
        ID FATEST ;
        IDLABEL FATEST;
RUN;

***************************< merge all datasets ****************************************;

PROC SORT DATA = rsn_ndon OUT=rsn_ndon1;
    BY SASR USUBJID VISITNUM VISIT PRLNKID TRT01AN ;
RUN;

PROC SORT DATA = ul_ut_2 OUT=ul_ut_3;
    BY SASR USUBJID VISITNUM VISIT FALNKID TRT01AN ;
RUN;

DATA final;
    MERGE rsn_ndon1(IN =a) ul_ut_3 (IN = b);
    BY SASR USUBJID VISITNUM VISIT TRT01AN ;
    WHERE VISITNUM NE .;
          LABEL PROCCUR = 'Endometrium assessment performed'
                VISIT = 'Visit'
                PRREASND = 'Reason endometrium assessment not performed'
                PRSTDTL = 'Date of examination'
                Endometrium_Visualized = 'Endometrium visualized'
                Thickness__Double_Layer_ = 'Thinkness (double layer in mm)';
RUN;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = final
  , page     = &treat_var.
  , by       = SASR VISIT PRSTDTL
  , var      = PROCCUR PRREASND Endometrium_Visualized  Thickness__Double_Layer_
  , optimal  = y
  , maxlen   = 30
  , split    =
  , layout   = Standard
  , bylen    = 20
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();