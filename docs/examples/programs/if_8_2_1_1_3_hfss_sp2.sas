/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = if_8_2_1_1_3_hfss_sp2   );
/*
 * Purpose          : Second supplementary estimand-change from baseline in mean daily frequency of moderate to severe hot flashes
 *                    - MMRM analysis - by treatment group(FAS)
 * Programming Spec :
 * Validation Level : 2 - Double programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 28NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/if_8_2_1_1_3_hfss_sp2.sas (gltsh (Bohdana Ratitch) / date: 15OCT2023)
 ******************************************************************************/
/* Changed by       : gltsh (Bohdana Ratitch) / date: 14DEC2023
 * Reason           : ###Pattern 3 input dataset - post-processing of imputed baseline value###
 ******************************************************************************/
/* Changed by       : emvsx (Phani Tata) / date: 28FEB2024
 * Reason           :  updated Plot Xtype = data as per Clinician  req
 ******************************************************************************/


%let param = %str(change from baseline in mean daily frequency of moderate to severe hot flashes) ;
%let sup = %str(Second supplementary estimand) ;

%let tti1 = %str(Table: &sup. - &param.- MMRM analysis - by treatment group &fas_label) ;
%let tti2 = %str() ;

%let tft1 = %str(Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks) ;
%let tft2 = %str(n = number of subjects with observed value for this timepoint and considered in the analysis model.) ;
%let tft3 = %str(Pattern mixture modelling using multiple imputation has been used to impute missing values or values discarded due to hypothetical strategy) ;
%let tft4 = %str(LS-Means = Least Squares Means, SE = Standard Error, CI = Confidence Interval, MMRM = Mixed Model Repeated Measures) ;
%let tft5 = %str() ;


%let xlabel= %str(Time (weeks));
%let ylabel= %str(Change in mean daily frequency);


%let fti1 = %str(Figure: &sup. - Line plot of LS-Means (MMRM) of &param. by treatment group &fas_label) ;
%let fti2 = %str() ;

%let fft1 = %str(Figure describes the time course of LS-Means +/- SE based on the estimates of the MMRM analysis.) ;
%let fft2 = %str(Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks) ;
%let fft3 = %str(LS-Means = Least Squares Means, SE = Standard Error, MMRM = Mixed Model Repeated Measures) ;


%load_ads_dat(adqshfss_view,
              adsDomain = adqshfss ,
              adslWhere =  &fas_cond.
              , adslVars          =) ;

%extend_data(indat = adqshfss_view, outdat = adqshfss)  ;
%load_ads_dat(adsl_view, adsDomain = adsl)  ;
%extend_data(indat = adsl_view, outdat = adsl)  ;

  options source notes;
%let impute=500;
%*let impute=5;

%put  &study.;
%let seed = &study.;

*** Suffix for dataset names saved for validation purposes in tlfmeta library;
%let valsuf=_sup2_hf;


*** Load endpoint data ***;
 data adqshfss;
     set ads.adqshfss;
     where parcat1="TWICE DAILY HOT FLASH DIARY V2.0" and
           ATPTN=. and
           paramcd="HFDB998" and
           avisitn in (5,10,40,80,120);
 RUN;

 data adsl;
     set ads.adsl;
     where fasfl="Y";
     keep studyid usubjid subjid age region1n trt01pn trt01an;
 RUN;

*** Create binary 0/1 versions of treatment and region variables for use in imputation steps using MCMC ***;
data adsl; set adsl;
  if (put(trt01pn, z_trt.)) = "Elinzanetant 120mg" then trt01pn_bin = 1; else trt01pn_bin = 0;
  if (put(region1n, x_region.)) = "North America" then region1n_bin = 1; else region1n_bin = 0;
run;

data anal;
   merge adsl adqshfss ;
   by usubjid;
run;

****************************************************************************************************************;
*** Create indicators for each patient/visit reflecting the role that each observation plays in each pattern ***;

data anal_pattern_by_visit; set anal;

    label
          pattern0="Observations under composite strategy"
          pattern1="Observation role for pattern 1"
          pattern2="Observation role for pattern 2"
          pattern3="Observation role for pattern 3"
          pattern4="Observation role for pattern 4"
          aval_p0="Value for pattern 0 - composite strategy"
          aval_p1="Value for pattern 1"
          aval_p2="Value for pattern 2"
          aval_p3="Value for pattern 3"
          aval_p4="Value for pattern 4"
      ;

    * Codes for pattern variables ;
    ** C = Treatment failure under the composite strategy;
    ** M = Missing/discarded value that needs to be imputed under the pattern;
    ** R = available value that can be used for estimation of MI model for pattern ;
    ** E = observation that should be excluded when estimating MI model for pattern ;

    *** Composite strategy ***;
    aval_p0 = aval;
    if (ANL03FL="Y") or
       (
        (ANL01FL="Y") and
        (upcase(trim(ICEDSRS)) in ("ADVERSE EVENT" "LACK OF EFFICACY")) and
        (ANL05FL="Y")
       )
    then do;
        * prohibited medication - use baseline value (or change from baseline = 0);
        if base ne . then do;
            pattern0 = "C";
            aval_p0 = base;
        END;
        else do;
            pattern0 = "M";
            aval_p0 = .;
        end;
    end;
    else pattern0="E";
    if avisitn=5 then pattern0 = ""; * baseline record;


    *** Pattern 1 ***;
    aval_p1 = aval_p0;

    if (ANL01FL ne "Y") and (ANL03FL ne "Y") and (ANL02FL="Y") and (upcase(trim(ICEINTRS)) not in ("ADVERSE EVENT")) then do;
        * interruption not due to AE and no permanent discontinuation at the same visit - discard value and impute;
        pattern1 = "M";
        aval_p1 = .;
    END;
    else if (ANL01FL ne "Y") and (ANL02FL ne "Y") and (ANL03FL ne "Y") then do;
        * no ICE - can be used as reference if non-missing or imputed under MAR if missing;
        if aval_p1 ne . then pattern1 = "R";
        else pattern1 = "M"; * this will include intermittent missing for patients with no ICE;
    END;
    else do;
        * other types of ICE - exclude - should not be used for estimation of MI model;
        pattern1 = "E";
        * Note: aval_p1 is not set to missing - may be used for prediction of imputed values (not for estimation of MI model);
    end;
    if avisitn=5 then pattern1 = ""; * baseline record;

    *** Pattern 2 ***;
    aval_p2 = aval_p0;
    if (ANL01FL ne "Y") and (ANL02FL="Y") and (ANL03FL ne "Y") then do;
        * interruption and no permanent discontinuation or prohibited meds at the same visit ;
        if (upcase(trim(ICEINTRS)) in ("ADVERSE EVENT")) and aval_p2 = . then do;
            * interruption due to AE and missing value - impute;
            pattern2 = "M";
        END;
        else do;
            if aval_p2 ne . then do;
                * interruption (any reason) and observed value - use as reference;
                pattern2 = "R";
            end;
            else do;
                * interruption not due to AE and missing value - exclude - not useful for imputation;
                pattern2 = "E";
            end;
        end;
    END;
    else do; * not an interruption - exclude - not useful for imputation;
        pattern2 = "E";
    END;
    if avisitn=5 then pattern2 = ""; * baseline record;

    * Pattern 3;
    aval_p3 = aval_p0;
    if (ANL01FL="Y") and (upcase(trim(ICEDSRS)) in ("ADVERSE EVENT" "LACK OF EFFICACY")) then do;
        * treatment-related permanent discontinuation;
        if (ANL05FL="Y") then do;
            * participants who initiate alternative treatment - composite strategy - use aval_p0;
            pattern3 = "R";
        END;
        else do;
            * participants who don't initiate alternative treatment - if non-missing use as reference, if missing - impute;
            if aval_p3 ne . then pattern3 = "R"; else pattern3 = "M";
        END;
    END;

    else pattern3="R"; * all other observations can be used in the imputation model that will be similar to primary analysis;
    if avisitn=5 then pattern3 = ""; * baseline record;

    *** Pattern 4 ***;
    aval_p4 = aval_p0;
    if (ANL01FL="Y") and (upcase(trim(ICEDSRS)) not in ("ADVERSE EVENT" "LACK OF EFFICACY")) and (ANL03FL ne "Y") then do;
        * non-treatment-related permanent discontinuation - discard and impute;
        aval_p4 = .;
        pattern4 = "M";
    END;
    else do;
        pattern4 = "R"; * all other observations can be used in the imputation model under hypothetical scenario;
    END;
    if avisitn=5 then pattern4 = ""; * baseline record;

