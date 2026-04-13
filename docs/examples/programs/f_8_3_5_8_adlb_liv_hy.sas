/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = f_8_3_5_8_adlb_liv_hy  );
/*
 * Purpose          : Hepatocellular drug-induced liver injury screening plot (SAF)
 * Programming Spec :
 * Validation Level : 2 - Double programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 08DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/f_8_3_5_8_adlb_liv_hy.sas (emvsx (Phani Tata) / date: 28SEP2023)
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


*------------------------------Prepare data as needed-------------------------------------------;
data adsl;
   set adsl ;
   label &mosto_param_class.='Treatment Group';
run;

data adlb_ext;

   set adlb ;
  where    &saf_cond  and  paramcd in (   "SGOTSP","SGPTSP" , "BILITOSP")
            and anl01fl = "Y"  and  ABLFL NE "Y"  and ADY GT 1  ;

length paramcd_n $40 ;
if paramcd in ("SGOTSP","SGPTSP" ) then paramcd_n = "ALT_AST" ;
if paramcd in ("BILITOSP" ) then paramcd_n = "BILITOSP" ;

if 0 < anrhi then aval_norm = aval / anrhi ;

else do;
    %log(
        WARN
      , "Cannot normalize by value <= 0 or missing, observation deleted "
      &subj_var.= avisitn= paramcd= aval= anrhi =
      , messageType = DS
    ) /* Warning message is optional, but before you remove it please have a look at the missing/incorrect data values and check if this is an issue */
   * delete  paramcd in (  "CCRIT9" "SGOTSP","SGPTSP" , "BILITOSP");
end;

*Potential Hy's Law (right upper)
*CCRIT9 >=3xBL of ALT or AST and >=2xBL Total bilirubin
any post-baseline total bilirubin equal to or exceeding 2 x ULN &
a post-baseline ALT or AST equal to or exceeding 3 x ULN*;

if paramcd_n = "ALT_AST"  then do;
    if  paramcd in ("SGOTSP" )  and aval >= 3*base then Crit_SGOTSP_F = 1 ;
    if  paramcd in ("SGPTSP" )  and aval >= 3*base then Crit_SGPTSP_F = 1 ;
end ;
if paramcd_n = "BILITOSP" then do ;
    if  paramcd in ("BILITOSP" )  and aval >= 2 * base  then Crit_BILITOSP_F = 1 ;
end;
if (Crit_SGOTSP_F = 1 or Crit_SGPTSP_F = 1 ) and (Crit_BILITOSP_F = 1 ) then hy_con = 1  ;
else hy_con = 0 ;

*Cholestasis (left upper)
any post-baseline total bilirubin equal to or exceeding 2 x ULN &
a post-baseline ALT or AST < 3 x ULN---Not there in LB data *;


if paramcd_n = "ALT_AST"  then do;
    alt_val = 3 * anrhi  ;  C_AL = 1 ;
    if  paramcd in ("SGOTSP" )  and aval < 3*anrhi then Crit_SGOTSP_LU = 1 ;
    if  paramcd in ("SGPTSP" )  and aval   < 3*anrhi then Crit_SGPTSP_LU = 1 ;
end ;
if paramcd_n = "BILITOSP" then do ;
    B_val = 2 * anrhi  ; C_B = 1 ;
    if  paramcd in ("BILITOSP" )  and aval >= 2 * anrhi  then Crit_BILITOSP_LU = 1 ;
end;

if (Crit_SGOTSP_LU = 1 or Crit_SGPTSP_LU = 1 ) and (Crit_BILITOSP_LU = 1 ) then Chol_con = 1  ;
else Chol_con = 0 ;
*Temple's corollary (right lower):
a post-baseline ALT or AST equal to or exceeding 3 x ULN &
any post-baseline total bilirubin < 2 x ULN
*;
if paramcd_n = "ALT_AST"  then do;
    alt_val = 3 * anrhi  ;
    if  paramcd in ("SGOTSP" )  and aval < 3*anrhi then Crit_SGOTSP_rU = 1 ;
    if  paramcd in ("SGPTSP" )  and aval   < 3*anrhi then Crit_SGPTSP_rU = 1 ;
