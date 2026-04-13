%MACRO m_visit2avisit(indat=ads.&adsDomain.,outdat=ads.&adsDomain., EOT=WEEK26)
/ DES = 'MACRO FOR CREATING AVISIT OUT OF VISIT INFORMATION';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: SPro
 *******************************************************************************
 * Purpose          : MACRO FOR CREATING AVISIT OUT OF VISIT INFORMATION
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * Parameters       :
 *                    indat  : input data
 *                    outdat : output data
 *                    EOT    : Choose between values EOT or WEEK26
 *                              EOT    : Map VISITNUM=600000 to avisitn= 600010 (Week 26/End of trial)
 *                              WEEK26 : Map VISITNUM=600000 to avisitn= 260 (Week 26)
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
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/macros/m_visit2avisit.sas
 *******************************************************************************
 * Change History   :
 ******************************************************************************/


/*******************************************************************************
 * Examples         :
   %m_visit2avisit();
 ******************************************************************************/



    %LOCAL macro mversion _starttime macro_parameter_error;
    %LET macro    = &sysmacroname.;
    %LET mversion = 1.0;

    %spro_check_param(name=indat, type=DATA)
    %spro_check_param(name=outdat, type=DATA)

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



    /********************************************************************/
    /* Start */
    /********************************************************************/
    /*< AVISITN Analysis Visit (N)*/
    /****
     * AVISITN contains the visit number as observed (i.e., from SDTM VISITNUM), derived visit numbers, time window numbers, conceptual
    description numbers (such as Average, Endpoint, etc.), or a combination of any of these. Has to be defined in SAP/TLF.
     ***/
    DATA &outdat.;
        SET &indat;

/**** Visit mapping for study 21651 and 21652 ************/

IF &study in (21651 21652) THEN DO;

        %createcustomvars(adsDomain=&adsDomain., vars=avisitn);
        /* for now, take codes from visitnum */
        avisitn = .;
        /*for all ADS datasets where Visit needs to map to AVISITN*/

        IF      VISITNUM=0 then do;                  avisitn= 0; end;       /*Screening */
        ELSE IF VISITNUM=5 then do;                  avisitn= 5; end;    /*Baseline*/
        ELSE IF VISITNUM=10 then do;                 avisitn= 40; end;   /*Week 4*/
        ELSE IF VISITNUM=20 then do;                 avisitn= 80; end;    /*Week 8*/
        ELSE IF VISITNUM=30 then do;                 avisitn= 120; end;    /*Week 12*/
        ELSE IF VISITNUM=40 then do;                 avisitn= 160; end;    /*Week 16*/
        ELSE IF VISITNUM=50 then do;                 avisitn= 200; end;    /*Week 20*/
        ELSE IF VISITNUM=500000 then do;             avisitn= 500000; end;    /*Close liver observation*/
        ELSE IF VISITNUM=700000 then do;             avisitn= 700000; end;  /*ENDO.FUP visit*/
        ELSE IF VISITNUM=900000 then do;             avisitn= 900000; end;  /*Unscheduled*/
        ELSE IF VISITNUM=600000 then do;
            %IF %upcase(&EOT)=EOT %THEN %DO;          avisitn= 600010; %END;    /*Week 26/EOT*/
            %ELSE %IF %upcase(&EOT)=WEEK26 %THEN %DO; avisitn= 260; %END;  /*Week 26*/
        END;


END;



IF avisitn = . and "&adsDomain." ^= "ADQS" THEN DO;
     PUT "WARNING: AVISITN is missing. " _N_= usubjid= visitnum=;
END;



RUN;

OPTIONS &l_opts.;

%MEND m_visit2avisit;
