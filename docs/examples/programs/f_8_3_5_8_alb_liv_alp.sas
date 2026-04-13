/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = f_8_3_5_8_alb_liv_alp  );
/*
 * Purpose          : Figure: Cholestatic drug-induced liver injury screening plot (SAF)
 * Programming Spec :
 * Validation Level :  2 - Double programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 08DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/f_8_3_5_8_alb_liv_alp.sas (emvsx (Phani Tata) / date: 09NOV2023)
 ******************************************************************************/


*Load datasets;

%load_ads_dat(
    adlb_view
  , adsDomain = adlb
  , adslWhere =   n(&treat_arm_a.)
  , adslVars  = SAFFL FASFL &treat_arm_a.   trtedt   trtsdt
)

%load_ads_dat(adsl_view , adsDomain = adsl , where =  &saf_cond );


%extend_data(indat = adlb_view , outdat = adlb )
%extend_data(indat = adsl_view  , outdat = adsl) ;

OPTIONS NOTES  SOURCE;;
*------------------------------Prepare data as needed-------------------------------------------;
data adsl;
   set adsl ;
   label &mosto_param_class.='Treatment Group';
run;

data adlb_ext;

   set adlb ;
   where    &saf_cond  and  paramcd in (  "ALKPHOSP" , "BILITOSP")
            and anl01fl = "Y"
            and  ABLFL NE "Y"
            and ADY GT 1  ;

if paramcd in ("ALKPHOSP" ) then paramcd_n = "ALT_AST" ;
if paramcd in ("BILITOSP" ) then paramcd_n = "BILITOSP" ;


if 0 < anrhi then aval_norm = aval / anrhi ;

else do;
    %log(
        WARN
      , "Cannot normalize by value <= 0 or missing, observation deleted "
      &subj_var.= avisitn= paramcd= aval= anrhi =
      , messageType = DS
    ) /* Warning message is optional, but before you remove it please have a look at the missing/incorrect data values and check if this is an issue */
   * delete;
end;
  label &mosto_param_class.='Treatment Group';
run;

/* Select maximum values for ALT or AST Vs Bil*/
proc sql;
    create table alt_max as
        select Usubjid   , max(aval_norm) as alt_max
        from adlb_ext
        where paramcd_n = "ALT_AST"
        group by Usubjid ;


    create table bil_max as
        select Usubjid  , max(aval_norm) as bil_max
        from adlb_ext
        where PARAMCD in ("BILITOSP")
        group by Usubjid ;
quit;

data CCRIT3 ;
    set adlb;
    where    &saf_cond  and  paramcd in ( "CCRIT8" ) ;
    if     avalc = "Y" then CCRIT3_F =1 ;
    keep usubjid    CCRIT3_F    ;
RUN;

data final ;
    merge Adsl (keep = usubjid TRT01AN )
          CCRIT3
          alt_max (in=_in_ast_max)
          bil_max (in=_in_bil_max);
    by Usubjid ;
    if (_in_bil_max or _in_ast_max);
    * keep only subject with at least one post baseline value *;
    if   CCRIT3_F = 1 then Flag = 1   ;
     keep usubjid alt_max bil_max  CCRIT3_F   Flag  TRT01AN ;
run;

data TLFMETA.&prog;
    set final;
RUN;

%sganno;
%sganno_help(sgoval);

data anno;
    set final(where=(flag=1));
    %sgoval(x1=alt_max ,y1= bil_max ,height=1.5,width=1.5,
            display='outline',drawspace='DATASPACE',HEIGHTUNIT="PIEXL"
            ,LAYER='FRONT',LINECOLOR="red",WIDTHUNIT='PIEXL'
            ,x1space='DATAVALUE',Y1SPACE='DATAVALUE');
run;


* add this to make sure anno is not empty when there no cond met for Anno data ;

data anno_text;
   %sgtext(label=' ', anchor='TOPLEFT', border='FALSE',drawspace="DATAVALUE"
              ,FILLCOLOR="black", JUSTIFY= "LEFT", LAYER= "FRONT",  TEXTCOLOR="black",
              TEXTFONT="arial", TEXTSIZE= 2,  TEXTSTYLE="NORMAL",    TEXTWEIGHT="NORMAL",
              width=3,widthunit='DATA',X1=0.1,X1SPACE='DATAVALUE',XAXIS='X',Y1=4,
              Y1SPACE='DATABALUE',YAXIS='Y',  RESET="ALL" );
run;

data anno;
    set anno anno_text;
RUN;
*-------------------------------------Mosto Start --------------------------------------------;
%MTITLE;

%ScatterPlot(
    data          = final
  , xvar          =    alt_max
  , yvar          = bil_max
  , class         = &mosto_param_class.
  , annodata      = ANNO
  , legendtitle   = 'Treatment group'
  , style_options =    MarkerSymbols   = 'Square'  'CircleFilled'
  , xrefline      = 2
  , xlabel        = 'Maximum post-baseline ALP (xULN)'
  , yrefline      = 2
  , ylabel        = 'Maximum post-baseline bilirubin (xULN)'
  , filename      = &prog.
  , title_ny         = NO
  , xtype         = LOG
  , ytype         = LOG
);

*---------------------------------Mosto End--------------------------------------------;

%endprog(cleanWork = Y);
