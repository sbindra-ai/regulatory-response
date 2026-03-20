/*******************************************************************************
 * Bayer AG
 * Study            : 21810 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 52 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_3_5_6_adlb_frq);
/*
 * Purpose          : Laboratory data: Number of subjects by <<LAB CATETOGY, category>> and  visit  ";
 * Programming Spec : 21810_tlf_v1.0.docx
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emzah (Rakesh Muppidi) / date: 20OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_3_5_6_adlb_frq.sas (emvsx (Phani Tata) / date: 02OCT2023)
 ******************************************************************************/

        %macro  prcat(  par = );


        %load_ads_dat(
            adlb_view
          , adsDomain = adlb
          , adslWhere = &saf_cond
          , adslVars  = SAFFL FASFL trt01an
        );

        %load_ads_dat(adsl_view , adsDomain = adsl , where =  &fas_cond )


        %extend_data(indat = adlb_view , outdat = adlb )
        %extend_data(indat = adsl_view  , outdat = adsl) ;


        data adlb  ;
             set adlb  ;
             where PARCAT1 = "URINALYSIS" and
                   not missing(paramcd) and
                   anl01fl = "Y"
                   and      avisitn in(5,520,600000,700000)
                   and paramcd in ("&par.") ;
             %M_PropIt(Var=parcat1);*changing Parcat1 to sentence case*;
             parcat1 = parcat1_prop ;
        label avalc= "Parameter";
        run;


        PROC SORT DATA=adlb
             OUT=tby (KEEP= paramcd  paramn parcat1)  nodupkey;
            BY parcat1 paramn ;
        RUN;

        %MTITLE;

        %freq_tab(
            data     = adlb
          , data_n   = adsl
          , var      = avalc
          , subject  = &subj_var.
          , page     = paramcd parcat1 paramn
          , by       = avisitn
          , order    =  paramcd parcat1 paramn
          , class    = &treat_var
          , hlabel   = Yes
          , missing  = NO
          , tablesby = tby
          , layout   = MINIMAL_BY
          , total    = NO
          , data_n_ignore       =   paramcd parcat1 paramn
        );

        %mend prcat;



        %prcat( par = UPH   );
        %prcat( par = UUROBIL   );
        %prcat( par = BLOOD   );
        %prcat( par = UPRO   );
        %prcat( par = KETONE   );
        %prcat( par = UBILI   );
        %prcat( par = NITRITE   );
        %prcat( par = UGLU   );
        %prcat( par = U_WBCC   );


        /*clean up*/
        %endprog;
