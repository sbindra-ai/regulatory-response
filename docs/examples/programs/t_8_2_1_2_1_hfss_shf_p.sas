/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_2_1_2_1_hfss_shf_p  );
/*
 * Purpose          : Mean daily severity of moderate to severe hot flashes:
 *                    summary statistics and percent change from baseline by treatment group (FAS)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : erjli (Yosia Hadisusanto) / date: 24NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/t_8_2_1_2_1_hfss_shf_p.sas (emvsx (Phani Tata) / date: 27JUL2023)
 ******************************************************************************/
%m_mean_base_chgp(param1 =      %str(HFDB999),
                param2   =      %str(TWICE DAILY HOT FLASH DIARY V2.0),
                ads      =      %str(adqshfss),
                param    =      %str(paramcd),
                pop      =      %str(&fas_cond.),
               round =       0.1
                     ) ;

%endprog;
