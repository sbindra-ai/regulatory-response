%MACRO m_impute_astdt(
         indat    =
       , sp_stdtc =
       , outdat   =
) / DES = 'Impute start date and create ASTDT and ASTDTF for ADAE or ADCM';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: SPro
 *******************************************************************************
 * Purpose          : Impute start date for ADAE or ADCM
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * Parameters       :
 *                    indat    : Input dataset (adae or adcm)
 *                               If ADSL variables TRTSDT TRT01AN PH2SDT are not present, they will be added
 *                    sp_stdtc : Name of SP variable with character start date (should be AESTDTC or CMSTDTC)
 *                    outdat   : Name of output dataset
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Preconditions    :
 *     Macrovar. needed: &adsDomain. (should be ADAE or ADCM)
 *     Datasets  needed:
 *     Ext.Prg/Mac used:
 * Postconditions   :
 *     Macrovar created:
 *     Output   created:
 *     Datasets created:
 * Comments         :
 *******************************************************************************
 * Author(s)        : epjgw (Roland Meizis) / date: 12JUN2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/macros/m_impute_astdt.sas
 *******************************************************************************
 * Change History   :
 ******************************************************************************/

/*******************************************************************************
 * Examples         :
 *
 * Imputing ASTDT for ADAE
 * %m_impute_astdt(
 *        indat    = adae
 *      , sp_stdtc = aestdtc
 *      , outdat   = adae2
 * )
 *
 * Imputing ASTDT for ADCM
 * %m_impute_astdt(
 *         indat    = adcm
 *       , sp_stdtc = cmstdtc
 *       , outdat   = adcm2
 * )
 ******************************************************************************/


    %LOCAL macro mversion _starttime macro_parameter_error;
    %LET macro    = &sysmacroname.;
    %LET mversion = 1.0;

    %spro_check_param(name=indat,    mustExist=Y,                type=DATA)
    %spro_check_param(name=sp_stdtc, mustExist=Y,  data=&indat., type=VARIABLES_C)
    %spro_check_param(name=outdat,                               type=TEXT)

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

    %* Put your macro code here!;

    /* Resolve data set options */
    data _m_indat;
        set &indat.;
    run;

    proc sort data=_m_indat;
        by usubjid;
    run;

    /* Check input dataset for variables TRTSDT TRT01AN PH2SDT and merge from ADSL if necessary */
    %local adsl_vars adsl_var_in_indat;

    %let adsl_vars = TRTSDT TRT01AN PH2SDT;
    %let adsl_var_in_indat = %getvarlist(indat=&indat., varlist=&adsl_vars.);

    %if %sysfunc(countw(&adsl_var_in_indat.%str( ))) NE 3 %then %do;
        data _m_adsl (drop=&adsl_var_in_indat.);
            set ads.adsl (keep=usubjid &adsl_vars.);
        run;

        data _m_indat;
            merge _m_indat (in=_in_indat)
                  _m_adsl;
            by usubjid;

            if _in_indat;
        run;
    %end;


    /* Imputation of (partially) missing start and end date as per SAP*/
    data &outdat.;
        set _m_indat;

        %createCustomVars(adsDomain=&adsDomain., vars=astdt astdtf);
        attrib acttrtsdt placebosdt rangestdt rangeendt format=date9.;

        /* Derive start date of active treatment and placebo */
        if trt01an = 100 then do; /* Elinzanetant 120mg */
            acttrtsdt = trtsdt;
            call missing(placebosdt);
        end;
        else if trt01an = 101 then do; /* Placebo - Elinzanetant 120mg */
            placebosdt = trtsdt;
            if not missing(ph2sdt) then acttrtsdt = ph2sdt;
            else call missing(acttrtsdt);
        end;
        else if trt01an = 9901 then do; /* Placebo */
            placebosdt = trtsdt;
            call missing(acttrtsdt);
        end;

        if length(compress(&sp_stdtc.)) = 10 then do; /* Date of the form YYYY-MM-DD */
            astdt = input(&sp_stdtc., yymmdd10.);
            call missing(astdtf);
        end;
        /* Derive ASTDTF and imputation range end and start as per SAP */
        else if length(compress(&sp_stdtc.)) = 7 then do; /* Date of the form YYYY-MM */
            astdtf = 'D';
            /* Calculate imputation range */
            rangestdt =                    input(substr(&sp_stdtc.,1,7)||"-01",yymmdd10.); /* First day of the month */
            rangeendt = min(intnx('month', input(substr(&sp_stdtc.,1,7)||"-01",yymmdd10.), 0, 'ending'), aendt); /* Last day of the month capped by CM end date */
        end;
        else if length(compress(&sp_stdtc.)) in (4, 9) then do; /* Date of the form YYYY or YYYY---DD */
            astdtf = 'M';
            /* Calculate imputation range */
            rangestdt =     input(substr(&sp_stdtc.,1,4)||"-01-01",yymmdd10.); /* First day of the year */
            rangeendt = min(input(substr(&sp_stdtc.,1,4)||"-12-31",yymmdd10.), aendt); /* Last day of the year capped by CM end date */
        end;
        else if missing(&sp_stdtc.) then do;
            call missing(astdt, astdtf);
        end;
        else put "WARN" "NING: Problem with ASTDT imputation, unexpected &sp_stdtc. value " usubjid= &sp_stdtc.= astdt= astdtf=;

        /* Impute start date as per SAP */
        if not missing(astdtf) then do;
            if      rangestdt <= acttrtsdt  <= rangeendt then astdt = acttrtsdt;
            else if rangestdt <= placebosdt <= rangeendt then astdt = placebosdt;
            else    astdt = rangestdt;
        end;
    RUN;

    /* Delete all temporary _m_ datasets */
    proc datasets nolist LIBRARY=work;
        delete _m_: / memtype = data;
        run;
    quit;

    OPTIONS &l_notes.;
/*    %PUT %STR(NO)TE: &macro. - Put your note here;*/
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

%MEND m_impute_astdt;