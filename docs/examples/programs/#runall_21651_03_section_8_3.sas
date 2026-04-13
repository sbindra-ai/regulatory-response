/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %LET prog = #runall_21651_03_section_8_3;
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
 * Author(s)        : enpjp (Prashant Patel) / date: 10SEP2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/#runall_21652_03_section_8_3.sas (enpjp (Prashant Patel) / date: 26JUN2023)
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


*******************************************************************************;
*< 8.3 Safety;
********************************************************************************;

****************************************************;
* 8.3.1 Treatment compliance, duration and exposure;
****************************************************;
%add_job(programFile=&prgdir/t_8_3_1_adex_trtdurtrtgrp.sas);
%add_job(programFile=&prgdir/t_8_3_1_adex_durstdrg.sas);
%add_job(programFile=&prgdir/t_8_3_1_adex_comptrtgrp.sas);
%add_job(programFile=&prgdir/t_8_3_1_adex_compstdrg.sas);
%add_job(programFile=&prgdir/t_8_3_1_adex_avgdos.sas);
%add_job(programFile=&prgdir/t_8_3_1_adex_totdos.sas);

/*8.3.2 Adverse events including deaths*/
/*8.3.2.1 Adeverse events*/
%add_job(programFile=&prgdir/t_8_3_2_1_adae_ovrl_pretrt.sas);
%add_job(programFile=&prgdir/t_8_3_2_1_adae_pretrtsocpt.sas);
%add_job(programFile=&prgdir/t_8_3_2_1_adae_ovrlpsttrt.sas);
%add_job(programFile=&prgdir/t_8_3_2_1_adae_psttrtsocpt.sas);

/*8.3.2.2 Serious adverse events*/
%add_job(programFile=&prgdir/t_8_3_2_2_adae_sae_socpt.sas);

/*8.3.2.3 Treatment-emergent adverse events*/
%add_job(programFile=&prgdir/t_8_3_2_3_adae_teae_ovrl.sas);
%add_job(programFile=&prgdir/t_8_3_2_3_adae_teae_socpt.sas);
%add_job(programFile=&prgdir/t_8_3_2_3_adae_teae_sdr.sas);
%add_job(programFile=&prgdir/t_8_3_2_3_adae_tesi_socpt.sas);
%add_job(programFile=&prgdir/t_8_3_2_3_adae_si_bld.sas);
%add_job(programFile=&prgdir/t_8_3_2_3_adae_tesdd_socpt.sas);
%add_job(programFile=&prgdir/t_8_3_2_3_adae_teaemisocpt.sas);
%add_job(programFile=&prgdir/t_8_3_2_3_adae_tesdmisocpt.sas);
%add_job(programFile=&prgdir/t_8_3_2_3_adae_tmrel_socpt.sas);
%add_job(programFile=&prgdir/t_8_3_2_3_ae_gt5_socpt.sas);

/*8.3.2.4 Treatment-Emergent serious adverse events*/
%add_job(programFile=&prgdir/t_8_3_2_4_adae_tesaesocpt.sas);
%add_job(programFile=&prgdir/t_8_3_2_4_adae_tesaemi.sas);
%add_job(programFile=&prgdir/t_8_3_2_4_adae_tesdsocpt.sas);
%add_job(programFile=&prgdir/t_8_3_2_4_adae_tesdmisocpt.sas);

/*8.3.1.5 Deaths*/
%add_job(programFile=&prgdir/t_8_3_2_5_adae_dth_socpt.sas);
%add_job(programFile=&prgdir/t_8_3_2_5_adae_teaedth.sas);

/*8.3.3 Physical examinations*/
%add_job(programFile=&prgdir/t_8_3_3_advs_ph_sbase.sas);
%add_job(programFile=&prgdir/f_8_3_3_adpe_box.sas);


/*8.3.4 Vital signs*/
%add_job(programFile=&prgdir/t_8_3_4_advs_sbase.sas);
%add_job(programFile=&prgdir/f_8_3_4_advs_box.sas);
%add_job(programFile=&prgdir/f_8_3_4_advs_line.sas);
%add_job(programFile=&prgdir/f_8_3_4_advs_scat.sas);

/*8.3.5 Clinical laboratory*/

