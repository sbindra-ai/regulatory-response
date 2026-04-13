/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/

%iniprog(name = t_8_1_7_ice_adex);

/*
 * Purpose          : Non-compliance related to temporary treatment interruption (estimand definition) by treatment group  (FAS)
 * Programming Spec :
 * Validation Level : 2 - Independent Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gnrty (Ashu Pandey) / date: 04DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_1_7_ice_adex.sas (egavb (Reema S Pawar) / date: 06JUN2023)
 ******************************************************************************/

%load_ads_dat(adex_view, adsDomain = adex, adslWhere = &fas_cond)
%load_ads_dat(adsl_view, adsDomain = adsl, where = &fas_cond, adslVars  =);

DATA adex;
    LENGTH Time $20 grp 8.;
    SET adex_view;
    time = strip(strip("Week ")||" "||strip(substr(paramcd,7)));
    where paramcd in ('TRTINW1' 'TRTINW4' 'TRTINW8' 'TRTINW12' );

     if paramcd = 'TRTINW1' then grp = 1;
         else if  paramcd = 'TRTINW4' then grp = 2;
         else if paramcd = 'TRTINW8' then grp = 3;
         else if paramcd = 'TRTINW12' then grp = 4;

KEEP usubjid ice01fl icereas avalc trt01pn trt01an paramcd time grp;
RUN;

proc sort data= adex out=ex_sort ;
    by usubjid grp avalc;
run;

%freq_tab(
    data        = ex_sort
  , data_n      = adsl_view
  , var         = avalc
  , subject     = &subj_var.
  , by          = grp time
  , order       = grp
  , class       = &treat_arm_p
  , hlabel      = no
  , levlabel    = yes
  , outdat      = out
  , missing     = no
  , complete    = ALL
  , optimal     = yes
  , hc_align    = CENTER
  , hn_align    = CENTER
  , print_empty = no
  , order_var   = avalc = "Y" "N" " "
  , label       = no
);



DATA out ;
  SET out;
  IF time= 'Week 1' AND _type_=0 AND _nr_=1 THEN _varl_ = 'Treatment taken on <5/7 days';
  IF time= 'Week 4' AND _type_=0 AND _nr_=1 THEN _varl_ = 'Treatment taken <80% during weeks 1-4 OR treatment taken on <5/7 days during either week 3 or 4';
  IF time= 'Week 8' AND _type_=0 AND _nr_=1 THEN _varl_ = 'Treatment taken <80% during weeks 1-8 OR treatment taken on <5/7 days during either week 7 or 8';
  IF time= 'Week 12' AND _type_=0 AND _nr_=1 THEN _varl_ = 'Treatment taken <80% during weeks 1-12 OR treatment taken on <5/7 days during either week 11 or 12';
  IF AVALC = "Y" THEN _varl_ = "Yes";
  IF AVALC = "N" THEN _varl_ = "No";
RUN;

data outinp;
    set outinp;
    if keyword = "FREELINE" then value = "Time" ;
RUN;

********************************** final ***************************************************;
%mtitle;

%mosto_param_from_dat(
    data    = outinp
  , var     = l_call
  , keyword = keyword
  , value   = value
)

%datalist(&l_call)

%endprog;