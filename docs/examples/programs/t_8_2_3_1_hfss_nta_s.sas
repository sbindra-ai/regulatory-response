/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_2_3_1_hfss_nta_s);
/*
 *
 * Purpose          : Custom table: Mean frequency of nighttime awakenings:
 *                    summary statistics and change from baseline by treatment group (FAS)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 29NOV2023
 * Reference prog   :
 ******************************************************************************/

;

%m_mean_base_chg(param1 =      %str(HFDB995),
               param2 =      %str(TWICE DAILY HOT FLASH DIARY V2.0),
               ads    =      %str(adqshfss),
               param =       %str(paramcd),
               pop   =        %str(&fas_cond.),
               round    =   0.1
                     ) ;

%endprog;

