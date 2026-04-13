%MACRO m_adae_bign(
) / DES = 'Create big N column as per TLF specification and Total ';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: pure SAS
 *******************************************************************************
/*
 * Purpose          : Calculate BIG "N" for the each Phase Column AE tables
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *  *******************************************************************************
 *   Preconditions    :
 *       Macrovar. needed:
 *       Datasets  needed:
 *       Ext.Prg/Mac used:
 *   Postconditions   :
 *       Macrovar created:
 *       Output   created:
 *       Datasets created:
 *   Comments         :
 *******************************************************************************
 * Author(s)        : enpjp (Prashant Patel) / date: 18AUG2023
 * Reference prog   :
 ******************************************************************************/

data adsl_view1;
    set adsl_view;
    format aphasen _phs.;
    if trt01an = 100 then do;
        aphasen = 1;
        output;
        aphasen=5;
        output;
        if ph2sdt ne . then do;
            aphasen = 3;
            output;
        end;
    END;
    else if trt01an = 101 then do;
        aphasen = 2;
        output;
        if ph2sdt ne . then do;
            aphasen = 4;
            output;
            aphasen =5;
            output;
        end;
    END;
    *aphasen = 6;
    *output;
RUN;

data adae_view1;
    set adae_view;
    format aphasen _phs.;
    if trt01an = 100 then do;
        if aphase = "Week 13-26" then aphasen=3;
        else aphasen = 1;
        output;
        aphasen = 5;
        output;
    end;
    if trt01an = 101 then do;
        if aphase = "Week 13-26" then aphasen=4;
        else aphasen = 2;
        output;
        if aphase = "Week 13-26" then do;
                aphasen = 5;
                output;
        END;
    end;
    *aphasen =6;
    *output;
RUN;

%MEND m_adae_bign;
