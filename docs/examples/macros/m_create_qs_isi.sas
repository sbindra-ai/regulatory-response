%MACRO m_create_qs_isi(

) / DES = 'add ISI related ANALYSIS variables and paramcd e.g Total ';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: pure SAS
 *******************************************************************************
 * Purpose          : Create ISI related ANALYSIS variables and paramcd e.g Total
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * Parameters       : N/A
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
 * Author(s)        : gmrnq (Susie Zhang) / date: 06NOV2023
 * Reference prog   :
 *******************************************************************************
 * Change History   :
 ******************************************************************************/

/*******************************************************************************
 * Examples         :
   %m_create_qs_isi();
 ******************************************************************************/



*** Get data from QS;
data adqs_tot;
    set &adsDomain._derive (where=(QSCAT in ('ISI')));
    if not missing(aval) then naval = aval;
RUN;

* Get the first assessment for each visit only;
proc sort data=adqs_tot;
    by usubjid qscat avisitn adt atm qstestcd;
RUN;

data adqs_ft(keep=usubjid qscat avisitn adt atm);
    set adqs_tot;
    by usubjid qscat avisitn adt atm;
    if first.avisitn;
RUN;

data adqs_tot;
    merge adqs_tot adqs_ft(in=b);
    by usubjid qscat avisitn adt atm;
    if b;
RUN;

* ISI;
proc sql;
    create table isi as
    select *, sum(naval) as total from adqs_tot
    where QSCAT="ISI"
    group by usubjid, qscat, avisitn, adt;
QUIT;

* Total ISI;
data isi_total(drop=naval total);
    set isi;
    by usubjid qscat avisitn adt;
    AVAL=total;
    AVALC=" ";
    QSTESTCD='ISIB0999';
    QSORRES=" ";
    QSTEST=" ";
    PARAMTYP="DERIVED";
    if last.adt;
RUN;

data &adsDomain.;
    set &adsDomain. isi_total;
RUN;

/*******************************************************************************
 * End of macro
 ******************************************************************************/

%MEND m_create_qs_isi;