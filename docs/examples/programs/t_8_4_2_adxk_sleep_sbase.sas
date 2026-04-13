/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_4_2_adxk_sleep_sbase);
/*
 * Purpose          : Actigraphy Sleep parameter: summary statistics and change from baseline by treatment group (SLAS)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 12JUN2023
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : epjgw (Roland Meizis) / date: 15DEC2023
 * Reason           : Update
 ******************************************************************************/

*****Sleep parameters:
*DAILY AGGREGATION -
*TSTD - Total Sleep Time over 24 hours (Minutes) - Daily Aggregation,
*SLED - Sleep Efficiency (%) - Daily Aggregation,
*SLWD - Wake after Sleep Onset (Minutes) - Daily Aggregation
*AACD - Average Number of Awakenings per Hour of Sleep - Daily Aggregation
*AAVD - Average Length of Awakenings during Sleep (Minutes) - Daily Aggregation

WEEKLY AGGREGATION
TSTWAVG - Mean of Total Sleep Time over 24 hours (Minutes) over 7day-window
SLEWAVG - Mean of Sleep Efficiency (%) over 7day-window
SLWWAVG - Mean of Wake after Sleep Onset (Minutes) over 7day-window
AACWAVG - Mean of Average Number of Awakenings per Hour of Sleep over 7day-window
AAVWAVG - Mean of Average Length of Awakenings during Sleep (Minutes) over 7day-window;


%load_ads_dat(
    adxk_view
  , adsDomain = adxk
  , where     = PARCAT1 = 'WEEKLY AGGREGATION'
                and avisitn not in ( 0 , 900000 )
                and paramcd in ( 'TSTWAVG' 'SLEWAVG' 'SLWWAVG' 'AACWAVG' 'AAVWAVG' )
                and not(missing(aval))
  , adslWhere = &slas_cond
)
%load_ads_dat(adsl_view , adsDomain = adsl , where =  &slas_cond )

%extend_data(indat = adxk_view, outdat = adxk)
%extend_data(indat = adsl_view, outdat = adsl)

PROC SORT DATA=adxk(keep=paramcd) OUT=paramcd NODUPKEY;
     BY paramcd;
RUN;

data adxk;
    set adxk;
    attrib &treat_arm_p. label="Treatment";
run;

%MTITLE;

%desc_tab(
    data          = adxk
  , data_n        = adsl
  , var           = aval
  , stat          = n mean std min median max
  , by            = paramcd
  , data_n_ignore = paramcd
  , order         = paramcd
  , class         = &treat_arm_p.
  , class_order   = &treat_arm_p. = &MOSTO_PARAM_CLASS_ORDER.
  , total         = NO
  , round_factor  = 0.1
  , vlabel        = no
  , baseline      = ablfl = "Y"
  , compare_var   = chg
  , time          = avisitn
  , subject       = &subj_var.
  , tablesby      = paramcd
  , optimal       = yes
  , bylen         = 10
)


%endprog();