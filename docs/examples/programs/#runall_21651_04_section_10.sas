/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
   %LET prog = #runall_21651_04_section_10;
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
 * Author(s)        : egavb (Reema S Pawar) / date: 23AUG2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/#runall_21652_04_section_10.sas (egavb (Reema S Pawar) / date: 27JAN2023)
 ******************************************************************************/
/* Changed by       : eokcw (Vijesh Shrivastava) / date: 20DEC2023
 * Reason           : Update inimode to ANALYSIS after unblinded data
 ******************************************************************************/

*******************************************************************************;
*< Initialize study;
*******************************************************************************;
*******************************************************************************;
%initsystems( initstudy=5, mosto=7, spro=3, adamap=2, gral=4, eva = 2, poster = 1, alsc = 2, dtools = 2, docfish = 2);
%initstudy(
    display_formats = Y
  , inimode         = ANALYSIS
);
*? attention: only in TLF runall display formats are used;
%LET mostocalcpercwidth= optimal;
%LET mostoprintpercwidth= yes;

/*** attention: only in TLF runall display formats are used;***/

%LET poster_param_iniprog= &prgdir./ini_prog.sas;
%LET POSTER_PARAM_TERMPROG = &prgdir./end_prog.sas;

%IF %upcase(&stage)=DEV %THEN %DO;
    %remove_trc(dir = &logDir., remove = Y)
%END;


*** We always create Mosto Metadata;
*%startmostometadata();

*<*****************************************************************************;
*< 16.x Listings (structure according BSP-SOP-470)                             ;
*<*****************************************************************************;
/* Note: names of programs/output files are according current defaults in ComBO-templates.
         Should be adapted to CDISC-terminology in the long run. */

*** per agreement: batch listing will be only produced if data are available in OAD;
****************************************************;
*16.1.6 Batch listing ;
****************************************************;

%add_job(programFile=&prgdir/l_10_1_6_spda_batch.sas);

****************************************************;
*16.1.7 Randomization scheme and codes;
****************************************************;

%add_job(programFile=&prgdir/l_10_1_7_adsl_rand.sas);

****************************************************;
*16.2.1.1 Screening failures;
****************************************************;

%add_job(programFile=&prgdir/l_10_2_1_1_adds_screen.sas);

****************************************************;
*16.2.1.2 Discontinued subjects;
****************************************************;

%add_job(programFile=&prgdir/l_10_2_1_2_adds_discon.sas);
%add_job(programFile=&prgdir/l_10_2_1_2_cvd.sas)

****************************************************;
*16.2.2 Protocol deviations;
****************************************************;

%add_job(programFile=&prgdir/l_10_2_2_addv_pd.sas);
%add_job(programFile=&prgdir/l_10_2_2_adsl_trt_grp.sas);
%add_job(programFile=&prgdir/l_10_2_2_addv_imp_pd_cvd.sas);

****************************************************;
*16.2.3 Analysis sets;
****************************************************;

%add_job(programFile=&prgdir/l_10_2_3_adsl_analy_set.sas);

****************************************************;
*<16.2.4 Demographics and baseline data;
****************************************************;

%add_job(programFile=&prgdir/l_10_2_4_ie_demo.sas);
%add_job(programFile=&prgdir/l_10_2_4_ie_demo_not_met.sas)
%add_job(programFile=&prgdir/l_10_2_4_adds_demo_cons.sas);
%add_job(programFile=&prgdir/l_10_2_4_adds_demo_enr_rd.sas);
%add_job(programFile=&prgdir/l_10_2_4_adsl_demo.sas);
%add_job(programFile=&prgdir/l_10_2_4_su_demo_smoke.sas);
%add_job(programFile=&prgdir/l_10_2_4_admh_demo.sas);
%add_job(programFile=&prgdir/l_10_2_4_adcm_demo.sas);
%add_job(programFile=&prgdir/l_10_2_4_adqs_mht.sas);
%add_job(programFile=&prgdir/l_10_2_4_adrp_demo.sas);

****************************************************;
* 16.2.5 Compliance, drug concentration data and/or related data;
****************************************************;

%add_job(programFile=&prgdir/l_10_2_5_spda.sas);
%add_job(programFile=&prgdir/l_10_2_5_spec_intake.sas);
%add_job(programFile=&prgdir/l_10_2_5_adex_trt_expo.sas);
%add_job(programFile=&prgdir/l_10_2_5_adex_stdy_expo.sas);
%add_job(programFile=&prgdir/l_10_2_5_spec_trt_intr.sas);

****************************************************;
* 16.2.6. Efficacy / Clinical pharmacology data;
****************************************************;

