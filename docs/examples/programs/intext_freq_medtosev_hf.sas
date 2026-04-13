/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = intext_freq_medtosev_hf);
/*
 * Purpose          : Generate intext table for mean change in frequency of mod to sev HF from
 *                    Baseline to week 12 (FAS)
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : ggqct (Jose Diaz) / date: 11DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/intext_freq_medtosev_hf.sas (ggqct (Jose Diaz) / date: 23OCT2023)
 ******************************************************************************/


data elmean;
    set tlfmeta.t_8_2_1_1_1_hfss_mhf_s_1;
    where avisitn in (5,10,40,120) and _nwtrt = 1;
    _difind = 0;
    format _difind;
    keep _difind _trt_txt  avisitn _v_1_1 _v_1_2 _v_1_3 _v_1_4;
run;

data _null_;
    set elmean;
    if _n_ = 1 then call symput ('lab1' , cat(substr(_trt_txt,1,18),"@",substr(_trt_txt,19,30) ) );
run;

data plamean;
    set tlfmeta.t_8_2_1_1_1_hfss_mhf_s_1;
    where avisitn in (5,10,40,120)  and _nwtrt = 2;
    _difind = 0;
    format _difind;
    keep avisitn _difind _trt_txt  _v_1_1 _v_1_2 _v_1_3 _v_1_4;
    rename _v_1_1 = _v_2_1 _v_1_2 = _v_2_2 _v_1_3 = _v_2_3 _v_1_4 = _v_2_4 ;
run;

data _null_;
    set plamean;
    if _n_ = 1 then call symput ('lab2' , cat(substr(_trt_txt,1,28),"@",substr(_trt_txt,29,40) ) );
run;

/* change from baseline */

data eldiff ;
    set tlfmeta.t_8_2_1_1_1_hfss_mhf_s_1;
    where avisitn in (10,40,120)  and  _nwtrt = 1;
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
    set tlfmeta.t_8_2_1_1_1_hfss_mhf_s_1;
    where avisitn in (10,40,120)  and  _nwtrt = 2;
    _difind = 1;
    format _difind;
    keep avisitn _difind _trt_txt  _v_2_1 _v_2_2 _v_2_3 _v_2_4;
run;

data _null_;
    set pladiff;
    if _n_ = 1 then call symput ('lab2' , cat(substr(_trt_txt,1,28),"@",substr(_trt_txt,29,40) ) );
run;

/* percent change from baseline */

data elpdiff ;
    set tlfmeta.t_8_2_1_1_1_hfss_mhf_p_1;
    where avisitn in (10,40,120)  and  _nwtrt = 1;
    _difind = 2;
    format _difind;
    keep avisitn _difind _trt_txt _v_2_1 _v_2_2 _v_2_3 _v_2_4;
    rename _v_2_1 = _v_1_1 _v_2_2 = _v_1_2 _v_2_3 = _v_1_3 _v_2_4 = _v_1_4 ;
run;

data plapdiff ;
    set tlfmeta.t_8_2_1_1_1_hfss_mhf_p_1;
    where avisitn in (10,40,120)  and  _nwtrt = 2;
    _difind = 2;
    format _difind;
    keep avisitn _difind _trt_txt  _v_2_1 _v_2_2 _v_2_3 _v_2_4;
run;



data means;
    merge elmean plamean ;
    by avisitn;
RUN;

data diff;
    merge eldiff pladiff;
    by avisitn;
RUN;

data pdiff;
    merge elpdiff plapdiff;
    by avisitn;
RUN;



data data3;
    set tlfmeta.if_8_2_1_1_1_hfss_1;
    where ~missing(COL1) ;
    if _orderN = 4 then avisitn = 10;
    else if _orderN = 10 then avisitn = 40;
    else if _orderN = 16 then avisitn = 120;
    _orderN + 50;
    _difind = 2;
    format _difind;
    keep comment _difind avisitn col1 _orderN;
run;

proc datasets lib = work;
    modify data3;
        attrib _all_ label = ' ';
QUIT;
RUN;

    data datfin0;
        length vis $50;
        set means diff pdiff data3 ;
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
        _difind=2;_nwtrt=0; vis = "Percent change from baseline"; output;
    RUN;

    data datfin;
        merge dum datfin0 ;
        by _difind _nwtrt;
    RUN;


%let enum_src1 = %intext_get_enumeration(meta_file = tlfmeta.t_8_2_1_1_1_hfss_mhf_s_1);
%let enum_src2 = %intext_get_enumeration(meta_file = tlfmeta.t_8_2_1_1_1_hfss_mhf_p_1);


title1 "Table: Mean change in frequency of moderate to severe HF from baseline to Week 12 &fas_label";

footnote1 "Source: &enum_src1., &enum_src2., Table 8.2.1.2 / 3 ";

%datalist(
    data   = datfin
  , var    =   vis comment col1   ("&lab1" _v_1_1 _v_1_2 _v_1_3  _v_1_4 ) ("&lab2" _v_2_1  _v_2_2 _v_2_3  _v_2_4 )
  , maxlen = 20
  , hsplit = '|@'
  , split = '|@'
  , label  = no
  , optimal = YES
);



%endprog;