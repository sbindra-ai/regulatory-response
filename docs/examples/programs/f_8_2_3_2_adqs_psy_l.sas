/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = f_8_2_3_2_adqs_psy_l );
/*
 * Purpose          : Line plot of change from baseline in MENQOL
 *                    Psychosocial score by treatment group (FAS)
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 27NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/f_8_2_3_2_adqs_psy_l.sas (emvsx (Phani Tata) / date: 20OCT2023)
 ******************************************************************************/

*summary statistics and change from baseline by treatment group * ;
*Table : Table:
            MENB995 - Vasomotor
            MENB996 - Psychosocial
            MENB997 - Physical
            MENB998 - Sexual
            MENOPAUSE-SPECIFIC QUALITY-OF-LIFE QUESTIONNAIRE (MENQOL) :*;


%m_f_line_plot( param1 = %str(MENB996) ,
              param2=  %str(MENOPAUSE-SPECIFIC QUALITY-OF-LIFE QUESTIONNAIRE (MENQOL)),
             ads    = %str(adqs) ,
             pop    = %str(&fas_cond.) ,
             label_x  = %str(Time (weeks)) ,
             label_y  = %nrstr(Change in domain score (mean +/- 95% CI))  ,
             lgtitle = %str(Treatment Group)
             ) ;

%endprog;



