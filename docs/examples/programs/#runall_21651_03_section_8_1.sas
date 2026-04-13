/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %LET prog = #runall_21651_03_section_8_1;
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
 * Author(s)        : enpjp (Prashant Patel) / date: 22SEP2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/#runall_21652_03_section_8_1.sas (enpjp (Prashant Patel) / date: 30AUG2023)
 ******************************************************************************/
/* Changed by       : eokcw (Vijesh Shrivastava) / date: 20DEC2023
 * Reason           : Update inimode to ANALYSIS after unblinded data
 ******************************************************************************/



*******************************************************************************;
*< Initialize study;
*******************************************************************************;
%initsystems( initstudy=5, mosto=7, spro=3, adamap=2, gral=4, eva = 2, poster = 1, alsc = 2, dtools = 2, docfish = 2);
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
*< 14.1 Demographics;
*******************************************************************************;
*********************************************;
* 8.1.1 Study Perios and sample size;
*********************************************;
%add_job(programFile=&prgdir/t_8_1_1_adsl_smpsz.sas);
%add_job(programFile=&prgdir/t_8_1_1_adsl_sbj_reg.sas);
%add_job(programFile=&prgdir/t_8_1_1_adsl_site_reg.sas);
%add_job(programFile=&prgdir/t_8_1_1_addv_pdsf_tunt.sas);
%add_job(programFile=&prgdir/t_8_1_1_addv_sbj_imppd.sas);

*********************************************;
*8.1.2 Subject validity status;
*********************************************;
%add_job(programFile=&prgdir/t_8_1_2_adsl_sbj_vlty_fnds.sas);

*********************************************;
*8.1.3 Disposition;
*********************************************;
%add_job(programFile=&prgdir/t_8_1_3_adds_sbj_disp.sas);
%add_job(programFile=&prgdir/t_8_1_3_adds_disp_ovrl.sas);
%add_job(programFile=&prgdir/t_8_1_3_adsv_sbj_vist.sas);

*********************************************;
* 8.1.4 Demographics;
*********************************************;
%add_job(programFile=&prgdir/t_8_1_4_adsl_demo_ovrl.sas);
%add_job(programFile=&prgdir/t_8_1_4_adsl_demo_sub.sas);

*********************************************;
* 8.1.5 Medical history;
*********************************************;
%add_job(programFile=&prgdir/t_8_1_5_admh_socpt.sas);
%add_job(programFile=&prgdir/t_8_1_5_adrp_rpmens_hist.sas);

*********************************************;
* 8.1.6 Prior and concomitant medication;
*********************************************;
%add_job(programFile=&prgdir/t_8_1_6_adcm_sbj_prior_cm.sas);
%add_job(programFile=&prgdir/t_8_1_6_adcm_sbj_cm.sas);
%add_job(programFile=&prgdir/t_8_1_6_adcm_sbj_psttrtmed.sas);

* 8.1.7 Intercurrent Events;
****************************************************;
%add_job(programFile=&prgdir/t_8_1_7_ice_adds_rsn.sas);
%add_job(programFile=&prgdir/t_8_1_7_ice_adex_rsn.sas);
%add_job(programFile=&prgdir/t_8_1_7_ice_adcm_rsn.sas);
%add_job(programFile=&prgdir/t_8_1_7_ice_adex.sas);
%add_job(programFile=&prgdir/t_8_1_7_adtte_km_ds.sas);
%add_job(programFile=&prgdir/f_8_1_7_tte_dis_km.sas);
%add_job(programFile=&prgdir/t_8_1_7_adtte_km_cm.sas);
%add_job(programFile=&prgdir/f_8_1_7_tte_pcm_km.sas);



*Execute all above jobs;
%run_jobs()

/*< Create word documents */


%document_finish(
    template     = %NRSTR(template_section_08_1\.txt)
  , headerRow2   = &reportno
  , resultPrefix = &resultPrefix
)

/*clean up*/
%endprog;