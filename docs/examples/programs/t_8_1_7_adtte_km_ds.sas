/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_1_7_adtte_km_ds);
/*
 * Purpose          : Time from randomization to permament discontinuation of randomized treatment: Descriptive statistics (FAS)
 * Programming Spec : 
 * Validation Level : 2 - Independent Programming
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gnrty (Ashu Pandey) / date: 29NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_1_7_adtte_km_ds.sas (egavb (Reema S Pawar) / date: 06JUN2023)
 ******************************************************************************/

 *T2DIS - Time from randomization to permament discontinuation of randomized treatment
 *T2FPC - Time from randomization to first intake of prohibited concomitant medication having impact on efficacy>>: Descriptive statistics (FAS)
 *T50RM - Time to treatment response reduction of 50% in mean daily frequency of moderate to severe hot flashes by treatment group: Descriptive statistics ;

%load_ads_dat(
    adtte_view
  , adsDomain = adtte
  , where     = PARAMCD = 'T2DISC'
  , adslWhere = &fas_cond
)

%load_ads_dat(adsl_view, adsDomain = adsl, where = &fas_cond)


********************** column header, with N ******************;

data adsl;
     attrib trtpn format = z_trt.;
     set adsl_view (rename=(trt01pn=trtpn));
     output;
     trtpn=9999;
     output;
RUN;

proc sql noprint;
    create table trtlabel as
    select distinct trtpn format = z_trt., trtpn as _trtno format=best., '_n_'||strip(put(_trtno, best.)) as _trtvar length=10,
    count(distinct usubjid) as _bign
    from adsl
    group by trtpn
    order by trtpn;
QUIT;RUN;

data trtlabel;
    set trtlabel end=lastrec;
    length _trtord $10      __flab $200;
    _trtord='__t'||strip(put(_n_, best.));
    if _trtno eq 9999 then __flab='Total';
    else __flab=strip(put(trtpn, z_trt.));
    call symput(_trtord, strip(put(_trtno, best.)));
    call symput(_trtvar, strip(__flab)||'#(N='||strip(put(_bign, best.))||')');
RUN;

**************** total column ************************;
data adtte;
    attrib trtpn format = z_trt.;
    set adtte_view(rename=(trt01pn=trtpn));
    output;
    trtpn=9999;
    output;
    keep usubjid param: cnsr aval: trtpn;
RUN;

******************* KM ********************************;

ods listing close;
ods output quartiles=sum2 censoredsummary=sum3 ;
proc lifetest data=adtte
              method=KM
              alpha=0.05
              outsurv=sum1 stderr
              conftype=loglog;
    time aval*cnsr(1);
    strata trtpn/notest;
    by param:;
RUN;
ods listing;

************ n, % for event, % for censored ********************;

data km_c;
    set sum3;
    where Stratum in(1 2 3 );
    length _: $200;
        _1=put(total, 5.0)||' (100.0%)';
        _2=put(failed, 5.0)||' ('||put(100-pctcens, 5.1)||'%)';
        _3=put(censored, 5.0)||' ('||put(pctcens, 5.1)||'%)';
    keep param: trtpn stratum _:;
    label _1='N (%) '
          _2='Number (%) of subjects with event'
          _3='Number (%) of subjects censored';
RUN;

proc transpose data=km_c out=km_c prefix=ttt;
     by param:;
     id trtpn;
     var _:;
    format trtpn;
RUN;

************************  range ****************************;
ods escapechar="^";

data sum1;
    set sum1;
    length  cen $200;
    if _censor_ eq 1 then cen="^&super_a.";
RUN;

*********************create aaa ********************************;

proc sql noprint;
    create table aaa as
    select distinct paramcd, trtpn, stratum, strip(put(aval, best.))||strip(cen) as avalc length=100
    from sum1
    /**** range including censored values ****/
    where not missing(_censor_)
    group by trtpn
    having aval eq min(aval) or aval eq max(aval)    ;
QUIT;

