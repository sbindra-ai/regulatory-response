/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(
      name            = l_10_2_4_su_demo_smoke);
/*
 * Purpose          : Smoking history
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gniiq (Mayur Parchure) / date: 13OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/l_10_2_4_su_demo_smoke.sas (gniiq (Mayur Parchure) / date: 13OCT2023)
 ******************************************************************************/


DATA SU;
    SET sp.su;
RUN;

%m_create_dtl(
    inputds = su
  , varname = SUSTDTL)

%m_create_dtl(
    inputds = su
  , varname = SUENDTL)

%extend_data(indat = ads.adsl, outdat = adsl)

PROC SQL NOPRINT;
    CREATE TABLE su_1 AS
        SELECT a.*,b.SASR,b.TRT01PN
        FROM su AS a LEFT JOIN adsl AS b
        ON a.USUBJID=b.USUBJID
        ORDER BY &subj_var., b.SASR;
    CREATE TABLE su_2 AS
        SELECT * FROM su_1
        ORDER BY &subj_var., SASR;
QUIT;

DATA adsu_01;
    MERGE su_1(WHERE=(SUTRT='CIGARETTES') IN=a)  su_2(KEEP=&subj_var. SASR SUTRT SUNCF SUSTTPT TRT01PN WHERE=(SUTRT_ NE 'CIGARETTES' /*2 - OTHER TOBACCO*/)
                                                RENAME=(SUNCF=_tabac SUTRT=SUTRT_ SUSTTPT=SUSTTPT_ TRT01PN=TRT01PN_) IN=b);
    BY &subj_var. SASR;
    IF a OR b;
    LENGTH SUB_ASR $40;
    SUB_ASR=SASR;
    IF missing(SUSTTPT) AND ~missing(SUSTTPT_) THEN SUSTTPT=SUSTTPT_;
    IF missing(TRT01PN) AND ~missing(TRT01PN_) THEN TRT01PN=TRT01PN_;
    LABEL SUB_ASR = "Subject Identifier/#Age/ Sex/ Race";
    LABEL  SUNCF='History of#Cigarette Smoking';
    LABEL  SUSTDTL='Date of#Start of#Cigarette Smoking';
    LABEL  SUENDTL='Date of#End of#Cigarette Smoking';
    LABEL _TABAC ='Status of Other#Tobacco Smoking Type';
    LABEL SUTRT_ = 'Type of Other#Tobacco/ Nicotine#Smoking Type';
    LABEL &treat_var_listings_part = "Planned Treatment Group";
RUN;

PROC SORT DATA=adsu_01;
    BY SASR;
RUN;

%MTITLE;

  %datalist(
      data    = adsu_01
    , page   = &treat_var_listings_part.
    , by      = SUB_ASR
    , var     = SUNCF SUSTDTL SUENDTL SUSTTPT _TABAC SUTRT_
    , hsplit  = "#"
    , optimal = yes
    , maxlen  = 25
    , bylen   = 13
  )

%endprog()