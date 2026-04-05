/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_2_2_adqs_bdi_s);
/*
 * Purpose          : Custom table: BDI-II total score:
 *                    summary statistics and change from baseline by treatment group (FAS)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : erjli (Yosia Hadisusanto) / date: 10NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/t_8_2_2_adqs_bdi_s.sas
 ******************************************************************************/

*summary statistics and change from baseline by treatment group * ;
*Table : Table: BDIB999 - Total Score
                  BECK DEPRESSION INVENTORY (BDI):*;

%m_mean_base_chg(param1 =      %str(BDIB999),
               param2 =      %str(BECK DEPRESSION INVENTORY - II (BDI-II)),
               ads    =      %str(adqs),
               param =       %str(paramcd),
               pop   =        %str(&fas_cond.),
               round    =   0
                     ) ;

%endprog;

