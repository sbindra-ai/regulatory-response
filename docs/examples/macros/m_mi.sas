%MACRO m_mi(datain,nimpute, seed, dataout)
/ DES = 'MACRO FOR CREATING MULTIPLE IMPUTATION';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: ###choose: TOSCA, initstudy, GMS, GDD, pure SAS###
 *******************************************************************************
 * Purpose          : Macro to create MI for OASIS analyses, datain is needed as wide-format, dataout comes as long-format
 * Programming Spec :
 * Validation Level : 1 - Validation by review
 * Parameters       :
 *                    datain  : Dataset to be read in
 *                    nimpute : Number of imputations
 *                    seed    : Seed for imputation
 *                    dataout : Output dataset
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Preconditions    :
 *     Macrovar. needed:
 *     Datasets  needed:
 *     Ext.Prg/Mac used:
 * Postconditions   :
 *     Macrovar created:
 *     Output   created:
 *     Datasets created:
 * Comments         :
 *******************************************************************************
 * Author(s)        : emybb (Kaisa Laapas) / date: 06JUL2023
 * Reference prog   :
 *******************************************************************************
 * Change History   :
 ******************************************************************************/
/* Changed by       : emvsx (Phani Tata) / date: 09AUG2023
 * Reason           : Updated for Menqol Tables
 ******************************************************************************/
/* Changed by       : emybb (Kaisa Laapas) / date: 16OCT2023
 * Reason           : removed unnecessary sorting
 ******************************************************************************/

/*******************************************************************************
 * Examples         :
   %m_mi();
 ******************************************************************************/

%LOCAL macro mversion _starttime macro_parameter_error;
    %LET macro    = &sysmacroname.;
    %LET mversion = 1.0;

   * %spro_check_param(name=param1, type=TEXT)
   * %spro_check_param(name=param2, type=TEXT)

    %IF (%QUOTE(&macro_parameter_error.) EQ %STR(1)) %THEN %RETURN;

    %LET _starttime = %SYSFUNC(datetime());
    %log(
            INFO
          , Version &mversion started
          , addDateTime = Y
          , messageHint = BEGIN)

    %LOCAL l_opts l_notes;
    %LET l_notes = %SYSFUNC(getoption(notes));

    %LET l_opts = %SYSFUNC(getoption(source))
                  %SYSFUNC(getoption(notes))
                  %SYSFUNC(getoption(fmterr))
    ;

    OPTIONS NONOTES NOSOURCE NOFMTERR;

/********************************************************************/
/* Start */
/********************************************************************/

/*************************************************************/
/********************* Analysis ******************************/
/*************************************************************/

* Check missing pattern from transposed data, with full visit structure;
ods output ModelInfo=modelinfo0 MissPattern=misspatt0;
PROC MI data=&datain nimpute=0;
    VAR trt01pn_bin region1n_bin base week_1 week_4 week_8 week_12;
RUN;

/*************************************
*Step 1 - Impute non-monotone missing
*************************************/

PROC MI data=&datain out = step_0 nimpute = &nimpute /*500*/ seed = &seed /*21652*/ /*minimum=0*/;
        /*Or by trt01pn*/
    VAR trt01pn_bin region1n_bin base week_1 week_4 week_8 week_12;
    MCMC IMPUTE=monotone CHAIN=multiple;
RUN;

* Check if imputed;
ods output ModelInfo=modelinfo1 MissPattern=misspatt1;
PROC MI data=step_0 nimpute=0;
    VAR base  flag_disc_w1n flag_disc_w4n flag_disc_w8n flag_disc_w12n week_1 week_4 week_8 week_12;
RUN;

*If value <0 are imputed, set those to 0;
DATA step_1;
    SET step_0;
    IF .z < base   < 0 THEN base=0;
    IF .z < week_1 < 0 THEN week_1=0;
    IF .z < week_4 < 0 THEN week_4=0;
    IF .z < week_8 < 0 THEN week_8=0;
    IF .z < week_12 < 0 THEN week_12=0;
RUN;


/*******************************************************************************
*Step 2 - Multiple Imputation using indicator variables for trt discontinuation
*******************************************************************************/

