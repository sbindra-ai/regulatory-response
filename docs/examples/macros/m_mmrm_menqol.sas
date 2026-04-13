%MACRO m_mmrm_menqol(datain, byvar, classvar, yvar, xvar,repstr, lsmeans, estim,pred)
/ DES = 'MACRO FOR CREATING MMRM-ANALYSIS';

/*******************************************************************************
 * Bayer AG
 * Macro rely on: ###choose: TOSCA, initstudy, GMS, GDD, pure SAS###
 *******************************************************************************
 * Purpose          : Macro to create MMRM-analysis
 * Programming Spec :
 * Validation Level : 1 - verification by review
 * Parameters       :
 *                    datain : Data to go into analysis
 *                    byvar : If analysis is done by any group
 *                    classvar : List of classification variables
 *                    yvar : Dependent variable
 *                    xvar : List of Independent variables
 *                    covstr = Type of covariance structure
 *                    lsmeans : Output dataset name for LSMeans
 *                    estim : Output dataset name for Estimates
 *                    pred: Predicted values + residuals
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
 * Author(s)        : emybb (Kaisa Laapas) / date: 27JUN2023
 *******************************************************************************
 * Change History   :
 ******************************************************************************/
/* Changed by       : sgtja (Katrin Roth) / date: 04JUL2023
 * Reason           : adapt for menqol, removing week1
 ******************************************************************************/
/* Changed by       : emybb (Kaisa Laapas) / date: 23OCT2023
 * Reason           : Only week 12 needed for output table, estimate week 4 commented out
 ******************************************************************************/
/* Changed by       : eokcw (Vijesh Shrivastava) / date: 06NOV2023
 * Reason           : Updated validation level to 1
 ******************************************************************************/
/* Changed by       : emybb (Kaisa Laapas) / date: 13DEC2023
 * Reason           : Adding regions to sort before mmrm
 ******************************************************************************/

/*******************************************************************************
 * Examples         :
   %m_mmrm();
 ******************************************************************************/



%LOCAL macro mversion _starttime macro_parameter_error;
%LET macro    = &sysmacroname.;
%LET mversion = 1.0;
/*
%spro_check_param(name=datain, type=TEXT)
%spro_check_param(name=byvar, type=TEXT)
%spro_check_param(name=classvar, type=TEXT)
%spro_check_param(name=yvar, type=TEXT)
%spro_check_param(name=xvar, type=TEXT)
%spro_check_param(name=type, type=TEXT)
%spro_check_param(name=lsmeans, type=TEXT)
%spro_check_param(name=estim, type=TEXT)*/

*%IF (%QUOTE(&macro_parameter_error.) EQ %STR(1)) %THEN %RETURN;

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

proc sort data=&datain; by &byvar trt01pn region1n avisitn usubjid ; run;

    %local StatMMRM;
    %global/*local*/ MMRMStrUsed;

    %let StatMMRM=0;

    %if "%upcase(&repstr)"="UN" %then %do;
        ods listing close;

        PROC MIXED data=&datain;
            BY &byvar;
            CLASS &classvar;
            MODEL &yvar = &xvar /ddfm=KR residual outp=&pred;
            REPEATED  avisitn / subject=usubjid type=un;
            LSMEANS trt01pn*avisitn /cl diff;
            *ESTIMATE  'Elinzanetant - Placebo at Week 1'  trt01pn 1 -1 trt01pn*avisitn 1 0 0 0 -1 0 0 0/cl ;
            *ESTIMATE  'Elinzanetant - Placebo at Week 4'  trt01pn 1 -1 trt01pn*avisitn  1 0 0  -1 0 0/cl ;
            ESTIMATE  'Elinzanetant - Placebo at Week 12' trt01pn 1 -1 trt01pn*avisitn  0 0 1  0 0 -1 /cl ;
            ODS OUTPUT LSMeans=&lsmeans Estimates=&estim ConvergenceStatus=convstatus ModelInfo=modinfo_mmrm;
        RUN;
        QUIT;

        ODS LISTING;
        PROC SORT DATA=convstatus; BY DESCENDING Status; RUN;
        DATA _NULL_;
            SET convstatus;
            IF _N_=1 THEN CALL symput("StatMMRM", compress(put(status, 1.0)));
        RUN;
        %*** Status = 0 means converged without any problem;
        %***        = 1 means converged, but some warnings;
        %***        = 3 means did not converge;
        %put MMRM convergence status for UN: &StatMMRM;

        %if "&StatMMRM"="0" %then %do;
            %let MMRMStrUsed =UN;
        %end;

