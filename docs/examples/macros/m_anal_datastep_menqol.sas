%MACRO m_anal_datastep_menqol(datain, param,timep,dataout)
/ DES = 'MACRO for data step for OASIS analyses';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: ###choose: TOSCA, initstudy, GMS, GDD, pure SAS###
 *******************************************************************************
 * Purpose          : MACRO to create data step for OASIS analyses
 * Programming Spec :
 * Validation Level : 1 - Validation by review
 * Parameters       :
 *                      datain : Dataset to be read in
 *                      param  : Variable needed
 *                      timep  : Timepoint, need to given as a list
 *                      dataout : Output dataset
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
 * Author(s)        : emybb (Kaisa Laapas) / date: 28JUN2023
 * Reference prog   :
 *******************************************************************************
 * Change History   :
 ******************************************************************************/
/* Changed by       : erepe (Claudia Rahner) / date: 04JUL2023
 * Reason           : adapted for menqol
 ******************************************************************************/
/* Changed by       : emvsx (Phani Tata) / date: 14AUG2023
 * Reason           : Updated sort order BY usubjid avisitn for HFDD dataset to avoid an ERROR
 ******************************************************************************/
/* Changed by       : emybb (Kaisa Laapas) / date: 16OCT2023
 * Reason           : Added trtpn and region as binary variables
 ******************************************************************************/

/*******************************************************************************
 * Examples         :
   %m_anal_datastep();
 ******************************************************************************/

%LOCAL macro mversion _starttime macro_parameter_error;
%LET macro    = &sysmacroname.;
%LET mversion = 1.0;

   * %spro_check_param(name=param1, type=TEXT)
   * %spro_check_param(name=param2, type=TEXT)

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

/*****************************
*Read data in
****************************/

    %load_ads_dat(&datain._view  , adsDomain = &datain );

        DATA hfdd;
            SET &datain._view;
            WHERE paramcd=&param  AND avisitn IN (&timep ) ;
            KEEP usubjid paramcd  avisitn aval chg trt01pn region1n anl01fl;/*anl01fl=permanent trt discontinuation*/
        RUN;

        /*Take baseline visit from avisit=5. If only baseline available, it has not been populated to other visits*/
        data base;
            SET  &datain._view;
            WHERE paramcd=&param AND avisitn=5;
            KEEP usubjid base;
        RUN;

        /*Keep all subjects in FAS*/
        DATA adsl;
            SET ads.adsl;
            WHERE fasfl='Y';
            KEEP usubjid fasfl trt01pn region1n;
        RUN;

        DATA hfdd;
            MERGE adsl (in=a) hfdd base;
            BY usubjid;
            if a;
        RUN;

        /*!Not needed after HFSS update*/
        /*Create full visit structure for all subjects*/
        PROC SORT DATA=hfdd NODUPKEY OUT=weeks (KEEP=avisitn);BY avisitn;RUN;
        PROC SORT DATA=hfdd NODUPKEY OUT=subjects (KEEP=usubjid paramcd base trt01pn region1n);BY usubjid;RUN;

        PROC SQL;
           CREATE TABLE str AS
           SELECT subjects.*,
                  weeks.*
           FROM subjects, weeks
           where avisitn NE .;
        QUIT;

        PROC SORT DATA=str  ;BY usubjid avisitn;RUN;
        PROC SORT DATA=hfdd ;BY usubjid avisitn;RUN;

        DATA hfdd2;
            MERGE hfdd str;
            BY usubjid avisitn;
            IF avisitn=. THEN DELETE;
        RUN;

       PROC SORT DATA=hfdd2 ;BY usubjid avisitn anl01fl ; RUN;
        *Add anl01fl for all subsequent visit per subject;
        DATA hfdd3;
            length _anl01fl $5;
            SET hfdd2;
            BY usubjid avisitn anl01fl;

            retain _anl01fl;
            if first.usubjid then _anl01fl='';
            if not missing(anl01fl) then _anl01fl='Yes';

            anl01fl=_anl01fl;
            drop _anl01fl;
        run;


        *Calculate number of missing observations and non-missing observations with ICE;
        PROC SORT DATA=hfdd3 out=hfdd3_sort;BY avisitn anl01fl;RUN;
        PROC MEANS DATA=hfdd3_sort noprint;
            BY avisitn anl01fl;
            VAR aval;
            OUTPUT OUT=missobs n=n nmiss=nmiss;
        RUN;

        /*Baseline can be imputed, if there are at least 2 post BL available. If not, add flag and ignore from analysis*/
        PROC SORT DATA=hfdd3 out=hfdd3_sorts;BY usubjid;RUN;
        PROC MEANS DATA=hfdd3_sorts(where=(base=.)) noprint;
            BY usubjid;
            VAR aval;
            OUTPUT OUT=missbl n=n nmiss=nmiss;
        RUN;

        DATA missbl;
            SET missbl;
            IF n < 2 THEN missblfl='Y';
            KEEP usubjid missblfl;
        RUN;


        /*Transpose visit to wide format*/
        PROC SORT DATA=hfdd3;BY usubjid paramcd base region1n trt01pn ;RUN;
        PROC TRANSPOSE DATA=hfdd3 OUT=hfdd_t;
            VAR  aval ;
            ID avisitn;
            BY usubjid paramcd base region1n trt01pn ;
        RUN;

        /*Transpose discont indicator flags to wide format*/
        PROC TRANSPOSE DATA=hfdd3 OUT=flag_t;
            VAR anl01fl;
            ID avisitn;
            BY usubjid  ;
        RUN;

        DATA flag_t2;
            SET flag_t;
            RENAME week_4=flag_disc_w4
                   week_8=flag_disc_w8
                   week_12=flag_disc_w12;
            DROP _NAME_;
        RUN;

        *Combine hfdd-data and discont indicator flags;
        DATA anal_;
            MERGE hfdd_t flag_t2 missbl;
            BY usubjid;
            DROP _NAME_ _LABEL_;

         /*Create numerical flagging variable*/
            IF flag_disc_w4="Y" THEN flag_disc_w4n=1; ELSE flag_disc_w4n=0;
            IF flag_disc_w8="Y" THEN flag_disc_w8n=1; ELSE flag_disc_w8n=0;
            If flag_disc_w12="Y" THEN flag_disc_w12n=1; ELSE flag_disc_w12n=0;

        /*Create binary variable for tretament and region*/
        if (put(trt01pn, z_trt.)) = "Elinzanetant 120mg" then trt01pn_bin = 1; else trt01pn_bin = 0;
        if (put(region1n, x_region.)) = "North America" then region1n_bin = 1; else region1n_bin = 0;
   RUN;

        DATA &dataout /*anal*/ missbldata;
            SET anal_;
            IF missblfl='Y' THEN OUTPUT missbldata;/*Maybe these observations could be deleted, but if one would like to check*/
            ELSE OUTPUT &dataout;
        RUN;

    /********************************************************************/
    /* End */
    /********************************************************************/

    OPTIONS &l_notes.;
    %PUT %STR(NO)TE: &macro. - Put your note here;
    OPTIONS NONOTES;

    %end_macro:;

    OPTIONS &l_opts.;
    %log(
            INFO
          , Version &mversion terminated.
          , addDateTime = Y
          , messageHint = END)
    %log(
            INFO
          , Runtime: %SYSFUNC(putn(%SYSFUNC(datetime())-&_starttime., F12.2)) seconds!
          , addDateTime = Y
          , messageHint = END)

%MEND m_anal_datastep_menqol;
