%MACRO define_var_meta(
      domain     =
    , adsMetaLib = adsmeta
    , var        =
    , label      =
    , lbl_ana1   =
    , format     =
    , method     =
    , methtyp    =
    , deri_way   =
    , codelist   =
    , core       =
    , adslcore   =
    , deri_txt   =
    , type       =
    , status     =
    , svarname   =
    , slabel     =
    , soutform   =
) / DES = 'Set variable attributes';
/*******************************************************************************
 * Bayer AG
 *******************************************************************************
 * Purpose          : Define attributes of a derived ADS variable
 * Parameters       :
 *           domain : The data set to apply metadata to.
 *       adsMetaLib : ADS metadata library name. The default value is adsmeta.
 *              var : This variable name to be updated in the ads meta data.
 *            label : The new value for label.
 *         lbl_ana1 : The new value for lbl_ana1.
 *           format : The new value for format.
 *           method : The new value for method.
 *          methtyp : The new value for methtyp.
 *         deri_way : The new value for deri_way.
 *         codelist : The new value for codelist.
 *             core : The new value for core.
 *         adslcore : The new value for adslcore.
 *         deri_txt : The new value for deri_txt.
 *             type : The new value for type.
 *           status : The new value for status.
 *         svarname : The new value for svarname (supportive variable name).
 *           slabel : The new value for slabel (supportive variable label).
 *         soutform : The new value for soutform (supportive outform value).
 * SAS Version      : Linux 9.4
 * Validation Level : 1 - Verification by Review
 *
 * Comment          : NOT A PRODUCTION MACRO - DOES NOT NEED TO BE VALIDATED
 *******************************************************************************
 * Author(s)        : shkzu (Saminder Bindra) / date: 20JUL2022
 ******************************************************************************/

    /*******************************************************************************
     * Create list of domains
     ******************************************************************************/

    %LOCAL _dlist;

    PROC SQL NOPRINT;
        SELECT memname INTO :_dlist SEPARATED BY ' '
            FROM &adsMetaLib..ad
            WHERE UPCASE(memname) = "%UPCASE(&domain)" OR %LENGTH(&domain) = 0
            ORDER BY memname;
    QUIT;

    /*******************************************************************************
     * Create variable metadata from parsing format
     ******************************************************************************/

    %LOCAL _type _outform _codelist;

    %IF %LENGTH(&format) = 0 %THEN %DO;
        %LET _type = ;
        %LET _outform = ;
        %LET _codelist = ;
    %END;
    %ELSE %IF %SUBSTR(&format, 1, 1) = %STR($) %THEN %DO;
        %LET _type = C;
        %LET _outform = %SUBSTR(&format, 2).;
        %LET _codelist = ;
    %END;
    %ELSE %IF %upcase(%SUBSTR(&format, 1, 1)) = %STR(Z) %THEN %DO;
        %LET _type = N;
        %LET _outform = 8.;
        %LET _codelist = &format;
    %END;
        %ELSE %DO;
        %LET _type = N;
        %LET _outform = &format;
        %LET _codelist = ;
    %END;

    /*******************************************************************************
     * Loop through domains
     ******************************************************************************/

    %LOCAL _n;
    %DO _n = 1 %TO %SYSFUNC(COUNTW(&_dlist));

    DATA &adsMetaLib..%SCAN(&_dlist, &_n);
        SET &adsMetaLib..%SCAN(&_dlist, &_n);
        IF UPCASE(varname) = UPCASE("&var") THEN DO;
            %IF %upcase(&methtyp)=SDTM %THEN %DO;
                label= '#';
                type= '#';
                outform= '#';
                core= '#';
                codelist= '#';
                deri_txt= '';
                deri_way= .;
                status= 'A';
            %END;
            %IF %LENGTH(&label) > 0 %THEN %DO;
                label = "&label";
            %END;
            %IF %LENGTH(&lbl_ana1) > 0 %THEN %DO;
                lbl_ana1 = "&lbl_ana1";
            %END;
            %IF %LENGTH(&_type) > 0 %THEN %DO;
                type = "&_type";
                outform = "&_outform ";
                codelist = "&_codelist ";
            %END;
            %IF %LENGTH(&method) > 0 %THEN %DO;
                method = "&method";
            %END;
            %IF %LENGTH(&codelist) > 0 %THEN %DO;
                codelist = "&codelist";
            %END;
            %IF %LENGTH(&deri_way) > 0 %THEN %DO;
                deri_way = &deri_way;
            %END;
            %IF %LENGTH(&deri_txt) > 0 %THEN %DO;
                deri_txt = "&deri_txt";
            %END;
            %IF %LENGTH(&methtyp) > 0 %THEN %DO;
                methtyp= "&methtyp";
            %END;
            %ELSE %DO;
                IF methtyp = 'default' THEN methtyp = 'derived';
            %END;
            %IF %LENGTH(&adslcore) > 0 %THEN %DO;
                adslcore= "&adslcore";
            %END;
            %IF %LENGTH(&core) > 0 %THEN %DO;
                core= "&core";
            %END;
            %IF %LENGTH(&type) > 0 %THEN %DO;
                type= "&type";
            %END;
            %IF %LENGTH(&status) > 0 %THEN %DO;
                status= "&status";
            %END;
            %IF %LENGTH(&svarname) > 0 %THEN %DO;
                svarname= "&svarname";
            %END;
            %IF %LENGTH(&svarname) > 0 %THEN %DO;
                slabel= "&slabel";
            %END;
            %IF %LENGTH(&soutform) > 0 %THEN %DO;
                soutform= "&soutform";
            %END;
        END;
    RUN;

    %END;

    /*******************************************************************************
     * End of macro
     ******************************************************************************/

%MEND define_var_meta;
