/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = f_8_2_1_3_1_adqs_line  );
/*
 * Purpose          : Line plot of change from baseline in PROMIS SD SF 8b total T-score by treatment group
 *                     (FAS)
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 27NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/f_8_2_1_3_1_adqs_line.sas (emvsx (Phani Tata) / date: 28SEP2023)
 ******************************************************************************/

*PSDSB998 - Total Score raw of PROMIS sleep disturbance short form 8B V1.0*;

%m_f_line_plot( param1 = %str(PSDSB999) ,
              param2=  %str(PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0),
             ads    = %str(adqs) ,
             pop    = %str(&fas_cond.) ,
             label_x  = %str(Time (weeks)) ,
             label_y  = %nrstr(Change in total T-score (mean +/- 95% CI)) ,
             lgtitle = %str(Treatment Group),
             cond = %str(  and ANL04FL = "Y")
             ) ;

%endprog;