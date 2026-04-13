/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_3_5_8_1_adlb_frq );
/*
 * Purpose          : Number of subjects by cumulative hepatic safety laboratory parameter category
 * Programming Spec : 
 * Validation Level : 2 - Independent programming
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 30NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/t_8_3_5_8_1_adlb_frq.sas (emvsx (Phani Tata) / date: 03AUG2023)
 ******************************************************************************/

%macro par (par =  , ord =  , out =  , paramcd = , row = ) ;

%load_ads_dat(adlb_view, adsDomain = adlb , adslWhere =  &saf_cond )
%load_ads_dat(adsl_view , adsDomain = adsl , where =  &saf_cond )

%extend_data(indat = adlb_view , outdat = adlb )
%extend_data(indat = adsl_view  , outdat = adsl) ;

data adlb22 ;
    set adlb ;
where paramcd in ( &par. )  and ANL01FL="Y"  ;
length avist $50. ;
if avisitn  > 5  then avist = "Post Baseline";
if avisitn  = 5  then avist = "Baseline";

CRITT1   = ">=1 x ULN" ;
CRITT2   = ">=1.5 x ULN"  ;
CRITT3   = ">=2 x ULN";
CRITT4   = ">=3 x ULN";
CRITT5   = ">=5 x ULN";
CRITT6   = ">=8 x ULN";
CRITT7   = ">=10 x ULN";
CRITT8   = ">=20 x ULN";
CRITT9   =   "<2 x ULN"  ;

CRITT11   = ">=1.5";
CRITT12   =   ">=2"  ;

 if avisitn  >= 5;
  attrib   avist  label = "Visit";
run;
proc sort data = adlb22 out = Crit
     (keep = usubjid avisitn  &treat_var paramcd
     parcat1 avist paramn Crit: Crit1--Crit8 Crit11  Crit12  );
    by usubjid paramcd paramn ;
RUN;

%macro rest (flg =  );
    data  c_ct_&flg.  ;
      set crit ;

         crit = Crit&flg. ;
          critfl = Crit&flg.fl ;

          Critord  = &flg. ;

          keep  &subj_var.    parcat1 paramn  paramcd   crit

           crit    avist TRT01AN
           critfl

           Critord ;
    run;

%mend ;
%rest (flg = 1 );
%rest (flg = 2 );
%rest (flg = 3 );
%rest (flg = 4 );
%rest (flg = 5 );
%rest (flg = 6 );
%rest (flg = 7 );
%rest (flg = 8 ) ;

%rest (flg = 11 );
%rest (flg = 12 ) ;

data  c_ct_all;

    set   c_ct_:;
     if paramcd in ( &par. )   ;

     paramcd = "&out.";
RUN;
PROC SORT DATA=adlb
     OUT=tby (KEEP= paramcd  paramn parcat1)  nodupkey;
    BY parcat1 paramn ;
RUN;

%MTITLE;

%freq_tab(
    data     = c_ct_all
  , data_n   = adsl
  , var      = paramcd * crit
  , subject  = &subj_var.
  , by       = avist paramcd
  , total    = NO
  , order    = paramcd parcat1
  , class    = &treat_var
  , hlabel   = Yes
  , outdat   = __stat_&out
  , missing  = NO
  , complete = ALL
  , layout   = MINIMAL_BY
);

data CRITT_&out    ;
    set adlb22 ;

     paramcd = "&out.";
RUN;
proc sort data =  CRITT_&out  (keep = paramcd CRITT:) NODUPKEY  ;
    by paramcd ;
RUN;
proc transpose data =  CRITT_&out  out = CRITT1_&out(rename = (col1 = crit1 ) ) ;
    by paramcd ;
    var CRITT: ;
RUN;

data CRITT1_&out ;
    set CRITT1_&out;
    crit2 = crit1 ;
    crit1 = compress(crit1);
    ord = input(compress(_name_,'','kd') , 3.) ;
    ord_og = ord ;
    if ord_og in (&ord. );
    ord = ord + 10 ;
    outcat = "&out";
   avist = "Post Baseline"; output ;
    avist = "Baseline"; output ;
run;

data __stat_&out ;
    set __stat_&out;

    crit1 = compress(crit);
    outcat = "&out";
RUN;
proc sort data = __stat_&out ;
    by outcat   avist   crit1   ;
RUN;
proc sort data = CRITT1_&out (drop = paramcd )  ;
    by outcat   avist crit1  ;
RUN;


