%MACRO create_domain_meta(
      domain      =             /*@type DATA*/
    , gadsMetalib = ADSM_C_P    /*@type LIBRARY*/
    , adsMetaLib  = adsmeta     /*@type LIBRARY*/
    , spMetaLib   = spmeta      /*@type LIBRARY*/
    , vars        =             /*@type VARIABLES*/
) / DES = 'Create ADS domain';
/*******************************************************************************
 * Bayer AG
 *******************************************************************************
 * Purpose          : Create ADS domain metadata
 * Parameters       :
 *           domain : The data set to apply metadata to.
 *      gadsMetalib : The global ADS metadata library.
 *      Validation Level : 1 - Verification by Review
 *       adsMetaLib : The ADS metadata library.
 *        spMetaLib : The source metadata library.
 *             vars : The list of variables to be included in metadata.
 * SAS Version      : Linux 9.4
 *
 * Comment          : NOT A PRODUCTION MACRO - DOES NOT NEED TO BE VALIDATED
 *******************************************************************************
 * Author(s)        : shkzu (Saminder Bindra) / date: 05JUL2022
 ******************************************************************************/

    %LOCAL _n;

    /*******************************************************************************
     * Identify domain suffix
     ******************************************************************************/

    %LOCAL _sfx;
    %LET _sfx = %UPCASE(%SUBSTR(&domain, 3, 2));

    /*******************************************************************************
     * Build list of critically-important variables
     ******************************************************************************/

    %LOCAL _vlist;
    %LET _vlist = ADSNAME STUDYID USUBJID ASEQ;

    /*******************************************************************************
     * Create dummy dataset with critically-important global variables
     ******************************************************************************/

    DATA _varlist1;
        SET &gadsMetaLib..&domain;
        %DO _n = 1 %TO %SYSFUNC(COUNTW(&_vlist));
            IF varname = "%SCAN(&_vlist, &_n)" THEN OUTPUT;
        %END;
        KEEP varname;
    RUN;

    /*******************************************************************************
     * Create dummy dataset with manually requested variables
     ******************************************************************************/

    DATA _varlist2;
        ATTRIB varname LENGTH=$8;
        %DO _n = 1 %TO %SYSFUNC(COUNTW(&vars));
            varname = "%SCAN(&vars, &_n)";
            OUTPUT;
        %END;
    RUN;

    /*******************************************************************************
     * Create dummy dataset with all domain variables
     ******************************************************************************/

    DATA _varlist;
        SET _varlist1 _varlist2;
    RUN;

    /*******************************************************************************
     * Restrict domain metadata to critical and requested variables
     ******************************************************************************/

    PROC SORT NODUPKEY DATA=_varlist;
        BY varname;
    RUN;

    PROC SORT DATA=&gadsMetaLib..&domain OUT=_gadsmeta;
        BY varname;
    RUN;

    DATA &adsMetaLib..&domain;
        MERGE _gadsmeta _varlist(IN=_x);
        BY varname;
        IF _x;
    RUN;

    PROC DATASETS NOLIST LIBRARY=work;
        DELETE _varlist1 _varlist2 _varlist _gadsmeta;
    QUIT;

    /*******************************************************************************
     * Identify SDTM+ source name
     ******************************************************************************/

    %LOCAL _source;
    PROC SQL NOPRINT;
        SELECT SCAN(method, 1, ' (') INTO :_source
            FROM &gadsMetaLib..ad
            WHERE UPCASE(memname) = "%UPCASE(&domain)";
    QUIT;

    /*******************************************************************************
     * Discard SDTM+ variables not available in SDTM+ source (if available)
     ******************************************************************************/

    %IF %LENGTH(&_source) > 0 %THEN %DO;

        PROC SQL NOPRINT UNDO_POLICY=NONE;
            CREATE TABLE &adsMetaLib..&domain AS
                SELECT DISTINCT dat.*
                FROM &adsMetaLib..&domain AS dat JOIN &spMetaLib..&_source AS src ON
                     dat.varname = src.varname OR
                     dat.methtyp ^= 'SDTM' OR
                     UPCASE(SCAN(dat.method, 1, '.')) ^= UPCASE("&_source");
        QUIT;

    %END;

    PROC SORT DATA=&adsMetaLib..&domain;
        BY varseq varname;
    RUN;

    /*******************************************************************************
     * End of macro
     ******************************************************************************/

%MEND create_domain_meta;
