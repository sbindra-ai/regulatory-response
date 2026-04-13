/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = intext_promis);
/*
 * Purpose          : Generate intext table for mean change in PROMIS SD SF 8b total score from to Week 12 (FAS)
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : ggqct (Jose Diaz) / date: 11DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/intext_promis.sas (ggqct (Jose Diaz) / date: 08NOV2023)
 ******************************************************************************/

data elmean;
    set tlfmeta.t_8_2_1_3_1_adqs_ts_s_1;
    where avisitn in (5,120) and _nwtrt = 1;
    _difind = 0;
    format _difind;
    keep _difind _trt_txt  avisitn _v_1_1 _v_1_2 _v_1_3 _v_1_4;
run;

data _null_;
    set elmean;
    if _n_ = 1 then call symput ('lab1' , cat(substr(_trt_txt,1,18),"@",substr(_trt_txt,19,30) ) );
run;


data plamean;
    set tlfmeta.t_8_2_1_3_1_adqs_ts_s_1;
    where avisitn in (5,120)  and _nwtrt = 2;
    _difind = 0;
    format _difind;
    keep avisitn _difind _trt_txt  _v_1_1 _v_1_2 _v_1_3 _v_1_4;
    rename _v_1_1 = _v_2_1 _v_1_2 = _v_2_2 _v_1_3 = _v_2_3 _v_1_4 = _v_2_4 ;

run;


data eldiff ;
    set tlfmeta.t_8_2_1_3_1_adqs_ts_s_1;
    where avisitn in (120)  and  _nwtrt = 1;
    _difind = 1;
    format _difind;
    keep avisitn _difind _trt_txt _v_2_1 _v_2_2 _v_2_3 _v_2_4;
    rename _v_2_1 = _v_1_1 _v_2_2 = _v_1_2 _v_2_3 = _v_1_3 _v_2_4 = _v_1_4 ;
run;

data _null_;
    set eldiff;
    if _n_ = 1 then call symput ('lab2' , cat(substr(_trt_txt,1,28),"@",substr(_trt_txt,29,40) ) );
run;

data pladiff ;
    set tlfmeta.t_8_2_1_3_1_adqs_ts_s_1;
    where avisitn in (120)  and  _nwtrt = 2;
    _difind = 1;
    format _difind;
    keep avisitn _difind _trt_txt  _v_2_1 _v_2_2 _v_2_3 _v_2_4;
run;

data _null_;
    set pladiff;
    if _n_ = 1 then call symput ('lab2' , cat(substr(_trt_txt,1,28),"@",substr(_trt_txt,29,40) ) );
run;


data means;
    merge elmean plamean ;
    by avisitn;
RUN;

data diff;
    merge eldiff pladiff;
    by avisitn;
RUN;


data data3;
    set tlfmeta.i_8_2_1_3_1_PR_1;
    where ~missing(COL1) ;
    _orderN + 50;
    _difind = 2;
    format _difind;
    keep comment _difind col1 _orderN;
run;

proc datasets lib = work;
    modify data3;
        attrib _all_ label = ' ';
QUIT;
RUN;

    data datfin0;
        length vis $50;
        set means diff data3 ;
        if avisitn ne . then vis = put(avisitn,z_avisit.);
        _nwtrt = 1;
    RUN;

    proc sort data=datfin0 ;
        by _difind _nwtrt;
    RUN;

    data dum;
        length vis $50.;
        _difind=0;_nwtrt=0; vis = "Value at visit"; output;
        _difind=1;_nwtrt=0; vis = "Change from baseline"; output;
    RUN;

    data datfin;
        merge dum datfin0 ;
        by _difind _nwtrt;
    RUN;

%let enum_src = %intext_get_enumeration(meta_file = tlfmeta.t_8_2_1_3_1_adqs_ts_s_1);

title1 "Table: Mean change in PROMIS SD SF 8b total score from baseline to Week 12 &fas_label";

footnote1 "Source: &enum_src., Table 8.2.1.8 / 2";

%datalist(
    data   = datfin
  , var    =   vis comment col1   ("&lab1" _v_1_1 _v_1_2 _v_1_3  _v_1_4 ) ("&lab2" _v_2_1  _v_2_2 _v_2_3 _v_2_4 )
  , maxlen = 20
  , hsplit = '|@'
  , split = '|@'
  , label  = no
  , optimal = YES
);

%endprog;