run;
****************************************************************************************************************;
*** Transpose the data into horizontal structure ***;
*******************************************************************************************;
%macro transpvar(datain=, var=, idvar=, by=);
    proc transpose data=&datain out=&datain.t_&var(drop=_NAME_ _LABEL_) prefix=&var._;
        by &by ;
        var &var ;
        id &idvar;
    RUN;

%MEND;
*******************************************************************************************;
data allv; set anal_pattern_by_visit; run;

*** Keep ICE information in the transposed dataset for traceability ;
%transpvar(datain=allv, var=ANL01FL, idvar=avisitn, by=usubjid trt01pn region1n trt01pn_bin region1n_bin);
%transpvar(datain=allv, var=ICEDSRS, idvar=avisitn, by=usubjid trt01pn region1n trt01pn_bin region1n_bin);
%transpvar(datain=allv, var=ANL05FL, idvar=avisitn, by=usubjid trt01pn region1n trt01pn_bin region1n_bin);
%transpvar(datain=allv, var=ANL02FL, idvar=avisitn, by=usubjid trt01pn region1n trt01pn_bin region1n_bin);
%transpvar(datain=allv, var=ICEINTRS, idvar=avisitn, by=usubjid trt01pn region1n trt01pn_bin region1n_bin);
%transpvar(datain=allv, var=ANL03FL, idvar=avisitn, by=usubjid trt01pn region1n trt01pn_bin region1n_bin);

*** Pattern variables ;
%transpvar(datain=allv, var=pattern0, idvar=avisitn, by=usubjid trt01pn region1n trt01pn_bin region1n_bin);
%transpvar(datain=allv, var=pattern1, idvar=avisitn, by=usubjid trt01pn region1n trt01pn_bin region1n_bin);
%transpvar(datain=allv, var=pattern2, idvar=avisitn, by=usubjid trt01pn region1n trt01pn_bin region1n_bin);
%transpvar(datain=allv, var=pattern3, idvar=avisitn, by=usubjid trt01pn region1n trt01pn_bin region1n_bin);
%transpvar(datain=allv, var=pattern4, idvar=avisitn, by=usubjid trt01pn region1n trt01pn_bin region1n_bin);

%transpvar(datain=allv, var=aval_p0, idvar=avisitn, by=usubjid trt01pn region1n trt01pn_bin region1n_bin);
%transpvar(datain=allv, var=aval_p1, idvar=avisitn, by=usubjid trt01pn region1n trt01pn_bin region1n_bin);
%transpvar(datain=allv, var=aval_p2, idvar=avisitn, by=usubjid trt01pn region1n trt01pn_bin region1n_bin);
%transpvar(datain=allv, var=aval_p3, idvar=avisitn, by=usubjid trt01pn region1n trt01pn_bin region1n_bin);
%transpvar(datain=allv, var=aval_p4, idvar=avisitn, by=usubjid trt01pn region1n trt01pn_bin region1n_bin);

*** Original aval value;
%transpvar(datain=allv, var=aval, idvar=avisitn, by=usubjid trt01pn region1n trt01pn_bin region1n_bin);

*** Merge all variables into one horizontal dataset;
data allvt0(drop = pattern0_Baseline pattern1_Baseline pattern2_Baseline pattern3_Baseline pattern4_Baseline
     aval_p1_Baseline  aval_p2_Baseline  aval_p3_Baseline  aval_p4_Baseline
     );
    merge allvt_ANL01FL allvt_ICEDSRS allvt_ANL05FL allvt_ANL02FL allvt_ICEINTRS allvt_ANL03FL allvt_aval
          allvt_pattern0 allvt_aval_p0
          allvt_pattern1 allvt_aval_p1
          allvt_pattern2 allvt_aval_p2
          allvt_pattern3 allvt_aval_p3
          allvt_pattern4 allvt_aval_p4
          ;
    by usubjid trt01pn region1n trt01pn_bin region1n_bin;
run;

