/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog( name     = f_10_2_8_2_adlb_over   );
/*
 * Purpose          : LB test plot by subject
 * Programming Spec :
 * Validation Level : 2 - Double programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 07MAR2024
 * Reference prog   : /var/swan/root/bhc/3427080/21810/stat/main01/val/analysis/pgms/f_10_2_8_2_adlb_over.sas (emvsx (Phani Tata) / date: 21FEB2024)
 ******************************************************************************/

%LET mosto_param_class = &treat_arm_a. ;

* Load and extend data;
%load_ads_dat(adlb_view,
              adsDomain = adlb,
              where = paramcd in ('SGOTSP', 'SGPTSP','BILITOSP','ALKPHOSP'),
              adslWhere = &saf_cond.   ,
              adslVars          = SAFFL FASFL &treat_arm_a.    trtedt trtsdt randdt
   );
%load_ads_dat(adsl_view, adsDomain = adsl, where = &saf_cond.);

%load_ads_dat(adae_view, adsDomain = adae,
              where = not missing(aedecod),
              adslWhere = &saf_cond. ,
              adslVars  = SAFFL FASFL &treat_arm_a.    trtedt trtsdt randdt
              );

%load_ads_dat(adcm_view, adsDomain = adcm,
              where = not missing(cmdecod),
              adslWhere = &saf_cond.  ,
              adslVars  = SAFFL FASFL &treat_arm_a.    trtedt trtsdt randdt
              );

proc sort data = sp.ce out = ce (keep = usubjid cedtc studyid) ;
    by usubjid cedtc;
run;
data ce_l ;
    set ce;
    by usubjid cedtc;
    if first.usubjid ;
    cedtn = input(cedtc, yymmdd10.);
    format cedtn date9. ;
RUN;
proc sort data = adlb_view out = adlb ;
    by studyid usubjid ;
run;

data adlb ;
    merge adlb ( in = a ) ce_l ( in = b );
    by studyid usubjid ;
    if b ;

RUN;
proc sort data =adcm_view  out = adcm ;
    by studyid usubjid ;
run;
data adcm ;
    merge adcm ( in = a ) ce_l ( in = b );
    by studyid usubjid ;
    if b ;
RUN;

DATA adlb_vars;
    SET adlb ;
    ARRAY _dt[*]     trtsdt ph2sdt trtedt;
    ARRAY _refdy[3]  sttp1   sttp2  entp2;
    DO i = 1 TO dim(_dt);
        IF n(_dt[i], trtsdt) = 2 THEN do;
           if _dt[i]<trtsdt then _refdy[i] = _dt[i] - trtsdt;
           else _refdy[i] = _dt[i] - trtsdt + 1;
        end;
    END;
   FORMAT new_aval 4.1;
   IF paramcd NE 'PTINR' THEN DO;
       if not missing (aval) or not missing(anrhi)  then do ;
       new_aval = aval/anrhi;
       anrhi1   = anrhi/anrhi;
       anrhi2   = anrhi/anrhi*2;
       anrhi3   = anrhi/anrhi*3;
       end ;
   END;
   value =  aval/anrhi ;
   if aval/anrhi >= 3 then Flag = 1 ;
   LABEL anrhi1 = 'ULN'       anrhi2 = '2xULN'      anrhi3 = '3xULN'
         ady    = 'Days'
         sttp1  = 'First dose of double blind'
         sttp2  = 'First dose of Elinzanetant 120mg'
         entp2  = 'Last dose'
         ;
  length trt_tit $200;
   trt_tit =  put(&treat_arm_a. , Z_TRT. ) ;
run;
proc sort data=adlb_vars  out=adlb_alt;
    by studyid usubjid adt;
RUN;

data adlb_adt(keep=studyid usubjid adt);
    set adlb_alt;
    by studyid usubjid;
    if first.usubjid;
run;
proc sql;
    create table toc as
           select distinct &treat_arm_a. , usubjid
           from adlb_vars
         order by usubjid ;
quit;
data toc ;
    set toc ;
    sub = substr(usubjid , 6  );
run;

data adae;
    set adae_view;
    if not missing(astdt);
    if nmiss(astdy, aendy) = 1 then  aedecod = cat (strip(aedecod) , '*');
    if nmiss(astdy, aendy) = 0 then do;
        _ae_lowpos  = astdy;
        _ae_highpos = aendy + 1;
    end;
    else if not missing(astdy) then do;
         _ae_startmarkerpos  = astdy;
    end;

     if nmiss(_ae_lowpos, _ae_highpos, _ae_startmarkerpos)=3 then
     _ae_startmarkerpos=astdt-randdt+(astdt>randdt);


    keep usubjid aedecod _ae_lowpos _ae_highpos _ae_startmarkerpos astdt   ;
