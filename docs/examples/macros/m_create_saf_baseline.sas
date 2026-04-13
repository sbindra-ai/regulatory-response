%MACRO m_create_saf_baseline(
       data =
)/ DES = 'Set baseline related values in safety domain';
/*******************************************************************************
  * Bayer AG
  * Macro rely on: pure SAS
  *******************************************************************************
  * Purpose          : Set baseline related values in safety domain
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
  * Author(s)        : gkbkw (Ashutosh Kumar) / date: 05JUL2022
  ******************************************************************************/
/* Changed by       : glimy (Victoria Aitken) / date: 29MAR2023
  * Reason           : added pchg
  *                    added base_anrind to be used for creation of trtemfl
  *                    updated to use work library instead of ads library
  ******************************************************************************/
/* Changed by       : gkbkw (Ashutosh Kumar) / date: 18OCT2023
  * Reason           : Taking treatment start from EX instead of ADSL
  ******************************************************************************/
    %LOCAL _sfx;

    %LET _sfx = %SUBSTR(&data, 3, 2);

    data EX;
        set sp.ex;
        format trtsdt date9.;
        trtsdt = INPUT(EXstdtc, ?? yymmdd10.);
        where EXstdtc ne "";
    RUN;

    data ds;
        set sp.ds;
        format rnddt date9.;
        rnddt = INPUT(dsstdtc, ?? yymmdd10.);
       where DSDECOD eq "RANDOMIZED";
    RUN;

    proc sort data=ds(keep=usubjid rnddt  );
        by usubjid rnddt;
    RUN;

    proc sort data=EX(keep=usubjid trtsdt   );
        by usubjid trtsdt;

    RUN;

    data _adsl;
        set EX;
        by usubjid trtsdt;
        if first.usubjid then output;
    RUN;

    data adsl;
        merge _adsl DS;
        by usubjid;
        if missing(trtsdt) then trtsdt=rnddt;
    RUN;

    proc sort data=&data;
        by usubjid;
    RUN;

    data &data;
        merge &data(in=a) adsl ;
        by usubjid ;
        if a ;
        IF LENGTH(&_sfx.dtc) = 10 THEN DO;
            _&_sfx.dtm = INPUT(CATS(&_sfx.dtc, 'T00:00:00'), ?? E8601DT19.);
        END;
        ELSE DO;
            _&_sfx.dtm = INPUT(&_sfx.dtc, ?? E8601DT19.);
        END;
    RUN;

    proc sort data=&data out=baseline;
        by usubjid paramcd avisitn _&_sfx.dtm &_sfx.seq;
        where avisitn<=5 and (aval ne . or avalc ne "") and adt ne . and trtsdt ne . and (adt le trtsdt);

    run;

    data baseline;
        set baseline;
        by usubjid paramcd avisitn _&_sfx.dtm &_sfx.seq;
        if last.paramcd then blfl='Y';
    RUN;

    proc sort data=baseline;
        by usubjid paramcd avisitn _&_sfx.dtm &_sfx.seq;
    RUN;

    proc sort data=&data;
        by usubjid paramcd avisitn _&_sfx.dtm &_sfx.seq;
    RUN;

    data &data;
        merge &data baseline(in=b where = (blfl='Y') keep= usubjid paramcd avisitn _&_sfx.dtm blfl &_sfx.seq);
        by usubjid paramcd avisitn _&_sfx.dtm &_sfx.seq;
        if b then do;
            %createCustomVars(adsDomain = &data, vars = ABLFL)
            ;
            ablfl='Y';
        end;
        IF LENGTH(&_sfx.dtc) = 10 THEN DO;
            _dtm = INPUT(CATS(&_sfx.dtc, 'T00:00:00'), ?? E8601DT19.);
        END;
        ELSE DO;
            _dtm = INPUT(&_sfx.dtc, ?? E8601DT19.);
        END;
    run;

    data base;
        length base_anrind $10;
        set baseline;

        where blfl='Y';
        base=aval;
        base_anrind="";
        %if %upcase("&_sfx.")="LB" %then %do;

            base_anrind=anrind;
        %END;

        IF LENGTH(&_sfx.dtc) = 10 THEN DO;
            _dtm_base = INPUT(CATS(&_sfx.dtc, 'T00:00:00'), ?? E8601DT19.);
        END;
        ELSE DO;
            _dtm_base = INPUT(&_sfx.dtc, ?? E8601DT19.);
        END;
        keep usubjid paramcd base base_anrind _dtm_base;
    RUN;

    proc sort data=&data;
        by usubjid paramcd avisitn;
    RUN;

    data &data;
        merge &data base;
        by usubjid paramcd;
        IF _dtm >= _dtm_base AND NOT MISSING(aval) AND NOT MISSING(base) THEN DO;
            chg = aval - base;
            if base ne 0 then pchg = ((AVAL-BASE)/BASE)*100;
        END;
    RUN;
%MEND m_create_saf_baseline;