*** Derive patient-level indicators for each pattern - patient is included in a pattern if at least one visit is not excluded from the pattern;
data allvt deleted_pts; set allvt0;
    if pattern1_Week_1 ne "E" or pattern1_Week_4 ne "E" or pattern1_Week_8 ne "E" or pattern1_Week_12 ne "E" then pattern1_pt="Y";
    if pattern2_Week_1 ne "E" or pattern2_Week_4 ne "E" or pattern2_Week_8 ne "E" or pattern2_Week_12 ne "E" then pattern2_pt="Y";
    if pattern3_Week_1 ne "E" or pattern3_Week_4 ne "E" or pattern3_Week_8 ne "E" or pattern3_Week_12 ne "E" then pattern3_pt="Y";
    if pattern4_Week_1 ne "E" or pattern4_Week_4 ne "E" or pattern4_Week_8 ne "E" or pattern4_Week_12 ne "E" then pattern4_pt="Y";

    p1n = ifn((aval_Week_1 ne . and pattern1_Week_1 = "R"),1,0) +
          ifn((aval_Week_4 ne . and pattern1_Week_4 = "R"),1,0) +
          ifn((aval_Week_8 ne . and pattern1_Week_8 = "R"),1,0) +
          ifn((aval_Week_12 ne . and pattern1_Week_12= "R"),1,0) ;

    if aval_Baseline = . then base_missing = 1;

    if pattern2_Week_1 = "M" or pattern2_Week_4 = "M" or pattern2_Week_8 = "M" or pattern2_Week_12 = "M" then pattern2_pt_miss="Y";

    *< Remove from analysis participants with missing baseline and < 2 non-missing observations;
    nonmis = 0;
    if aval_p0_Week_1 ne . and pattern1_Week_1 ne "M" and pattern2_Week_1 ne "M" and pattern3_Week_1 ne "M" and pattern4_Week_1 ne "M" then nonmis = nonmis+1;
    if aval_p0_Week_4 ne . and pattern1_Week_4 ne "M" and pattern2_Week_4 ne "M" and pattern3_Week_4 ne "M" and pattern4_Week_4 ne "M"  then nonmis = nonmis+1;
    if aval_p0_Week_8 ne . and pattern1_Week_8 ne "M" and pattern2_Week_8 ne "M" and pattern3_Week_8 ne "M" and pattern4_Week_8 ne "M"  then nonmis = nonmis+1;
    if aval_p0_Week_12 ne . and pattern1_Week_12 ne "M" and pattern2_Week_12 ne "M" and pattern3_Week_12 ne "M" and pattern4_Week_12 ne "M" then nonmis = nonmis+1;
    /*if aval_Baseline = . and nonmis < 2 then output deleted_pts; else output allvt;*/
    if aval_Baseline = . and nonmis < 2 then output deleted_pts;
    else if aval_Baseline = . and p1n < 2 and pattern2_pt_miss="Y" then output deleted_pts;
    else output allvt;
RUN;

*** Create multiple copies of the data (number of copies equal to the number of multiple imputations - easier to handle like this from the start;
data allvtm; set allvt;
    do m=1 to &impute;
        _Imputation_=m;
        output;
    END;
run;

proc sort data=allvtm; by _Imputation_ usubjid; run;

********************************************************************************************************************;
*** Impute pattern 1 ***;
********************************************************************************************************************;


*** Dataset for estimation of MI model under pattern 1 ***;
data p1_data4mi(keep=_Imputation_ usubjid trt01pn region1n trt01pn_bin region1n_bin aval_Baseline
        aval_p1_Week_1 aval_p1_Week_4 aval_p1_Week_8 aval_p1_Week_12
        pattern1_Week_1  pattern1_Week_4  pattern1_Week_8  pattern1_Week_12 p1n base_missing);
    set allvtm(where=(pattern1_pt = "Y"));

run;

*** MI in pattern 1 is performed under the MAR assumption using the MCMC method for all participants ***;
*** This will also impute missing values (intermittent or not) for participants with no ICEs ***;
*** Imputation is done in 2 steps;
****** 1) estimate and save the imputation model;
****** 2) pass the saved imputation model to next MI call to perform the imputations;
*** This 2-step approach allows us to exclude certain values from model estimation,
***   but include them for predicting imputed values -
***   to account for all observed values in patients with intermittent missingness ;

* Step 1 - dataset for imputation model estimation;
data p1_data4mi_est; set p1_data4mi;
    array pattern {4} pattern1_Week_1  pattern1_Week_4  pattern1_Week_8  pattern1_Week_12;
    array aval_p  {4} aval_p1_Week_1 aval_p1_Week_4 aval_p1_Week_8 aval_p1_Week_12;

    *** Set excluded observations to missing for the estimation of the MI model ***;
    do i=1 to 4;
        if pattern[i] = "E" then aval_p[i] = .;
    END;
    drop i;
run;

* Save dataset used as input for pattern 1 imputation for validation;
/*
Data tlfmeta.p1_data4mi_est&valsuf;
    Set p1_data4mi_est;
Run;
*/

******************************************************************************************************************************;
*** Removing excluded values both from model estimation and prediction ***;

proc sort data=p1_data4mi_est; by _Imputation_ trt01pn_bin region1n_bin usubjid; run;
ods listing close;
proc mi data=p1_data4mi_est nimpute=1 seed=&seed displaypattern=ALL
     out=p1_data_imputed(rename=(
     aval_Baseline = aval_Baseline_imp
     aval_p1_Week_1=aval_p1_Week_1_imp
     aval_p1_Week_4=aval_p1_Week_4_imp
     aval_p1_Week_8=aval_p1_Week_8_imp
     aval_p1_Week_12=aval_p1_Week_12_imp));

    by _Imputation_;
    *< Make sure to use binary 0/1 versions of treatment and region when MCMC is used;
    var trt01pn_bin region1n_bin aval_Baseline aval_p1_Week_1 aval_p1_Week_4 aval_p1_Week_8 aval_p1_Week_12;
    mcmc chain=multiple;
RUN;
ods listing;
* Save imputed dataset for validation;
/*
Data tlfmeta.p1_data_imputed&valsuf;
    Set p1_data_imputed;
Run;
*/

*** If missing baseline and less than 2 post-baseline observations available in the above imputation step,
discard imputed baseline value - will be imputed as part of Pattern 3;
data p1_data_imputed; set p1_data_imputed;
    if base_missing = 1 and p1n < 2 then aval_Baseline_imp = .;
run;

******************************************************************************************************************************;

********************************************************************************************************************;
*** Impute pattern 2 ***;
********************************************************************************************************************;

*** Count number of patients with any missing values under pattern 2;
PROC SQL NOPRINT;
    SELECT COUNT(*) into :p2
           FROM allvtm WHERE (pattern2_pt="Y") and
           ((pattern2_Week_1="M") or (pattern2_Week_4="M") or (pattern2_Week_8="M") or (pattern2_Week_12="M"));
QUIT;
%put p2=&p2;