%end;

        %if "%upcase(&repstr)"="AR(1)" or "&StatMMRM" ne "0" %then %do;
        ODS LISTING CLOSE;
        PROC MIXED data=&datain;
            BY &byvar;
            CLASS &classvar;
            MODEL &yvar = &xvar /ddfm=KR residual outp=&pred;
            REPEATED  avisitn / subject=usubjid type=ar(1);
            RANDOM usubjid;
            LSMEANS trt01pn*avisitn /cl diff;
            *ESTIMATE  'Elinzanetant - Placebo at Week 1'  trt01pn 1 -1 trt01pn*avisitn 1 0 0 0 -1 0 0 0/cl ;
            *ESTIMATE  'Elinzanetant - Placebo at Week 4'  trt01pn 1 -1 trt01pn*avisitn 1 0 0  -1 0 0/cl ;
            ESTIMATE  'Elinzanetant - Placebo at Week 12' trt01pn 1 -1 trt01pn*avisitn 0 0 1  0 0 -1 /cl ;
            ODS OUTPUT LSMeans=&lsmeans Estimates=&estim ConvergenceStatus=convstatus ModelInfo=modinfo_mmrm;
RUN;
quit;
        ods listing;

        PROC SORT DATA=convstatus; BY DESCENDING Status; RUN;
        DATA _NULL_;
            SET convstatus;
            IF _N_=1 THEN CALL symput("StatMMRM", compress(put(status, 1.0)));
        RUN;
        %*** Status = 0 means converged without any problem;
        %***        = 1 means converged, but some warnings;
        %***        = 3 means did not converge;
        %put MMRM convergence status for AR(1): &StatMMRM;

        %if "&StatMMRM"="0" %then %do;
            %let MMRMStrUsed =AR(1);
        %end;

%end;

        %if "%upcase(&repstr)"="CS" %then %do;
        ods listing close;

        PROC MIXED data=&datain;
            BY &byvar;
            CLASS &classvar;
            MODEL &yvar = &xvar /ddfm=KR residual outp=&pred;
            REPEATED  avisitn / subject=usubjid type=cs;
            LSMEANS trt01pn*avisitn /cl diff;
            *ESTIMATE  'Elinzanetant - Placebo at Week 1'  trt01pn 1 -1 trt01pn*avisitn 1 0 0 0 -1 0 0 0/cl ;
           * ESTIMATE  'Elinzanetant - Placebo at Week 4'  trt01pn 1 -1 trt01pn*avisitn 1 0 0  -1 0 0/cl ;
            ESTIMATE  'Elinzanetant - Placebo at Week 12' trt01pn 1 -1 trt01pn*avisitn 0 0 1  0 0 -1 /cl ;
            ODS OUTPUT LSMeans=&lsmeans Estimates=&estim ConvergenceStatus=convstatus ModelInfo=modinfo_mmrm;
        RUN;
        quit;


        ODS LISTING;
        PROC SORT DATA=convstatus; BY DESCENDING Status; RUN;
        DATA _NULL_;
            SET convstatus;
            IF _N_=1 THEN CALL symput("StatMMRM", compress(put(status, 1.0)));
        RUN;
        %*** Status = 0 means converged without any problem;
        %***        = 1 means converged, but some warnings;
        %***        = 3 means did not converge;
        %put MMRM convergence status for CS: &StatMMRM;

        %if "&StatMMRM"="0" %then %do;
            %let MMRMStrUsed =CS;
        %end;

%end;



        %if "%upcase(&repstr)" ne "UN" and "%upcase(&repstr)" ne "AR(1)" and "%upcase(&repstr)" ne "CS"
        %then %do;
            %put ERROR: MMRM analysis not performed - specified structure of R matrix not supported;
            %put Available choices for structure of R matrix: UN, AR(1), CS;
            /*	%goto finish;*/
        %end;
        %else %if "&StatMMRM" ne "0"
            %then %do;
            %put ERROR: MMRM analysis not performed - convergence criteria not met;
            /*	%goto finish;*/
        %end;

/********************************************************************/
/* End */
/********************************************************************/

    OPTIONS &l_notes.;
    %PUT %STR(NO)TE: &macro. - Put your note here;
    OPTIONS NONOTES;

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

%MEND m_mmrm_menqol;
