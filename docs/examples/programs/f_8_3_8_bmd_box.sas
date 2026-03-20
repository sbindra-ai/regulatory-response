/*******************************************************************************
 * Bayer AG
 * Study            : 21810 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 52 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = f_8_3_8_bmd_box);
/*
 * Purpose          : Figure: Box plot of percentage change in BMD from baseline to Week <<24/52>> by race (BAS)
 *                    (safety analysis set)
 * Programming Spec : 21810_tlf_v1.0.doc
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emzah (Rakesh Muppidi) / date: 13NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21651/stat/main01/dev/analysis/pgms/f_8_3_2_advs_mdev.sas (emvsx (Phani Tata) / date: 20JUN2022)
 ******************************************************************************/
/* Changed by       : glimy (Victoria Aitken) / date: 19FEB2024
 * Reason           : updated parameter being used
 ******************************************************************************/

%load_ads_dat(admk_view, adsDomain = admk , adslWhere =  &bas_cond )
%load_ads_dat(adsl_view , adsDomain = adsl , where =  &bas_cond )

%extend_data(indat = admk_view  , outdat = admk);
%extend_data(indat = adsl_view  , outdat = adsl);

%macro subgrp(vis_sub=,vis=,loc=,fname=,ystart=,yend=);

data admk_&vis._&fname.;
    set admk;
    where not missing (&treat_arm_a.) and paramcd in ("BMD","BMDAV1_4") and &vis_sub. and mkloc=upcase("&loc.");
    attrib   &treat_arm_a.  label = "Treatment Group" ;
RUN;

proc datasets library=work nolist;
    modify admk_&vis._&fname. ;
    format aval base pchg 9.2;
quit;


 *<-----------------------------*;
 ***< 2. Mean-deviation Plots ***;
 *<-----------------------------*;

 %MTITLE;

 %BoxPlot(
     data             = admk_&vis._&fname.
   , xvar             = race
   , yvar             = pchg
   , by               = mkloc
   , equal_axis_by    = <DEFAULT>
   , class            = &treat_arm_a.
   , class_data       = <DEFAULT>
   , class_order      = &mosto_param_class_order.
   , class_scale      = 0.8
   , completeclass    = <DEFAULT>
   , datalabel        =
   , annodata         =
   , title_ny         = No
   , titfoot_scale    = 1
   , figtit_file_ny   = YES
   , legend           = yes big_n
   , legendtitle      = Treatment Group
   , data_n           = admk_&vis._&fname.
   , data_n_ignore    =
   , subject          = usubjid
   , style            = REPORT
   , style_options    =
   , outdat           =
   , combo_tag        = YES
   , template2log     = NO
   , box_style        = NORMAL
   , min_obs_for_box  = 0
   , boxwidth         = <DEFAULT>
   , connect          =
   , show_stat        =
   , stat_marker      = PLUS
   , show_scatter     = NO
   , marker_legend    = <DEFAULT>
   , gridlines        = NO
   , extremes         = NO
   , outlier_marker   = X
   , desc_footnote    = NO
   , ticksplitchar    =
   , xrefline         =
   , xreflinetext     =
   , xlabel           = Race
   , xoffset          = <DEFAULT>
   , ytype            = LIN
   , ystart           = &ystart.
   , yend             = &yend.
   , yincrement       = AUTO
   , yticklist        = AUTO
   , yrefline         =
   , yreflinetext     =
   , ylabel           = % change from baseline in BMD
   , yaxisbreakranges =
   , axisbreaktype    = <DEFAULT>
   , axisbreaksymbol  = <DEFAULT>
   , filename         = &prog._&vis._&fname.
 )

%mend subgrp;

%subgrp(vis_sub=%str(avisitn=240),vis=24,loc=%str(Hip),fname=hip,ystart=-20,yend=40);
%subgrp(vis_sub=%str(avisitn=520),vis=52,loc=%str(Hip),fname=hip,ystart=-20,yend=40);
%subgrp(vis_sub=%str(avisitn=240),vis=24,loc=%str(Femoral Neck),fname=neck,ystart=-20,yend=40);
%subgrp(vis_sub=%str(avisitn=520),vis=52,loc=%str(Femoral Neck),fname=neck,ystart=-20,yend=40);
%subgrp(vis_sub=%str(avisitn=240),vis=24,loc=%str(Lumbar Spine),fname=lumb,ystart=-15,yend=15);
%subgrp(vis_sub=%str(avisitn=520),vis=52,loc=%str(Lumbar Spine),fname=lumb,ystart=-15,yend=15);
/* Use %endprog at the end of each study program */
%endprog;
