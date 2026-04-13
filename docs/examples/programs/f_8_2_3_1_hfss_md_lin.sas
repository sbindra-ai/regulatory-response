/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = f_8_2_3_1_hfss_md_lin  );
/*
 * Purpose          : Line plot of change from baseline in mean daily frequency of mild, moderate, and severe hot flashes by treatment group(FAS)
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 06MAR2024
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/f_8_2_3_1_hfss_md_lin.sas (emvsx (Phani Tata) / date: 28SEP2023)
 ******************************************************************************/

*HFDB997 - Mean daily frequency of mild, moderate and severe hot flashes*;

%m_f_line_plot(
    param1   = %str(HFDB997)
  , param2   = %str(TWICE DAILY HOT FLASH DIARY V2.0)
  , ads      = %str(adqshfss)
  , pop      = %str(&fas_cond.)
  , label_x  = %str(Time (weeks))
  , label_y  = %nrstr(Change in mean daily frequency (mean +/- 95% CI))
  , lgtitle  = %str(Treatment Group)
  , cond     = %str( )
  , avisvar  = avisitn
  , xtypeval = discrete
)
;

%endprog;
