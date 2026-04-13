/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_2_1_3_1_adqs_ts_s);
/*
 * Purpose          : PROMIS SD SF 8b total T-score:
 *                    summary statistics and change from baseline by treatment group (FAS)
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 27NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/t_8_2_1_3_1_adqs_ts_s.sas (emvsx (Phani Tata) / date: 02AUG2023)
 ******************************************************************************/

%m_mean_base_chg(param1 =      %str(PSDSB999),
               param2 =      %str(PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0),
               ads    =      %str(adqs),
               param =       %str(paramcd),
               pop   =        %str(&fas_cond.),
               round    =   0
                     ) ;

%endprog;
