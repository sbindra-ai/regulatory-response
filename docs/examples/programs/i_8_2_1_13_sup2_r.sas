/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = i_8_2_1_13_sup2_r );
/*
 * Purpose          : Create table of confirmatory testing results for main estimand with validated R
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * ################################################################################
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 27NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/i_8_2_1_13_sup2_r.sas (gfsdv (Ulrike Krahn) / date: 12SEP2023)
 ******************************************************************************/
*Changed by       : gfsdv (Ulrike Krahn) / date: 01NOV2023
*Reason           : The header for study was corrected to 21652
******************************************************************************/;

%add2library(
  TLFMETA
,&PRGDIR
);

%LET LOG_LEVEL=DEBUG;
OPTIONS LS=MAX PS=MAX;
%let tfldata = p_val_sup2 ;

%*< 1: Define some helper variables;
DATA  p_val_sup2 ;
    set tlfmeta.p_val_sup2;
RUN;


%LET mainR     =  %str(i_8_2_1_13_sup2_r.r);

%LET bname     = %QSYSFUNC(prxchange(%STR(s/\.[rR]$//), 1, &mainR.));
%put &bname. ;

%LET zipFile   = %SYSFUNC(pathname(WORK))/&bname..zip;
%LET auditFile = &logdir./&bname..aud;
/*%LET outFile   = &outdir./&prog._out.zip; */
%LET outFile   = &outdir./&bname._out.zip;


%*< 2: Execute the next code block to create a ZIP file containing the R program and required work data;
%*<    For now there is no need to change anything in here;

%zip(zipFile = &zipFile., file = &PRGDIR./&mainR., replace = Y, junkPath = Y)

%zip(zipfile = &zipFile., dataset = tlfmeta.p_val_sup2 );


%*< 3: Execute the following macro call to submit the created ZIP archive package on validated R;

%executeValidatedR(
    inFile        = &zipFile.
  , outFile       = &outFile.
  , auditFile     = &auditFile.
  , mainR         = &mainR.
  , cpu           = 2
  , memory        = 2000M
)

%*< 4: List all the result files and extract to correct location;
%unzip(zipFile = &outFile., listOnly=Y, listDat=zipList)
DATA _NULL_;
    SET zipList;
    PUT size @16 modt NAME;
RUN;

%unzip(zipFile = &outFile., file = output/error.txt,    to = &logdir./&bname..err, junkPath = Y)
%unzip(zipFile = &outFile., file = output/output.txt,   to = &logdir./&bname..out, junkPath = Y)
%unzip(zipFile = &outFile., file = output/&bname..rout, to = &logdir., junkPath = Y)

%unzip(zipFile = &outFile., file = work/i_8_2_1_13_gmcp_sup2.csv    , to = &outdir./tlfmeta, junkPath = Y)

data i_8_2_1_13_gmcp_sup2    ;
           %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
           infile "&outdir/tlfmeta/i_8_2_1_13_gmcp_sup2.csv" delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
           informat VAR1 $4. ;
           informat alpha $20. ;
           informat p_values best32. ;
           informat rej best32. ;

           format VAR1 $4. ;
           format p_values best12. ;
           format rej best12. ;

         input VAR1  $   alpha  p_values    rej   ;
           if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;


data tlfmeta.i_8_2_1_13_gmcp_sup2 ;
    set  i_8_2_1_13_gmcp_sup2 ;
    length eff_var $2000.;


if Var1= "H1" then  eff_var ="HF frequency at week 4";
if Var1= "H2" then  eff_var ="HF frequency at week 12";
if Var1= "H3" then  eff_var ="HF severity at week 4";
if Var1= "H4" then  eff_var ="HF severity at week 12";
if Var1= "H5" then  eff_var ="PROMIS SD SF 8b total score at week 12";
if Var1= "H6" then  eff_var ="HF frequency at week 1";
if Var1= "H7" then  eff_var ="MENQOL total score at week 12";

format p_values 5.4 ;

if rej = 0 then rejc = "Not Rejected";
if rej = 1 then rejc = "Rejected";

    attrib Var1 label = "Hypotheses"
           eff_var  label  = "Efficacy variable"
           alpha label = "Significance level"
           p_values label = "p-value (one-sided)"
           rejc label = "Result regarding null hypothesis";
RUN;

%endprog();
