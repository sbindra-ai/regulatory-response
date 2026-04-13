/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_2_3_4_adqs_pgic );
/*
 * Purpose          : PGI-C Number of subjects by treatment group (FAS)
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 27NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/t_8_2_3_4_adqs_pgic.sas (emvsx (Phani Tata) / date: 25SEP2023)
 ******************************************************************************/

%macro  par (par = ,  formtn   =   );

%load_ads_dat(adqs_view, adsDomain = adqs , adslWhere =  &fas_cond );
%load_ads_dat(adsl_view   , adsDomain = adsl  , where  = &fas_cond );

%extend_data(indat = adqs_view , outdat =  adqs  );
%extend_data(indat = adsl_view  , outdat = adsl) ;

data adqs ;
    set adqs  ;
    where   paramcd in ( "&par.") and
            parcat1 = "PATIENT GLOBAL IMPRESSION VASOMOTOR SYMPTOMS V1.0"
                and avisitn in (40 ,80,120,160,260 , 700000 )
                and anl04fl = "Y" ;

    aval_n   = input( strip(put( avalc ,  $&formtn.  )) ,  3. ) ;
    format aval_n  &formtn.;

    attrib  &treat_var  label = "Treatment group"
           paramcd   label = "PGI-C"
           avisitn  label = "Time";
        ** round AVAL BASE and CHG **;
      %put  ***Treatment variable is ****&treat_arm_p**********;

run;

proc sort data = adqs out = tby (keep = paramcd ) nodupkey;
    by paramcd ;
run;

%MTITLE;

%freq_tab(
    data          = adqs
  , data_n        = adsl
  , var           = aval_n
  , subject       = &subj_var.
  , page          = paramcd
  , by            = avisitn
  , data_n_ignore = paramcd
  , total         = NO
  , class         = &treat_arm_p
  , hlabel        = Yes
  , missing       = NO
  , tablesby      = TBY
  , layout        = MINIMAL_BY
  , order         = paramcd
);
%MEND;


%par (par = PGVB104, formtn =   _pgicmsf.  );
%par (par = PGVB105, formtn =   _pgicssf.  );
%par (par = PGVB106, formtn =   _pgicssf.   );

%endprog;
