/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = f_8_2_3_1_hfss_cg_cum );
/*
 * Purpose          : Figure: Cumulative change of subjects by
 *                    Relative change (%) from  baseline in mean daily frequency of
 *                    moderate to severe hot flashes
 *                    <<at Week 4/at Week 12>> (<<FAS>>)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 29DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/f_8_2_3_1_hfss_cg_cum.sas (emvsx (Phani Tata) / date: 02OCT2023)
 ******************************************************************************/

%m_f_cum_chg(   param1 = HFDB998 ,
                  param2=  %str(TWICE DAILY HOT FLASH DIARY V2.0),
                  ads = adqshfss  ,
                  pop =  &fas_cond ,
                  xtick =   -100 -80 -55 -30 -5   20 45 70
                  );
