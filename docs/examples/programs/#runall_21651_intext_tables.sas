/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %LET prog = #runall_21651_intext_tables;
/*
 * Purpose          : Intext tables
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : enpjp (Prashant Patel) / date: 08JAN2024
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/#runall_21652_intext_tables.sas (enpjp (Prashant Patel) / date: 26SEP2023)
 ******************************************************************************/

*******************************************************************************;
*< Initialize study;
*******************************************************************************;
%initsystems( initstudy=5, mosto=7, spro=3, adamap=2, gral=4, eva = 2, poster = 1, alsc = 2, docfish = 2, dtools = 2, woops = 1,valir=1);
%initstudy(
    display_formats = Y
  , inimode         = ANALYSIS
);

DATA TLFMETA.PITT;
    SET TLFMETA.META_T:;
RUN;

 /*Get enumeration from DocFish output and write them to metamaster*/
%intext_find_source_tables(
    meta_master  = TLFMETA.PITT
  , documDir     =
  , includeFiles = &docdir./&RESULTPREFIX.section_08_1.docx
                   &docdir./&RESULTPREFIX.section_08_2.docx
                   &docdir./&RESULTPREFIX.section_08_3.docx
  , excludeFiles =
)

%startmostortf(file=&outdir./intext_tables, orientation=LANDSCAPE)

%LET mostocalcpercwidth=optimal;
%LET mostoprintpercwidth=yes;

%printline(<h1page>Demographics and baseline characteristics)
%printline(<h1page>Medical History)
%INCLUDE     "&prgdir/intext_admh.sas";
%printline(<h1page>Prior and Concomitant therapy)
%INCLUDE     "&prgdir/intext_adcm.sas";
%printline(<h1page>Efficacy evaluation)
%INCLUDE     "&prgdir/intext_freq_medtosev_hf.sas";
%INCLUDE     "&prgdir/intext_daily_medtosev_hf.sas";
%INCLUDE     "&prgdir/intext_promis.sas";
%INCLUDE     "&prgdir/intext_menqol.sas";
%INCLUDE     "&prgdir/intext_bdi.sas";
%printline(<h1page>Safety evaluation)
%INCLUDE     "&prgdir/intext_adae.sas";
%INCLUDE     "&prgdir/intext_sleep.sas";

%endmostortf()

%document_finish(
    template     = %NRSTR(template_intext_tables\.txt)
  , headerRow1   = PiCSR Tables
  , headerRow2   = &REPORTNO
  , resultPrefix = &resultPrefix
)
***************************************************************************;
*< Clean up;
***************************************************************************;
%endprog()