run;
data adcm;
    set adcm ;
    attrib _cmdecod_propcase length=$200;

    if nmiss(astdy, aendy) = 1 then  _cmdecod_propcase = cat (strip(cmdecod) , '*');
    else  _cmdecod_propcase =  cmdecod ;

    if nmiss(astdy, aendy) = 0 then do;
        _cm_lowpos  = astdy;
        _cm_highpos = aendy + 1;
    end;
    else if not missing(astdy) and CMENRTPT EQ 'ONGOING' then do;
         _cm_startmarkerpos = astdy;
    end;

*The time frame for concomitant medication will be presented as 6 months prior
 to the first onset of close liver observation for all participants,  *;

   if n(astdt,cedtn )=2 and (astdt+182)>=cedtn    ;
keep studyid usubjid _cmdecod_propcase _cm_lowpos _cm_highpos _cm_startmarkerpos
        astdt aendt cmdecod cmtrt CMENRTPT astdy ;
run;
proc sort data=adcm ;
    by studyid usubjid  cmdecod  astdt;
RUN;
data adcm ;
    retain row 0 ;
    set adcm ;
    by studyid usubjid cmdecod astdt;
    if first.cmdecod then row = row + 1 ;
    if not first.cmdecod then _cmdecod_propcase = '' ;
RUN;
proc sort data=adcm  out = adcm_cmen  ;
    by studyid usubjid  cmdecod  astdt;
    where  missing(_cmdecod_propcase) and CMENRTPT EQ 'ONGOING' ;
RUN;
data adcm_cmen  ( keep = studyid usubjid  cmdecod  astdt _cmdecod_propcase_cont );
    set adcm_cmen ;
    by studyid usubjid  cmdecod  astdt;
    length _cmdecod_propcase_cont $200.  ;
  _cmdecod_propcase_cont = cat (strip(cmdecod) , '*');
RUN;

proc sort data=  adcm;
 by studyid usubjid  cmdecod  astdt;
RUN;

data adcm ;
    merge adcm (in = a ) adcm_cmen ;
    by studyid usubjid  cmdecod  astdt;
    if a ;
    if not missing(_cmdecod_propcase_cont) and
        not missing(_cmdecod_propcase)
     then do ;
           if  _cmdecod_propcase_cont ^=  _cmdecod_propcase  then
                   _cmdecod_propcase =   _cmdecod_propcase_cont;
     end ;
        drop _cmdecod_propcase_cont ;
RUN;
proc sort data=  adcm;
 by studyid usubjid   row ;
RUN;

%sganno;

%let anno_help_text = %str( BORDER='FALSE',      DRAWSPACE="DATAVALUE", FILLCOLOR="black",   LAYER="FRONT",
                       TEXTFONT="arial",    TEXTSIZE=2,            TEXTSTYLE="NORMAL",  TEXTWEIGHT="NORMAL", WIDTH=100,
                       WIDTHUNIT='PERCENT',
                      X1SPACE='DATAVALUE', XAXIS='X',             Y1SPACE='DATAPERCENT', YAXIS='Y',           RESET="ALL");
%LET anno_help_text = %SYSFUNC(COMPBL(&anno_help_text.));

%let anno_help_line = %str(DRAWSPACE="DATAVALUE",  LAYER="FRONT",
                      X1SPACE='DATAVALUE', X2SPACE='DATAVALUE', XAXIS='X',  Y1SPACE='DATAPERCENT', YAXIS='Y',   Y2SPACE='DATAPERCENT',
                      RESET="ALL");
%LET anno_help_line = %SYSFUNC(COMPBL(&anno_help_LINE.));


