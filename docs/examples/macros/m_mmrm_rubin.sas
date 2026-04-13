%macro m_mmrm_rubin (ds1  , ds2 ,param) / DES = 'Combine results with Rubin rule';

/*******************************************************************************
 * Bayer AG
 * Macro rely on: ###choose: TOSCA, initstudy, GMS, GDD, pure SAS###
 *******************************************************************************
 * Purpose          : Macro to create Combine results with Rubin rule
 * Programming Spec :
 * Validation Level : 1 - Validation by review
 * Parameters       :
 *                    Ds1   : Dataset to be read in
 *                    Ds2   : Dataset to be read in
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
 * Author(s)        : emvsx  / date: 28JUN2023
 * Reference prog   :
 *******************************************************************************
 * Change History   :
 ******************************************************************************/
/* Changed by       : emybb (Kaisa Laapas) / date: 02OCT2023
 * Reason           : #Save estim_tot dataset + added parameter name to file
 *                  : Calculating 'n' only from subjects, who has observations at specific time point
 *                  : Calculate 'n' from anal-dataset
 ******************************************************************************/
/* Changed by       : emvsx (Phani Tata) / date: 04DEC2023
 * Reason           : Updated at line 188 to update line2 to read in LCLMean and UCLmean
 ******************************************************************************/

/*******************************************************************************
 * Examples         :
   %mmrm_rubin (estim  , lsmeans );

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


/*******************************************************************************
 *Combine results with Rubin's rule
 *******************************************************************************/

* Difference in LS Means *;

PROC SORT DATA=&ds1. ;
    BY label  _imputation_;
RUN;

PROC MIANALYZE DATA=&ds1.;
    BY label;
    MODELEFFECTS estimate;
    STDERR stderr;
ODS OUTPUT ParameterEstimates=&ds1._tot;
RUN;


/*<Save estim-dataset for future use*/

data tlfmeta.&param._estim_s;
    set &ds1._tot;
RUN;

* Divide two-sided p-Value by 2 to get one-sided p-value ;
DATA &ds1._tot;
    SET &ds1._tot;
    IF tValue < 0 THEN Probt_1 = Probt/2;
    ELSE Probt_1 = 1-Probt/2;
    FORMAT probt_1 pvalue6.4;
    LABEL probt_1='1-sided p-value';
RUN;


*Table Programming *;

data  table_l2 ;
    length line3 line4 Line5 $200. ;
    set &ds1._tot ;
    line3  = cat (strip(put(estimate,12.2)) , ' (', strip(put(StdErr,12.2)), ')');
    line4  = cat (strip(put(LCLmean,12.2)) , ', ', strip(put(UCLmean,12.2)) );
    line5  =  strip(put(probt_1, pvalue6.4))  ;


    week =  Put(strip(compress(Label, ' ' ,'Kd')) , 4.) ;
    keep label Line: week ;
RUN;
proc sort data  = table_l2 ;
    by week label ;
RUN;

proc transpose data =  table_l2  out = t_l2 ;
    by week  label ;
    var Line3 line4 line5 ;
RUN;

data t_l2  ;
    length Col0 comment   $200. ;
    set t_l2;
    if upcase(_name_) = "LINE3" then do;
        comment = "Difference in LS-Means (SE)";
        row1 = 3 ;
    end ;

    if upcase(_name_) = "LINE4" then do ;
        comment = "95% CI for Difference in LS-Means";
        row1 = 4 ;
    end ;

    if upcase(_name_) = "LINE5" then do ;
        comment = "p-value (one-sided)";
        row1 = 5 ;
    end ;

    Row =  input (strip(week) , 3. ) ;
    Col0  = Cat  ("Week " , Put (week , 3. ));

    Label col1 = "Elinzanetant 120mg vs. Placebo"
          Col0  = "Time";

run;

/*<Save estim-dataset for future use*/

data tlfmeta.&ds1._tot_&param._o2;
    set &ds1._tot;
    time="Week"||''||compress(0-compress(label,'','A'));
    label time="Time point";
RUN;


/* LS Means */
PROC SORT DATA=&ds2.;
    BY trt01pn avisitn  _imputation_;
RUN;

