/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = f_8_2_1_3_1_adqs_rbar   );
/*
 * Purpose          : Bar chart illustrating PROMIS SD SF 8b raw score <<item>> by treatment group (FAS)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 28NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/f_8_2_1_3_1_adqs_rbar.sas (emvsx (Phani Tata) / date: 03OCT2023)
 ******************************************************************************/


*PSDSB998 - Total Score raw of PROMIS sleep disturbance short form 8B V1.0*;
%macro paramcd (par= ,  formtn   =   );
%load_ads_dat(
    adqs_view
  , adsDomain = adqs
  , adslWhere = &fas_cond. and n( &treat_arm_p.)
  , adslVars  = SAFFL FASFL &treat_arm_a.  &treat_arm_p.
  , where =       paramcd = "&par."
                  and not missing(aval)
                  and 5 <= avisitn < 900000
                  and anl04fl = "Y"
                  and not missing(avisitn)

 , labelVars         = lbl_ana1

)

%load_ads_dat(
    adsl_view
  , adsDomain = adsl
  , Where = &fas_cond. and n( &treat_arm_p.)
)

%extend_data(indat = adqs_view , outdat = adqs );
%extend_data(indat = adsl_view  , outdat = adsl) ;
 options Notes source ;
data adqs_vis;
    set adqs_view    ;

aval_n   = input( strip(put( avalc ,  $&formtn.  )) ,  3. ) ;
format aval_n  &formtn. &treat_arm_p. ;

RUN;


proc sort data=adqs_vis out=adqs_vis2;
    by paramcd trt01pn aval_n;
run;

ods exclude CrossTabfreqs;
ods output CrossTabfreqs=freq (drop=table _table_ percent colpercent missing);
proc freq data=adqs_vis2;
    tables avisitn * aval_n;
    by paramcd trt01pn;
run;
ods output close;


proc sql;
    create table freq2 as
    select a.paramcd, a.trt01pn,
    a.avisitn, a.aval_n,
    a.frequency, a.rowpercent,
    b.frequency as freqtot
    from freq (where=(_type_ = '11')) a
    left join freq (where=(_type_ = '10')) b
    on a.trt01pn = b.trt01pn and
    a.avisitn = b.avisitn
    ;
    create table stat4anno as
    select distinct trt01pn,    avisitn, aval_n, freqtot
    from freq2
    ;
quit;

data freq2 ;
    set freq2 ;
    trt =  ifn(trt01pn = 100, 0, 1) ;
   format trt _trt. ;

RUN;

data stat4anno ;
    set stat4anno ;
     trt =  ifn(trt01pn = 100, 0,1 ) ;
     format trt _trt. ;

RUN;

%sganno
data anno;
    set stat4anno;
    if _n_ = 1 then do;
        %sgtext(drawspace='wallpercent', x1=-1.55, y1=97.4, textsize=7, label='n', textweight='bold')
    end;
    %sgtext(x1space='datavalue', y1space='wallpercent',
            x1=avisitn, y1=2,     textsize=7,
            discreteoffset=ifn(trt01pn=100, -0.2, 0.2),
            label=vvalue(trt))


    %sgtext(x1space='datavalue', y1space='wallpercent',
            x1=avisitn, y1=98.75,
            textsize=7,
            discreteoffset=ifn(trt01pn=100, -0.2, 0.2),
            label=freqtot)
run;


%MTITLE;

%gral_style(colorscale=n=5 grey level=0, graphreference=contrastcolor=black)


%BarChart(
    data          = freq2
  , xvar          = avisitn
  , yvar          = rowpercent
  , class         = aval_n
  , inclass       = trt
  , annodata      = anno
  , title_ny      = NO
  , legendtitle   = Response:
  , style         = report2
  , outdat        = tmp
/*  , gridlines     = yes*/
  , xoffset       = 0.05
  , yrefline      = 100
  , ylabel        = Frequency (in percent)
  , yoffset       = 0.04
  , filename      = f_8_2_1_3_1_rbar_&par.
);

data tmpinp;
    set tmpinp;
    if type = 'referenceline' and attribute = 'datatransparency' then delete;
    if attribute = 'yoffsetmax' then value = '0.05';
run;

%gral_from_dat(data=tmp)

%mend ;


%paramcd (par = %str(PSDSB101) ,  formtn   = _prawsf. );
%paramcd (par = %str(PSDSB102) ,  formtn   = _prawsfs. );
%paramcd (par = %str(PSDSB103) ,  formtn   = _prawsfs. );
%paramcd (par = %str(PSDSB104) ,  formtn   = _prawsf. );
%paramcd (par = %str(PSDSB105) ,  formtn   = _prawss. );
%paramcd (par = %str(PSDSB106) ,  formtn   = _prawss.  );
%paramcd (par = %str(PSDSB107) ,  formtn   = _prawsse. );
%paramcd (par = %str(PSDSB108) ,  formtn   = _prawse. );

%endprog;