*** If there are no missing data to impute in pattern 2, copy existing data to a placeholder dataset;
%if (&p2 = 0) %then %do;
    data p2_data_imputed(rename=(
         aval_p2_Week_1=aval_p2_Week_1_imp
         aval_p2_Week_4=aval_p2_Week_4_imp
         aval_p2_Week_8=aval_p2_Week_8_imp
         aval_p2_Week_12=aval_p2_Week_12_imp));

        set allvtm(where=(pattern2_pt = "Y"));
    run;
%END;
%else %do;

*** Subset pattern 2 participants and merge with their values after the pattern 1 imputation;
*** Values imputed under pattern 1 may be used in pattern 2 ;
proc sort data=p1_data_imputed; by _Imputation_ usubjid; run;
data p2_data4mi_est0;
    merge allvtm(where=(pattern2_pt = "Y") in=p2)
          p1_data_imputed(keep=_Imputation_ usubjid aval_Baseline_imp aval_p1_Week_1_imp aval_p1_Week_4_imp aval_p1_Week_8_imp aval_p1_Week_12_imp);
    by _Imputation_ usubjid;
    if p2;
run;

*** Create a dataset with records that represent a change from visit prior to interruption to visit with interruption;
****  This dataset will be in a vertical structure - one record per patient/visit;
data p2_data4mi_est(keep=_Imputation_ usubjid trt01pn region1n tvisitn base prev chg p2);
    set p2_data4mi_est0;
    array pattern {4} pattern2_Week_1  pattern2_Week_4  pattern2_Week_8  pattern2_Week_12;
    array pattern1 {4} pattern1_Week_1  pattern1_Week_4  pattern1_Week_8  pattern1_Week_12;
    array aval_p  {5} aval_Baseline aval_p2_Week_1 aval_p2_Week_4 aval_p2_Week_8 aval_p2_Week_12;
    array aval_p1 {5} aval_Baseline_imp aval_p1_Week_1_imp aval_p1_Week_4_imp aval_p1_Week_8_imp aval_p1_Week_12_imp;
    array fl {5} ANL02FL_Baseline ANL02FL_Week_1 ANL02FL_Week_4 ANL02FL_Week_8 ANL02FL_Week_12;

    label
        chg = "Change from visit before interruption to visit with interruption"
        prev = "Value at visit prior to interruption"
        base = "Baseline value"
        tvisitn = "Temporary visit number"
        ;

    * baseline value;
    if aval_Baseline ne . then base = aval_Baseline; else do;
        if aval_Baseline_imp < 0 then base=0; *** post-processing for values that got imputed with an unrealistic negative value;
        else base = aval_Baseline_imp;
    end;

    do i=1 to 4;
        if i=1 then prev = base; *previous visit is a baseline visit;
        else do; *previous visit is a post-baseline visit;
             if aval_p[i] ne . and fl[i] ne "Y" then prev = aval_p[i]; * previous visit not an interruption and previous value non-missing ;
             else if aval_p[i] = . and fl[i] ne "Y" and pattern1[i-1]="M" then do; * previous visit not an interruption but previous value missing use imputation from pattern 1;
                 if aval_p1[i] < 0 then prev=0; *** post-processing for values that got imputed with an unrealistic negative value;
                 else prev = aval_p1[i];
             end;
        END;

        if pattern[i] = "R" then do;
            p2 = pattern[i];
            chg = prev-aval_p[i+1]; * change from previous visit;
            tvisitn = i; * temporary visit number;
            if base ne . and prev ne . and chg ne . then output;
        END;
        else if pattern[i] = "M" then do;
            p2 = pattern[i];
            chg = .;
            tvisitn = i;
            if prev ne . then output;
        END;
    END;

    drop i;

RUN;

* Impute missing values of chg ;
proc sort data=p2_data4mi_est; by _Imputation_ trt01pn region1n usubjid; run;

* Save dataset used as input for pattern 2 imputation for validation;
/*
Data tlfmeta.p2_data4mi_est&valsuf;
    Set p2_data4mi_est;
Run;
*/

ods listing close;
proc mi data=p2_data4mi_est nimpute=1 seed=&seed out=p2_data_imputed_t0 displaypattern=ALL;
    by _Imputation_;
    class trt01pn region1n;
    var trt01pn region1n base prev chg;
    monotone reg;
RUN;
ods listing;

* Save dataset for validation;
/*
data tlfmeta.p2_data_imputed_t0&valsuf; set p2_data_imputed_t0; run;
*/

*** Based on the imputed change from previous visit, calculate absolute value at the interruption visit;
data p2_data_imputed_t1; set p2_data_imputed_t0;
    aval_p2_imp = prev - chg;
    label aval_p2_imp = "Pattern 2 imputed value";
run;

* Transpose imputed values into horizontal structure;
proc sort data=p2_data_imputed_t1; by _Imputation_ usubjid; run;
%transpvar(datain=p2_data_imputed_t1, var=aval_p2_imp, idvar=tvisitn, by=_Imputation_ usubjid);

data    p2_data_imputed_t2;
    set p2_data_imputed_t1t_aval_p2_imp(rename=(
     aval_p2_imp_1 = aval_p2_Week_1_imp
     aval_p2_imp_2 = aval_p2_Week_4_imp
     aval_p2_imp_3 = aval_p2_Week_8_imp
     aval_p2_imp_4 = aval_p2_Week_12_imp));
run;

* Save dataset for validation;
/*
data tlfmeta.p2_data_imputed_t2&valsuf; set p2_data_imputed_t2; run;
*/

*** Incorporate imputed values into original data structure for pattern 2;
data p2_data_imputed_t3;
    merge p2_data4mi_est0(keep=_Imputation_ usubjid trt01pn region1n
          pattern2_Week_1  pattern2_Week_4  pattern2_Week_8  pattern2_Week_12
          aval_p2_Week_1 aval_p2_Week_4 aval_p2_Week_8 aval_p2_Week_12)
          p2_data_imputed_t2;
    by _Imputation_ usubjid;
run;

data p2_data_imputed(drop=aval_p2_Week_1 aval_p2_Week_4 aval_p2_Week_8 aval_p2_Week_12 i);
    set p2_data_imputed_t3;

    array pattern {4} pattern2_Week_1  pattern2_Week_4  pattern2_Week_8  pattern2_Week_12;
    array aval_p  {4} aval_p2_Week_1 aval_p2_Week_4 aval_p2_Week_8 aval_p2_Week_12;
    array aval_p_imp {4} aval_p2_Week_1_imp aval_p2_Week_4_imp aval_p2_Week_8_imp aval_p2_Week_12_imp;

    do i=1 to 4;
        if pattern[i] = "E" then aval_p_imp[i] = aval_p[i]; * put excluded values back into the records;
    END;
run;

