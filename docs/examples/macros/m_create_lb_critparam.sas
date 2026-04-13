%MACRO m_create_lb_critparam(
         indat           =
       , byvars          =
       , copyvars        =
       , crit1_selection =
       , crit1_cond      =
       , crit2_selection =
       , crit2_cond      =
       , outdat          =
       , paramcd_out     =
) / DES = 'Create new ADLB parameter which checks multiple records for criteria (for example ">=3xULN of ALT or AST and >=1.5xULN Total bilirubin")';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: SPro
 *******************************************************************************
 * Purpose          : Create new ADLB parameter which checks multiple records for criteria (for example ">=3xULN of ALT or AST and >=1.5xULN Total bilirubin")
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * Parameters       :
 *                    indat           : Input dataset, usually ADLB after early_ads_processing
 *                    byvars          : By variables in &indat. Each by group is checked for criterion 1 and 2.
 *                    copyvars        : Variables in &indat. that will be copied to &outdat.
 *                    crit1_selection : If condition that specifies which records in &indat. should be check for 1st criterion
 *                    crit1_cond      : If condition for 1st criterion
 *                    crit2_selection : If condition that specifies which records in &indat. should be check for 2nd criterion. Can be empty if there is only one criterion to be checked.
 *                    crit2_cond      : If condition 2nd criterion. Can be empty if there is only one criterion to be checked.
 *                    outdat          : Name of the output dataset with the new derived records
 *                    paramcd_out     : Value of PARAMCD of the new derived records in &outdat.
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
 * Author(s)        : epjgw (Roland Meizis) / date: 25MAY2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/macros/m_create_lb_critparam.sas
 *******************************************************************************
 * Change History   :
 ******************************************************************************/

/*******************************************************************************
 * Examples         :
 *
 * Two Criteria '(>=3xBL of ALT or AST) and >=2xBL Total bilirubin'
 * %m_create_lb_critparam(
 *     indat           = adlb_sort
 *   , byvars          = usubjid lbrefid
 *   , copyvars        = adsname studyid avisitn adt atm
 *   , crit1_selection = paramcd in ('SGOT', 'SGPT')
 *   , crit1_cond      = cmiss(aval, base) = 0 and aval >= 3 * base
 *   , crit2_selection = paramcd in ('BILITOT')
 *   , crit2_cond      = cmiss(aval, base) = 0 and aval >= 2 * base
 *   , outdat          = adlb_critpar1
 *   , paramcd_out     = TESTPAR1
 * )
 *
 * Single Criterion '>=1xULN of ALT or AST'
 * %m_create_lb_critparam(
 *     indat           = adlb_sort
 *   , byvars          = usubjid lbrefid
 *   , copyvars        = adsname studyid avisitn adt atm
 *   , crit1_selection = paramcd in ('SGOT', 'SGPT')
 *   , crit1_cond      = cmiss(aval, anrhi) = 0 and aval >= 1 * anrhi
 *   , crit2_selection =
 *   , crit2_cond      =
 *   , outdat          = adlb_critpar2
 *   , paramcd_out     = TESTPAR2
 * )
 ******************************************************************************/



    %LOCAL macro mversion _starttime macro_parameter_error;
    %LET macro    = &sysmacroname.;
    %LET mversion = 1.0;

    %spro_check_param(name=indat          , type=DATA)
    %spro_check_param(name=byvars         , type=VARIABLES, data = &indat.)
    %spro_check_param(name=copyvars       , type=VARIABLES, data = &indat.)
    %spro_check_param(name=crit1_selection, type=TEXT)
    %spro_check_param(name=crit1_cond     , type=TEXT)
    %spro_check_param(name=crit2_selection, type=TEXT     , canBeEmpty = Y)
    %spro_check_param(name=crit2_cond     , type=TEXT     , canBeEmpty = Y)
    %spro_check_param(name=outdat         , type=TEXT)
    %spro_check_param(name=paramcd_out    , type=TEXT)

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

    /*< Prepare input data */
    /* Resolve data set options */
    data _m_indat;
        set &indat.;
    run;

    proc sort data=_m_indat presorted;
        by &byvars;
    run;

    /*< Derive new parameters */

    %local lastbyvar;
    %let lastbyvar = %scan(&byvars., -1);

    data _m_checkcrit;
        set _m_indat;
        by &byvars;

        format crit1_record_present
               crit2_record_present
               crit1_satisfied
               crit2_satisfied
               NY. ;

        retain crit1_record_present
               crit2_record_present
               crit1_satisfied
               crit2_satisfied;

        if first.&lastbyvar. then do;
            call missing(crit1_record_present,
                         crit2_record_present,
                         crit1_satisfied,
                         crit2_satisfied);
        end;

        if &crit1_selection. then do;
            crit1_record_present = 1;
            if &crit1_cond. then crit1_satisfied = 1;
        end;

        %if %nrbquote(&crit2_cond.) =   %then %do;
            /* If no 2nd criterion is specified in macro call, pretend that 2nd criterion is always satisfied */
            crit2_record_present = 1;
            crit2_satisfied      = 1;
        %end;
        %else %do;
            if &crit2_selection. then do;
                crit2_record_present = 1;
                if &crit2_cond. then crit2_satisfied = 1;
            end;
        %end;

        output;

        /* Create new record/parameter */
        if last.&lastbyvar. then do;
            if (crit1_record_present = 1 and crit2_record_present = 1) then do;
                paramcd = "&paramcd_out.";
                paramtyp = "DERIVED";
                call missing(aval);
                if (crit1_satisfied = 1 and crit2_satisfied = 1) then avalc = "Y";
                else avalc = "N";

                output;
            end;
        end;
    run;

    /*< Save outdat and clean up */
    data &outdat.;
        set _m_checkcrit;

        if paramcd = "&paramcd_out."; /* Keep only the new derived records */

        keep &byvars. &copyvars. paramcd paramtyp aval avalc;
    run;

    /* Delete all temporary _m_ datasets */
    proc datasets nolist library=work;
        delete _m_: / memtype = data;
        run;
    quit;


    OPTIONS &l_notes.;
/*    %PUT %STR(NO)TE: &macro. - Put your note here;*/
    OPTIONS NONOTES;

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

%MEND m_create_lb_critparam;