data all_&out ;
    merge __stat_&out CRITT1_&out ;
    by outcat avist  crit1  ;
    if not missing(_cptog1) then do ;
    _cptog11 =    strip(scan( strip (_cptog1),1 , "   ",  "b"   ))     ;
    str1 = substr ( strip(_cptog1)  , 1 , length( strip( _cptog1 ) ) -  length( strip( _cptog11 ) )  ) ;
     if length (str1) < 12  then str1 = "  " !! str1 ;
    END;
    if   missing(_cptog1) then   str1 = "  0"  ;


    if not missing(_cptog2) then do ;
     _cptog12 =    strip(scan( strip (_cptog2),1 , "   ",  "b"   ))     ;
    str2 = substr ( strip(_cptog2)  , 1 , length( strip( _cptog2 ) ) -  length( strip(  _cptog12 ) )  ) ;

     if length (str2) < 12  then str2 = "  " !! str2 ;
    end ;
    if   missing(_cptog2) then   str2 = "  0"  ;

    if _type_ = . and ord ^=. then _type_ = ord ;
    if _varl_ = " " and _name_ ^= " " then _varl_ = '   ' !! crit1 ;

    if _type_ = 2   then do ;
        _varl_ =  'Category'  ;
         str1   = "   "  ;
        str2    = "   "  ;
    end ;
    length para $40 ;
    Para  = "&paramcd." ;
    label para = "Parameter"
          AVIST = "Time interval" ;
    row = &row ;

RUN;

%mend  ;

%par (par = %str("SGPTSP" ) , ord = %str( (1,4,5,6,7, 8  ) ) ,
      out = alt   ,
      paramcd = %str(ALT) ,
      row = 1 ) ;

%par (par = %str("SGOTSP" ) , ord = %str( (1,4,5,6,7, 8  ) ) ,
      out = ast   ,
      paramcd = %str(AST) ,
      row = 2  ) ;

%par (par = %str( "SGOTSP","SGPTSP" ) , ord = %str( (4,5,6,7, 8  ) ) ,
      out = als
    , paramcd = %str(ALT or AST),
      row = 3
    ) ;
%par (par = %str("BILITOSP" ) , ord = %str( (1,3,  5,6   ) ) ,
      out = bil      ,
      paramcd = %str(Total bilirubin),
      row = 4 ) ;
%par (par = %str("ALKPHOSP" ) , ord = %str( ( 2,3, 4    ) ) ,
      out = ALP      ,
      paramcd = %str(ALP),
      row = 5 ) ;

%par (par = %str("PTINR" ) ,   ord = %str( ( 11,12  ) ) ,
      out = ptn      ,
      paramcd = %str(INR),
      row = 6 ) ;
proc sql noprint ;
    create table trt_cnt as
           select count( &treat_var ) as count ,  &treat_var
           from adsl
           Group by  &treat_var ;
    select  count into : trt1 trimmed
           from trt_cnt
           where  &treat_var = 100 ;

    select  count into : trt2 trimmed
           from trt_cnt
           where  &treat_var = 101 ;
    %put &trt1 &trt2;
QUIT;
data all;
    set all_alt
        all_ast
        all_als
        all_bil
        all_alp
        all_ptn ;
    label str1 = "Elinzanetant 120mg (N=&trt1.)" ;
    label str2 = "Placebo - Elinzanetant 120mg (N=&trt2.)" ;

    if AVIST = "Baseline"  then vstrow = 1 ;
    if AVIST = "Post Baseline"  then vstrow = 2 ;
if AVIST = "Post Baseline"  then  AVIST = "At any time post-baseline"  ;
if Ord_og = . and _varl_ not in  ('', "n", "Category")  then delete   ;
RUN;

data all;
    length _varl_1 $200. ;
    set all ;
    *label _varl_1    = '00'x  ;
    label _varl_1    = ' '   ;
   _varl_1 =  strip(_varl_) ;
   if _varl_1  =  strip(">=10xULN") then _varl_1  = ">=10 x ULN" ;
   if _varl_1  =  strip(">=20xULN") then _varl_1  = ">=20 x ULN" ;
   if _varl_1  =  strip(">=5xULN")  then _varl_1  = ">=5 x ULN" ;
   if _varl_1  =  strip(">=8xULN")  then _varl_1  = ">=8 x ULN" ;
   if _varl_1  =  strip(">=2xULN")  then _varl_1  = ">=2 x ULN" ;
   if _varl_1  =  strip(">=3xULN")  then _varl_1  = ">=3 x ULN" ;

   if _type_ > 2 then  _varl_1 ='   ' !! strip(_varl_1);
RUN;

%datalist(
    data     = all
  , by       = vstrow AVIST row  Para  _TYPE_
  , var      =  _varl_1   STR1 STR2
  , order    = _TYPE_  row vstrow
  , freeline = Para
  , together = Para
  , hb_align = Left
  , label    = N
) ;

%endprog;