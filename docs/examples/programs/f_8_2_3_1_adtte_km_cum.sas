/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = f_8_2_3_1_adtte_km_cum   );
/*
 * Purpose          : Cumulative incidence plot of time to treatment response reduction of 50% in mean daily frequency of moderate to severe hot flashes by treatment group (FAS)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 02JAN2024
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/f_8_2_3_1_adtte_km_cum.sas (emvsx (Phani Tata) / date: 09OCT2023)
 ******************************************************************************/

%let pop =  &fas_cond ;
%let _treat_var = &treat_arm_p.;

**T50RM - Time to treatment response reduction of 50% in mean daily frequency of moderate to severe hot flashes by treatment group;


%load_ads_dat(adtte_view, adsDomain = adtte ,
              adslWhere =  &fas_cond )
%load_ads_dat(adsl_view , adsDomain = adsl , where =  &fas_cond )

%extend_data(indat = adtte_view , outdat = adtte )
%extend_data(indat = adsl_view  , outdat = adsl) ;

data adtte ;
    set adtte ;
    where paramcd = "T50RMDF";
RUN;
* Run KM procedure and get one dataset with survival parameters (KM_SURV) and one with confidence intervals (KM_INT);
PROC LIFETEST data=adtte alphaqt=0.05 method=km outsurv=km_outsurv1 conftype=linear stderr;
    TIME aval * cnsr(1);
    STRATA  &_treat_var.;
    ODS OUTPUT ProductLimitEstimates=km_surv;
RUN;

%MTITLE;

%KaplanMeierPlot(
    data          = km_outsurv1
  , class         =  &_treat_var.
  , atriskdata    = km_surv
  , km_type       = cumulative
  , filename      = &prog
  , title_ny     = NO
  , LEGENDTITLE  = Treatment Group
  , xlabel       = Time (weeks)
  , atrisk_enumerate_class = yes
  , SHOW_CENSORED = YES
);
%endprog()