***********************************************;
proc sql noprint;
        create table km_r as
        select distinct aaa.paramcd, aaa.trtpn, aaa.stratum,
               /**** need to compare character values for min and max to avoid case like (1081** - 14) ****/
               case
                    when input(compress(min(avalc), "^&super_a."), best.) le input(compress(max(avalc), "^&super_a."), best.) then '    ('||strip(min(avalc))||' - '||strip(max(avalc))||')'
                    when input(compress(min(avalc), "^&super_a."), best.) gt input(compress(max(avalc), "^&super_a."), best.) gt .Z then '    ('||strip(max(avalc))||' - '||strip(min(avalc))||')'
                    else ' '
               end as _1 length=200 label='Range (including censored values)',
               _2 length=200 label='Range (without censored values)'

        from (select distinct paramcd, trtpn, stratum, strip(put(aval, best.))||strip(cen) as avalc length=100
                        from sum1
                        /**** range including censored values ****/
                        where not missing(_censor_)
                        group by trtpn
                        having aval eq min(aval) or aval eq max(aval)) as aaa
             left join (select distinct trtpn,
                            '    ('||strip(put(min(aval), best.)||strip(cen))||' - '||strip(put(max(aval), best.)||strip(cen))||')' as _2
                        from sum1
                        /**** range without censored values ****/
                        where _censor_ eq 0
                        group by trtpn) as bbb on aaa.trtpn=bbb.trtpn
        group by paramcd, aaa.trtpn
        order by paramcd, trtpn        ;
QUIT;

proc transpose data=km_r out=km_r prefix=ttt;
        by paramcd;
        id trtpn;
        var _1 _2;
        format trtpn ;
RUN;

proc delete data=sum1;RUN;

************ quantile ************************************;

data km_q;
    set sum2 end=lastrec;
    length Weeks $200;
    if missing(lowerlimit) then lowerlimit=.A;
    if missing(upperlimit) then upperlimit=.A;
    if missing(estimate) then estimate=.A;
    Weeks=put(estimate, 5.0)||' ['||strip(put(lowerlimit, 5.0))||';'||strip(put(upperlimit, 5.0))||']';
    retain _ft1flag;
    if missing(lowerlimit) or missing(upperlimit) or missing(estimate) then _ft1flag='Y';
    if lastrec then call symput('_ft1', strip(_ft1flag));
RUN;

proc sort data=km_q;
    by paramcd percent;
RUN;

proc transpose data=km_q out=km_q (rename=(percent=group2)) prefix=ttt;
    by paramcd percent;
    id trtpn;
    var Weeks;
    format trtpn;
RUN;


proc delete data=sum2; RUN;

************************ all together ****************************;

data final (drop=paramcd);
    length ttt&__t1. ttt&__t2. ttt&__t3. _label_ _name_ paramcd $200;
    set km_c (in=aaa) km_q (in=bbb) km_r (in=ccc) ;
        if aaa then do;
            group2=input(compress(_name_, '_'), ??best.);
            group1=1;
            _name_=' ';
        END;
        if bbb then do;
            group1=2;
            if group2 eq 50 then _label_='Median [95% CI]';
            else _label_=strip(put(group2, best.))||'th percentile [95% CI]';
            _name_='(Weeks)';
        END;
        if ccc then do;
            group2=input(compress(_name_, '_'), ??best.)+100;
            group1=2;
            _name_='(Weeks)';
        END;
        label _label_='#'
              _name_='#'
              group1=' '
              group2=' '

              ttt&__t1.="Elinzanetant 120mg"
              ttt&__t2.="Placebo - Elinzanetant 120mg"
              ttt&__t3.="Total"
              ;
RUN;


%MTITLE;

%datalist(
    data     = final
  , by       = group1 group2 _label_ _name_
  , var      = ttt&__t1. ttt&__t2. ttt&__t3.
  , order    = group1 group2
  , freeline = group1
  , optimal  = yes
  , maxlen   = 50
  , space    = 3
  , hsplit   = '#'
  , bylen    = 45
  , hv_align = LEFT
);

%endprog;