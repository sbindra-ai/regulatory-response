/*******************************************************************************
 * Bayer AG
 * Study            : 21810 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 52 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_3_5_8_adlb_alt_km);
/*
 * Purpose          : Cumulative incidence for  ALT/  >=3xULN by treatment group: Descriptive statistics (SAF)
 * Programming Spec : 21810_tlf_v1.0.docx
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emzah (Rakesh Muppidi) / date: 20FEB2024
 * Reference prog   : /var/swan/root/bhc/3427080/21651/stat/main01/dev/analysis/pgms/t_8_3_5_8_adlb_alt_km.sas (emvsx (Phani Tata) / date: 02JAN2024)
 ******************************************************************************/


%let pop = &saf_cond ;
%let _treat_var = &treat_var.;



%let parameters = 'T2ALT';
%let criteria = %str(Time to ALT >= 3xULN (Days)) ;

%let subgroup_label =  ;
%let subgroup_var =  ;

%let timelist = 28 56 84 112 140 168 196 224 252 280 308 336 364 392 420 448 476 504 532 560;

%load_ads_dat(adtte_view, adsDomain = adtte ,
              adslWhere =  &saf_cond )
%load_ads_dat(adsl_view , adsDomain = adsl , where =  &saf_cond )

%extend_data(indat = adtte_view , outdat = adtte )
%extend_data(indat = adsl_view  , outdat = adsl) ;

ods escapechar="^";

data adtte ;
    set adtte ;
    where paramcd = "T2ALT";
RUN;


* Run KM procedure and get one dataset with survival parameters (KM_SURV) and one with confidence intervals (KM_INT);
PROC LIFETEST data=adtte alpha=0.05 method=km outsurv=km_int timelist = &timelist.  atrisk ;
    TIME aval * cnsr(1);
    STRATA  &_treat_var.;
    ODS OUTPUT ProductLimitEstimates=km_surv;
RUN;

proc sql;
    create table km_int_sort as
           select *, round(aval, 0.00000001) as aval1
           from km_int
           order by stratum, &_treat_var.,
                   aval1, _censor_ desc, survival desc;
QUIT;

data km_outsurv2;
    set km_int_sort;
    by stratum   &_treat_var. aval1 descending _censor_ descending survival;
    if last.aval1;
RUN;


proc sort data = km_surv out = km_surv_sort;
    by stratum &subgroup_var. &_treat_var. aval;
RUN;


data km_all;
    merge km_surv_sort (keep = stratum   &_treat_var. aval timelist failed left failure numberatrisk in = a)
          km_outsurv2  (keep = stratum   &_treat_var. aval1 sdf_:
                      rename = (aval1 = aval) in = b);
    by stratum  &_treat_var. aval;
    if a and b;

  length timelistc $3 ;
    attrib timelistc         label = "Relative Days^&s_a"   format = 3.
           failed           label = "n"
           numberatrisk     label = "N"
           cum_inc          label = "Cum. prob (%)"    format = 8.2
           conf_int         label = "KM 95% CI (Lower, Upper limit)"             length = $40
           &_treat_var.     Label  = "Treatment"  ;

    if not missing(failure) then cum_inc = 100*failure;
    timelistc = strip(put(timelist, 4.)) ;
    * Calculate CI for failure (1-survival);
    if not missing(sdf_lcl) then f_lcl = 100*(1-sdf_ucl); else call missing(f_lcl);
    if not missing(sdf_ucl) then f_ucl = 100*(1-sdf_lcl); else call missing(f_ucl);

     conf_int = cats("(" , put(f_lcl, 8.2)  ,  "," , put(f_ucl, 8.2) ,  ")" );

RUN;

%MTITLE;

%datalist(
    data     = km_all
  , by       = &_treat_var. timelist timelistc
  , var      = failed numberatrisk cum_inc conf_int
  , freeline = &_treat_var.
  , optimal  = YES
  , maxlen   = 10
  , space    = 1
  , hsplit   = '#'
  , bylen    = 10
  , hb_align = left
  , hv_align = center
  , hc_align = right
  , hn_align = center
  , order  = timelist
)

%endprog()