end ;
if paramcd_n = "BILITOSP" then do ;
    B_val = 2 * anrhi  ;
    if  paramcd in ("BILITOSP" )  and aval <  2 * anrhi  then Crit_BILITOSP_rU = 1 ;
end;

if (Crit_SGOTSP_rU = 1 or Crit_SGPTSP_rU = 1 ) and (Crit_BILITOSP_rU = 1 ) then  tem_con  = 1  ;
else   tem_con  = 0  ;

  label &mosto_param_class.='Treatment Group';


  drop  alt_val B_val Crit_:;
run;

%macro cond (  cond ) ;
proc sort data  = adlb_ext out = &cond. (keep = usubjid &cond. ) nodupkey ;
    by usubjid ;
    where not missing(&cond.) ;
RUN;
%mend ;

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
    where    &saf_cond  and  paramcd in ( "CCRIT3" ) ;
    if     avalc = "Y" then CCRIT3_F =1 ;
    keep usubjid    CCRIT3_F    ;
RUN;


proc sort data = adlb out = Crit9 (keep = usubjid  CRIT9FL  ) nodupkey ;
    by usubjid ;
    where    &saf_cond   and  CRIT9FL = "Y"  and PARAMCD EQ "ALKPHOSP" ;
RUN;

%cond( hy_con ); %cond( Chol_con ); %cond( tem_con );


data final ;
    merge Adsl (keep = usubjid TRT01AN )
          CRIT9
          CCRIT3
          hy_con
          Chol_con
          tem_con

          alt_max (in=_in_ast_max)
          bil_max (in=_in_bil_max);
    by Usubjid ;
    if (_in_bil_max or _in_ast_max);
    * keep only subject with at least one post baseline value *;
    if CRIT9FL = "Y" and CCRIT3_F = 1 then Flag = 1   ;
     keep usubjid alt_max bil_max  CCRIT3_F CRIT9FL Flag hy_con Chol_con tem_con  TRT01AN ;
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

data anno_text;
    %sgtext(label='Cholestasis', anchor='TOPLEFT', border='FALSE',drawspace="DATAVALUE"
          ,FILLCOLOR="black", JUSTIFY= "LEFT", LAYER= "FRONT",  TEXTCOLOR="black",
          TEXTFONT="arial", TEXTSIZE= 2,  TEXTSTYLE="NORMAL",    TEXTWEIGHT="NORMAL",
          width=3,widthunit='DATA',X1=0.1,X1SPACE='DATAVALUE',XAXIS='X',Y1=9.5,Y1SPACE='DATABALUE',YAXIS='Y',
         RESET="ALL" );
     %sgtext(label="Potential Hy's Law", anchor='TOPRIGHT', border='FALSE',drawspace="DATAVALUE"
           ,FILLCOLOR="black", JUSTIFY= "RIGHT", LAYER= "FRONT",  TEXTCOLOR="black",
           TEXTFONT="arial", TEXTSIZE= 2,  TEXTSTYLE="NORMAL",    TEXTWEIGHT="NORMAL",
           width=3,widthunit='DATA',X1=9.1,X1SPACE='DATAVALUE',XAXIS='X',Y1=9.5,Y1SPACE='DATABALUE',YAXIS='Y',
          RESET="ALL" );

    %sgtext(label="Temple's corollary", anchor="BOTTOMRIGHT", border='FALSE',drawspace="DATAVALUE"
          ,FILLCOLOR="black", JUSTIFY= "RIGHT", LAYER= "FRONT",  TEXTCOLOR="black",
          TEXTFONT="arial", TEXTSIZE= 2,  TEXTSTYLE="NORMAL",    TEXTWEIGHT="NORMAL",
          width=3,widthunit='DATA',X1=9.1,X1SPACE='DATAVALUE',XAXIS='X',Y1=0.1 ,Y1SPACE='DATABALUE',YAXIS='Y',
          RESET="ALL" );

RUN;


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
  , xrefline      = 3
  , xlabel        = 'Maximum post-baseline ALT or AST (xULN)'
  , yrefline      = 2
  , ylabel        = 'Maximum post-baseline bilirubin (xULN)'
  , filename      = &prog.
  , title_ny         = NO
  , xtype         = LOG
  , ytype         = LOG

);

*---------------------------------Mosto End--------------------------------------------;

%endprog(cleanWork = Y);
