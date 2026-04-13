/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_2_3_3_adqs_isits_s   );
/*
 * Purpose          :  ISI total score Insomnia severity index:
 *                     summary statistics and change from baseline by treatment group (FAS):
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
*summary statistics and change from baseline by treatment group * ;
*Table : Table:ISIB0999 - Total Score ;

%m_mean_base_chg(param1 =      %str(ISIB0999),
                param2 =      %str(ISI),
                ads    =      %str(adqs),
                param =       %str(paramcd),
               pop   =        %str(&fas_cond.),
               round    =   0
                     ) ;

%endprog;

