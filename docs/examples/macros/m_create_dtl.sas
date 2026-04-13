%MACRO m_create_dtl(inputds=, varname=)
/ DES = "Macro to create derived text date variable for listings only";
/******************************************************************************
 * Bayer Schering Pharma AG
 * Macro rely on    : XXDTC variables
 ******************************************************************************
 * Purpose          : Derivation macro for inline derivation of text date
 *                    variables.
 * Parameters       :
 *          inputds : The dataset name that include the XXDTC variable.
 *          varname : The variable name to store the Derive Listing date values.
 * SAS Version      : HP-UX 9.1
 * Validation Level : 1 - Verification by Review
 ******************************************************************************
 * Preconditions    :
 *     Macrovar. needed: &varname.
 *     Datasets  needed: -
 *     Ext.Prg/Mac used: -
 * Postconditions   :
 *     Macrovar created: -
 *     Output   created: -
 *     Datasets created: -
 * Comments         : Constructs a text variable to create the <var>DTL
 *                    variable of &varname.
 ******************************************************************************
 * Author(s)        : shkzu (Saminder Bindra) / date: 24AUG2022
 ******************************************************************************
 * Change History   :
 ******************************************************************************/

    %LOCAL _macro _pcm;
    %LET _macro = &sysmacroname.;
    %LET _pcm   = 0;

    %IF %QUPCASE(%SUBSTR(&varname., %LENGTH(&varname.)-2)) EQ %STR(DTL)
    %THEN %DO;
        %LET sasname=%SUBSTR(&varname., 1, %LENGTH(&varname.)-3);
    %END;

    %IF %LENGTH(&sasname.) EQ 0
    %THEN %DO;
        %PUT %STR(ER)ROR: &macro. - &_macro. (&inputds.-->&varname.) Could not determine variable base name for &varname.!;
        %LET _pcm = &_pcm. + 1;
    %END;

    %IF %EVAL(&_pcm.) GT 0 %THEN %RETURN;

    %LOCAL _day _month _year;
    %LET _day   = &sasname._D;
    %LET _month = &sasname._M;
    %LET _year  = &sasname._Y;

    DATA &inputds.;
        SET &inputds.;

        IF LENGTH(&sasname.DTC) = 10 THEN DO;
            &sasname._Y = INPUT(SCAN(&sasname.DTC,1,'-'),best.);
            &sasname._M = INPUT(SCAN(&sasname.DTC,2,'-'),best.);
            &sasname._D = INPUT(SCAN(&sasname.DTC,-1,'-'),best.);
        END;
        ELSE DO;
            IF LENGTH(&sasname.DTC) = 7 THEN DO;
                &sasname._Y = INPUT(SCAN(&sasname.DTC,1,'-'),best.);
                &sasname._M = INPUT(SCAN(&sasname.DTC,-1,'-'),best.);
            END;
            ELSE IF LENGTH(&sasname.DTC) = 4 THEN DO;
                &sasname._Y = INPUT(&sasname.DTC,best.);
            END;
        END;

        &varname. = "---------";
        IF NOT nmiss(&_day.)
        THEN DO;
            substr(&varname., 1, 2) = put(&_day., Z2.);
        END;

        IF NOT nmiss(&_month.)
        THEN DO;
            substr(&varname., 3, 3) = upcase(put(mdy(&_month., 1, 1), monname3.));
        END;
        IF NOT nmiss(&_year.)
        THEN DO;
            substr(&varname., 6, 4) = put(&_year., Z4.);
        END;
        DROP  &sasname._Y &sasname._m &sasname._d;
        LABEL &varname. = 'Derived Listing Date';
    RUN;

%MEND m_create_dtl;


