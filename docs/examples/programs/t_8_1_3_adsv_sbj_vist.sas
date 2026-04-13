/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_1_3_adsv_sbj_vist);
/*
 * Purpose          : Number of subjects in study by visit (safety analysis set)
 * Programming Spec :
 * Validation Level : 2 - Verification by Double Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : enpjp (Prashant Patel) / date: 28SEP2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_1_3_adsv_sbj_vist.sas (enpjp (Prashant Patel) / date: 09SEP2023)
 ******************************************************************************/

%load_ads_dat(adsv_view, adsDomain = adsv, adslWhere = &SAF_COND.)
%load_ads_dat(
    adds_view
  , adsDomain = adds
  , where     = dscat in('DISPOSITION EVENT' " ") and dsscat ne "INFORMED CONSENT"
  , adslWhere = &SAF_COND.
)
%load_ads_dat(adsl_view, adsDomain = adsl, where = &SAF_COND., adslVars =);

%extend_data(indat = adsl_view, outdat = adsl)
%extend_data(indat = adsv_view, outdat = adsv)

data adsv;
    set adsv_view;
    where avisitn not in(0 900000);
    label avisitn = "In study at";
RUN;
/* last available date from DS*/
data adds;
    set adds_view;
    where epoch not in ("SCREENING" "TREATMENT");* and dsdecod ne "COMPLETED";
    keep usubjid astdt;
    rename astdt = discdt;
RUN;
/* all SV records on or before last available date*/
data adsv1;
    merge adsv(in=a) adds;
    by usubjid;
    if a;
    if discdt = . or (discdt ne . and . < aendt <= discdt);
    if avisitn < 900000;
RUN;

proc sort data = adsv1;
    by usubjid aendt;
RUN;
/* identify last available visit*/
data adsv2;
    set adsv1;
    by usubjid;
    if last.usubjid;
    keep usubjid avisitn aendt;
    rename avisitn=vis aendt=last;
RUN;
/* get records in sv till last available visit*/
data adsv3;
        merge adsv(in=a) adsv2;
        by usubjid;
        if a;
        if (cmiss(last,aendt)=0 and aendt<=last  and avisitn<=vis) or ( cmiss(last,aendt) ne 0 and avisitn<=vis);
RUN;

%mtitle;

%freq_tab(
    data    = adsv3
  , data_n  = adsl_view
  , var     = avisitn
  , subject = usubjid
  , class   = &TREAT_ARM_A
  , basepct = N_CLASS
)

%endprog();