* Save imputed dataset for pattern 2 imputation for validation;
/*
Data tlfmeta.p2_data_imputed&valsuf;
    Set p2_data_imputed;
Run;
*/

%end;

********************************************************************************************************************;
*** Impute pattern 3 ***;
********************************************************************************************************************;
*** Missing data in pattern 3 will be imputed using the same model as under treatment policy in the primary analysis;
*** All patients will be used to estimate the imputation model and ;
***   indicator variables will be used to flag records before and after permanent treatment discontinuation;
*** The only values that are excluded are those after the initiation of alternative treatments. ;

*** Values previously imputed in patterns 1 and 2 will be incorporated here.;
proc sort data=p1_data_imputed; by _Imputation_ usubjid; run;
proc sort data=p2_data_imputed; by _Imputation_ usubjid; run;
data p3_data4mi_t1;
    merge allvtm
          p1_data_imputed(keep=_Imputation_ usubjid aval_Baseline_imp aval_p1_Week_1_imp aval_p1_Week_4_imp aval_p1_Week_8_imp aval_p1_Week_12_imp)
          p2_data_imputed(keep=_Imputation_ usubjid aval_p2_Week_1_imp aval_p2_Week_4_imp aval_p2_Week_8_imp aval_p2_Week_12_imp)
          ;
    by _Imputation_ usubjid;
run;

data p3_data4mi_t2; set p3_data4mi_t1;

    array p0 {4} pattern0_Week_1  pattern0_Week_4  pattern0_Week_8  pattern0_Week_12;
    array p1 {4} pattern1_Week_1  pattern1_Week_4  pattern1_Week_8  pattern1_Week_12;
    array p2 {4} pattern2_Week_1  pattern2_Week_4  pattern2_Week_8  pattern2_Week_12;
    array p3 {4} pattern3_Week_1  pattern3_Week_4  pattern3_Week_8  pattern3_Week_12;
    array ANL01FL {4} ANL01FL_Week_1 ANL01FL_Week_4 ANL01FL_Week_8 ANL01FL_Week_12;

    array aval {4} aval_Week_1 aval_Week_4 aval_Week_8 aval_Week_12;

    array aval_p0_imp {4} aval_p0_Week_1_imp aval_p0_Week_4_imp aval_p0_Week_8_imp aval_p0_Week_12_imp;
    array aval_p1_imp {4} aval_p1_Week_1_imp aval_p1_Week_4_imp aval_p1_Week_8_imp aval_p1_Week_12_imp;
    array aval_p2_imp {4} aval_p2_Week_1_imp aval_p2_Week_4_imp aval_p2_Week_8_imp aval_p2_Week_12_imp;
    array aval_p3 {4} aval_p3_Week_1 aval_p3_Week_4 aval_p3_Week_8 aval_p3_Week_12;

    * Derive indicator variables will be used to flag records before and after permanent treatment discontinuation;
    array post_trt {4} post_trt_Week_1 post_trt_Week_4 post_trt_Week_8 post_trt_Week_12;

    aval_p3_Baseline = aval_Baseline;
    if aval_Baseline = . and aval_Baseline_imp ne . then do;
        if aval_Baseline_imp < 0 then aval_p3_Baseline=0; *** post-processing for values that got imputed with an unrealistic negative value;
        else aval_p3_Baseline = aval_Baseline_imp;
    end;


    * Utilize imputed values from patterns 1 and 2;
    do i=1 to 4;
        post_trt[i]=0;
        if ANL01FL[i] = "Y" then post_trt[i] = 1;

        if p0[i] = "M" then do;
            if aval_p3_Baseline ne . then do;
                if aval_p3_Baseline < 0 then aval_p3[i] = 0; *** post-processing for values that got imputed with an unrealistic negative value;
                else aval_p3[i] = aval_p3_Baseline;
            end;
        END;
        else if p1[i] = "M" then do;
            if aval_p1_imp[i] < 0 then aval_p3[i]=0; *** post-processing for values that got imputed with an unrealistic negative value;
            else aval_p3[i] = aval_p1_imp[i];
        end;
        else if p2[i] = "M" then do;
            if aval_p2_imp[i] < 0 then aval_p3[i]=0; *** post-processing for values that got imputed with an unrealistic negative value;
            else aval_p3[i] = aval_p2_imp[i];
        end;
        if p3[i] = "E" then aval_p3[i] = .;

    end;

run;

* Save dataset used as input for pattern 3 imputation for validation;
/*
Data tlfmeta.p3_data4mi_t2&valsuf;
    Set p3_data4mi_t2;
Run;
*/


proc sort data=p3_data4mi_t2; by _Imputation_ trt01pn_bin region1n_bin usubjid; run;
*** Impute intermittent missing values ***;
ods listing close;
PROC MI data=p3_data4mi_t2 nimpute=1 seed=&seed displaypattern=ALL out=p3_data_imputed_t1;
    *< Make sure to use binary 0/1 versions of treatment and region when MCMC is used;
    var trt01pn_bin region1n_bin aval_p3_Baseline aval_p3_Week_1 aval_p3_Week_4 aval_p3_Week_8 aval_p3_Week_12;
    mcmc chain=multiple impute=monotone;
    by _Imputation_;
RUN;
ods listing;

* Save dataset used as input for pattern 3 imputation for validation;
/*
Data tlfmeta.p3_data_imputed_t1&valsuf;
    Set p3_data_imputed_t1;
Run;
*/

* Calculate the number of observed post-treatment values at each visit;
PROC SQL NOPRINT;
    SELECT COUNT(*) into :post_trt_Week_1 FROM p3_data_imputed_t1
        WHERE _Imputation_=1 and post_trt_Week_1=1 and aval_p3_Week_1 ne .;
    SELECT COUNT(*) into :post_trt_Week_4 FROM p3_data_imputed_t1
        WHERE _Imputation_=1 and post_trt_Week_4=1 and aval_p3_Week_4 ne .;
    SELECT COUNT(*) into :post_trt_Week_8 FROM p3_data_imputed_t1
        WHERE _Imputation_=1 and post_trt_Week_8=1 and aval_p3_Week_8 ne .;
    SELECT COUNT(*) into :post_trt_Week_12 FROM p3_data_imputed_t1
        WHERE _Imputation_=1 and post_trt_Week_12=1 and aval_p3_Week_12 ne .;
QUIT;
%put post_trt_Week_1=&post_trt_Week_1;
%put post_trt_Week_4=&post_trt_Week_4;
%put post_trt_Week_8=&post_trt_Week_8;
%put post_trt_Week_11=&post_trt_Week_12;

