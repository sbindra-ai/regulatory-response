
/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %LET prog = #runall_21651_prod_amendment2;
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


%LET mostocalcpercwidth= optimal;
%LET mostoprintpercwidth= yes;

*** attention: only in TLF runall display formats are used;
%LET poster_param_iniprog = &prgdir./ini_prog.sas;
%LET poster_param_termprog = &prgdir./end_prog.sas;    %*? End code before termination of each job;

%IF %upcase(&stage)=DEV %THEN %DO;
    %remove_trc(dir = &logDir., remove = Y)
%END;

****************************************************;
* 10.2.8.2 Other safety evaluations;

*** to update 4 listings due to programing error  *
****************************************************;

/*** To update below listings to fix programing error **/
%add_job(programFile=&prgdir/l_10_2_8_2_adqs_lsmb.sas);



********< run jobs *******;

%run_jobs()

/*< Create word documents */

%document_finish(
    template     = %NRSTR(template_10_2_8_2_other_safety_evaluations\.txt)
  , headerRow2   = &reportno
  , resultPrefix = &resultPrefix
)


****************************************************;
*<clean up;
****************************************************;
%endprog;