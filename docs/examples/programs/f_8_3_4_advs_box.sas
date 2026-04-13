/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = f_8_3_4_advs_box    );
/*
 * Purpose          : Box plot  Parameter , name unit by treatment Group
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 21NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/f_8_3_4_advs_box.sas (emvsx (Phani Tata) / date: 23AUG2023)
 ******************************************************************************/

%load_ads_dat(adsl_view,
              adsDomain = adsl,
              where = &saf_cond);

%load_ads_dat(advs_view,
              adsDomain = advs ,
              where =anl01fl = "Y"
                     and   paramcd in (  'HR' 'SYSBP' 'DIABP'  )
                     and   0 < avisitn < 900000   ,
              adslWhere =  &saf_cond )
%extend_data(indat = adsl_view, outdat = adsl)
%extend_data(indat = advs_view, outdat = advs)

data advs_ph ;
    set advs ;
    format aval ;  informat aval;
RUN;

%MTITLE;

%BoxPlot(
    data        = advs_ph
  , xvar        = avisitn
  , yvar        = aval
  , by          = paramcd
  , class       = TRT01AN
  , class_order = &mosto_param_class_order.
  , title_ny    = No
  , legend      = yes big_n
  , legendtitle = Treatment Group
  , data_n      = adsl
  , subject     = usubjid
  , connect     = mean
  , extremes    = NO
  , xlabel      = Time (weeks)
  , ylabel      = $paramcd$
  , filename    = $paramcd$_&prog.
  , data_n_ignore = paramcd
  , desc_footnote    = NO
) ;

%endprog(
    cleanWork       = y
  , cleanTitlesFoot = y
  , verbose         = Y
)

;