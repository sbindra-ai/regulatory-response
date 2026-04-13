/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_3_11_qscssrs_frq);
/*
 * Purpose          : Number of subjects with suicidal ideation and behavior based on the eC-SSRS  (SAF)
 * Programming Spec :
 * Validation Level : 2 - Independent Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : epjgw (Roland Meizis) / date: 12DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/t_8_3_11_qscssrs_frq.sas (egavb (Reema S Pawar) / date: 14JUN2023)
 ******************************************************************************/

%load_ads_dat(
    adqs_view
  , adsDomain = adqs
  , where     = ANL04FL = 'Y'
                AND PARCAT1 IN ('COLUMBIA-SUICIDE SEVERITY RATING SCALE (BAYER) BASELINE/SCREENING (ECOA)', 'COLUMBIA-SUICIDE SEVERITY RATING SCALE (BAYER) SINCE LAST VISIT (ECOA)')
                AND PARCAT2 IN ('SUICIDAL BEHAVIOR', 'SUICIDAL IDEATION')
                AND NOT(MISSING(ATPTN))
  , adslWhere = &saf_cond
)

%extend_data(indat = adqs_view, outdat = adqs)

/* Derive new variable with parameters for suicidal ideation and another one for suicidal behavior */
/* Use custom format for these variables such that all categories are shown even if n=0 */
data final;
    set adqs;

    attrib paramcd_ideation format=_suicidal_ideation_subcat.
           paramcd_behavior format=_suicidal_behavior_subcat.
           ;

    if      parcat2 = "SUICIDAL IDEATION" then do;
        select(PARAMCD);
            when('CSSB402B', 'CSSB402A', 'CSSB202') paramcd_ideation = 1;
            when('CSSB403B', 'CSSB403A', 'CSSB203') paramcd_ideation = 2;
            when('CSSB404B', 'CSSB404A', 'CSSB204') paramcd_ideation = 3;
            when('CSSB405B', 'CSSB405A', 'CSSB205') paramcd_ideation = 4;
            when('CSSB406A', 'CSSB406B', 'CSSB206') paramcd_ideation = 5;
            otherwise DELETE;
        end;
    end;
    else if parcat2 = "SUICIDAL BEHAVIOR" then do;
        select(PARAMCD);
            when( 'CSSB414B', 'CSSB414A', 'CSSB214') paramcd_behavior = 1;
            when( 'CSSB416B', 'CSSB416A', 'CSSB216') paramcd_behavior = 2;
            when( 'CSSB418B', 'CSSB418A', 'CSSB218') paramcd_behavior = 3;
            when( 'CSSB420B', 'CSSB420A', 'CSSB220') paramcd_behavior = 4;
            when( 'CSSB422' , 'CSSB222'            ) paramcd_behavior = 5;
            otherwise DELETE;
        end;
    end;
run;


%MTITLE;

/* Create table, strategy: Create numbers for all categories at all timepoints and remove unnecessary lines afterwards */
%overview_tab(
    data     = final
  , data_n   =
  , class    = &treat_var
  , by       = avisitn ATPTN
  , missing  = YES
  , misstext =
  , total    = NO
  , groups   = 'PARCAT1 '       *'n'
               '<DEL>'*''
               'parcat2 = "SUICIDAL IDEATION" and avalc = "Y"'* 'Suicidal ideation  (Category 1-5)'* 'PARAMCD_IDEATION'* '<DEL>'
               '<DEL>'*''
               'parcat2 = "SUICIDAL BEHAVIOR" and avalc = "Y"'* 'Suicidal Behavior  (Category 6-10)'* 'PARAMCD_BEHAVIOR'* '<DEL>'
               '<DEL>'*''
               'parcat2 NE  ""                and avalc = "Y"'* 'Suicidal Ideation or Behavior (Category 1-10)'
               '<DEL>'*''
  , n_group  = 1
  , complete = YES
  , outdat   = base
  , order_var = ATPTN = 99999930.04 -99999993.06 99999993.24 99999930.02 /*'Lifetime' 'Last 6 Months' 'Last 24 Months' 'Since Last Visit'*/
  , freeline =
  , together = ATPTN
)

/* Remove unnecessary lines (e.g. no since last visit at baseline) */
data base;
    set base;

    if avisitn = 5 and atptn = 99999930.02 then delete; /* Don't show "since last visit" at baseline */
    else if avisitn ne 5 and atptn ne 99999930.02 then delete; /* Only show "since last visit" if not baseline */

    if atptn = -99999993.06 and floor(_order_) in (4, 5) then delete; /* Remove Suicidal Behavior categories (and one blank line) at timepoint "last 6 months"  */
    if atptn = -99999993.24 and floor(_order_) in (2, 3) then delete; /* Remove Suicidal ideation categories (and one blank line) at timepoint "last 24 months" */
run;

%mosto_param_from_dat(data = baseinp, var = config)
%datalist(&config.)


%endprog;