*** Create macro variables for each visit so that the macro variable is;
***   equal to the name of the post-treatment indicator variable if there >= 10 post-treatment values at this visit;
***   or blank otherwise;
DATA _NULL_;
   LENGTH include_Week_1 include_Week_4 include_Week_8 include_Week_12 $200;
   IF &post_trt_Week_1>=10 THEN include_Week_1='post_trt_Week_1'; ELSE include_Week_1='';
   IF &post_trt_Week_4>=10 THEN include_Week_4='post_trt_Week_4'; ELSE include_Week_4='';
   IF &post_trt_Week_8>=10 THEN include_Week_8='post_trt_Week_8'; ELSE include_Week_8='';
   IF &post_trt_Week_12>=10 THEN include_Week_12='post_trt_Week_12'; ELSE include_Week_12='';
   CALL SYMPUT('include_Week_1',include_Week_1);
   CALL SYMPUT('include_Week_4',include_Week_4);
   CALL SYMPUT('include_Week_8',include_Week_8);
   CALL SYMPUT('include_Week_12',include_Week_12);
RUN;
%PUT include_Week_1=&include_Week_1;
%PUT include_Week_4=&include_Week_4;
%PUT include_Week_8=&include_Week_8;
%PUT include_Week_12=&include_Week_12;

*** Imputation model with post-treatment indicator variables ***;

proc sort data=p3_data_imputed_t1; by _Imputation_ trt01pn region1n &include_Week_1 &include_Week_4 &include_Week_8 &include_Week_12 usubjid ; run;
ods listing close;
PROC MI data=p3_data_imputed_t1 nimpute=1 seed=&seed displaypattern=ALL
     out=p3_data_imputed(rename=(
        aval_p3_Baseline = aval_p3_Baseline_imp
        aval_p3_Week_1=aval_p3_Week_1_imp
        aval_p3_Week_4=aval_p3_Week_4_imp
        aval_p3_Week_8=aval_p3_Week_8_imp
        aval_p3_Week_12=aval_p3_Week_12_imp));

    by _Imputation_;
    class  trt01pn region1n &include_Week_1 &include_Week_4 &include_Week_8 &include_Week_12 ;
    VAR    trt01pn region1n &include_Week_1 &include_Week_4 &include_Week_8 &include_Week_12
           aval_p3_Baseline aval_p3_Week_1 aval_p3_Week_4 aval_p3_Week_8 aval_p3_Week_12;
    MONOTONE reg (aval_p3_Week_1  = trt01pn region1n aval_p3_Baseline
                                    &include_Week_1);
    MONOTONE reg (aval_p3_Week_4  = trt01pn region1n aval_p3_Baseline
                                    &include_Week_1  &include_Week_4
                                    aval_p3_Week_1 );
    MONOTONE reg (aval_p3_Week_8  = trt01pn region1n aval_p3_Baseline
                                    &include_Week_1 &include_Week_4 &include_Week_8
                                    aval_p3_Week_1 aval_p3_Week_4);
    MONOTONE reg (aval_p3_Week_12 = trt01pn region1n aval_p3_Baseline
                                    &include_Week_1 &include_Week_4 &include_Week_8 &include_Week_12
                                    aval_p3_Week_1 aval_p3_Week_4 aval_p3_Week_8 );
RUN;
ods listing;

proc sort data=p3_data_imputed; by _Imputation_ usubjid; run;

*** Save imputed dataset for validation;
/*
data tlfmeta.p3_data_imputed&valsuf; set p3_data_imputed; run;
*/

********************************************************************************************************************;
*** Impute pattern 4 ***;
********************************************************************************************************************;
*** Values previously imputed in patterns 1, 2 and 3 will be incorporated here.;

data p4_data4mi_t1;
    merge allvtm
          p1_data_imputed(keep=_Imputation_ usubjid aval_Baseline_imp aval_p1_Week_1_imp aval_p1_Week_4_imp aval_p1_Week_8_imp aval_p1_Week_12_imp)
          p2_data_imputed(keep=_Imputation_ usubjid aval_p2_Week_1_imp aval_p2_Week_4_imp aval_p2_Week_8_imp aval_p2_Week_12_imp)
          p3_data_imputed(keep=_Imputation_ usubjid aval_p3_Baseline_imp aval_p3_Week_1_imp aval_p3_Week_4_imp aval_p3_Week_8_imp aval_p3_Week_12_imp)
          ;
    by _Imputation_ usubjid;
run;

data p4_data4mi_t2; set p4_data4mi_t1;
    array p0 {4} pattern0_Week_1  pattern0_Week_4  pattern0_Week_8  pattern0_Week_12;
    array p1 {4} pattern1_Week_1  pattern1_Week_4  pattern1_Week_8  pattern1_Week_12;
    array p2 {4} pattern2_Week_1  pattern2_Week_4  pattern2_Week_8  pattern2_Week_12;
    array p3 {4} pattern3_Week_1  pattern3_Week_4  pattern3_Week_8  pattern3_Week_12;
    array p4 {4} pattern4_Week_1  pattern4_Week_4  pattern4_Week_8  pattern4_Week_12;

    array aval {4} aval_Week_1 aval_Week_4 aval_Week_8 aval_Week_12;

    array aval_p1_imp {4} aval_p1_Week_1_imp aval_p1_Week_4_imp aval_p1_Week_8_imp aval_p1_Week_12_imp;
    array aval_p2_imp {4} aval_p2_Week_1_imp aval_p2_Week_4_imp aval_p2_Week_8_imp aval_p2_Week_12_imp;
    array aval_p3_imp {4} aval_p3_Week_1_imp aval_p3_Week_4_imp aval_p3_Week_8_imp aval_p3_Week_12_imp;
    array aval_p4 {4} aval_p4_Week_1 aval_p4_Week_4 aval_p4_Week_8 aval_p4_Week_12;

    aval_p4_Baseline = aval_Baseline;
    if aval_Baseline = . and aval_Baseline_imp ne . then do;
        if aval_Baseline_imp < 0 then aval_p4_Baseline = 0; *** post-processing for values that got imputed with an unrealistic negative value;
        else aval_p4_Baseline = aval_Baseline_imp;
    end;
    else if aval_Baseline = . and aval_p3_Baseline_imp ne . then do;
        if aval_p3_Baseline_imp < 0 then aval_p4_Baseline = 0;  *** post-processing for values that got imputed with an unrealistic negative value;
        else aval_p4_Baseline = aval_p3_Baseline_imp;
    end;
    do i=1 to 4;
        if p0[i] = "M" then do;
            if aval_p4_Baseline ne . then do;
                if aval_p4_Baseline < 0 then aval_p4[i] = 0; *** post-processing for values that got imputed with an unrealistic negative value;
                else aval_p4[i] = aval_p4_Baseline;
            end;
        END;
        else if p1[i] = "M" then do;
            if aval_p1_imp[i] < 0 then aval_p4[i] = 0; *** post-processing for values that got imputed with an unrealistic negative value;
            else aval_p4[i] = aval_p1_imp[i];
        end;
        else if p2[i] = "M" then do;
            if aval_p2_imp[i] < 0 then aval_p4[i] = 0; *** post-processing for values that got imputed with an unrealistic negative value;
            else aval_p4[i] = aval_p2_imp[i];
        end;
        else if p3[i] = "M" then do;
            if aval_p3_imp[i] < 0 then aval_p4[i] = 0; *** post-processing for values that got imputed with an unrealistic negative value;
            else aval_p4[i] = aval_p3_imp[i];
        end;
    END;

    drop i;
