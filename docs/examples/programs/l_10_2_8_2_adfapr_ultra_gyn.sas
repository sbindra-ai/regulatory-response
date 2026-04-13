/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_8_2_adfapr_ultra_gyn);
/*
 * Purpose          : Ultrasound Gynecological
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 17NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_8_2_adfapr_ultra_gyn.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/
%load_ads_dat(adsl_view , adsDomain = adsl , where =  &saf_cond )
%extend_data(indat = adsl_view, outdat = adsl)

DATA PR;
    SET sp.pr;
     WHERE PRCAT = 'GYNECOLOGICAL EXAMINATION'
           AND PRSCAT = " ";
     KEEP USUBJID VISITNUM VISIT PRTRT PRLNKID PRSTDTC PROCCUR PRSTAT PRREASND PRSTDTC;
RUN;

%extend_data(indat = pr, outdat = pr_all)

DATA faPR;
    SET sp.fapr;
     WHERE FACAT = 'ULTRASOUND'
           AND FATEST IN ( 'Method of Examination' 'Pregnancy' 'Interpretation');
     FADTC = substr (FADTC,1,10 );
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

**********************< creating listing variables ******************************;

*******   PR - PRSTAT(Ultrasound performed), PRREASND (Reason not done) **********;
PROC SORT DATA=f_pr OUT = rsn_ndon
     (KEEP = TRT01AN SASR USUBJID VISITNUM VISIT PRLNKID PROCCUR PRSTAT PRREASND PRSTDTL);
    BY SASR USUBJID VISITNUM  PRSTDTL PRLNKID TRT01AN;
RUN;

*******   FAPR - Method of Examination , Pregnancy, Interpretation **********;
DATA ultra2;
     SET f_fapr;
     BY SASR USUBJID VISITNUM  FADTL;
      IF FATESTCD = 'METHEX' AND  FAORRES = 'Abdominal' THEN aval_seq = 1 ;
      IF FATESTCD = 'METHEX' AND  FAORRES = 'Transrectal' THEN aval_seq = 2;
      WHERE FATEST NE ' ';
RUN;

PROC SORT DATA = ultra2 OUT=ultra3;
    BY SASR USUBJID VISITNUM VISIT FADTL FALNKID FASTAT TRT01AN FAREASND aval_seq ;
    WHERE FATEST NE ' ';
RUN;

PROC TRANSPOSE DATA = ultra3 OUT= ultra4 (DROP=_name_ _LABEL_ );
    BY SASR USUBJID VISITNUM VISIT FADTL FALNKID FASTAT TRT01AN FAREASND aval_seq ;
    ID FATEST;
    VAR FAORRES;
RUN;

***************************< merge all datasets ****************************************;


PROC SORT DATA = rsn_ndon OUT=rsn_ndon1;
    BY SASR USUBJID VISITNUM VISIT PRLNKID TRT01AN ;
RUN;

PROC SORT DATA = ultra4 OUT=ultra5;
    BY SASR USUBJID VISITNUM VISIT FALNKID TRT01AN ;
RUN;

DATA final;
    MERGE rsn_ndon1(IN =a) ultra5 (IN = b);
    BY SASR USUBJID VISITNUM VISIT TRT01AN ;
    WHERE VISITNUM NE .;
          LABEL PROCCUR = 'Ultrasound performed'
                VISIT = 'Visit'
                PRSTDTL = 'Measurement Date'
                Method_of_Examination = 'Method of Examination'
                Pregnancy = 'Pregnancy'
                Interpretation = 'Interpretation';
RUN;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = final
  , page     = &treat_var.
  , by       = SASR VISIT PRSTDTL
  , var      = PROCCUR PRREASND Method_of_Examination Pregnancy Interpretation
  , optimal  = y
  , maxlen   = 15
  , space    = 1
  , split    =
  , layout   = Standard
  , bylen    = 12
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();
