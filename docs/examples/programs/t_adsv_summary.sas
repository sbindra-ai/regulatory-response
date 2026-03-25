/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
    %iniprog(name = t_adsv_summary);
/*
 * Purpose          : Number of subjects by IA visit  (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : ereiu (Katharina Meier) / date: 01MAR2024
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 18MAR2024
 * Reason           : Use in addition ADDS as in corresponding O2 program
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 18MAR2024
 * Reason           : Adding still in study in label and title
 ******************************************************************************/

%LET mosto_param_class = %scan(&extend_var_disp_12_ezn_52_a_nsa, 1, '@');

*** ADSV;
%load_ads_dat(adsv_view, adsDomain = adsv)

%extend_data(
    indat       = adsv_view
  , outdat      = adsv_ext
  , var         = &extend_var_disp_12_ezn_52_a_nsa.
  , extend_rule = &extend_rule_disp_12_ezn_52_a_afl.
);

%m_switcher_avisit2(
    indat  = adsv_ext
  , trtvar = &mosto_param_class.
  , byvar  = usubjid
);

* Treatment switcher visits 16, 20 and 26 will be presented as week 4, 8 and 12 / 14 for All EZN 120 mg (week 1-52).;
DATA adsv;
    SET adsv_ext;
    ATTRIB avisitn LABEL = "Number of subjects still in study by IA visit";
    if avisitn>=5;
    format &mosto_param_class. _trtgrp_nsa_splitted.;
RUN;
proc sort data = adsv; by usubjid; run;

*** ADSL;
%load_ads_dat(adsl_view, adsDomain = adsl)

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_12_ezn_52_a_nsa
  , extend_rule = &extend_rule_disp_12_ezn_52_a
);

*** ADDS;
%load_ads_dat(
    adds_view
  , adsDomain = adds
  , where     = dscat in('DISPOSITION EVENT' " ") and dsscat ne "INFORMED CONSENT"
  , adslWhere = &SAF_COND.
)

%extend_data(
    indat       = adds_view
  , outdat      = adds_ext
  , var         = &extend_var_disp_12_ezn_52_a_nsa
  , extend_rule = &extend_rule_disp_12_ezn_52_a_afl.
);

data adds;
    set adds_ext;
    where epoch not in ("SCREENING" "TREATMENT");* and dsdecod ne "COMPLETED";
    keep usubjid astdt;
    rename astdt = discdt;
RUN;

*** Merge;
/* all SV records on or before last available date*/
data adsv1;
    merge adsv(in=a) adds;
    by usubjid;
    if a;
    if discdt = . or (discdt ne . and . < aendt <= discdt);
    if avisitn < 900000;
RUN;
proc sort data = adsv1; by usubjid aendt; RUN;

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

%set_titles_footnotes(
    tit1 = "Table: Number of subjects still in study by IA visit &saf_label."
  , ftn1 = "IA = Integrated Analysis."
  , ftn2 = "This table includes all subjects who participated in the respective visit irrespective of study drug status."
  , ftn3 = "&foot_switcher_26_52."
  , ftn4 = "%sysfunc(tranwrd(&foot_ia_eot., %str(EoT), %str(End of Treatment)))"
)
;

%freq_tab(
    data    = adsv3
  , data_n  = adsl_ext(WHERE=(&saf_cond.))
  , var     = avisitn
  , basepct = N_CLASS
  , hlabel  = yes
  , outdat  = outdat
  , missing = NO
);

DATA outdat;
    SET outdat;
    ** For EZN 120 mg (week 1-12) and Placebo (week 1-12) visits between Z_AVISIT.121 [Week 12/14] and Z_AVISIT.600000 [End of Treatment] should be removed;
    IF (NOT missing(_col_01) OR NOT missing(_col_02)) AND 121 < avisitn < 600000 THEN DO;
        _col_01 = substr(_col_01, index(_col_01, 'N') - 1);
        _col_02 = substr(_col_02, index(_col_02, 'N') - 1);
    END;
RUN;

%mosto_param_from_dat(data = outdatinp, var = config);
%datalist(&config);


%endprog();