PROC MIANALYZE DATA=&ds2.;
    BY trt01pn avisitn;
    MODELEFFECTS estimate;
    STDERR stderr;
   ODS OUTPUT ParameterEstimates=&ds2._tot;
RUN;

/*<Save estim-dataset for future use*/

data tlfmeta.&param._lsmean_s;
    set &ds2._tot;
run;

DATA &ds2._tot ;
    set &ds2._tot;
 if avisitn in (1,4,8,12) then   avisitn = avisitn *10 ;
run;

data &ds2._tot;
    set &ds2._tot;
    *Display model based estimates +/- SEs for week 1, week 4 and week 12 -- Updated Sep8th*;
     where avisitn in (10 40 120);
    format avisitn z_avisit.  estimate 12.2 ;
    se_low=estimate-stderr;
    se_upp=estimate+stderr;
RUN;

data  table_l0 ;
    length line1 line2   $200. ;
    set &ds2._tot ;
    line1  = cat (strip(put(estimate,12.2)) , ' (', strip(put(StdErr,12.2)), ')');
    *line2  = cat (strip(put(se_low,12.2)) , ', ', strip(put(se_upp,12.2)) );
    *Updated here for 95% tables*;
    line2  = cat (strip(put(LCLmean,12.2)) , ', ', strip(put(UCLmean,12.2)) );
    Row = avisitn / 10 ;
    if Row ^= 8  ;

    keep trt01pn avisitn  Line:   Row ;
RUN;

proc sort data  = table_l0 ;
    by Row trt01pn ;
    format trt01pn ;
RUN;

proc transpose data =  table_l0
     out = t_l0  prefix = Col_;
    by Row   ;
    var  Line1 line2   ;
    id trt01pn;
RUN;


data t_l0  ;
    length Col0 comment col_100  col_101  $200. ;
    set t_l0 ;
    if upcase(_name_) = "LINE1" then do ;
        comment = "LS-Means (SE)";row1 = 1 ;
    end ;

    if upcase(_name_) = "LINE2" then do ;
        comment = "95% CI for LS-Means"; row1 = 2 ;
    end ;


    Col0  = Cat  ("Week ",  strip(Put (Row , 3. ))  );
    Label col_100 = "Elinzanetant 120mg"
          col_101 = "Placebo"
          Col0  = "Time";

run;

/*Calculate n from anal-dataset, changed 02Oct2023 by KL*/
proc sort data=anal;by usubjid trt01pn region1n base;run;
proc transpose data=anal OUT=anal_trans ;
    by usubjid trt01pn region1n base;
    var Week_1 Week_4 Week_8 Week_12;
RUN;

DATA anal_trans;
    SET anal_trans;
    IF _name_='Week_1' THEN avisitn=10;
    ELSE IF _name_='Week_4' THEN avisitn=40;
    ELSE IF _name_='Week_8' THEN avisitn=80;
    ELSE IF _name_='Week_12' THEN avisitn=120;

    rename col1=aval;
run;

PROC SQL;
    CREATE TABLE subjn (where = (avisitn ^= 80) ) AS
    SELECT COUNT(usubjid) as n,avisitn,trt01pn
    FROM anal_trans WHERE aval is not null /*12Sep2023 KL added where statement*/
    GROUP BY trt01pn,avisitn
    order by avisitn , trt01pn ;
QUIT;

proc transpose data =  subjn  out = t_0  prefix = Colp_;
    by avisitn   ;
    var  n   ;
    id trt01pn;
    format trt01pn ;
run;


data t_0  ;
    length Col0 comment col_100 col_101 $200. ;
    set t_0 ;
    if upcase(_name_) = "N" then comment = "n";

    Row = avisitn / 10 ;
    row1 = 0 ;
    col_100 = strip(put( Colp_100 , 4. ) ) ;
    col_101 = strip(put( Colp_101 , 4. ) ) ;  ;
    drop Colp_100 Colp_101 ;
    Col0  = Cat  ("Week ",  strip(Put ( (avisitn / 10) , 3. ))  );
run;


proc sql;
    create table bign  as
    select count(usubjid) as bign, trt01pn
    from adsl
    group by trt01pn
    order by   trt01pn ;

quit;

proc sort data = hfdd
     out = tby (keep = paramcd) nodupkey ;
    by paramcd ;
RUN;




%mend m_mmrm_rubin ;