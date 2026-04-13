/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = f_8_2_1_4_1_adqs_cum  );
/*
 * Purpose          : Cumulative percent of subjects by change from baseline in MENQOL total score at <<Week 4/Week 12>> (FAS)
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 27NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/f_8_2_1_4_1_adqs_cum.sas (emvsx (Phani Tata) / date: 20OCT2023)
 ******************************************************************************/


%m_f_cum_per(   param1 = MENB999 ,
                  param2=  %str(MENOPAUSE-SPECIFIC QUALITY-OF-LIFE QUESTIONNAIRE (MENQOL)),
                  ads = ADQS  ,
                  pop =  &fas_cond,
                  xtick =  -6 -5 -4 -3 -2 -1 0 1 2 3

                  );
