%MACRO m_create_qs_bdi(

) / DES = 'add BDI related ANALYSIS variables and paramcd e.g Total ';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: pure SAS
 *******************************************************************************
 * Purpose          : Create BDI related ANALYSIS variables and paramcd e.g Total
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
   %m_create_qs_bdi();
 ******************************************************************************/



*** Get data from QS;
*"BDIB122": Total Score;
data adqs_tot;
    set &adsDomain._derive;
    if find(qscat, 'BECK DEPRESSION INVENTORY')>0 and qstestcd ne 'BDIB122';
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

* bdi;
proc sql;
    create table bdi as
    select *, sum(naval) as total from adqs_tot
    where find(qscat, 'BECK DEPRESSION INVENTORY')>0
    group by usubjid, qscat, avisitn, adt;
QUIT;

* Total bdi;
data bdi_total(drop=naval total);
    set bdi;
    by usubjid qscat avisitn adt;
    %createCustomVars(adsDomain=adqs, vars=PARAMTYP);
    AVAL=total;
    AVALC=" ";
    QSTESTCD='BDIB999';
    QSORRES=" ";
    QSTEST=" ";
    PARAMTYP="DERIVED";
    if last.adt;
RUN;

data &adsDomain.;
    set &adsDomain._ori bdi_total;
RUN;

/*******************************************************************************
 * End of macro
 ******************************************************************************/

%MEND m_create_qs_bdi;