/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %LET prog = #runall_21651_03_section_8_2;
/*
 * Purpose          : Start all programs, related to that study.
 * Programming Spec :
 * Validation Level : 1 - verification by review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 13OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/#runall_21652_03_section_8_2.sas (eokcw (Vijesh Shrivastava) / date: 18SEP2023)
 ******************************************************************************/
/* Changed by       : eokcw (Vijesh Shrivastava) / date: 20DEC2023
 * Reason           : Update inimode to ANALYSIS after unblinded data
 ******************************************************************************/

*******************************************************************************;

*< Initialize study;
*******************************************************************************;

%initsystems( initstudy=5, mosto=7, spro=3, adamap=2,
             gral=4, eva = 2, poster = 1, alsc = 2,
             dtools = 2, docfish = 2 , valir=1);
 %initstudy(
       display_formats = Y
     , inimode         = ANALYSIS
                    );
%LET mostocalcpercwidth= optimal;
%LET mostoprintpercwidth= yes;

*** attention: only in TLF runall display formats are used;
%LET poster_param_iniprog = &prgdir./ini_prog.sas;
%LET poster_param_termprog = &prgdir./end_prog.sas;    %*? End code before termination of each job;

%IF %upcase(&stage)=DEV %THEN %DO;
    %remove_trc(dir = &logDir., remove = Y)
%END;

*******************************************************************************;
*< 8.2 Efficacy ;
*******************************************************************************;
*********************************************;
* 8.2.1 Primary and key secondary endpoints
  8.2.1.1 Frequency of moderate to severe hot flashes
  8.2.1.1.1 Main analyses;
*********************************************;
%add_job(programFile=&prgdir/i_8_2_1_gloss_endpt.sas );
%add_job(programFile=&prgdir/t_8_2_1_1_1_hfss_mhf_s.sas);
%add_job(programFile=&prgdir/t_8_2_1_1_1_hfss_mhf_p.sas);
%add_job(programFile=&prgdir/f_8_2_1_1_1_hfss_mhf_s.sas);
%add_job(programFile=&prgdir/f_8_2_1_1_1_hfss_mhf_p.sas);
%add_job(programFile=&prgdir/if_8_2_1_1_1_hfss.sas );
*8.2.1.1.2 Sensitivity analyses*;
%add_job(programFile=&prgdir/f_8_2_1_1_2_hfss_scat.sas );*  Scatterplot of residuals and predicted  **;
%add_job(programFile=&prgdir/f_8_2_1_1_2_hfss_qq.sas    );
%add_job(programFile=&prgdir/i_8_2_1_1_2_hfss_np.sas );*non-parametric analysis *;
%add_job(programFile=&prgdir/i_8_2_1_1_2_hfss_tp.sas);*Tipping point analysis *;
*8.2.1.1.3 Supplementary analyses*;
%add_job(programFile=&prgdir/if_8_2_1_1_3_hfss_sp1.sas);*First supplementary estimand *;
%add_job(programFile=&prgdir/if_8_2_1_1_3_hfss_sp2.sas); *Second supplementary estimand *;
**********************************************;
*8.2.1.2 Severity of moderate to severe hot flashes
*8.2.1.2.1 Main analysis
**********************************************;;
%add_job(programFile=&prgdir/t_8_2_1_2_1_hfss_shf_s.sas);
%add_job(programFile=&prgdir/t_8_2_1_2_1_hfss_shf_p.sas);
%add_job(programFile=&prgdir/f_8_2_1_2_1_hfss_shf_s.sas);
%add_job(programFile=&prgdir/f_8_2_1_2_1_hfss_shf_p.sas);
*8.2.1.2 Severity of moderate to severe hot flashes*;
*MMRM analysis *;
%add_job(programFile=&prgdir/if_8_2_1_2_1_shf.sas);
*8.2.1.2.2 Sensitivity analysis*;
%add_job(programFile=&prgdir/f_8_2_1_2_2_shf_scat.sas  );*Scatterplot of residuals and predicted **;
%add_job(programFile=&prgdir/f_8_2_1_2_2_shf_qq.sas    );  *  QQ-plot  *;
%add_job(programFile=&prgdir/i_8_2_1_2_2_shf_np.sas);*- non-parametric analysis *;
%add_job(programFile=&prgdir/i_8_2_1_2_2_shf_tp.sas);*Tipping point analysis *;
*8.2.1.2.3 Supplementary analysis*;
%add_job(programFile=&prgdir/if_8_2_1_2_3_shf_sp1.sas);*First supplementary estimand *;
%add_job(programFile=&prgdir/if_8_2_1_2_3_shf_sp2.sas);*Second supplementary estimand *;
**********************************************;
*8.2.1.3 PROMIS SD SF 8b
*8.2.1.3.1 Main analysis
**********************************************;;
%add_job(programFile=&prgdir/t_8_2_1_3_1_adqs_ts_s.sas);
%add_job(programFile=&prgdir/f_8_2_1_3_1_adqs_line.sas);
%add_job(programFile=&prgdir/i_8_2_1_3_1_pr.sas );*T-score change from baseline - MMRM analysis *;
%add_job(programFile=&prgdir/t_8_2_1_3_1_adqs_trs_s.sas);
%add_job(programFile=&prgdir/t_8_2_1_3_1_adqs_rs_f.sas);
%add_job(programFile=&prgdir/f_8_2_1_3_1_adqs_rbar.sas);
%add_job(programFile=&prgdir/f_8_2_1_3_1_adqs_cum.sas);
*8.2.1.3.2 Sensitivity analysis*;
%add_job(programFile=&prgdir/f_8_2_1_3_2_pr_scat.sas);*Scatterplot of residuals *;
%add_job(programFile=&prgdir/f_8_2_1_3_2_pr_qq.sas);*QQ-Plot from MMRM  *;
%add_job(programFile=&prgdir/i_8_2_1_3_2_pr_np.sas);*- non-parametric analysis *;
%add_job(programFile=&prgdir/i_8_2_1_3_2_pr_tp.sas);*Tipping point analysis *;
*8.2.1.3.3 Supplementary analysis*;
%add_job(programFile=&prgdir/i_8_2_1_3_3_pr_sp1.sas);*First supplementary estimand *;
%add_job(programFile=&prgdir/i_8_2_1_3_3_pr_sp2.sas);*First supplementary estimand - Line plot *;
**********************************************;
*8.2.1.4 MENQOL
*8.2.1.4.1 Main analysis
**********************************************;;
%add_job(programFile=&prgdir/t_8_2_1_4_1_adqs_ms_s.sas);
%add_job(programFile=&prgdir/f_8_2_1_4_1_adqs_line.sas);
%add_job(programFile=&prgdir/f_8_2_1_4_1_adqs_cum.sas);
*8.2.1.4 MENQOL
 8.2.1.4.1 Main analysis *;
