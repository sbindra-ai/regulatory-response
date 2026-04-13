/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %LET prog = #runall_21651_06_topline;
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
 * Author(s)        : eokcw (Vijesh Shrivastava) / date: 01DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/#runall_21652_06_topline.sas (eokcw (Vijesh Shrivastava) / date: 19SEP2023)
 ******************************************************************************/
/* Changed by       : eokcw (Vijesh Shrivastava) / date: 20DEC2023
 * Reason           : Update inimode to ANALYSIS after unblinded data
 ******************************************************************************/

*******************************************************************************;
*< Initialize study;
*******************************************************************************;
%initsystems( initstudy=5, mosto=7, spro=3, adamap=2, gral=4, eva = 2, poster = 1, alsc = 2, dtools = 2, docfish = 2 , valir=1);
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

*********************************************;
*8.1.3 Disposition;
*********************************************;

%add_job(programFile=&prgdir/t_8_1_3_adds_disp_ovrl.sas);

*********************************************;
* 8.1.4 Demographics;
*********************************************;
%add_job(programFile=&prgdir/t_8_1_4_adsl_demo_ovrl.sas);


*********************************************;
* 8.2.1 Primary and key secondary endpoints
  8.2.1.1 Frequency of moderate to severe hot flashes
  8.2.1.1.1 Main analyses;
*********************************************;

%add_job(programFile=&prgdir/t_8_2_1_1_1_hfss_mhf_s.sas);
%add_job(programFile=&prgdir/if_8_2_1_1_1_hfss.sas );

%add_job(programFile=&prgdir/if_8_2_1_1_3_hfss_sp1.sas);*First supplementary estimand *;
%add_job(programFile=&prgdir/if_8_2_1_1_3_hfss_sp2.sas); *Second supplementary estimand *;


**********************************************;
*8.2.1.2 Severity of moderate to severe hot flashes
*8.2.1.2.1 Main analysis
**********************************************;;

%add_job(programFile=&prgdir/t_8_2_1_2_1_hfss_shf_s.sas);
%add_job(programFile=&prgdir/if_8_2_1_2_1_shf.sas);

*8.2.1.2.3 Supplementary analysis*;
%add_job(programFile=&prgdir/if_8_2_1_2_3_shf_sp1.sas);*First supplementary estimand *;
%add_job(programFile=&prgdir/if_8_2_1_2_3_shf_sp2.sas);*Second supplementary estimand *;

**********************************************;
*8.2.1.3 PROMIS SD SF 8b
*8.2.1.3.1 Main analysis
**********************************************;;

%add_job(programFile=&prgdir/t_8_2_1_3_1_adqs_ts_s.sas);
%add_job(programFile=&prgdir/i_8_2_1_3_1_pr.sas );*T-score change from baseline - MMRM analysis *;

*8.2.1.3.3 Supplementary analysis*;
%add_job(programFile=&prgdir/i_8_2_1_3_3_pr_sp1.sas);*First supplementary estimand *;
%add_job(programFile=&prgdir/i_8_2_1_3_3_pr_sp2.sas);*First supplementary estimand - Line plot *;


**********************************************;
*8.2.1.4 MENQOL
*8.2.1.4.1 Main analysis
**********************************************;;

%add_job(programFile=&prgdir/t_8_2_1_4_1_adqs_ms_s.sas);
%add_job(programFile=&prgdir/i_8_2_1_4_1_mq.sas );

*8.2.1.4.3 Supplementary analysis*;
%add_job(programFile=&prgdir/i_8_2_1_4_3_mq_sp1.sas);*First supplementary estimand *;
%add_job(programFile=&prgdir/i_8_2_1_4_3_mq_sp2.sas);*First supplementary estimand *;


****************************************************;
* 8.3.1 Treatment compliance, duration and exposure;
****************************************************;

/*8.3.2.3 Treatment-emergent adverse events*/

%add_job(programFile=&prgdir/t_8_3_2_3_adae_teae_socpt.sas);

/*8.3.2.4 Treatment-Emergent serious adverse events*/
%add_job(programFile=&prgdir/t_8_3_2_4_adae_tesaesocpt.sas);

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

%run_jobs();

/*< Create word documents */


%document_finish(
    template     = %NRSTR(template_topline\.txt)
  , headerRow2   = &reportno
  , resultPrefix = &resultPrefix
)

/*clean up*/
%endprog;