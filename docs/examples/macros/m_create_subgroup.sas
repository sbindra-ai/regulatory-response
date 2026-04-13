%MACRO m_create_subgroup()
/ DES = 'add subgroup variables in ADSL';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: pure SAS
 *******************************************************************************
 * Purpose          : Create subgroup variables in adsl
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
 * Author(s)        : eokcw (Vijesh Shrivastava) / date: 01AUG2022
 *******************************************************************************
 * Change History   :
 ******************************************************************************/
/* Changed by       : gmrpb (Fiona Yan) / date: 05JUN2023
 * Reason           : remove extra blank line
 *                    add condition "if in adsl" when merging qs with adsl
 *                    use QSORRES when calculate naval for ISI instead, to avoid potential future update
 *                    update macro title part to Bayer standard
 ******************************************************************************/
/* Changed by       : gmrpb (Fiona Yan) / date: 20SEP2023
 * Reason           : add 0=missing for isicat
 ******************************************************************************/
/* Changed by       : gmrpb (Fiona Yan) / date: 02JAN2024
 * Reason           : update baseline selection logic
 ******************************************************************************/

/*******************************************************************************
 * Examples         :
   %m_create_subgroup();
 ******************************************************************************/


*================================================================================================================;
* Add ISI subgroup variables;
* SAP 5.7.2
* 0-14 = No clinically significant and subthreshold insomnia
* 15-21 = Clinical insomnia (moderate severity)
* 22-28 = Clinical insomnia (severe)

*================================================================================================================;

*** Get data from QS;
data adqs_tot(keep=usubjid naval);
    set sp.qs (where=(QSCAT in ('ISI') and (visitnum=5 or qsdy<=1) and qsdy<=1));
    if not missing(qsorres) then naval=input(substr(qsorres,1,1),best.);
RUN;


* ISI;
proc sql;
    create table ISI as
    select usubjid, sum(naval) as ISI_tot from adqs_tot
    group by usubjid;
QUIT;

data ISI(drop=isi_tot);
    set ISI;

    * 0-14 = No clinically significant and subthreshold insomnia;
    * 15-21 = Clinical insomnia (moderate severity);
    * 22-28 = Clinical insomnia (severe);

    if 0<= ISI_tot <= 14 then ISICAT=1;
     else if 15 <= ISI_tot <= 21 then ISICAT=2;
      else if 22 <= ISI_tot <= 28 then ISICAT=3;

RUN;



data &adsDomain.;
    merge &adsDomain.(in=a) isi(in=b);
    by usubjid;
    * ISI;
    %createCustomVars(adsDomain=adsl, vars=ISICAT);
    if a;
    if missing(isicat) then isicat=0;
RUN;


/*******************************************************************************
 * End of macro
 ******************************************************************************/

%MEND m_create_subgroup;