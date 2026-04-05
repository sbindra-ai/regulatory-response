/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adsl_ise_demo);
/*
 * Purpose          : Create table: Demographics <<overall/by region/by race/by ethnicity/by BMI/by Smoking history>> (full analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gltlk (Rui Zeng) / date: 07DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_1_4_adsl_demo_ovrl.sas (enpjp (Prashant Patel) / date: 09NOV2023)
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 13FEB2024
 * Reason           : Use BMI label as in adsmeta.adsl
 ******************************************************************************/

%LET mosto_param_class = &mosto_param_class_eff.;

%load_ads_dat(adsl_view, adsDomain = adsl, where = &fas_cond.)

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_eff.
  , extend_rule = &extend_rule_disp_eff.
);

DATA adsl_ext;
    SET adsl_ext;
    ATTRIB sex_out FORMAT = $200. LABEL = "%varlabel(adsl_ext, sex)";
    FORMAT weightbl heightbl bmibl 8.1;
    sex_out = put(input(sex, sex.), sex.);

    format smokhxn _smk.;
    format edulvn _edu.;
    format racen _race.;
    format ethnicn _ethnic.;
    label agegr1n= "Age group"
          age = "Age (years)"
          sex="Sex"
/*          region1n="Region"*/
      RACEN="Race"
      ETHNICN="Ethnicity"
      edulvn="Level of Education";
    %M_PropIt(Var=race);
    %M_PropIt(Var=ethnic);
    if race_prop ne ' ' then do;
        racen = input(strip(put(RACE_PROP, $_race.)), 3.) ;
    end;
    ethnicn = input(strip(put(ETHNIC_PROP, $_ethnic.)),3.) ;
    edulvn = input(strip(put(upcase(edulevel), $_edu.)), 3.) ;
RUN;

%MACRO m_demo(by=, by_title=);

    %set_titles_footnotes(
        tit1 = "Table: Demographics &by_title.&fas_label."
      , ftn1 = "&foot_placebo_ezn."
      , ftn2 = "&foot_sd."
    )

    %desc_freq_tab(
        data     = adsl_ext
      , var      = sex_out  /*Sex*/
                   racen    /*Race*/
                   ethnicn  /*Ethnicity*/
                   age      /*Age (units)*/
                   agegr1n  /*Age group (years)*/
                   weightbl /*Weight (kg)*/
                   heightbl /*Height (cm)*/
                   bmibl    /*Body mass index (kg/m2)*/
                   bmigr1n  /*BMI group (kg/m2)*/
                   smokhxn  /*Smoking history*/
                   edulvn  /*Level of education (group)*/
      , data_n   = adsl_ext
      , page     = &by.
      , outdat   = demo_out
      , basepct  = N_CLASS
      , complete = NONE
      , total    = YES
      , misstext = Missing
    )

    ** Remove var in the table if the table is subgroup by the same var;
    DATA demo_out;
        SET demo_out;
        IF upcase(_var_) NE %upcase("&by.");
    RUN;

    %mosto_param_from_dat(data = demo_outinp, var = config)
    %datalist(&config)

%MEND m_demo;

%m_demo()

%m_demo(by=region1n, by_title = by %lowcase(%varlabel(adsl_ext, region1n))%str( ))
%m_demo(by=racen  , by_title = by %lowcase(%varlabel(adsl_ext, race))%str( ))
%m_demo(by=ethnicn , by_title = by %lowcase(%varlabel(adsl_ext, ethnic))%str( ))
%m_demo(by=bmigr1n, by_title = by %varlabel(adsl_ext, bmigr1n)%str( ))
%m_demo(by=smokhxn, by_title = by %lowcase(%varlabel(adsl_ext, smokhxn))%str( ))

%endprog;