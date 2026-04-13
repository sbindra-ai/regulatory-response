/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_1_4_adsl_demo_ovrl);
/*
 * Purpose          : Demographics overall/by region/by race/by eligibility for menopause hormone therapy/by BMI (FAS/SAF/sleep analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : enpjp (Prashant Patel) / date: 09NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_1_4_adsl_demo.sas (enpjp (Prashant Patel) / date: 09SEP2023)
 ******************************************************************************/

%macro demog (pop_cond1=,subset=,pop_label1=, trtused=);

%load_ads_dat(adsl_view, adsDomain = adsl, where =  (&pop_cond1. and &trtused. ne . /*and &subset*/ ), adslVars  =);

%extend_data(indat = adsl_view, outdat = adsl)

data adsl;
    set adsl_view(rename=(sex=sex_));
    format weightbl heightbl bmibl 8.1 &trtused. z_trt.  ;
    format smokhxn _smk.;
    format edulvn _edu.;
    format racen _race.;
    format ethnicn _ethnic.;
    if sex_='F' then sex='Female';
    label agegr1n= "Age group"
          age = "Age (years)"
          sex="Sex"
          region1n="Region"
      RACEN="Race"
      ETHNICN="Ethnicity"
      edulvn="Level of Education";
    %M_PropIt(Var=race);
    %M_PropIt(Var=ethnic);
    if race_prop ne ' ' then do;
        racen = input(strip(put(RACE_PROP, $_race.)), 3.) ;
    end;
    ethnicn = input(strip(put(ETHNIC_PROP, $_ethnic.)),3.) ;
    edulvn = input(strip(put(edulevel, $_edu.)), 3.) ;
RUN;

%mtitle;
%desc_freq_tab(
    data     = adsl
  , var      = sex racen ethnicn age agegr1n weightbl heightbl bmibl bmigr1n smokhxn edulvn
  , class    = &trtused.
  , data_n   = adsl
  , subject  = usubjid
  , page     = &subset.
  , complete = none
  , basepct  = n_class
  , misstext = Missing
  , stat     = n mean std min median max
  , optimal  = yes
  , maxlen   = 12
  , bylen    = 40
)

%mend;
/*FAS*/
%demog (pop_cond1=&fas_cond,subset=%str(),pop_label1=overall &fas_label, trtused=&treat_arm_p.);
/*SAF*/
%demog (pop_cond1=&saf_cond,subset=%str(),pop_label1=overall &saf_label, trtused=&treat_arm_a.);
/*SLAS*/
%demog (pop_cond1=&slas_cond,subset=%str(),pop_label1=overall &slas_label, trtused=&treat_arm_p.);

%endprog();