%add_job(programFile=&prgdir/i_8_2_1_4_1_mq.sas );
*8.2.1.4.2 Sensitivity analysis*;
%add_job(programFile=&prgdir/f_8_2_1_4_2_mq_scat.sas);*Scatterplot of residuals *;
%add_job(programFile=&prgdir/f_8_2_1_4_2_mq_qq.sas);*QQ-Plot from MMRM  *;
%add_job(programFile=&prgdir/i_8_2_1_4_2_mq_np.sas);*- non-parametric analysis *;
%add_job(programFile=&prgdir/i_8_2_1_4_2_mq_tp.sas);*Tipping point analysis *;
*8.2.1.4.3 Supplementary analysis*;
%add_job(programFile=&prgdir/i_8_2_1_4_3_mq_sp1.sas);*First supplementary estimand *;
%add_job(programFile=&prgdir/i_8_2_1_4_3_mq_sp2.sas);*First supplementary estimand *;
*********************************************;
*8.2.2 Supportive secondary endpoints*;
*********************************************;
%add_job(programFile=&prgdir/t_8_2_2_adqs_bdi_s.sas);
%add_job(programFile=&prgdir/t_8_2_2_adqs_bdi_t.sas);
*********************************************;
*8.2.3 Exploratory endpoints analyses
*8.2.3.1 HFDD related exploratory endpoints
*********************************************;
%add_job(programFile=&prgdir/t_8_2_3_1_hfss_hf_s.sas);
%add_job(programFile=&prgdir/f_8_2_3_1_hfss_cg_cum.sas);
%add_job(programFile=&prgdir/f_8_2_3_1_hfss_hf_cum.sas);
%add_job(programFile=&prgdir/t_8_2_3_1_adtte_km_qs.sas);
%add_job(programFile=&prgdir/f_8_2_3_1_adtte_km_cum.sas);
%add_job(programFile=&prgdir/t_8_2_3_1_hfss_mdhf_s.sas);
%add_job(programFile=&prgdir/f_8_2_3_1_hfss_md_lin.sas );
%add_job(programFile=&prgdir/t_8_2_3_1_hfss_nta_s.sas);
%add_job(programFile=&prgdir/f_8_2_3_1_hfss_nta_cum.sas);
%add_job(programFile=&prgdir/f_8_2_3_1_hfss_nt_lin.sas );
%add_job(programFile=&prgdir/f_8_2_3_1_shf_hf_cum.sas);
%add_job(programFile=&prgdir/f_8_2_3_1_shf_cg_cum.sas);
%add_job(programFile=&prgdir/t_8_2_3_1_hfss_sd_s.sas);
%add_job(programFile=&prgdir/f_8_2_3_1_hfss_sd_lin.sas );
*********************************************;
*8.2.3.2 MENQOL related exploratory endpoints
*********************************************;
%add_job(programFile=&prgdir/t_8_2_3_2_adqs_ind_s.sas);
%add_job(programFile=&prgdir/t_8_2_3_2_adqs_vas_s.sas);
%add_job(programFile=&prgdir/f_8_2_3_2_adqs_vas_l.sas);
%add_job(programFile=&prgdir/t_8_2_3_2_adqs_psy_s.sas);
%add_job(programFile=&prgdir/f_8_2_3_2_adqs_psy_l.sas );
%add_job(programFile=&prgdir/t_8_2_3_2_adqs_phy_s.sas);
%add_job(programFile=&prgdir/f_8_2_3_2_adqs_phy_l.sas );
%add_job(programFile=&prgdir/t_8_2_3_2_adqs_sex_s.sas);
%add_job(programFile=&prgdir/f_8_2_3_2_adqs_sex_l.sas);
*********************************************;
*8.2.3.3 Insomnia severity index
********************************************;
%add_job(programFile=&prgdir/t_8_2_3_3_adqs_isits_s.sas);
%add_job(programFile=&prgdir/t_8_2_3_3_adqs_isi_sev.sas);
%add_job(programFile=&prgdir/t_8_2_3_3_adqs_isitst.sas);
*********************************************;
*8.2.3.4 Patient global impression of severity and change
********************************************;
%add_job(programFile=&prgdir/t_8_2_3_4_adqs_pgic.sas );
%add_job(programFile=&prgdir/t_8_2_3_4_adqs_pgis.sas );
%add_job(programFile=&prgdir/t_8_2_3_4_adqs_pgit.sas );
*********************************************;
*8.2.3.5 European quality of life 5-dimension 5-level questionnaire
********************************************;
%add_job(programFile=&prgdir/t_8_2_3_5_adqs_eq5d_f.sas);
%add_job(programFile=&prgdir/t_8_2_3_5_adqs_eq5d_t.sas );
%add_job(programFile=&prgdir/t_8_2_3_5_adqs_eq5d_s.sas );
%run_jobs();

*********************************************;
*8.2.1.13 Overview of the main analyses results*;
* this has to run after all the other outputs are created;
* since it takes pvalue from other outputs;
*********************************************;
%INCLUDE "&PRGDIR./i_8_2_1_13_pval_trans.sas"; *Program to Create Combined P-value data*;
%INCLUDE "&PRGDIR./i_8_2_1_13_main_r.sas";
%INCLUDE "&PRGDIR./i_8_2_1_13_sup1_r.sas";
%INCLUDE "&PRGDIR./i_8_2_1_13_sup2_r.sas";
%add_job(programFile=&prgdir/i_8_2_1_13_over_main.sas);
%add_job(programFile=&prgdir/i_8_2_1_13_over_sup1.sas);
%add_job(programFile=&prgdir/i_8_2_1_13_over_sup2.sas);
%run_jobs();

/*< Create word documents */
%document_finish(
    template     = %NRSTR(template_section_08_2\.txt)
  , headerRow2   = &reportno
  , resultPrefix = &resultPrefix
)
/*clean up*/
%endprog;