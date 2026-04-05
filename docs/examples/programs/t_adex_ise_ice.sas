/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adex_ise_ice);
/*
 * Purpose          : Create table: Non-compliance related to temporary treatment interruption (estimand definition) up to Week 12 (full analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gltlk (Rui Zeng) / date: 02JAN2024
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_1_7_ice_adex.sas (egavb (Reema S Pawar) / date: 06JUN2023)
 ******************************************************************************/

%LET mosto_param_class = &mosto_param_class_eff.;

%load_ads_dat(adsl_view, adsDomain = adsl, where = &fas_cond.)
%load_ads_dat(
    adex_view
  , adsDomain = adex
  , where     = paramcd in ('TRTINW1' 'TRTINW4' 'TRTINW8' 'TRTINW12')
  , adslWhere = &fas_cond.
)

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_eff.
  , extend_rule = &extend_rule_disp_eff.
);

%extend_data(
    indat       = adex_view
  , outdat      = adex_ext
  , var         = &extend_var_disp_eff.
  , extend_rule = &extend_rule_disp_eff.
);

DATA adex_ext2;
    LENGTH Time $20 grp 8.;
    SET adex_ext;
    IF PARAMCD = 'TRTINW1' THEN DO;
        Time = 'Week 1' ; grp = 1; END;
     IF PARAMCD = 'TRTINW4' THEN DO;
         Time = 'Week 4' ; grp = 2; END;
     IF PARAMCD = 'TRTINW8' THEN DO;
         Time = 'Week 8' ; grp = 3; END;
     IF PARAMCD = 'TRTINW12' THEN DO;
         Time = 'Week 12'; grp = 4; END;
     KEEP studyid usubjid ice01fl icereas avalc &mosto_param_class. paramcd time grp;
RUN;

%freq_tab(
    data        = adex_ext2
  , data_n      = adsl_ext
  , var         = avalc
  , by          = grp time
  , total       = yes
  , order       = grp
  , outdat      = out
  , missing     = no
  , complete    = ALL
  , optimal     = yes
  , freeline    = time
  , order_var   = avalc = "Y" "N" " "
);

DATA out;
  SET out;
  IF time= 'Week 1' AND _type_=0 AND _nr_=1 THEN _varl_ = 'Treatment taken on <5/7 days';
  IF time= 'Week 4' AND _type_=0 AND _nr_=1 THEN _varl_ = 'Treatment taken <80% during weeks 1-4 OR treatment taken on <5/7 days during either week 3 or 4';
  IF time= 'Week 8' AND _type_=0 AND _nr_=1 THEN _varl_ = 'Treatment taken <80% during weeks 1-8 OR treatment taken on <5/7 days during either week 7 or 8';
  IF time= 'Week 12' AND _type_=0 AND _nr_=1 THEN _varl_ = 'Treatment taken <80% during weeks 1-12 OR treatment taken on <5/7 days during either week 11 or 12';
  IF AVALC = "Y" THEN _varl_ = "Yes";
  IF AVALC = "N" THEN _varl_ = "No";
RUN;

%set_titles_footnotes(
    tit1 = "Table: Non-compliance related to temporary treatment interruption (estimand definition) up to Week 12 &fas_label."
    , ftn1 = "&foot_placebo_ezn."
    , ftn2 = "A 'Yes' means the subject had a temporary treatment interruption or has not been compliant."
);

%mosto_param_from_dat(
    data = outinp
  , var  = l_call
)

%datalist(&l_call)

%endprog;