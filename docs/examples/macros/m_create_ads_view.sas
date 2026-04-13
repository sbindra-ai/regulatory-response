%MACRO m_create_ads_view(
    adsDomain    =                          /*@type DATA(#adsLib.)*/
  , outDat       =                          /*@type DATA*/
  , adsLib       = ADS                      /*@type LIBRARY*/
  , metaLib      = ADSMETA                  /*@type LIBRARY*/
  , addSupADS    = Y                        /*@type ONE(|YES|NO)*/
  , addSupADSL   = Y                        /*@type ONE(|YES|NO)*/
  , srcLib       = SP                       /*@type LIBRARY*/
  , srcMetaLib   = SPMETA                   /*@type LIBRARY*/
  , addSupSDTM   = Y                        /*@type ONE(|YES|NO)*/
  , subjectVars  = STUDYID USUBJID          /*@type VARIABLES(#srcDat.)*/
  , adslVars     = #CORE#                   /*@type VARIABLES(#adsLib..ADSL)*/
  , createSorted = Y                        /*@type ONE(|YES|NO)*/
  , createAsView  = Y                       /*@type ONE(|YES|NO)*/
) / DES = 'Create a view that contains core ADS, core ADSL and optionally supportive ADS and SDTM';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: DaLi
 *******************************************************************************
 * Purpose          : Create a view that contains core ADS, core ADSL and optionally supportive ADS and SDTM
 * Programming Spec :
 * Validation Level : 3 - Verification by Pre-Defined Test Protocol(s)
 * Parameters       :
 *        adsDomain : The related ADS domain name.
 *                    This is the domain to be referenced in the created view.
 *           outDat : The target name of the view.
 *           adsLib : The ADS data library.
 *          metaLib : The ADS metadata library.
 *        addSupADS : A flag to indicate if supportive ADS variables should be added (Y) or not (N).
 *                    These are decode variables of derived ADS variables referenced in
 *                    SVARNAME, SLABEL and SOUTFORM.
 *       addSupADSL : A flag to indicate if supportive ADSL variables should be added (Y) or not (N).
 *                    These are ADSL variables flagged as ADSLCORE=Y.
 *           srcLib : The source data library.
 *       srcMetaLib : The source metadata library.
 *       addSupSDTM : A flag to indicate if supportive SDTM variables should be added (Y) or not (N).
 *                    This are all SDTM variables that are flagged with BAY_ADS=Y and (BAY_SDTM=Y or BAY_SUPP=Y)
 *                    but are not explicitly mentioned in ADS metadata.
 *      subjectVars : Variables used to identify a subject.
 *         adslVars : A list of ADSL variables to be merged from ADSL data set.
 *                    Use #CORE# to merge all core variables.
 *                    Set empty to merge no ADSL variables.
 *     createSorted : A flag to indicate if target view should be accessed ordered by ADS key variables (Y) or not (N).
 *     createAsView : A flag to indicate if target should be created as VIEW (Y) or DATA Set (N).
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
 * Author(s)        : sgsaj (Michael Weiss) / date: 12FEB2020
 *******************************************************************************
 * Change History   :
 ******************************************************************************/
/* Changed by       : sgsaj (Michael Weiss) / date: 28MAY2020      Version: 1.1
 * Reason           : Added NOPRINT option to PROC SQL
 ******************************************************************************/
/* Changed by       : evmqf (Rowland Hale) / date: 27OCT2020       Version: 1.2
 * Reason           : - added support for China eSubmissions (ReCOp)
 ******************************************************************************/
/* Changed by       : sgsaj (Michael Weiss) / date: 09DEC2021      Version: 1.3
 * Reason           : Added parameter createAsView to support creation as DATA Set.
 ******************************************************************************/
/* Changed by       : sgsaj (Michael Weiss) / date: 18FEB2022      Version: 1.3
 * Reason           : Changed according to validation findings.
 ******************************************************************************/
/* Changed by       : sgsaj (Michael Weiss) / date: 13MAY2022
 * Reason           : Added a fix for the issue that decodes of missing numeric
 *                    values result in . as decode value. Expected is an empty
 *                    string.
 ******************************************************************************/
/* Changed by       : shkzu (Saminder Bindra) / date: 26AUG2022
 * Reason           : Downgraded the global-level macro to study-level due to a
 *                    major issue for Supporting non-core ADSL variables.
 *                    Added a new parameters adslVars.
 ******************************************************************************/

