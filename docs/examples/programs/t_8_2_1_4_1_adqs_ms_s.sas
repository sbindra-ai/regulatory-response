/*******************************************************************************
 * Bayer AG
 * Study            :  
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog( name      = t_8_2_1_4_1_adqs_ms_s );
/*
 * Purpose          : Custom table: MENQOL total score:
 *                  summary statistics and change from baseline by treatment group (FAS)
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : erjli (Yosia Hadisusanto) / date: 07NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/t_8_2_1_4_1_adqs_ms_s.sas (emvsx (Phani Tata) / date: 01AUG2023)
 ******************************************************************************/

%m_mean_base_chg(param1 =      %str(MENB999),
               param2 =      %str(MENOPAUSE-SPECIFIC QUALITY-OF-LIFE QUESTIONNAIRE (MENQOL)),
               ads    =      %str(adqs),
               param =       %str(paramcd),
               pop   =        %str(&fas_cond.),
               round    =   0.1
                     ) ;

%endprog;
