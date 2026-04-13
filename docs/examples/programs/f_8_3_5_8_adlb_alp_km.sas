/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = f_8_3_5_8_adlb_alp_km  );
/*
 * Purpose          : Figure: Cumulative incidence for <<ALT/ALP>> >=3xULN by treatment group: Descriptive statistics (SAF)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 02JAN2024
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/f_8_3_5_8_adlb_alp_km.sas (emvsx (Phani Tata) / date: 17AUG2023)
 ******************************************************************************/


%let pop = &saf_cond ;
%let _treat_var = &treat_var.;


%let parameters = 'T2ALP';
%let criteria = %str(Time to ALP >= 3xULN (Days)) ;

*< Select subgroup that should be displayed in the table (label for table header and variable);
%let subgroup_label =  ;
%let subgroup_var =  ;

*< Timepoints to be displayed in the table;

%let timelist = 28 56 84 112 140 168 196 224 252 ; ;


%load_ads_dat(adtte_view, adsDomain = adtte ,
              adslWhere =  &saf_cond )
%load_ads_dat(adsl_view , adsDomain = adsl , where =  &saf_cond )

%extend_data(indat = adtte_view , outdat = adtte )
%extend_data(indat = adsl_view  , outdat = adsl) ;

data adtte ;
    set adtte ;
    where paramcd = "T2ALP";
RUN;

* Run KM procedure and get one dataset with survival parameters (KM_SURV) and one with confidence intervals (KM_INT);
PROC LIFETEST data=adtte alpha=0.05 method=km outsurv=km_int conftype=linear atrisk; /*stderr  */ ;
    TIME aval * cnsr(1);
    STRATA  &_treat_var.;
    ODS OUTPUT ProductLimitEstimates= km_surv;
RUN;

%MTITLE;

%KaplanMeierPlot(
    data       = km_int
  , class      =  &_treat_var.
  , atriskdata = km_surv
  , legendtitle       = Treatment group
  , title_ny     = NO
  , filename      = &prog
  , km_type       = cumulative
  , XTICKLIST     =   28 56 84 112 140 168 196 224 252
  , desc_footnote = NO
  , SHOW_CENSORED = YES
);

%endprog()
