/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = f_8_2_1_3_1_adqs_cum  );
/*
 * Purpose          : Cumulative percent of subjects by change from baseline in PROMIS SD SF 8b total T-score at
 *                   <<Week 4/Week 12>> (FAS)
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 27NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/f_8_2_1_3_1_adqs_cum.sas (emvsx (Phani Tata) / date: 02OCT2023)
 ******************************************************************************/

%m_f_cum_per(   param1 = PSDSB999 ,
                  param2= PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0,
                  ads = ADQS  ,
                  pop =  &fas_cond,
                  xtick =  -40 -30 -20 -10 0 10 20 25
                  );

%endprog;