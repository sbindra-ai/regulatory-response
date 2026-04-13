%MACRO m_create_saf_anlflag(data=) / DES = 'Set analysis flag in safety domain';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: pure SAS
 *******************************************************************************
 * Purpose          : Set analysis flag in safety domain to identify valid records to analyze
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
 * Author(s)        : gkbkw (Ashutosh Kumar) / date: 05MAY2022
 ******************************************************************************/
/* Changed by       : glimy (Victoria Aitken) / date: 16MAR2023
 * Reason           : updated to create new var ANL01FL
 *                    updated to use work library instead of ads library
 *                    updated to exclude unscheduled visits
 ******************************************************************************/
/* Changed by       : gkbkw (Ashutosh Kumar) / date: 29AUG2023
 * Reason           : updated for avalc
 ******************************************************************************/
/* Changed by       : gmrnq (Susie Zhang) / date: 12SEP2023
 * Reason           : Add condition for ana01fl to exclude records with visitn=Baseline but ablfl ^='Y"
 ******************************************************************************/



%LOCAL _suffix;
%LET _suffix = %SUBSTR(&data, 3, 2);


DATA master;
    set &data(in=a) ;

    _pretrt = (&_suffix.strf in ('BEFORE', ''));
    IF LENGTH(&_suffix.dtc) = 10 THEN DO;
        _dtm = INPUT(CATS(&_suffix.dtc, 'T00:00:00'), ?? E8601DT19.);
    END;
    ELSE DO;
        _dtm = INPUT(&_suffix.dtc, ?? E8601DT19.);
    END;
    _valid = (NOT MISSING(_dtm) AND NOT MISSING(avisitn) AND (NOT MISSING(aval) or   NOT MISSING(avalc)) AND AVISITN not in(500000 900000));
RUN;

PROC SORT DATA=master;
    BY usubjid paramcd _valid _pretrt avisitn _dtm;
RUN;

/******************************************************************************
 * NOTE: Earliest non-missing in-treatment assessment per visit is flagged
 *       Pre-treatment assessment flagged as baseline is also flagged
 ******************************************************************************/

DATA &data;
    SET master;
    BY usubjid paramcd _valid _pretrt avisitn;
    %createCustomVars(adsDomain=&data, vars=anl01fl);
    IF (_valid AND NOT _pretrt AND FIRST.avisitn and avisitn>5) OR ablfl = 'Y' THEN anl01fl = 'Y';
    DROP _valid _pretrt _dtm;

RUN;

PROC DATASETS NOLIST LIBRARY=work;
    DELETE master;
QUIT;

/*******************************************************************************
 * End of macro
 ******************************************************************************/

%MEND m_create_saf_anlflag;
