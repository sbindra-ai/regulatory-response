/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
%iniprog(name = t_adsl_iss_demo)
;
/*
 * Purpose          : Demographics <<overall/by race/by ethnicity/by BMI>> (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        :  erjli (Yosia Hadisusanto) / date: 04MAR2024
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 27MAR2024
 * Reason           : Change title: by body mass index group (kg/m2)
 ******************************************************************************/
/* Changed by       : eqczz (Petri Pulkkinen) / date: 05APR2024
 * Reason           : BMI in group variable label changed to Body Mass Index
 ******************************************************************************/

%LET mosto_param_class = %scan(&extend_var_disp_12_52_a., 1, '@');

%load_ads_dat(adsl_view, adsDomain = adsl)
%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_12_52_a.
  , extend_rule = &extend_rule_disp_12_52_a.
)

DATA adsl_ext;
    SET adsl_ext;
    ATTRIB sex_out FORMAT = $200.   LABEL = "%varlabel(adsl_ext, sex)";
    ATTRIB country_c LENGTH = $200  LABEL = "%varlabel(adsl_ext, country)";
    ATTRIB racen                    LABEL = "%varlabel(adsl_ext, race)";
    ATTRIB ethnicn                  LABEL = "%varlabel(adsl_ext, ethnic)";
    ATTRIB edulvn                   LABEL = "%varlabel(adsl_ext, edulevel)";
    ATTRIB agegr1n                  LABEL = "Age group (years)";
    ATTRIB age                      LABEL = "Age (years)";
    ATTRIB bmigr1n LABEL = "Body Mass Index group (kg/m2)";
    FORMAT weightbl heightbl bmibl 8.1;
    sex_out = put(input(sex, sex.), sex.);
    country_c = put(country, $country.);

    FORMAT smokhxn _smk.;
    FORMAT edulvn _edu.;
    FORMAT racen _race.;
    FORMAT ethnicn _ethnic.;
    %M_PropIt(Var = race)
    %M_PropIt(Var = ethnic)
    IF race_prop NE ' ' THEN DO;
        racen = input(strip(put(RACE_PROP, $_race.)), 3.) ;
    END;
    ethnicn = input(strip(put(ETHNIC_PROP, $_ethnic.)),3.) ;
    edulvn = input(strip(put(upcase(edulevel), $_edu.)), 3.) ;
RUN;

%MACRO m_demo(
       class_title  =
     , class        = &mosto_param_class.
     , total        = NO
     , subject      = &subj_var.
);

    %set_titles_footnotes(
        tit1 = "Table: Demographics &class_title. &saf_label."
      , ftn1 = "SD = Standard Deviation"
    )
    %desc_freq_tab(
        data              = adsl_ext
      , var               = sex_out     /*Sex*/
                            %IF %lowcase(&class.) NE racen   %THEN %DO; racen    %END;    /*Race*/
                            %IF %lowcase(&class.) NE ethnicn %THEN %DO; ethnicn  %END;    /*Ethnicity*/
                            country_c   /*Country/Region*/
                            age         /*Age (units)*/
                            agegr1n     /*Age group (years)*/
                            weightbl    /*Weight (kg)*/
                            heightbl    /*Height (cm)*/
                            bmibl       /*Body mass index (kg/m2)*/
                            %IF %lowcase(&class.) NE bmigr1n %THEN %DO; bmigr1n  %END;   /*BMI group (kg/m2)*/
                            smokhxn     /*Smoking history*/
                            edulvn      /*Level of education (group)*/
      , data_n            = adsl_ext
      , outdat            = demo_out
      , harmonized_outdat = NO
      , basepct           = N_CLASS
      , complete          = NONE
      , misstext          = Missing
      , class             = &class.
      , total             = &total.
      , subject           = &subject.

    )

    %mosto_param_from_dat(data = demo_outinp, var = config)
    %datalist(&config)

%MEND m_demo;

%m_demo()

%LET MOSTOCALCPERCWIDTH  = NO;
%insertOptionRTF(namevar = text, width = 29mm, keep = n, overwrite = n)
%insertOptionRTF(namevar = col1, width = 23mm, keep = n, overwrite = n)
%insertOptionRTF(namevar = col2, width = 22mm, keep = n, overwrite = n)
%insertOptionRTF(namevar = col3, width = 21mm, keep = n, overwrite = n)
%insertOptionRTF(namevar = col4, width = 22mm, keep = n, overwrite = n)
%insertOptionRTF(namevar = col5, width = 22mm, keep = n, overwrite = n)
%insertOptionRTF(namevar = col6, width = 22mm, keep = n, overwrite = n)
%insertOptionRTF(namevar = col7, width = 21mm, keep = n, overwrite = n)
%insertOptionRTF(namevar = col8, width = 22mm, keep = n, overwrite = n)
%insertOptionRTF(namevar = col9, width = 23mm, keep = n, overwrite = n)

%m_demo(class = racen  , class_title = by %lowcase(%varlabel(adsl_ext, racen)), total = YES, subject = usubjid_ori)

%LET MOSTOCALCPERCWIDTH  = OPTIMAL;
%m_demo(class = ethnicn  , class_title = by %lowcase(%varlabel(adsl_ext, ethnicn)), total = YES, subject = usubjid_ori)
%m_demo(class = bmigr1n  , class_title = by body mass index group (kg/m2), total = YES, subject = usubjid_ori)


%endprog()



