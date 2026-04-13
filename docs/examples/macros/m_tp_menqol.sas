%MACRO m_tp_menqol(datain, delta)
/ DES = 'tipping point analysis for MMRM';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: ###choose: TOSCA, initstudy, GMS, GDD, pure SAS###
 *******************************************************************************
 * Purpose          : ##########
 * Programming Spec :
 * Validation Level : 1 - verification by review
 * Parameters       :
 *                    param1 :
 *                    param1 :
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
 * Author(s)        : sgtja (Katrin Roth) / date: 04JUL2023
 * Reference prog   :
 *******************************************************************************
 * Change History   :
 ******************************************************************************/
/* Changed by       : sgtja (Katrin Roth) / date: 12OCT2023
 * Reason           : corrected label of the "scenarios"
 ******************************************************************************/
/* Changed by       : eokcw (Vijesh Shrivastava) / date: 06NOV2023
 * Reason           : Updated validation level to 1
 ******************************************************************************/

/*******************************************************************************
 * Examples         :
   %m_tp();
 ******************************************************************************/
    %LOCAL macro mversion _starttime macro_parameter_error;
    %LET macro    = &sysmacroname.;
    %LET mversion = 1.0;

    *%spro_check_param(name=param1, type=TEXT)
    *%spro_check_param(name=param2, type=TEXT)

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
    %let d =%sysfunc(COMPRESS(&delta,.));
    %m_shift_menqol(datain=step3, delta=&delta)

    PROC SORT DATA=tp_&d; BY _imputation_ usubjid trt01pn region1n base;RUN;
    PROC TRANSPOSE DATA=tp_&d OUT=tp_trans_&d /*prefix=chg*/;
        BY _imputation_ usubjid trt01pn region1n base;
        VAR Week4a Week8a Week12a;
    RUN;

    DATA step_4;
        SET tp_trans_&d;
        IF _name_='Week4a' THEN avisitn=40;
        ELSE IF _name_='Week8a' THEN avisitn=80;
        ELSE IF _name_='Week12a' THEN avisitn=120;
        chg=col1-base;
        LABEL chg='Change from baseline';
    RUN;

    %LET byvar = _imputation_;
    %LET classvar = usubjid trt01pn region1n avisitn ;
    %LET xvar = base trt01pn region1n avisitn trt01pn*avisitn base*avisitn ;

    OPTIONS MPRINT;
    %m_mmrm_menqol(step_4,&byvar,&classvar,chg,&xvar,un,lsmeans,estim,pred);quit;

/*******************************************************************************
 *Step 5 - Combine results with Rubin's rule
 *******************************************************************************/

    PROC SORT DATA=estim; BY label  _imputation_; RUN;
    PROC MIANALYZE DATA=estim;
        BY label;
        MODELEFFECTS estimate;
        STDERR stderr;
    ODS OUTPUT ParameterEstimates=estim_tot;
    RUN;

    * Divide two-sided p-Value by 2 to get one-sided p-value ;
    DATA estim_tot_&d;
        SET estim_tot;
        IF tValue < 0 THEN Probt_1 = Probt/2;
        ELSE Probt_1 = 1-Probt/2;
        FORMAT probt_1 pvalue6.4;
        LABEL probt_1='1-sided p-value';
        scenario = cat("Elinzanetant+",&delta," and Placebo+0"); *delta needs to be the value of the respective (macro) variable;
        label scenario='Scenario';
        shift = &delta;
        label shift='delta';
        label estimate='Difference of LS Means';
    RUN;


    /******************************************************************/
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

%MEND m_tp_menqol;