* SAP:  In case, there are less than 10 participants (who permanently discontinued the randomized treatment)
* with available post-discontinuation data at any intermediate time point;
* --> Create flags (nonmiss_w1 - nonmiss_w12) to check;
    PROC SQL NOPRINT;
        CREATE TABLE iceind1 AS
        SELECT COUNT(Week_1) AS nonmiss_w1, _imputation_
        FROM step_1(WHERE=(flag_disc_w1n=1)) GROUP BY _imputation_;

        CREATE TABLE iceind4 AS
        SELECT COUNT(Week_4) AS nonmiss_w4, _imputation_
        FROM step_1(WHERE=(flag_disc_w4n=1)) GROUP BY _imputation_;

        CREATE TABLE iceind8 AS
        SELECT COUNT(Week_8) AS nonmiss_w8, _imputation_
        FROM step_1(WHERE=(flag_disc_w8n=1)) GROUP BY _imputation_;

        CREATE TABLE iceind12 AS
       SELECT COUNT(Week_12) AS nonmiss_w12, _imputation_
        FROM step_1(WHERE=(flag_disc_w12n=1)) GROUP BY _imputation_;
    QUIT;


    *** Merge number of available data with ICE at certain visits onto data ***;
    DATA step_1b;
         MERGE step_1 iceind1 iceind4 iceind8 iceind12;
         BY _imputation_ ;
    RUN;


    /* The MI regression model will include auxiliary variables indicating (yes/no) whether the participant continued on
     * randomized treatment at each visit (i.e. Week 1, 4, 8 & 12) */

    DATA  _NULL_;
         SET step_1b ;

       LENGTH include_ind_w1 include_ind_w4 include_ind_w8 include_ind_w12 $200;
       IF nonmiss_w1>=10 THEN include_ind_w1='flag_disc_w1n'; ELSE include_ind_w1='';
       IF nonmiss_w4>=10 THEN include_ind_w4='flag_disc_w4n'; ELSE include_ind_w4='';
       IF nonmiss_w8>=10 THEN include_ind_w8='flag_disc_w8n'; ELSE include_ind_w8='';
       IF nonmiss_w12>=10 THEN include_ind_w12='flag_disc_w12n'; ELSE include_ind_w12='';
       CALL SYMPUT('include_ind_w1',include_ind_w1);
       CALL SYMPUT('include_ind_w4',include_ind_w4);
       CALL SYMPUT('include_ind_w8',include_ind_w8);
       CALL SYMPUT('include_ind_w12',include_ind_w12);
    RUN;

    PROC SQL;
        SELECT SUM(NMISS(week_1 , week_4, week_8, week_12)) INTO :num_miss
               FROM step_1b;

        SELECT distinct (pos1) INTO : pos1 trimmed
        FROM step_1b;
    QUIT;

    options mprint;
    %PUT include_ind_w1=&include_ind_w1;
    %PUT include_ind_w4=&include_ind_w4;
    %PUT include_ind_w8=&include_ind_w8;
    %PUT include_ind_w12=&include_ind_w12;
    %PUT num_miss=&num_miss.;

%IF &num_miss NE 0 %THEN %DO;

PROC SORT DATA=step_1b;
    BY _imputation_ trt01pn region1n &include_ind_w1 &include_ind_w4 &include_ind_w8 &include_ind_w12 usubjid;
RUN;

options mprint;


    PROC MI data=step_1b  out=step_2  NOPRINT nimpute=1 seed = &seed ;
        BY _imputation_;
        CLASS trt01pn region1n &include_ind_w1 &include_ind_w4 &include_ind_w8 &include_ind_w12;
        VAR trt01pn region1n base &include_ind_w1 &include_ind_w4 &include_ind_w8 &include_ind_w12
            week_1 week_4 week_8 week_12;
        MONOTONE reg(week_1 =  trt01pn region1n base &include_ind_w1);
        MONOTONE reg(week_4 =  trt01pn region1n base &include_ind_w1 week_1 &include_ind_w4);
        MONOTONE reg(week_8 =  trt01pn region1n base &include_ind_w1 week_1 &include_ind_w4 week_4 &include_ind_w8);
        MONOTONE reg(week_12 = trt01pn region1n base &include_ind_w1 week_1 &include_ind_w4 week_4 &include_ind_w8 week_8 &include_ind_w12);
    RUN;

%END;


%ELSE %DO;
    DATA step_2;
        SET step_1;
    RUN;

    %LET err_mess=Nothing to impute;

%END;
/*******************************************************************************
*Step 3 - Transpose data to fit to MMRM
*******************************************************************************/
    PROC SORT DATA=step_2;BY _imputation_ usubjid trt01pn region1n base;RUN;
    PROC TRANSPOSE DATA=step_2 OUT=step_2_trans /*prefix=chg*/;
        BY _imputation_ usubjid trt01pn region1n base;
        VAR Week_1 Week_4 Week_8 Week_12;
    RUN;

    DATA &dataout;
        SET step_2_trans;
        IF _name_='Week_1' THEN avisitn=10;
        ELSE IF _name_='Week_4' THEN avisitn=40;
        ELSE IF _name_='Week_8' THEN avisitn=80;
        ELSE IF _name_='Week_12' THEN avisitn=120;

        IF . < col1 < 0 then col1=0; *If imputed values are negative, setting those to 0* ;
        chg=col1-base;
        LABEL chg='Change from baseline';
    RUN;

/******************************************************************/
/* End */
/********************************************************************/

    OPTIONS &l_notes.;
    %PUT %STR(NO)TE: &macro. - Put your note here;
    OPTIONS NOTES;

    %end_macro:;

    OPTIONS &l_opts.;
    %log(
            INFO
          , Version &mversion terminated.
          , addDateTime = Y
          , messageHint = END)
    %log(
            INFO
          , Runtime: %SYSFUNC(putn(%SYSFUNC(datetime())-&_starttime., F12.2)) seconds!
          , addDateTime = Y
          , messageHint = END)

%MEND m_mi;