run;

* Save dataset used as input for pattern 4 imputation for validation;
/*
Data tlfmeta.p4_data4mi_t2&valsuf;
    Set p4_data4mi_t2;
Run;
*/

proc sort data=p4_data4mi_t2; by _Imputation_ trt01pn region1n usubjid; run;
ods listing close;
proc mi data=p4_data4mi_t2 nimpute=1 seed=&seed displaypattern=ALL
     out=p4_data_imputed(rename=(
        aval_p4_Baseline = aval_p4_Baseline_imp
        aval_p4_Week_1=aval_p4_Week_1_imp
        aval_p4_Week_4=aval_p4_Week_4_imp
        aval_p4_Week_8=aval_p4_Week_8_imp
        aval_p4_Week_12=aval_p4_Week_12_imp));
    by _Imputation_;
    class trt01pn region1n;
    var trt01pn region1n aval_p4_Baseline aval_p4_Week_1 aval_p4_Week_4 aval_p4_Week_8 aval_p4_Week_12;
    monotone reg;
RUN;
ods listing;
proc sort data=p4_data_imputed; by _Imputation_ usubjid; run;

* Save dataset used as input for pattern 4 imputation for validation;
/*
Data tlfmeta.p4_data_imputed&valsuf;
    Set p4_data_imputed;
Run;
*/

***************************************************************************************************************;
***************************************************************************************************************;
*** Consolidate all imputed data ;

data all_imputed_t1;
    merge allvtm
          p1_data_imputed(keep=_Imputation_ usubjid aval_p1_Week_1_imp aval_p1_Week_4_imp aval_p1_Week_8_imp aval_p1_Week_12_imp)
          p2_data_imputed(keep=_Imputation_ usubjid aval_p2_Week_1_imp aval_p2_Week_4_imp aval_p2_Week_8_imp aval_p2_Week_12_imp)
          p3_data_imputed(keep=_Imputation_ usubjid aval_p3_Week_1_imp aval_p3_Week_4_imp aval_p3_Week_8_imp aval_p3_Week_12_imp)
          p4_data_imputed(keep=_Imputation_ usubjid aval_p4_Baseline_imp aval_p4_Week_1_imp aval_p4_Week_4_imp aval_p4_Week_8_imp aval_p4_Week_12_imp)
          ;
    by _Imputation_ usubjid;
run;

data all_imputed_t2; set all_imputed_t1;
    array p0 {4} pattern0_Week_1  pattern0_Week_4  pattern0_Week_8  pattern0_Week_12;
    array p1 {4} pattern1_Week_1  pattern1_Week_4  pattern1_Week_8  pattern1_Week_12;
    array p2 {4} pattern2_Week_1  pattern2_Week_4  pattern2_Week_8  pattern2_Week_12;
    array p3 {4} pattern3_Week_1  pattern3_Week_4  pattern3_Week_8  pattern3_Week_12;
    array p4 {4} pattern4_Week_1  pattern4_Week_4  pattern4_Week_8  pattern4_Week_12;

    array p_imp {4} p_imp_Week_1  p_imp_Week_4  p_imp_Week_8  p_imp_Week_12; * for data review later;

    array aval {4} aval_p0_Week_1 aval_p0_Week_4 aval_p0_Week_8 aval_p0_Week_12;

    array aval_p1_imp {4} aval_p1_Week_1_imp aval_p1_Week_4_imp aval_p1_Week_8_imp aval_p1_Week_12_imp;
    array aval_p2_imp {4} aval_p2_Week_1_imp aval_p2_Week_4_imp aval_p2_Week_8_imp aval_p2_Week_12_imp;
    array aval_p3_imp {4} aval_p3_Week_1_imp aval_p3_Week_4_imp aval_p3_Week_8_imp aval_p3_Week_12_imp;
    array aval_p4_imp {4} aval_p4_Week_1_imp aval_p4_Week_4_imp aval_p4_Week_8_imp aval_p4_Week_12_imp;

    * final consolidated observed and imputed values ;
    array aval_f_imp {4} aval_f_Week_1_imp aval_f_Week_4_imp aval_f_Week_8_imp aval_f_Week_12_imp;

    aval_f_Baseline = aval_Baseline;
    if aval_Baseline = . and aval_p4_Baseline_imp ne . then do;
        if aval_p4_Baseline_imp < 0 then aval_f_Baseline = 0;*** post-processing for values that got imputed with an unrealistic negative value;
        else aval_f_Baseline = aval_p4_Baseline_imp;
    end;

    do i=1 to 4;
        aval_f_imp[i] = aval[i];
        p_imp[i]=-1;
        if p0[i] = "C" then do;
            p_imp[i] = 0;
        end;
        if p0[i] = "M" then do;
            p_imp[i] = 0;
            if aval_f_Baseline ne . then aval_f_imp[i] =  aval_f_Baseline;
        END;
        else if p1[i] = "M" then do;
            if aval_p1_imp[i] < 0 then aval_f_imp[i] = 0; else aval_f_imp[i] = aval_p1_imp[i];
            p_imp[i] = 1; * indicates value imputed under pattern 1;
        end;
        else if p2[i] = "M" then do;
            if aval_p2_imp[i] < 0 then aval_f_imp[i] = 0; else aval_f_imp[i] = aval_p2_imp[i];
                p_imp[i] = 2; * indicates value imputed under pattern 2;
            end;
        else if p3[i] = "M" then do;
            if aval_p3_imp[i] < 0 then aval_f_imp[i] = 0; else aval_f_imp[i] = aval_p3_imp[i];
                p_imp[i] = 3; * indicates value imputed under pattern 3;
            end;
        else if p4[i] = "M" then do;
            if aval_p4_imp[i] < 0 then aval_f_imp[i] = 0; else aval_f_imp[i] = aval_p4_imp[i];
                p_imp[i] = 4; * indicates value imputed under pattern 4;
            end;
    END;

    drop i;
