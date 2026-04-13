
/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %LET prog = #runall_21651_prod_amendment;
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
 * Author(s)        : eokcw (Vijesh Shrivastava) / date: 29JAN2024
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : enpjp (Prashant Patel) / date: 05MAR2024
 * Reason           : ###AE Special Interest updated as per supplement TLF Spec###
 ******************************************************************************/

*******************************************************************************;
*< Initialize study;
*******************************************************************************;
%initsystems( initstudy=5, mosto=7, spro=3, adamap=2, gral=4, eva = 2, poster = 1, alsc = 2, dtools = 2, docfish = 2);
%initstudy(display_formats = Y);

*** run updated d_formats: new visit format has been created for line plots (_plotvis);
%INCLUDE "&PRGDIR./d_formats.sas";

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

/**** To update Line plot ******/
*** This amendment is added due to clinician's request to display visit with week spread;
%add_job(programFile=&prgdir/f_8_2_1_1_1_hfss_mhf_p.sas);
%add_job(programFile=&prgdir/f_8_2_1_1_1_hfss_mhf_s.sas);
%add_job(programFile=&prgdir/f_8_2_1_2_1_hfss_shf_p.sas);
%add_job(programFile=&prgdir/f_8_2_1_2_1_hfss_shf_s.sas);
%add_job(programFile=&prgdir/f_8_2_1_3_1_adqs_line.sas);
%add_job(programFile=&prgdir/f_8_2_1_4_1_adqs_line.sas);
%add_job(programFile=&prgdir/f_8_2_3_1_hfss_md_lin.sas);
%add_job(programFile=&prgdir/f_8_2_3_1_hfss_nt_lin.sas);
%add_job(programFile=&prgdir/f_8_2_3_1_hfss_sd_lin.sas);
%add_job(programFile=&prgdir/f_8_2_3_2_adqs_phy_l.sas);
%add_job(programFile=&prgdir/f_8_2_3_2_adqs_psy_l.sas);
%add_job(programFile=&prgdir/f_8_2_3_2_adqs_sex_l.sas);
%add_job(programFile=&prgdir/f_8_2_3_2_adqs_vas_l.sas);

/*Line Plot Added*/
%add_job(programFile=&prgdir/if_8_2_1_1_1_hfss.sas);
%add_job(programFile=&prgdir/if_8_2_1_1_3_hfss_sp1.sas);
%add_job(programFile=&prgdir/if_8_2_1_1_3_hfss_sp2.sas);
*******************************************************************************;
*< 8.3 Safety;
********************************************************************************;


/* 8.3.1 Treatment compliance, duration and exposure*/
/*** Update table based on new specs ***/
%add_job(programFile=&prgdir/t_8_3_1_adex_comptrtgrp.sas);

/*Somnolence super script and footnote updated as per supplement TLF Spec.*/
%add_job(programFile=&prgdir/t_8_3_2_3_adae_tesi_socpt.sas);

/*Missing intensity and AE action*/
%add_job(programFile=&prgdir/t_8_3_2_3_adae_teae_ovrl.sas);


/** 8.3.4 and 8.3.5 vitals and lab line plot issue ***/
*** This amendment is added due to clinician's request to display visit with week spread;
%add_job(programFile=&prgdir/f_8_3_4_advs_line.sas);
%add_job(programFile=&prgdir/f_8_3_5_2_adlb_line.sas);
%add_job(programFile=&prgdir/f_8_3_5_3_adlb_line.sas);
%add_job(programFile=&prgdir/f_8_3_5_4_adlb_line.sas);

/*8.3.5.9.1 Liver monitoring*/

/*** Update table based on new specs ***/
%add_job(programFile=&prgdir/t_8_3_5_8_alb_cyst_nu.sas);


/*8.3.9.3 Endometrial biopsy*/
/*** To update below table to fix programing error **/
%add_job(programFile=&prgdir/t_8_3_9_adfapr_enbio.sas);


****************************************************;
*<10.2.4 Demographics and baseline data;
****************************************************;

/*** To update below listing to fix programing error **/
%add_job(programFile=&prgdir/l_10_2_4_adds_demo_enr_rd.sas);

****************************************************;
* 10.2.6.2 Efficacy / Clinical pharmacology data;
* To update PC listing based on planned re opening of DB*
****************************************************;

%add_job(programFile=&prgdir/l_10_2_6_2_sppc_plsm_cnct.sas);

****************************************************;
* 10.2.8.2 Other safety evaluations;

*** to update 4 listings due to programing error  *
****************************************************;

