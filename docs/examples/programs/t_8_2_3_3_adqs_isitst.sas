/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_2_3_3_adqs_isitst ,print2file = y );

/*
 * Purpose          : Transitions from baseline in Severity ISI categories by time: number of subjects (full analysis set)
 * Programming Spec :
 * Validation Level : 1 - Validation by programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 27JUL2023
 * Reference prog   :
 *****************************************************************************/

%load_ads_dat(adqs_view  , adsDomain = adqs , adslWhere =  &fas_cond. );
%load_ads_dat(adsl_view   , adsDomain = adsl  , where     = &fas_cond. );

%extend_data(indat = adqs_view , outdat = adqs );
%extend_data(indat = adsl_view  , outdat = adsl) ;

data adqs ;
    set adqs  ;

    where paramcd = "ISIB0999" and parcat1 = "ISI"
          and not missing(avisitn)
          and avisitn in (5, 40 ,80,120,160,260 , 700000 )
          and ANL04FL="Y"  ;

   avaln = aval *1 ;
  *  aval_n   = input( strip(put( avalc ,  $&formtn.  )) ,  3. ) ;
  * format aval_n  &formtn.;

    attrib  avalc   label = "Severity ISI categories"
           avisitn  label = "Visit"
           &treat_arm_p  label ='00'x
           ;
run;

proc sort data = adqs_view out = adqs_dup (keep =     AVALCA1N) nodupkey ;
    by     AVALCA1N ;
    where paramcd = "ISIB0999" and parcat1 = "ISI" ;
RUN;

%MTITLE;

 %shift_tab(
     data          = adqs
   , data_n        = adsl
   , var           = AVALCA1N
   , subject       = usubjid
   , by            = avisitn
   , data_n_ignore = avisitn
   , class         = trt01pn
   , order         = AVALCA1N
   , baseline      = avisitn=5
   , freeline      = trt01pn
   , maxlen        = 18
 );


%endprog;;