%add_job(programFile=&prgdir/l_10_2_6_1_1spqs.sas);
%add_job(programFile=&prgdir/l_10_2_6_1_2spqs.sas);
%add_job(programFile=&prgdir/l_10_2_6_1_3spqs.sas);
%add_job(programFile=&prgdir/l_10_2_6_1_4spqs.sas);
%add_job(programFile=&prgdir/l_10_2_6_1_5spqs.sas);
%add_job(programFile=&prgdir/l_10_2_6_1_6spqs.sas);
%add_job(programFile=&prgdir/l_10_2_6_1_7spqs.sas);
%add_job(programFile=&prgdir/l_10_2_6_1_8spqs.sas);


%add_job(programFile=&prgdir/l_10_2_6_2_adds_info_const.sas);
%add_job(programFile=&prgdir/l_10_2_6_2_sppc_plsm_cnct.sas);

****************************************************;
* 16.2.7 Adverse events;
****************************************************;

%add_job(programFile=&prgdir/l_10_2_7_adae.sas);
%add_job(programFile=&prgdir/l_10_2_7_adae_meddra.sas);
%add_job(programFile=&prgdir/l_10_2_7_adae_teae.sas);
%add_job(programFile=&prgdir/l_10_2_7_adae_tesae.sas);
%add_job(programFile=&prgdir/l_10_2_7_adae_cvd.sas);
%add_job(programFile=&prgdir/l_10_2_7_adae_dth_fatl.sas);
%add_job(programFile=&prgdir/l_10_2_7_adae_dth.sas);

****************************************************;
* 16.2.8.1 Clinical laboratory data;
****************************************************;

%add_job(programFile=&prgdir/l_10_2_8_1_adlb_hema.sas);
%add_job(programFile=&prgdir/l_10_2_8_1_adlb_gnrl_chem.sas);
%add_job(programFile=&prgdir/l_10_2_8_1_adlb_coag.sas);
%add_job(programFile=&prgdir/l_10_2_8_1_adlb_horm.sas);
%add_job(programFile=&prgdir/l_10_2_8_1_adlb_urin.sas);
%add_job(programFile=&prgdir/l_10_2_8_1_adlb_vitm.sas);
%add_job(programFile=&prgdir/l_10_2_8_1_adlb_immu.sas);
%add_job(programFile=&prgdir/l_10_2_8_1_adlb_preg.sas);

****************************************************;
* 16.2.8.2 Other safety evaluations;
****************************************************;

%add_job(programFile=&prgdir/l_10_2_8_2_adpr_fapr_mamo.sas);
%add_job(programFile=&prgdir/l_10_2_8_2_adfapr_ultra_gyn.sas);
%add_job(programFile=&prgdir/l_10_2_8_2_adfapr_ultra_ovr.sas);
%add_job(programFile=&prgdir/l_10_2_8_2_adfapr_ult_utr.sas);
%add_job(programFile=&prgdir/l_10_2_8_2_adfapr_crv_cyt.sas);
%add_job(programFile=&prgdir/l_10_2_8_2_adpr_end_bps.sas);
%add_job(programFile=&prgdir/l_10_2_8_2_adqshfss_slp_scl.sas);
%add_job(programFile=&prgdir/l_10_2_8_2_adqs_ecssrs.sas);
%add_job(programFile=&prgdir/l_10_2_8_2_admh_liv_evnt.sas);
%add_job(programFile=&prgdir/l_10_2_8_2_adcm_liv_evnt.sas);
%add_job(programFile=&prgdir/l_10_2_8_2_adlb_clo.sas);
%add_job(programFile=&prgdir/l_10_2_8_2_spce_liv_enzm.sas);
%add_job(programFile=&prgdir/l_10_2_8_2_spce_liv_enzm_fu.sas);
%add_job(programFile=&prgdir/l_10_2_8_2_adpr_adfapr_liv.sas);
%add_job(programFile=&prgdir/l_10_2_8_2_adqs_lsmb.sas);
%add_job(programFile=&prgdir/f_10_2_8_2_adlb_over.sas);
%add_job(programFile=&prgdir/f_10_2_8_2_adlb_inr.sas);
%add_job(programFile=&prgdir/l_10_2_8_2_adlb_liv_hp.sas);

****************************************************;
* 16.2.8.3 [Other listings];
****************************************************;

%add_job(programFile=&prgdir/l_10_2_8_3_advs_phy_exm.sas);
%add_job(programFile=&prgdir/l_10_2_8_3_advs.sas);
%add_job(programFile=&prgdir/l_10_2_8_3_speg_msmt.sas);
%add_job(programFile=&prgdir/l_10_2_8_3_speg_fnd.sas);

********< run jobs *******;

%run_jobs();

/*< Create word documents */


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