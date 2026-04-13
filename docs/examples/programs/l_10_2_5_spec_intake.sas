/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_5_spec_intake);
/*
 * Purpose          : Study drug intake documentation
 * Programming Spec : 
 * Validation Level : 1 - Verification by Revie
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 17OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_5_spec_intake.sas (egavb (Reema S Pawar) / date: 22JUN2023)
 ******************************************************************************/

%load_ads_dat(adsl_view , adsDomain = adsl , where =  &saf_cond )

PROC SORT DATA=sp.ec OUT=ecall/*(KEEP =USUBJID ECMOOD ECTPT ECSTDTC ECENDTC ECDOSE ECTRT ECDOSU ECDOSFRM ECDOSFRQ ECROUTE)*/;
    BY usubjid ECSTDTC;
RUN;

%extend_data(indat = adsl_view, outdat = adsl)
%extend_data(indat = ecall, outdat = ec)

DATA ec1;
    SET ec;
    ECSTDTC = substr(ECSTDTC,1, 10);
    ECENDTC = substr(ECENDTC,1, 10);
RUN;

%m_create_dtl(inputds=ec1, varname= ECENDTL);
%m_create_dtl(inputds=ec1, varname= ECSTDTL );

PROC SORT DATA = ec1 (KEEP =usubjid ECDOSE ECENDTL ECCAT ECSTDTL ECOCCUR ECMOOD ECSTDTC ECENDTC
     WHERE =(ECCAT = 'STUDY INTERVENTION, DIARY' AND ECMOOD = 'PERFORMED')) OUT = ec_sort;    BY usubjid ;RUN;
PROC SORT DATA = adsl;    BY usubjid ;RUN;

DATA EC_dose ;
    MERGE  adsl (IN=a) ec_sort(IN=b) ;
    BY usubjid ;
    IF b;
    newdate=input(ECSTDTC,yymmdd10.);
    FORMAT ECOCCUR $x_ny.;
    n_ECOCCUR = upcase(put(ECOCCUR, $x_ny.));
    c_ECDOSE =put (ECDOSE, 3.) ;
    LABEL &treat_var. ='Actual Treatment Group'
          ECSTDTL = 'Date'
          n_ECOCCUR='Taken yes/no'
          c_ECDOSE ='Number of capsules';
RUN;

PROC SORT DATA= EC_dose OUT= EC_final NODUP DUPOUT= dp;
    BY &treat_var. &subj_var.  newdate ECSTDTL n_ECOCCUR c_ECDOSE ;
RUN;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;


%MTITLE;

%datalist(
    data     = EC_final
  , page     = &treat_var.
  , by       = SASR newdate
  , var      = ECSTDTL n_ECOCCUR c_ECDOSE
  , order    = newdate
  , freeline = FIRST.SASR
  , optimal  = y
  , maxlen   = 30
  , space    = 5
  , split    =
  , layout   = Standard
  , bylen    = 30
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();