%add_job(programFile=&prgdir/t_8_3_5_1_adlb_sbase.sas);
%add_job(programFile=&prgdir/f_8_3_5_1_adlb_box.sas);

%add_job(programFile=&prgdir/t_8_3_5_2_adlb_sbase.sas);
%add_job(programFile=&prgdir/f_8_3_5_2_adlb_box.sas);
%add_job(programFile=&prgdir/f_8_3_5_2_adlb_line.sas);

%add_job(programFile=&prgdir/t_8_3_5_3_adlb_sbase.sas);
%add_job(programFile=&prgdir/f_8_3_5_3_adlb_box.sas);
%add_job(programFile=&prgdir/f_8_3_5_3_adlb_line.sas);


%add_job(programFile=&prgdir/t_8_3_5_4_adlb_sbase.sas);
%add_job(programFile=&prgdir/f_8_3_5_4_adlb_box.sas);
%add_job(programFile=&prgdir/f_8_3_5_4_adlb_line.sas);

%add_job(programFile=&prgdir/t_8_3_5_5_adlb_sbase.sas);
%add_job(programFile=&prgdir/f_8_3_5_5_adlb_box.sas);

%add_job(programFile=&prgdir/t_8_3_5_6_adlb_sbase.sas);
%add_job(programFile=&prgdir/f_8_3_5_6_adlb_box.sas);
%add_job(programFile=&prgdir/t_8_3_5_6_adlb_frq.sas);

%add_job(programFile=&prgdir/t_8_3_5_7_adlb_high.sas );
%add_job(programFile=&prgdir/t_8_3_5_7_adlb_low.sas );


/*8.3.5.9.1 Liver monitoring*/
%add_job(programFile=&prgdir/t_8_3_5_8_1_adlb_frq.sas);
%add_job(programFile=&prgdir/t_8_3_5_8_2_adlb_frq.sas);
%add_job(programFile=&prgdir/t_8_3_5_8_3_adlb_frq.sas);

%add_job(programFile=&prgdir/t_8_3_5_8_adlb_alt_km.sas);
%add_job(programFile=&prgdir/f_8_3_5_8_adlb_alt_km.sas);

%add_job(programFile=&prgdir/t_8_3_5_8_adlb_alp_km.sas);
%add_job(programFile=&prgdir/f_8_3_5_8_adlb_alp_km.sas);

%add_job(programFile=&prgdir/f_8_3_5_8_adlb_liv_hy.sas);
%add_job(programFile=&prgdir/t_8_3_5_8_adlb_liv_hy.sas);

%add_job(programFile=&prgdir/f_8_3_5_8_alb_liv_alp.sas);
%add_job(programFile=&prgdir/t_8_3_5_8_alb_liv_alp.sas);

%add_job(programFile=&prgdir/t_8_3_5_8_alb_cyst_nu.sas);
/*8.3.6 Mammogram*/
%add_job(programFile=&prgdir/t_8_3_6_adpr_mmo_frq.sas);

/*8.3.7 Gynecological ultrasound*/
%add_job(programFile=&prgdir/t_8_3_7_gyn_ult_frq.sas);
%add_job(programFile=&prgdir/t_8_3_7_adfapr_endo_sbase.sas);
%add_job(programFile=&prgdir/t_8_3_7_adfapar_cyst_frq.sas);

/*8.3.8 Cervical cytology*/
%add_job(programFile=&prgdir/t_8_3_8_adpr_crv_ct_frq.sas);

/*8.3.9 Endometrial biopsy*/
%add_job(programFile=&prgdir/t_8_3_9_adpr_end_bio_frq.sas);
%add_job(programFile=&prgdir/t_8_3_9_adfapr_enbio.sas);
%add_job(programFile=&prgdir/t_8_3_9_adfapr_enbiof.sas);

/*8.3.10 Sleepiness scale*/
%add_job(programFile=&prgdir/t_8_3_10_hfss_sleep.sas);

/*8.3.11 Electronic Columbia-suicide severity rating scale*/
%add_job(programFile=&prgdir/t_8_3_11_qscssrs_frq.sas);

*Execute all above jobs;
%run_jobs()

/*< Create word documents */


%document_finish(
    template     = %NRSTR(template_section_08_3\.txt)
  , headerRow2   = &reportno
  , resultPrefix = &resultPrefix
)

/*clean up*/
%endprog;