%MACRO m_create_covid()
/ DES = 'add covid variables in ADSL';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: pure SAS
 *******************************************************************************
 * Purpose          : Create COVID related variables in adsl
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
 * Author(s)        : eokcw (Vijesh Shrivastava) / date: 22SEP2022
 *******************************************************************************
 * Change History   :
 ******************************************************************************/
/* Changed by       : gmrpb (Fiona Yan) / date: 10JUL2023
 * Reason           : remove extra blank line
 *                    upcase DVCAT and compared term to be safer
 *                    update macro title part to Bayer standard
 *                    update dv logic
 ******************************************************************************/

/*******************************************************************************
 * Examples         :
   %m_create_covid();
 ******************************************************************************/

*================================================================================================================;
* Details on COVID-19 pandemic related study disruption,
 * i.e. description of COVID-19 pandemic related important protocol deviation (DV.DVEPRELI = "Y")
 * / premature discontinuation (DS.DSEPRELI = "Y")
 * / dose modification (EC.ECEPADJI = "Y")
 * / adverse events (AE.AEEPRELI = "Y")
 * / COVID-19 pandemic related inclusion/exclusion criteria violation (*2)

 *================================================================================================================;

* Get all pandemic affected data;

    proc sort data=sp.dv out=_dv1(keep=usubjid DVEPRELI) nodupkey;
        by usubjid;
        where DVEPRELI ne " " and not missing(IDREQIMD);
    RUN;

    proc sort data=sp.dv out=_dv2(keep=usubjid dvdecod) nodupkey;
        by usubjid;
        where DVEPRELI ne " " and DVDECOD= "OTHER PROTOCOL DEVIATIONS" and missing(IDREQIMD);
    RUN;

    proc sort data=sp.ds out=_ds(keep=usubjid DSEPRELI) nodupkey;
        by usubjid;
        where DSEPRELI ne " ";
    RUN;

    proc sort data=sp.ec out=_ec(keep=usubjid ecepadji) nodupkey;
        by usubjid;
        where ecepadji ne " ";
    RUN;

    proc sort data=sp.ae out=_ae(keep=usubjid AEEPRELI) nodupkey;
        by usubjid;
        where AEEPRELI ne " ";
    RUN;

    proc sort data=sp.xi out=_xi(keep=usubjid) nodupkey;
        by usubjid;
        where find(xiorres,"covid","i")>0 or find(xiorres1,"covid","i")>0 or find(xiorres2,"covid","i")>0 or find(xistresc,"covid","i")>0 or
                find(xiorres,"pandemic","i")>0 or find(xiorres1,"pandemic","i")>0 or find(xiorres2,"pandemic","i")>0 or find(xistresc,"pandemic","i")>0;
    RUN;

    data &adsDomain. (drop=DVEPRELI DVDECOD DSEPRELI ecepadji AEEPRELI);
        merge &adsDomain.(in=a) _ec(in=b) _ae(in=c) _ds(in=d) _dv1(in=e1) _dv2(in=e2) _xi(in=f);

        by usubjid;

        %createCustomVars(
            adsDomain = adsl
          , vars      = EP1FL EP1SEI EP2SEI EP1BDCSI EP1DVFL EP1ODFL EP1IEFL
        )
        ;
        if a;

        * EP1FL all pandemic flag;
        if b or c or d or e1 or e2 or f then do;
            EP1FL = 'Y';
        END;
        else do;
            EP1FL = 'N';
        END;

        *  EP1SEI dose adjustment due to COVID;
        if b then do;
            EP1SEI = 'Y';
        END;
        else do;
            EP1SEI = 'N';
        END;

        *  EP2SEI adverse event;
        if c then do;
            EP2SEI = 'Y';
        END;
        else do;
            EP2SEI = 'N';
        END;

        *  Discontinued due to COVID;
        if d then do;
            EP1BDCSI = 'Y';
        END;
        else do;
            EP1BDCSI = 'N';
        END;

        *  COVID related important protocol deviation;
        if e1 then do;
            EP1DVFL = 'Y';
        END;
        else do;
            EP1DVFL = 'N';
        END;

        *  COVID related other protocol deviation;
        if e2 then do;
            EP1ODFL = 'Y';
        END;
        else do;
            EP1ODFL = 'N';
        END;

        *  COVID related inclusion/exclusion;
        if f then do;
            EP1IEFL = 'Y';
        END;
        else do;
            EP1IEFL = 'N';
        END;
    RUN;

    /*******************************************************************************
     * End of macro
     ******************************************************************************/

%MEND m_create_covid;
