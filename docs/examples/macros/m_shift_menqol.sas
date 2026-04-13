%MACRO m_shift_menqol(datain=, delta=)
/ DES = 'add delta to imputed values in EZN arm for menqol';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: ###choose: TOSCA, initstudy, GMS, GDD, pure SAS###
 *******************************************************************************
 * Purpose          : ##########
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
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
 * Author(s)        : sgtja (Katrin Roth) / date: 02NOV2023
 * Reference prog   :
 *******************************************************************************
 * Change History   :
 ******************************************************************************/

/*******************************************************************************
 * Examples         :
   %m_shift();
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
    data tp_&d;
        set &datain;
        if trt01pn=100 then do;
            if missing(Week4a) then Week4a = Week_4 + &delta;
            if missing(Week8a) then Week8a = Week_8 + &delta;
            if missing(Week12a) then Week12a = Week_12 + &delta;
        end;
        else if trt01pn=101 then do;
            Week4a = Week_4;
            Week8a = Week_8;
            Week12a = Week_12;
        END;
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

%MEND m_shift_menqol;
