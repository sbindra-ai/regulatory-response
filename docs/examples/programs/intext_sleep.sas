/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = intext_sleep);
/*
 * Purpose          : 
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : enpjp (Prashant Patel) / date: 17JAN2024
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/intext_sleep.sas (enpjp (Prashant Patel) / date: 06NOV2023)
 ******************************************************************************/


%let sleeptable = %intext_find_metadata(title1 = Table: Sleepiness scale: summary statistics and change from baseline by treatment group - Mean daily sleepiness total score);

data sleep;
    set &sleeptable.;/*tlfmeta.t_8_3_10_hfss_sleep_4*/
RUN;

data trt1;
    set sleep;
    where trt01an=100;
    keep _difind  _nwtrt _trt_txt _v_1_1 _v_1_2 _v_1_3 _v_1_4 ;
    _difind=0;
RUN;

proc sort;
    by _difind _nwtrt _trt_txt;
RUN;

data trt2;
    set sleep;
    where trt01an=100;
    keep _difind  _nwtrt _trt_txt _v_2_1 _v_2_2 _v_2_3 _v_2_4;
    rename _v_2_1=_v_1_1 _v_2_2=_v_1_2 _v_2_3=_v_1_3 _v_2_4=_v_1_4;
    _difind=1;
    if _nwtrt>1;
RUN;

proc sort;
    by _difind _nwtrt _trt_txt;
RUN;

data pla1;
    set sleep;
    where trt01an=101;
    keep _difind  _nwtrt _trt_txt _v_1_1 _v_1_2 _v_1_3 _v_1_4;
    rename _v_1_1=_v_2_1 _v_1_2=_v_2_2 _v_1_3=_v_2_3 _v_1_4=_v_2_4;
    _difind=0;
RUN;

proc sort;
    by _difind _nwtrt _trt_txt;
RUN;

data pla2;
    set sleep;
    where trt01an=101;
    keep _difind  _nwtrt _trt_txt _v_2_1 _v_2_2 _v_2_3 _v_2_4;
    _difind=1;
    if _nwtrt>1;
RUN;

proc sort;
    by _difind _nwtrt _trt_txt;
RUN;

data dum;
    length _trt_txt $200.;
    _difind=0;_nwtrt=0; _trt_txt = "Value at visit"; output;
    _difind=1;_nwtrt=0; _trt_txt = "Change from baseline"; output;
RUN;

%let enum_src = %intext_get_enumeration(meta_file = &sleeptable.);

title1 "Table: Mean daily sleepiness in total score change from baseline &saf_label";
footnote1 "Source: &enum_src.";

data final;
    merge dum trt1 trt2 pla1 pla2;
    by _difind _nwtrt _trt_txt;
RUN;

%datalist(
    data = final
  , by   = _difind _nwtrt
  , order   = _difind _nwtrt
  , var  = _trt_txt ('Elinzanetant 120mg' _v_1_1 _v_1_2 _v_1_3 _v_1_4)  ('Placebo - Elinzanetant 120mg' _v_2_1 _v_2_2 _v_2_3 _v_2_4)
)

%endprog;
