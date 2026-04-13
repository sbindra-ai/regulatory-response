/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_3_5_8_alb_liv_alp );
/*
 * Purpose          : Table: Cholestatic drug-induced liver injury screening plot (SAF)
 * Programming Spec : 
 * Validation Level : 2 - Independent programming
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 30NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/t_8_3_5_8_alb_liv_alp.sas (emvsx (Phani Tata) / date: 16NOV2023)
 ******************************************************************************/


%load_ads_dat(
    adlb_view
  , adsDomain = adlb
  , adslWhere =   n(&treat_arm_a.)
  , adslVars  = SAFFL FASFL &treat_arm_a.   trtedt   trtsdt
)

%load_ads_dat(adsl_view , adsDomain = adsl , where =  &saf_cond );
%extend_data(indat = adlb_view , outdat = adlb )
%extend_data(indat = adsl_view  , outdat = adsl) ;

OPTIONS NOnoTES  SOURCE;;
*------------------------------Prepare data as needed-------------------------------------------;
data adsl;
   set adsl ;
   label &mosto_param_class.='Treatment Group';
run;

data adlb_ext;

   set adlb ;
  where    &saf_cond  and  paramcd in (   "ALKPHOSP" , "BILITOSP")
            and anl01fl = "Y"  and  ABLFL NE "Y"  and ADY GT 1  ;

length paramcd_n $40 ;
if paramcd in ("ALKPHOSP") then paramcd_n = "ALT_AST" ;
if paramcd in ("BILITOSP" ) then paramcd_n = "BILITOSP" ;

if 0 < anrhi then aval_norm = aval / anrhi ;

else do;
    %log(
        WARN
      , "Cannot normalize by value <= 0 or missing, observation deleted "
      &subj_var.= avisitn= paramcd= aval= anrhi =
      , messageType = DS
    ) /* Warning message is optional, but before you remove it please have a look at the missing/incorrect data values and check if this is an issue */
   * delete  paramcd in (  "CCRIT9" "ALKPHOSP","SGPT" , "BILITOSP");
end;
        *Total bilirubin >= 2xULN and ALP >= 2xULN (right upper) ;
    if  paramcd in ("ALKPHOSP" )  and aval >= 2* anrhi then Crit_ALKPHOSP_F = 1 ;
    if  paramcd in ("BILITOSP" )  and aval >= 2 * anrhi  then Crit_BILITOSP_F = 1 ;
        *Total bilirubin >= 2xULN and ALP < 2xULN (left upper);
    if  paramcd in ("ALKPHOSP"  )  and aval < 2 * anrhi then Crit_ALKPHOSP_LU = 1 ;
    if  paramcd in ("BILITOSP" )  and aval >= 2 * anrhi  then Crit_BILITOSP_LU = 1 ;
     *Total bilirubin < 2xULN and ALP >= 2xULN (right lower);
    if  paramcd in ("ALKPHOSP"  )  and aval >= 2 * anrhi then Crit_ALKPHOSP_rU = 1 ;
    if  paramcd in ("BILITOSP" )  and aval < 2 * anrhi  then Crit_BILITOSP_rU = 1 ;

    label &mosto_param_class.  =  'Treatment Group';

run;
%macro cond (  cond =  , var = , para =  ) ;

proc sort data  = adlb_ext
     out =    Crit_&para._&var. (keep = usubjid avisitn Crit_&para._&var.) nodupkey    ;
    by usubjid avisitn  ; *<This would change from AST or APT as it would extra *;
    where paramcd = "&para." ;
run;

proc sort data  = adlb_ext   out =    Crit_BILITOSP_&var.
     (keep = usubjid avisitn Crit_BILITOSP_&var.)    nodupkey   ;
    by usubjid avisitn  ;
    where paramcd =  "BILITOSP" ;
run;

data &cond. ;
    merge Crit_&para._&var.  Crit_BILITOSP_&var. ;
    by usubjid avisitn  ;
    if (Crit_&para._&var. = 1  ) and (Crit_BILITOSP_&var. = 1 ) then &cond = 1  ;
    else &cond. = 0 ;
    keep usubjid &cond.;
RUN;

%mend ;

%cond (  cond =  hy_con    , var = F   , para = ALKPHOSP  );
%cond (  cond =  Chol_con  , var = LU  , para = ALKPHOSP  );
%cond (  cond =  tem_con   , var = rU  , para = ALKPHOSP  );

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
run;
proc sort data = adlb out = Crit9 (keep = usubjid  CRIT9FL  ) nodupkey ;
     by usubjid ;
     where    &saf_cond   and  CRIT9FL = "Y" ;
run;

data final ;
     merge Adsl (keep = usubjid TRT01AN )
           CRIT9
           CCRIT3
           hy_con Chol_con  tem_con

           alt_max (in=_in_ast_max)
           bil_max (in=_in_bil_max);
     by Usubjid ;
      * keep only subject with at least one post baseline value *;
     if (_in_bil_max or _in_ast_max);

   *  if CRIT9FL = "Y" and CCRIT3_F = 1 then Flag = 1   ;
   if   CCRIT3_F = 1 then Flag = 1   ;
      keep usubjid alt_max bil_max  CCRIT3_F CRIT9FL Flag hy_con Chol_con tem_con  TRT01AN ;
run;

 %MTITLE;

%overview_tab(
     data   = final
   , data_n = adsl
   , total  = no
   , groups = 'hy_con    = 1 '         * "Total bilirubin >= 2xULN and ALP >= 2xULN (right upper)"
              'Chol_con  = 1'         *  "Total bilirubin >= 2xULN and ALP < 2xULN (left upper)"
              'tem_con   = 1'         *  "Total bilirubin < 2xULN and ALP >= 2xULN (right lower)"
   , split  = '/#*'
   , hsplit = '/#*'
 );

 *---------------------------------Mosto End--------------------------------------------;
 %endprog(cleanWork = Y);
 *******This is the end of tf_8_3_adlb_liver_cholestatic.sas******;