%mtitle ;
%MACRO _subj();
    %local _i;

    DATA _NULL_;
        SET toc END=last;
        CALL symputx('subj'||cats(_n_),cats(usubjid));

        CALL symputx('sub',cats(sub));

        IF last THEN CALL symputx('nsubj',cats(_n_));
    RUN;

    %DO _i=1 %TO &nsubj.;
        DATA adlb;
            SET adlb_vars;
            FORMAT _subj $200.;
            IF usubjid IN ("&&subj&_i.");
            _subj=scan(usubjid,1,'_');
        RUN;

            DATA anno_ae;
                set adae(where=(usubjid IN ("&&subj&_i."))) end=last;
                    ;
                if n(_ae_lowpos,_ae_highpos)=2 then do;
                  %SGTEXT(TEXTCOLOR="red",LABEL = aedecod,
                          ANCHOR = 'BOTTOMLEFT',JUSTIFY = "LEFT",
                          X1 = _ae_lowpos,
                          y1 = abs(100-_n_*5), &anno_help_text.);
                  %SGLINE(x1=_ae_lowpos ,
                          y1=abs(100-_n_*5-0.5),
                          x2=_ae_highpos  ,
                          y2=abs(100-_n_*5-0.5),
                          LINECOLOR="red",&anno_help_line.);
                end;
                else do;
                    %SGTEXT(TEXTCOLOR="red",LABEL = aedecod, ANCHOR = 'BOTTOMLEFT', JUSTIFY = "LEFT",
                            x1=_ae_startmarkerpos, y1 = abs(100-_n_*5), &anno_help_text.);
                    %sgarrow(x1=_ae_startmarkerpos+1,
                             y1=abs(100-_n_*5-0.5),dx=2,y2=abs(100-_n_*5-0.5),
                             DIRECTION='OUT',LINECOLOR="red",
                              shape="OPEN",scale=0.8,&anno_help_line.)
                END;
                if last then call symputx('_last',cats(_n_));
            RUN;

DATA anno_cm;
    set adcm(where=(usubjid IN ("&&subj&_i.")));
    by studyid usubjid   row ;
    if n(_cm_lowpos,_cm_highpos)=2 then do;
      %SGTEXT(TEXTCOLOR="green",
              LABEL = _cmdecod_propcase,
              ANCHOR = 'BOTTOMLEFT',
              JUSTIFY = "LEFT",
              X1 = _cm_lowpos  ,
              y1 = abs(100-(&_last.+ row  )*5) +.5 , &anno_help_text.);
      %SGLINE(x1=_cm_lowpos,
              y1=abs(100-(&_last.+ row )*5-0.5) ,
              x2=_cm_highpos ,
              y2=abs(100-(&_last.+ row )*5-0.5),
              LINECOLOR="green",&anno_help_line.);
    end;

    else do;
        %SGTEXT(TEXTCOLOR="green",LABEL = _cmdecod_propcase, ANCHOR = 'BOTTOMLEFT', JUSTIFY = "LEFT",
                x1=_cm_startmarkerpos,
                y1 = abs(100-(&_last.+row)*5), &anno_help_text.);
        %sgarrow( x1=_cm_startmarkerpos+1,
                 y1=abs(100-(&_last.+row  )*5-0.5),
                 dx=2,
                 y2=abs(100-(&_last.+ row  )*5-0.5),
                 DIRECTION='OUT', LINECOLOR="green",
                  shape="OPEN",   scale=0.8,&anno_help_line.)
    END;

RUN;

data anno_cm ;
    set  anno_cm;
    if length (LABEL) > 100 then WIDTH= 40  ;
RUN;

        data anno_ae_cm;
            set anno_ae anno_cm;
        RUN;

        proc sql noprint;
            select min(x1) into :_min1
                   from anno_ae_cm
                   where x1 is not missing;
            select min(ady) into :_min2
                   from adlb
                   where ady is not missing;
        QUIT;

        data _null_;
            m1=&_min1.;
            m2=&_min2.;
            m3=min(m1,m2);
            call symputx('_min',cats(m3));
        RUN;

        PROC SORT DATA = adlb OUT = class_data NODUPKEY;
            BY studyid usubjid paramcd;
        RUN;

        %LinePlot(
            data       = adlb
          , xvar       = ady
          , yvar       = new_aval
          , by         = &treat_arm_a. usubjid _subj
          , class      = paramcd
          , class_data = class_data
          , title_ny   = no
          , subject    = usubjid
          , style      = presentation
          , annodata   = anno_ae_cm
          , xstart     = &_min.
          , xrefline   = sttp1 entp2
          , xlabel     = 'Days since reference start date'
          , yrefline   = anrhi1 anrhi2 anrhi3
          , ylabel     = 'ALT. AST. TBIL. AP. (/ULN)'
          , filename   = &prog._&_i.
        );
    %END;

%MEND;
%_subj();

%symdel mosto_param_class;
%endprog;