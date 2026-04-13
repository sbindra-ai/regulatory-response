/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_3_5_8_adlb_liv_hy   );
/*
 * Purpose          : Hepatocellular drug-induced liver injury screening plot (SAF)
 * Programming Spec : 
 * Validation Level : 2 - Independent programming
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 30NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/t_8_3_5_8_adlb_liv_hy.sas (emvsx (Phani Tata) / date: 03AUG2023)
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
any post-baseline total bilirubin equal to or exceeding 2 x ULN &
a post-baseline ALT or AST equal to or exceeding 3 x ULN
*;

if paramcd_n = "ALT_AST"  then do;
    if  paramcd in ("SGOTSP" )  and aval >= 3*anrhi then Crit_SGOTSP_F = 1 ;
    if  paramcd in ("SGPTSP" )  and aval >= 3*anrhi then Crit_SGPTSP_F = 1 ;
end ;

if paramcd_n = "BILITOSP" then do ;
    if  paramcd in ("BILITOSP" )  and aval >= 2 * anrhi  then Crit_BILITOSP_F = 1 ;
end;

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

*Temple's corollary (right lower):
a post-baseline ALT or AST equal to or exceeding 3 x ULN &
any post-baseline total bilirubin < 2 x ULN
*;
if paramcd_n = "ALT_AST"  then do;
    alt_val = 3 * anrhi  ;
    if  paramcd in ("SGOTSP" )  and aval >= 3*anrhi then Crit_SGOTSP_rU = 1 ;
    if  paramcd in ("SGPTSP" )  and aval   >= 3*anrhi then Crit_SGPTSP_rU = 1 ;
end ;
if paramcd_n = "BILITOSP" then do ;
    B_val = 2 * anrhi  ;
    if  paramcd in ("BILITOSP" )  and aval <  2 * anrhi  then Crit_BILITOSP_rU = 1 ;
end;

  label &mosto_param_class.='Treatment Group';

run;

%macro cond (  cond =  , var = , para =  , para1 =  ) ;
 proc sort data  = adlb_ext
      out =    Crit_&para._&var. (keep = usubjid avisitn Crit_&para._&var.) nodupkey    ;
     by usubjid avisitn  ;
     where paramcd = "&para." ;
 run;

  proc sort data  = adlb_ext
       out =    Crit_&para1._&var. (keep = usubjid avisitn Crit_&para1._&var.) nodupkey    ;
      by usubjid avisitn  ;
      where paramcd = "&para1." ;
  run;

 proc sort data  = adlb_ext   out =    Crit_BILITOSP_&var.
      (keep = usubjid avisitn Crit_BILITOSP_&var.)    nodupkey   ;
     by usubjid avisitn  ;
     where paramcd =  "BILITOSP" ;
 run;

 data &cond. ;
     merge Crit_&para._&var.  Crit_&para1._&var. Crit_BILITOSP_&var. ;
     by usubjid avisitn  ;
     if (Crit_&para._&var. = 1  or  Crit_&para1._&var. = 1 ) and
        (Crit_BILITOSP_&var. = 1 ) then &cond = 1  ;
     else &cond. = 0 ;
     if &cond. = 1 ;
     keep usubjid &cond.  ;
 RUN;

 %mend ;


%cond (  cond =  hy_con    , var = F   , para = SGOTSP , para1 = SGPTSP  );
%cond (  cond =  Chol_con  , var = LU  , para = SGOTSP , para1 = SGPTSP  );
%cond (  cond =  tem_con   , var = rU   , para = SGOTSP , para1 = SGPTSP  );



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
     where    &saf_cond   and  CRIT9FL = "Y" and PARAMCD EQ "ALKPHOSP" ;
RUN;

 data final ;
     merge Adsl (keep = usubjid TRT01AN )
           CRIT9     CCRIT3      hy_con         Chol_con      tem_con

           alt_max (in=_in_ast_max)
           bil_max (in=_in_bil_max);
     by Usubjid ;
     if (_in_bil_max or _in_ast_max);
     * keep only subject with at least one post baseline value *;
 if CRIT9FL = "Y" and CCRIT3_F = 1 then Flag = 1   ;
      keep usubjid alt_max bil_max  CCRIT3_F CRIT9FL Flag
           hy_con Chol_con tem_con  TRT01AN ;
 run;

 %MTITLE;

 %overview_tab(
     data   = final
   , data_n = adsl
   , total  = no
   , groups = 'hy_con    = 1 '         *   "Potential Hy's Law (right upper)"
              'Chol_con  = 1'         *  "Cholestasis (left upper)"
              'tem_con   = 1'         *   "Temple's corollary (right lower)"
   , split  = '/#*'
   , hsplit = '/#*'
 );

*---------------------------------Mosto End--------------------------------------------;

%endprog(cleanWork = Y);

 *******This is the end of tf_8_3_adlb_liver_cholestatic.sas******;
