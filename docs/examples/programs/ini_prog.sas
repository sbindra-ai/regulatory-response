/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %*LET prog = ini_prog;
/*
 * Purpose          : Initialization program
 * Programming Spec : 
 * Validation Level : 1 - Verification by review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : eokcw (Vijesh Shrivastava) / date: 29SEP2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/ini_prog.sas (eokcw (Vijesh Shrivastava) / date: 18SEP2023)
 ******************************************************************************/


%initsystems( initstudy=5, mosto=7, spro=3, adamap=2, gral=4, eva = 2, poster = 1, alsc = 2, dtools = 2);
%initstudy(
    display_formats = Y
  , inimode         = ANALYSIS
)

/* As %prepare_job set areadir it needs to be deleted */
%SYMDEL areadir;
%prepare_job()

%LET mostocalcpercwidth=optimal;
%LET mostoprintpercwidth=yes;

/*%GLOBAL default_createRTF;*/
/*%LET default_createRTF   = Y; *if you use poster you definitely need to do this;*/

*Creation TLF metadata;
/*LIBNAME tl_meta "&outdir/tlfmeta";*/
/*%LET mosto_param_outdat_meta_lib = tl_meta;*/
%startmostometadata(metadata_version = 2); *to store results metadata;

%startMostoRTF(file = &outdir./&prog., onlyrtf = YES)