/*** To update below listings to fix programing error **/
%add_job(programFile=&prgdir/l_10_2_8_2_adfapr_ultra_gyn.sas);
%add_job(programFile=&prgdir/l_10_2_8_2_adfapr_ult_utr.sas);
%add_job(programFile=&prgdir/l_10_2_8_2_adpr_end_bps.sas);
%add_job(programFile=&prgdir/l_10_2_8_2_adlb_clo.sas);

*** update after FDA meeting due to spec change;
%add_job(programFile=&prgdir/f_10_2_8_2_adlb_over.sas);
%add_job(programFile=&prgdir/f_10_2_8_2_adlb_inr.sas);
%add_job(programFile=&prgdir/l_10_2_8_2_adlb_liv_hp.sas);


********< run jobs *******;

%run_jobs()

/*< Create word documents */

%document_finish(
    template     = %NRSTR(template_section_08_2\.txt)
  , headerRow2   = &reportno
  , resultPrefix = &resultPrefix
)


%document_finish(
    template     = %NRSTR(template_section_08_3\.txt)
  , headerRow2   = &reportno
  , resultPrefix = &resultPrefix
)

%document_finish(
    template     = %NRSTR(template_10_1_6_batch_listing\.txt)
  , headerRow2   = &reportno
  , resultPrefix = &resultPrefix
)

%document_finish(
    template     = %NRSTR(template_10_1_7_randomization_scheme_and_codes\.txt)
  , headerRow2   = &reportno
  , resultPrefix = &resultPrefix
)

%document_finish(
    template     = %NRSTR(template_10_2_1_1_screening_failures\.txt)
  , headerRow2   = &reportno
  , resultPrefix = &resultPrefix
)


%document_finish(
    template     = %NRSTR(template_10_2_1_2_discontinued_subjects\.txt)
  , headerRow2   = &reportno
  , resultPrefix = &resultPrefix
)

%document_finish(
    template     = %NRSTR(template_10_2_2_protocol_deviations\.txt)
  , headerRow2   = &reportno
  , resultPrefix = &resultPrefix
)

%document_finish(
    template     = %NRSTR(template_10_2_3_analysis_sets\.txt)
  , headerRow2   = &reportno
  , resultPrefix = &resultPrefix
)

%document_finish(
    template     = %NRSTR(template_10_2_4_demographics_and_baseline_data\.txt)
  , headerRow2   = &reportno
  , resultPrefix = &resultPrefix
)

%document_finish(
    template     = %NRSTR(template_10_2_5_compliance_drug_concentration_and_or_related_data\.txt)
  , headerRow2   = &reportno
  , resultPrefix = &resultPrefix
)


%document_finish(
    template     = %NRSTR(template_10_2_6_1_efficacy_part1.txt)
  , headerRow2   = &reportno
  , resultPrefix = &resultPrefix
)


%document_finish(
    template     = %NRSTR(template_10_2_6_1_efficacy_part2.txt)
  , headerRow2   = &reportno
  , resultPrefix = &resultPrefix
)

%document_finish(
    template     = %NRSTR(template_10_2_6_1_efficacy_part3.txt)
  , headerRow2   = &reportno
  , resultPrefix = &resultPrefix
)


%document_finish(
    template     = %NRSTR(template_10_2_6_2_clinical_pharmacology_data\.txt)
  , headerRow2   = &reportno
  , resultPrefix = &resultPrefix
)

%document_finish(
    template     = %NRSTR(template_10_2_7_adverse_events\.txt)
  , headerRow2   = &reportno
  , resultPrefix = &resultPrefix
)

%document_finish(
    template     = %NRSTR(template_10_2_8_1_clinical_laboratory_data_part1.txt)
  , headerRow2   = &reportno
  , resultPrefix = &resultPrefix
)

%document_finish(
    template     = %NRSTR(template_10_2_8_1_clinical_laboratory_data_part2.txt)
  , headerRow2   = &reportno
  , resultPrefix = &resultPrefix
)


%document_finish(
    template     = %NRSTR(template_10_2_8_1_clinical_laboratory_data_part3.txt)
  , headerRow2   = &reportno
  , resultPrefix = &resultPrefix
)

%document_finish(
    template     = %NRSTR(template_10_2_8_2_other_safety_evaluations\.txt)
  , headerRow2   = &reportno
  , resultPrefix = &resultPrefix
)


%document_finish(
    template     = %NRSTR(template_10_2_8_3_other_listings\.txt)
  , headerRow2   = &reportno
  , resultPrefix = &resultPrefix
)


****************************************************;
*<clean up;
****************************************************;
%endprog;