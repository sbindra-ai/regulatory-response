/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_6_2_sppc_plsm_cnct);
/*
 * Purpose          : Concentrations for Elinzanetant in Plasma
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 04DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/l_10_2_6_2_sppc_plsm_cnct.sas (egavb (Reema S Pawar) / date: 29NOV2023)
 ******************************************************************************/
proc sort data=ads.adsl out=adsl(keep= usubjid SAFFL SASR TRT01AN );
     by  USUBJID ;
     where saffl = 'Y';
RUN;

proc sort data=sp.pc out=pc
     (keep= USUBJID PCTEST PCCAT PCSCAT PCDTC PCORRES PCTMDEV PCORRESU PCSTRESC PCSTRESN PCSTRESU PCSTAT PCREASND PCEXDOSE PCEXDOSU PCSPEC PCEXTRT VISITNUM VISIT PCTPT PCTPTNUM PCTPTREF PCSTRF PCDTPT PCDTPTNM);
     by  USUBJID ;
RUN;

DATA slpc (rename =( PC_date = PCDTC ));
    MERGE pc (IN=a) adsl (IN=b);
    BY usubjid ;
    IF a;
    PC_date = substr(PCDTC,1,10) ;
    PC_Time= substr(PCDTC,12,5) ;
    LABEL VISIT = 'Visit'
          PCTEST = 'Pharmacokinetic Test Name'
          PC_Time = 'Start Time of PK Sample Collection'
          PCTPT ='Scheduled Rel Start Time of PK Sample'
          PCORRES = 'Result (ug/L)'
          &treat_var. = 'Actual Treatment Group';
    drop PCDTC;
RUN;

%m_create_dtl(inputds=slpc, varname= PCDTL);

DATA pc_final;
    SET slpc;
    if PCORRES = '' then PCORRES = PCSTAT;
    LABEL PCDTL = 'Date of PK Sample';
          keep SASR VISIT PCTEST PCDTL VISITNUM  PC_Time PCTPT PCORRES &treat_var.;
RUN;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = pc_final
  , page     = &treat_var.
  , by       = SASR VISIT PCDTL PC_Time  PCTEST
  , var      = PCTPT PCORRES
  , optimal  = Y
  , maxlen   = 50
  , split    = '/*'
  , hsplit   = #
  , layout   = Standard
  , bylen    = 20
  , hc_align = CENTER
  , hn_align = CENTER
);

****************************************************;
*<clean up;
****************************************************;

%endprog();