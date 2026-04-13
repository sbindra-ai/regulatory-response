/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %LET prog = #runall_21652_03_section_8_4;
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
 * Author(s)        : egavb (Reema S Pawar) / date: 28SEP2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/#runall_21652_03_section_8_4.sas (eokcw (Vijesh Shrivastava) / date: 18SEP2023)
 ******************************************************************************/
/* Changed by       : eokcw (Vijesh Shrivastava) / date: 20DEC2023
 * Reason           : Update inimode to ANALYSIS after unblinded data
 ******************************************************************************/

*******************************************************************************;
*< Initialize study;
*******************************************************************************;
%initsystems(initstudy=5, mosto=7, spro=3, adamap=2, gral=4, eva = 2, poster = 1, alsc = 2, dtools = 2, docfish = 2);

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



/*8.4.1 Subgroup analyses*/
%add_job(programFile=&prgdir/t_8_4_1_subgrp_hf.sas);
%add_job(programFile=&prgdir/t_8_4_1_subgrp_shf.sas);
%add_job(programFile=&prgdir/t_8_4_1_subgrp_pr.sas);
%add_job(programFile=&prgdir/t_8_4_1_subgrp_pr_isi.sas);
%add_job(programFile=&prgdir/t_8_4_1_subgrp_mq.sas);
%add_job(programFile=&prgdir/t_8_4_1_subgrp_vmq.sas);


/*8.4.2 Sleep efficiency measurement - Actigraphy*/
%add_job(programFile=&prgdir/t_8_4_2_adxk_sleep_sbase.sas);

*Execute all above jobs;
%run_jobs()

/*< Create word documents */

%document_finish(
    template     = %NRSTR(template_section_08_4\.txt)
  , headerRow2   = &reportno
  , resultPrefix = &resultPrefix
)

/*clean up*/
%endprog;