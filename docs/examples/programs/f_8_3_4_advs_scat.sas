/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = f_8_3_4_advs_scat );
/*
 * Purpose          : ScatterPlot plot  Parameter , name unit by treatment Group
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 30NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/f_8_3_4_advs_scat.sas (emvsx (Phani Tata) / date: 19SEP2023)
 ******************************************************************************/
/* Changed by       : emvsx (Phani Tata) / date: 05FEB2024
 * Reason           : Updated Y-axis from EOT to W12
 ******************************************************************************/


%load_ads_dat(adsl_view, adsDomain = adsl, where = &saf_cond)
%load_ads_dat(advs_view
            , adsDomain = advs
            , adslWhere =  &saf_cond

            , where  =  anl01fl = "Y"
             and   paramcd in (  "SYSBP" ,   "DIABP"  )
             and   avisitn in (5 , 120 )
       , labelVars         = lbl_ana1
     )
%extend_data(indat = adsl_view, outdat = adsl)
%extend_data(indat = advs_view, outdat = advs)

proc sort data = advs out = advs1 ( keep = usubjid   aval avisitn  &treat_arm_a. paramcd );
    by usubjid  paramcd  &treat_arm_a.  avisitn   ;

   format   aval avisitn;
RUN;

proc transpose data = advs1 out = advs_t prefix = col_ ;
    by usubjid paramcd  &treat_arm_a.     ;
    var aval ;
    id   avisitn ;
RUN;

%MTITLE;

%ScatterPlot(
     data       = advs_t (where = (paramcd = "SYSBP") )
    , xvar            =  col_5
    , yvar            =  col_120
    , by              = paramcd
    , class           =  &treat_arm_a.
    , regression      = Yes
    , regression_stat = footnote
    , filename        = &prog._1
    , xlabel          =  $paramcd$ at baseline
    , ylabel          =  $paramcd$ at Week 12
    , title_ny        = No
    , legendtitle     = Treatment Group
    , STYLE_OPTIONS =  MarkerSymbols   = 'Square'  'CircleFilled'
    , xticklist        =    80 90 100 110 120 130 140 150 160
    , yticklist        =   80 90 100 110 120 130 140 150 160

 );

%ScatterPlot(
     data       = advs_t (where = (paramcd = "DIABP") )
    , xvar            =  col_5
    , yvar            =  col_120
    , by              = paramcd
    , class           =  &treat_arm_a.
    , regression      = Yes
    , regression_stat = footnote
    , filename        = &prog._2
    , xlabel          =  $paramcd$ at baseline
    , ylabel          =  $paramcd$ at Week 12
    , title_ny        = No
    , legendtitle     = Treatment Group
    , STYLE_OPTIONS =  MarkerSymbols   = 'Square'  'CircleFilled'
    , xticklist        =   40 50 60 70 80 90 100 110 120
    , yticklist        =   40 50 60 70 80 90 100 110 120

 );

%endprog(
    cleanWork       = y
  , cleanTitlesFoot = y
  , verbose         = Y
)