/*******************************************************************************
 * Examples         :
   %m_create_ads_view(adsDomain=ADVS, outDat=ADVS_ex);
 ******************************************************************************/


    %LOCAL macro mversion _starttime macro_parameter_error;
    %LET macro    = &sysmacroname.;
    %LET mversion = 1.3;

    %spro_check_param(name=adsDomain, type=TEXT)
    %IF (%QUOTE(&macro_parameter_error.) EQ %STR(1)) %THEN %RETURN;

    %spro_check_param(name=adsDomain, value=&metaLib..&adsDomain., type=DATA, mustExist=Y)
    %spro_check_param(name=adsDomain, value=&adsLib..&adsDomain., type=DATA,  mustExist=Y)

    %spro_check_param(name=addSupADS,    type=YESNO)
    %spro_check_param(name=addSupADSL,   type=YESNO)
    %spro_check_param(name=addSupSDTM,   type=YESNO)
    %spro_check_param(name=createSorted, type=YESNO)
    %spro_check_param(name=createAsView,  type=YESNO)


    %IF (%QUOTE(&macro_parameter_error.) EQ %STR(1)) %THEN %RETURN;

    %LOCAL _doMergeADSL;
    %LET _doMergeADSL = 0;

    %IF %QUPCASE(&adsDomain.) EQ %STR(ADSL) AND %length(&adslVars.) GT 0
    %THEN %DO;
        %log(D, %NRSTR(Requested to merge ADSL variables cannot done when related ADS domain is ADSL.))
        %RETURN;
    %END;
    %ELSE %IF %QUPCASE(&adsDomain.) NE %STR(ADSL) AND %length(&adslVars.) GT 0
    %THEN %DO;
        %LET _doMergeADSL = 1;
    %END;

    %IF &_doMergeADSL.
    %THEN %DO;
        %spro_check_param(value=&adsLib..ADSL,  type=DATA, mustExist=Y)
        %spro_check_param(value=&metaLib..ADSL, type=DATA, mustExist=Y)

        %IF (%QUOTE(&macro_parameter_error.) EQ %STR(1)) %THEN %RETURN;

        %spro_check_param(name=subjectVars, type=VARIABLES, mustExist=Y, data =&adsLib..ADSL)
    %END;
    %ELSE %DO;
        %* clean out adslVars as we do not merge ADSL;
        %LET adslVars = ;
    %END;

    %LET _starttime = %SYSFUNC(datetime());
    %log(I, Version &mversion started, addDateTime = Y, messageHint = BEGIN)


    %LOCAL l_opts l_notes;
    %LET l_notes = %SYSFUNC(getoption(notes));

    %LET l_opts = %SYSFUNC(getoption(SOURCE))
                  %SYSFUNC(getoption(SOURCE2))
                  %SYSFUNC(getoption(NOTES))
                  %SYSFUNC(getoption(FMTERR))
                  %SYSFUNC(getoption(QUOTELENMAX))
                  %SYSFUNC(getoption(VALIDVARNAME, KEYWORD))
                  %SYSFUNC(getoption(VARLENCHK,    KEYWORD))
    ;

    OPTIONS NOSOURCE NOSOURCE2 NONOTES NOFMTERR NOQUOTELENMAX VALIDVARNAME=V7 VARLENCHK=NOWARN;


    %LOCAL _tmpDat_vm1
           _tmpDat_vm_adsl_1
           _adsKeyVars _adsVars
           _id
           _srcKeyVars
           ;

    %LET adsDomain   = %UPCASE(&adsDomain.);
    %LET _adsVars    = %getVarlist(&adsLib..&adsDomain.);

    %LET _tmpDat_vm1 = %create_tempname(type = DATA, prefix = view_meta_);

    %**************************************************************************;
    %log(D, Will retrieve requested ADS variables from &metaLib..&adsDomain.)
    %UNQUOTE(* Will retrieve requested ADS variables from &metaLib..&adsDomain;)
    %**************************************************************************;

    %expand_ads_meta_dat(
        metaDat        = &metaLib..&adsDomain.
      , outDat         = &_tmpDat_vm1.
      , baseDat        = &adsLib..&adsDomain.
      , keepUnexpanded = N
      , keepAllVars    = N
    )

    %IF &createSorted. EQ %STR(Y)
    %THEN %DO;

        PROC SQL NOREMERGE NOPRINT;
            SELECT VARNAME INTO :_adsKeyVars SEPARATED BY ' '
                FROM &_tmpDat_vm1.
                WHERE NOT missing(KEYVAR)
                ORDER BY KEYVAR, VARNAME
            ;
        QUIT;

        %LOCAL _adsKeysMissing;
        %LET _adsKeysMissing = %updateVarlist(&_adsKeyVars., &_adsVars., mode = DROP);
        %IF %LENGTH(&_adsKeysMissing.) GT 0
        %THEN %DO;
            %log(W, Following ADS key variables are missing in &adsLib..&adsDomain.: &_adsKeysMissing.)
            %LET _adsKeyVars = %updateVarlist(&_adsKeyVars., &_adsKeysMissing., mode = DROP);
        %END;

        %log(I, Will use following ADS key variables: &_adsKeyVars.)

    %END;



    DATA &_tmpDat_vm1.(KEEP=VARSEQ MEMBER VARNAME LABEL TYPE OUTFORM CODELIST KEYVAR);
        LENGTH MEMBER $64;

        _id = open("&adsLib..&adsDomain.");

        %IF &addSupADS. EQ %STR(Y)
        %THEN %DO;
            DECLARE HASH merger(dataset:"&_tmpDat_vm1.(KEEP=VARNAME RENAME=(VARNAME=SVARNAME))");
            merger.defineKey("SVARNAME");
            merger.defineDone();
        %END;

        DO WHILE (NOT _last);
            SET &_tmpDat_vm1. END=_last;

            MEMBER = catx('.', "&adsDomain.", varname);
            IF varnum(_id, varname) LE 0
            THEN DO;
                %log(W, "Variable " varname " defined in &metaLib..&adsDomain. but not available in &adsLib..&adsDomain.!", messageType =DS);
                GOTO NEXT_VAR;
            END;

            OUTPUT;

            %IF &addSupADS. EQ %STR(Y)
            %THEN %DO;

                IF NOT MISSING(SVARNAME) AND
                   NOT merger.find()
                THEN DO;
                    %log(W, "Decode Variable " SVARNAME= "is already contained as primary variable. Will not consider decode.", messageType =DS)
                    SVARNAME=' ';
                END;

                IF NOT MISSING(SVARNAME)
                THEN DO;

                    * supportive ADS variable (decode) available;
                    VARSEQ + 0.5;
                    METHOD   = VARNAME;
                    MEMBER = ' ';
                    IF (lengthn(CODELIST) EQ 0)
                    THEN DO;
                        %log(W, "Variable &adsDomain." VARNAME= " does not contain a codelist, but references a supportive variable " SVARNAME= " this is invalid!", messageType =DS)
                    END;
                    ELSE DO;
                        IF TYPE EQ 'C' THEN DO;
                            MEMBER = catt('put(', "&adsDomain..", varname, ', $', CODELIST, '.)');
                        END;
                        ELSE DO;
                            MEMBER = catt('ifc(missing(', "&adsDomain..", varname,'), " ", put(', "&adsDomain..", varname, ', ', CODELIST, '.))');
                        END;

                        VARNAME  = SVARNAME;
                        LABEL    = SLABEL;
                        TYPE     = 'C';
                        OUTFORM  = SOUTFORM;
                        CODELIST = ' ';
                        methtyp  = 'decode';
                        deri_way = .;

                        OUTPUT;
                    END;
                END;
            %END;
            NEXT_VAR:
        END;
        _id = close(_id);
        STOP;
    RUN;

    %IF &addSupADSL. EQ %STR(Y) AND
        %QUPCASE(&adsDomain.) EQ %STR(ADSL)
    %THEN %DO;
        %log(I, Parameter addSupADSL is Y but adsDomain is ADSL. Will set addSupADSL to N!)
        %LET addSupADSL = N;
    %END;

    %IF &addSupADSL. NE %STR(Y)
    %THEN %DO;
        %log(D, Parameter addSupADSL is N. Will not merge ADSL variables.)
        %GOTO CONTINUE_AFTER_ADSL;
    %END;

    %**************************************************************************;
    %log(D, Will append adslcore variables from &metaLib..ADSL)
    %UNQUOTE(* Will append adslcore variables from &metaLib..ADSL;)
    %**************************************************************************;

    %IF NOT %SYSFUNC(exist(&metaLib..ADSL))
    %THEN %DO;
        %log(W, Data Set &metaLib..ADSL does not exist. Will not merge ADSL variables!)
        %LET addSupADSL = N;
        %GOTO CONTINUE_AFTER_ADSL;
    %END;

    %IF NOT %SYSFUNC(exist(&adsLib..ADSL))
    %THEN %DO;
        %log(W, Data Set &adsLib..ADSL does not exist. Will not merge ADSL variables!)
        %LET addSupADSL = N;
        %GOTO CONTINUE_AFTER_ADSL;
    %END;


    %LET _tmpDat_vm_adsl_1 = %create_tempname(type = DATA, prefix = view_meta_adsl_);
    %expand_ads_meta_dat(
        metaDat        = &metaLib..ADSL
      , outDat         = &_tmpDat_vm_adsl_1.
      , baseDat        = &adsLib..ADSL
      , updateVarSeq   = N
      , keepUnexpanded = N
      , keepAllVars    = Y
    )

    %IF %QUPCASE(&adslVars.) EQ %STR(#CORE#)
    %THEN %DO;
        %log(D, Will resolve ADSL core variables)

        %LET adslVars = %getDataValueList(&_tmpDat_vm_adsl_1.(WHERE=(adslcore EQ 'Y')), VARNAME);

        %log(D, adslVars #CORE# resolved to: &adslVars.)

    %END;
    %ELSE %IF %QUPCASE(&adslVars.) NE %STR(#CORE#)
    %THEN %DO;
        %log(D, Will resolve ADSL listed variables)

        %LOCAL _adslVars;
        %LET _adslvars = %BQUOTE(%SYSFUNC(TRANWRD(%SYSFUNC(COMPBL(&adslVars)),%STR( ),%STR(",")))) ;
        %LET _adslVars="&_adslVars";

        %LET adslVars = %getDataValueList(&_tmpDat_vm_adsl_1.(WHERE=(VARNAME in (&_adslVars))), VARNAME);

        %log(D, adslVars resolved to: &adslVars.)

    %END;
    * cut down &_tmpDat_vm_adsl_1. to related variables;
    DATA &_tmpDat_vm_adsl_1.;
        SET &_tmpDat_vm_adsl_1.;
        IF indexw("%QUPCASE(&adslVars.)", upcase(VARNAME), " ") GT 0;
    RUN;

    DATA &_tmpDat_vm_adsl_1.(KEEP=VARSEQ MEMBER VARNAME LABEL TYPE OUTFORM CODELIST);

        _id = open("&adsLib..ADSL");

        %IF &addSupADS. EQ %STR(Y)
        %THEN %DO;
            DECLARE HASH merger(dataset:"&_tmpDat_vm_adsl_1.(KEEP=VARNAME RENAME=(VARNAME=SVARNAME))");
            merger.defineKey("SVARNAME");
            merger.defineDone();
        %END;

        DO WHILE (NOT _last);
            SET &_tmpDat_vm_adsl_1. END=_last;
            %IF %QUPCASE(&adslVars.) EQ %STR(#CORE#)
            %THEN %DO;
                IF adslcore EQ 'Y';
            %END;
            VARSEQ + 1000;
            LENGTH MEMBER $64;
            MEMBER = catx('.', "ADSL", varname);
            IF varnum(_id, varname) LE 0
            THEN DO;
                %log(W, "Variable " varname " defined as adslcore=Y in &metaLib..ADSL but not available in &adsLib..ADSL!", messageType =DS);

                GOTO NEXT_VAR;
            END;

            OUTPUT;

            %IF &addSupADS. EQ %STR(Y)
            %THEN %DO;

                IF NOT MISSING(SVARNAME) AND
                   NOT merger.find()
                THEN DO;
                    %log(W, "Decode Variable " SVARNAME= "is already contained as primary variable in &metaLib..ADSL. Will not consider decode.", messageType =DS)
                    SVARNAME=' ';
                END;

                IF NOT MISSING(SVARNAME)
                THEN DO;
                    * supportive ADS variable (decode) available;
                    VARSEQ + 0.5;
                    METHOD   = VARNAME;
                    MEMBER = ' ';
                    if (lengthn(CODELIST) EQ 0)
                    THEN DO;
                        %log(W, "Variable ADSL." VARNAME= " does not contain a codelist, but references a supportive variable " SVARNAME= " this is invalid!", messageType =DS)
                    END;
                    ELSE DO;
                        IF TYPE EQ 'C' THEN DO;
                            MEMBER = catt('put(', "ADSL.", varname, ', $', CODELIST, '.)');
                        END;
                        ELSE DO;
                            MEMBER = catt('put(', "ADSL.", varname, ', ', CODELIST, '.)');
                        END;

                        METHOD   = VARNAME;
                        VARNAME  = SVARNAME;
                        LABEL    = SLABEL;
                        TYPE     = 'C';
                        OUTFORM  = SOUTFORM;
                        CODELIST = ' ';
                        methtyp  = 'decode';
                        deri_way = .;

                        OUTPUT;
                    END;
                END;
            %END;
            NEXT_VAR:
        END;
        _id = close(_id);
        STOP;
    RUN;

    %**************************************************************************;
    %log(D, Will merge &metaLib..ADSL with &metaLib..&adsDomain.)
    %UNQUOTE(* Will merge &metaLib..ADSL with &metaLib..&adsDomain;)
    %**************************************************************************;

    PROC SORT DATA=&_tmpDat_vm_adsl_1.; BY VARNAME; RUN;
    PROC SORT DATA=&_tmpDat_vm1.;       BY VARNAME; RUN;

    DATA &_tmpDat_vm_adsl_1.;
        MERGE &_tmpDat_vm_adsl_1.(IN=_in_adsl) &_tmpDat_vm1.(KEEP=VARNAME IN=_in_ads);
        BY VARNAME;
        IF _in_adsl AND NOT _in_ads;
    RUN;

    DATA &_tmpDat_vm1.;
        SET &_tmpDat_vm1. &_tmpDat_vm_adsl_1.;
    RUN;

%UNQUOTE(** >>> START IGNORE - &sysmacroname;)

    PROC DATASETS NOLIST NOWARN;
        DELETE &_tmpDat_vm_adsl_1. /MT=DATA;
    QUIT;

%UNQUOTE(** <<< END IGNORE - &sysmacroname;)

    %CONTINUE_AFTER_ADSL:

    %IF &addSupSDTM. NE %STR(Y)
    %THEN %DO;
        %log(D, Parameter addSupSDTM is N. Will not merge SDTM variables.)
        %GOTO CONTINUE_AFTER_SDTM;
    %END;

    %**************************************************************************;
    %log(D, Will retrieve related SDTMp domain)
    %**************************************************************************;

    %LOCAL srcDomain
           _tmpDat_sdtm1
           ;

    %LET srcDomain = ;

    %LET _id = %SYSFUNC(open(&metaLib..AD(WHERE=(memname EQ "%QUPCASE(&adsDomain.)"))));
    %IF NOT %SYSFUNC(fetch(&_id))
    %THEN %DO;
        %LET srcDomain = %getDataValue(&_id., METHOD, quote = Y);
        %LET srcDomain = %scan(&srcDomain., 1, %NRSTR(%());
    %END;
    %LET _id = %SYSFUNC(close(&_id.));

    %IF %LENGTH(&srcDomain.) EQ 0 %THEN %DO;
        %log(W, Can not fetch source domains for &adsDomain.. Will not merge supplemental SDTM variables!)
        %LET addSupSDTM = N;
        %GOTO CONTINUE_AFTER_SDTM;
    %END;

    %IF NOT %tableExist(&srcMetaLib..&srcDomain.)
    %THEN %DO;
        %log(W, Data Set &srcMetaLib..&srcDomain. does not exist. Will not merge supplemental SDTM variables!)
        %LET addSupSDTM = N;
        %GOTO CONTINUE_AFTER_SDTM;
    %END;

    %IF NOT %tableExist(&srcLib..&srcDomain.)
    %THEN %DO;
        %log(W, Data Set &srcLib..&srcDomain. does not exist. Will not merge supplemental SDTM variables!)
        %LET addSupSDTM = N;
        %GOTO CONTINUE_AFTER_SDTM;
    %END;

    %LET _srcKeyVars = %getDataValueList(&srcMetaLib..&srcDomain.(WHERE=(NOT MISSING(keyvar))), varname);
    %IF %LENGTH(&_srcKeyVars.) EQ 0
    %THEN %DO;
        %log(W, No key variables found in &srcMetaLib..&srcDomain.. Will not merge SDTM variables)
        %LET addSupSDTM = N;
        %GOTO CONTINUE_AFTER_SDTM;
    %END;

    %LOCAL _sdtmpVars _srcKeyVars_mis1 _srcKeyVars_mis2;
    %LET _sdtmpVars = %getVarlist(&srcLib..&srcDomain.);

    %LET _srcKeyVars_mis1 = %updateVarlist(&_srcKeyVars., &_sdtmpVars., mode = DROP);
    %LET _srcKeyVars_mis2 = %updateVarlist(&_srcKeyVars., &_adsVars.  , mode = DROP);

    %IF %LENGTH(&_srcKeyVars_mis1) GT 0
    %THEN %DO;
        %log(W, Following key variables are missing in &srcLib..&srcDomain.: &_srcKeyVars_mis1.. Will not merge SDTMp)
        %LET addSupSDTM = N;
        %GOTO CONTINUE_AFTER_SDTM;
    %END;

    %IF %LENGTH(&_srcKeyVars_mis2.) GT 0
    %THEN %DO;
        %log(W, Following key variables are missing in &adsLib..&adsDomain.: &_srcKeyVars_mis2.. Will not merge SDTMp)
        %LET addSupSDTM = N;
        %GOTO CONTINUE_AFTER_SDTM;
    %END;

    %log(D, Will use following variables when merging supportive SDTM variables: &_srcKeyVars.)

    %**************************************************************************;
    %log(D, Will retrieve metadata from &srcMetaLib..&srcDomain.)
    %UNQUOTE(* Will retrieve metadata from &srcMetaLib..&srcDomain;)
    %**************************************************************************;

    %LET _tmpDat_sdtm1 = %create_tempname(type = DATA, prefix = view_meta_sdtm_);

    DATA &_tmpDat_sdtm1.;

        _id = open("&srcLib..&srcDomain.");

        DO WHILE (NOT _last);
            SET &srcMetaLib..&srcDomain.;
            LENGTH MEMBER $64;

            * we are interested in all variables flagged as BAY_ADS=Y;
            IF BAY_ADS='Y';

            * we are only allowed to use SDTM (or SUPP) variables;
            IF NOT (BAY_SDTM='Y' OR BAY_SUPP='Y')
            THEN DO;
                %log(W, "Variable " varname " defined in &srcMetaLib..&srcDomain. as BAY_ADS=Y but neither BAY_SDTM=Y nor BAY_SUP=Y. Will ignore!", messageType =DS);
                GOTO NEXT_VAR;
            END;

            * We can only use if actually available;
            IF varnum(_id, varname) LE 0
            THEN DO;
                %log(W, "Variable " varname " defined in &srcMetaLib..&srcDomain. but not available in &srcLib..&srcDomain.!", messageType =DS);
                GOTO NEXT_VAR;
            END;

            * We need to build expression for variable;
            MEMBER = catx('.', "&srcDomain.", varname);

            OUTPUT;

            NEXT_VAR:
        END;
        _id = close(_id);
    RUN;

    %**************************************************************************;
    %log(D, Will merge &srcMetaLib..&srcDomain. to &metaLib..&adsDomain.)
    %UNQUOTE(* Will merge &srcMetaLib..&srcDomain. to &metaLib..&adsDomain;)
    %**************************************************************************;

    PROC SORT DATA=&_tmpDat_sdtm1.; BY VARNAME; RUN;
    PROC SORT DATA=&_tmpDat_vm1.;    BY VARNAME; RUN;

    DATA &_tmpDat_sdtm1.(KEEP=MEMBER VARSEQ VARNAME LABEL TYPE OUTFORM CODELIST);
        MERGE &_tmpDat_sdtm1.(IN=_in_sdtm) &_tmpDat_vm1.(KEEP=VARNAME IN=_in_ads);
        BY VARNAME;
        IF _in_sdtm AND NOT _in_ads;
        VARSEQ + 2000;
    RUN;

    DATA &_tmpDat_vm1.;
        SET &_tmpDat_vm1. &_tmpDat_sdtm1.;
    RUN;

    PROC DATASETS NOLIST NOWARN;
        DELETE &_tmpDat_sdtm1. /MT=DATA;
    QUIT;

    %CONTINUE_AFTER_SDTM:

    %LOCAL _first
           _fieldCmd
           VARNAME MEMBER LABEL TYPE LENGTH FORMAT
           _i _var
           varCount
           outType
           ;

    %LET varCount = %dsattrn(dataset = &_tmpDat_vm1., attrib = NOBS);
    %**************************************************************************;
    %log(D, Will create ADS view &outDat. with &varCount. variables!)
    %UNQUOTE(* Will create ADS view &outDat with &varCount variables;)
    %**************************************************************************;

    PROC SORT DATA=&_tmpDat_vm1.;    BY VARSEQ; RUN;

    DATA &_tmpDat_vm1.;
        SET &_tmpDat_vm1.;
        LENGTH length $8
               format $64
               ;

        IF TYPE EQ 'C'
        THEN DO;
            length = compress(OUTFORM, " .", "cfit");
            IF lengthn(codelist) GT 0
            THEN DO;
                format = cats("$",codelist, ".");
            END;
        END;
        ELSE DO;
            length = "8";
            IF lengthn(codelist) GT 0
            THEN DO;
                format = cats(codelist, '.');
            END;
            ELSE IF lengthn(OUTFORM) GT 0
            THEN DO;
                format = OUTFORM;
            END;
        END;
    RUN;

    %LET _id    = %SYSFUNC(open(&_tmpDat_vm1.));
    %LET _first = 1;

    %LET outType = %ifc(&createAsView. EQ %STR(Y), VIEW, TABLE);

    PROC SQL NOPRINT;

        CREATE &outType. &outDat. AS (
            SELECT

        %DO %WHILE (NOT %sysfunc(fetch(&_id.)));

            %IF &_first %THEN %LET _first=0; %ELSE ,;

            %LET VARNAME  = %getDataValue(&_id., VARNAME);
            %LET MEMBER   = %getDataValue(&_id., MEMBER);
            %LET LABEL    = %getDataValue(&_id., LABEL, quote = Y);
            %LET TYPE     = %getDataValue(&_id., TYPE);
            %LET LENGTH   = %getDataValue(&_id., LENGTH);
            %LET FORMAT   = %getDataValue(&_id., FORMAT);

            %LET _fieldCmd = &MEMBER. AS &VARNAME. LABEL="&LABEL.";

            %IF &TYPE. EQ %STR(C) %THEN %DO;
                %LET _fieldCmd = &_fieldCmd. LENGTH = &LENGTH.;
            %END;
            %IF %length(&FORMAT.) GT 0 %THEN %DO;
                %LET _fieldCmd = &_fieldCmd. FORMAT = &FORMAT.;
            %END;
            %log(D, &_fieldCmd.)
            &_fieldCmd.
        %END;
        %LET _id = %SYSFUNC(close(&_id.));

                FROM &adsLib..&adsDomain. AS &adsDomain.

                %IF &addSupADSL. EQ %STR(Y)
                %THEN %DO;
                    LEFT OUTER JOIN &adsLib..ADSL AS ADSL
                    ON
                    %DO _i = 1 %TO %sysfunc(countw(&subjectVars., %STR( )));
                        %LET _var = %scan(&subjectVars., &_i., %STR( ));
                        %IF &_i. GT 1 %THEN AND;
                        &adsDomain..&_var. EQ ADSL.&_var.
                    %END;
                %END;

                %IF &addSupSDTM. EQ %STR(Y) %THEN %DO;
                    LEFT OUTER JOIN &srcLib..&srcDomain. AS &srcDomain.
                    ON
                    %DO _i = 1 %TO %sysfunc(countw(&_srcKeyVars., %STR( )));
                        %LET _var = %scan(&_srcKeyVars., &_i., %STR( ));
                        %IF &_i. GT 1 %THEN AND;
                        &adsDomain..&_var. EQ &srcDomain..&_var.
                    %END;
                %END;
               )

                %IF &createSorted. EQ %STR(Y) AND
                    %LENGTH(&_adsKeyVars.) GT 0
                %THEN %DO;
                    ORDER BY
                    %DO _i = 1 %TO %sysfunc(countw(&_adsKeyVars., %STR( )));
                        %LET _var = %scan(&_adsKeyVars., &_i., %STR( ));
                        %IF &_i. GT 1 %THEN ,;
                        &_var.
                    %END;
                %END;

               ;
    QUIT;

%UNQUOTE(** >>> START IGNORE - &sysmacroname;)

    PROC DATASETS NOLIST NOWARN;
        DELETE &_tmpDat_vm1. /MT=DATA;
    QUIT;

%UNQUOTE(** <<< END IGNORE - &sysmacroname;)

    OPTIONS &l_opts.;
    %log(I, %NRBQUOTE(Version &mversion terminated. Runtime: %QSYSFUNC(putn(%SYSFUNC(datetime())-&_starttime., F12.2)) seconds!), messageHint =END)

%MEND m_create_ads_view;