run;


*** Transpose final imputed data into vertical structure with one patient/visit per record ;
data final0(keep=_Imputation_ usubjid region1n trt01pn baseline_visit avisitn aval chg aval_orig p_imp);

    set all_imputed_t2;
    baseline_visit = aval_f_Baseline;

    avisitn=10;
    aval_orig = aval_Week_1;
    aval = aval_f_Week_1_imp;
    chg = aval_f_Week_1_imp - baseline_visit;
    p_imp = p_imp_Week_1;
    output;

    avisitn=40;
    aval_orig = aval_Week_4;
    aval = aval_f_Week_4_imp;
    chg = aval_f_Week_4_imp - baseline_visit;
    p_imp = p_imp_Week_4;
    output;

    avisitn=80;
    aval_orig = aval_Week_8;
    aval = aval_f_Week_8_imp;
    chg = aval_f_Week_8_imp - baseline_visit;
    p_imp = p_imp_Week_8;
    output;

    avisitn=120;
    aval_orig = aval_Week_12;
    aval = aval_f_Week_12_imp;
    chg = aval_f_Week_12_imp - baseline_visit;
    p_imp = p_imp_Week_12;
    output;
run;

proc sort data=final0; by usubjid avisitn _Imputation_; run;
proc sort data=anal; by usubjid avisitn ; run;
data final;
    merge final0(in=f) anal(keep=usubjid avisitn ANL01FL ICEDSRS ANL05FL ANL02FL ICEINTRS ANL03FL);
    by usubjid avisitn;
    if f; *** Patients with missing baseline and not enough post-baseline data will be excluded;
RUN;


data review; set final;
    where aval ne aval_orig;
run;

proc sort data=final; by _Imputation_ trt01pn region1n avisitn usubjid; run;


* Save final imputed dataset for validation;
Data tlfmeta.final&valsuf;
    Set final;
Run;

**************************************************************************************************;

/*******************************************************************************************************/
*** Analyze imputed datasets ***;
/*******************************************************************************************************/
* Remove format from avisitn so that weeks are sorted in the same order as numerical levels ***;
data final; set final;
    format avisitn;
run;
proc sort data=final; by _Imputation_ trt01pn region1n avisitn usubjid; run;
/** main model **/
ods listing close;
PROC MIXED data=final;
    by _Imputation_;
    CLASS trt01pn region1n avisitn usubjid ;
    MODEL chg = baseline_visit trt01pn region1n avisitn trt01pn*avisitn baseline_visit*avisitn /ddfm=KR outp=resid s;
    REPEATED avisitn / subject=usubjid type=un;
    *RANDOM usubjid; /* only if AR(1) covariance structure is used */
    LSMEANS trt01pn*avisitn /cl pdiff=all;
    ESTIMATE 'Elinzanetant - Placebo at Week 1' trt01pn 1 -1 trt01pn*avisitn 1 0 0 0 -1 0 0 0 /cl;
    ESTIMATE 'Elinzanetant - Placebo at Week 4' trt01pn 1 -1 trt01pn*avisitn 0 1 0 0 0 -1 0 0 /cl;
    ESTIMATE 'Elinzanetant - Placebo at Week 12' trt01pn 1 -1 trt01pn*avisitn 0 0 0 1 0 0 0 -1 /cl;
    ODS OUTPUT TESTS3=TYPE3_eff Diffs=diffs LSMeans=LSMEAN ESTIMATES=ESTIM;
RUN;
ods listing;
proc sort data=estim out=estim_s; by label; run;


%LET timep = 10 40 80 120 ;
%m_anal_datastep(adqshfss, "HFDB998",&timep,anal);


%m_mmrm_rubin  (estim  , LSMEAN , hffreq_sup2 );

proc sort data = adqshfss
     out = tby (keep = paramcd) nodupkey ;
    by paramcd ;
    where not missing(paramcd);
RUN;

proc sort data = hfdd
     out = tby (keep = paramcd) nodupkey ;
    by paramcd ;
    where not missing(paramcd);
RUN;

Proc Sql noprint ;
    select count(usubjid) into : trtarm1 SEPARATED by "  "
           from adsl
           where trt01pn = 100
           group by trt01pn ;

    select count(usubjid) into : trtarm2 SEPARATED by "  "
           from adsl
           where trt01pn = 101
           group by trt01pn ;
    %put &trtarm1 &trtarm2 ;

  select paramcd into : paramcd SEPARATED by ""
           from tby
           where not missing(paramcd)
         ;
QUIT;

data final ;
    set t_0 t_l0 t_l2 ;
RUN;
proc sort data  = final ;
    by row row1 ;
RUN;

data final ;
    set final ;
    by row row1 ;
    if row1  = 0 then Col01  = Col0 ;
    if avisitn ^= 5 ;
    Label col_100 = "Elinzanetant 120mg (N= &trtarm1.)"
    col_101 = "Placebo - Elinzanetant 120mg (N= &trtarm2.)"
    Col01  = "Time"
    comment = "Statistics" ;
RUN;

/*************************************************************/
/********************* Output   ******************************/
/*************************************************************/


 %set_titles_footnotes(
      tit1 = &tti1.
  ,   tit2 = &tti2.
  ,   ftn1 = &tft1
  ,   ftn2 = &tft2
  ,   ftn3 = &tft3
  ,   ftn4 = &tft4
  ,   ftn5 = &tft5

 );



%datalist(
    data     = final
  , by       = row row1
  , var      = Col01  comment col_100 col_101 col1
  , order    = row row1
  , freeline = row
  , together = row
  , split =  *
)


%set_titles_footnotes(
     tit1 = &fti1
 ,   tit2 = &fti2
 ,   ftn1 = &fft1
 ,   ftn2 = &fft2
 ,   ftn3 = &fft3
);


%MeanDeviationPlot(
    data     = lsmean_tot
  , xvar     = avisitn
  , yvar     = estimate
  , class    = trt01pn
  , xtype    = data
  , lower_error = se_low
  , upper_error = se_upp
  , xstart   = min
  , xend     = max
  , xlabel   = &xlabel.
  , ylabel   = &ylabel.
  , XOFFSET  = 0.1
  , title_ny = No
  , yend     = 0
  ,LEGENDTITLE = "Treatment group"
);

%endprog();


