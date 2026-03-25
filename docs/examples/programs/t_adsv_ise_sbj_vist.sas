/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adsv_ise_sbj_vist);
/*
 * Purpose          : Number of subjects in study by visit (full analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gltlk (Rui Zeng) / date: 21DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_1_3_adsv_sbj_vist.sas (enpjp (Prashant Patel) / date: 28SEP2023)
 ******************************************************************************/

%LET mosto_param_class = &mosto_param_class_eff.;

%load_ads_dat(adsv_view, adsDomain = adsv, adslWhere = &fas_cond.)
%load_ads_dat(
    adds_view
  , adsDomain = adds
  , where     = dscat in('DISPOSITION EVENT' " ") and dsscat ne "INFORMED CONSENT"
  , adslWhere = &fas_cond.
)
%load_ads_dat(adsl_view, adsDomain = adsl, where = &fas_cond., adslVars =);

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_eff.
  , extend_rule = &extend_rule_disp_eff.
)

%extend_data(
    indat  = adsv_view
  , outdat = adsv_ext
  , var         = &extend_var_disp_eff.
  , extend_rule = &extend_rule_disp_eff.
)

%extend_data(
    indat  = adds_view
  , outdat = adds_ext
  , var         = &extend_var_disp_eff.
  , extend_rule = &extend_rule_disp_eff.
)

data adsv;
    set adsv_ext;
    where avisitn not in(0 900000);
    label avisitn = "In study at";
RUN;
/* last available date from DS*/
data adds;
    set adds_ext;
    where epoch not in ("SCREENING" "TREATMENT");* and dsdecod ne "COMPLETED";
    keep studyid usubjid astdt;
    rename astdt = discdt;
RUN;

proc sort data = adds;
    by studyid usubjid discdt;
RUN;

data adds2;
    set adds;
    by studyid usubjid discdt;
    if last.usubjid;
RUN;

/* all SV records on or before last available date*/
data adsv1;
    merge adsv(in=a) adds2;
    by studyid usubjid;
    if a;
    if discdt = . or (discdt ne . and . < aendt <= discdt);
    if avisitn < 900000;
RUN;

proc sort data = adsv1;
    by studyid usubjid aendt;
RUN;
/* identify last available visit*/
data adsv2;
    set adsv1;
    by studyid usubjid;
    if last.usubjid;
    keep studyid usubjid avisitn aendt;
    rename avisitn=vis aendt=last;
RUN;
/* get records in sv till last available visit*/
data adsv3;
        merge adsv(in=a) adsv2;
        by studyid usubjid;
        if a;
        if (cmiss(last,aendt)=0 and aendt<=last  and avisitn<=vis) or ( cmiss(last,aendt) ne 0 and avisitn<=vis);

        * present the study visit instead of IA visit;
        if avisitn = 121 then avisitn = 120;
        if avisitn = 161 then avisitn = 160;
        if avisitn = 241 then avisitn = 600010;
        if avisitn = 600000 then avisitn = 600010;
RUN;

%set_titles_footnotes(
    tit1 = "Table: Number of subjects in study by visit &fas_label."
  , ftn1 = '"Subjects in study" includes all subjects irrespective of study drug status.'
);

%freq_tab(
    data    = adsv3
  , data_n  = adsl_ext
  , var     = avisitn
  , basepct = N_CLASS
  , total   = YES
)
%endprog();


