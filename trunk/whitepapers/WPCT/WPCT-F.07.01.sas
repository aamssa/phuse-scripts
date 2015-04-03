/***

    White paper: Central Tendencies
    Display:     Figure 7.1 Box plot - Measurements by Analysis Timepoint, Visit and Planned Treatment

    page:  http://www.phusewiki.org/wiki/index.php?title=Scriptathon2014_targets
    image: http://www.phusewiki.org/wiki/index.php?title=File:CSS_WhitePaper_CentralTendency_f7_1.jpg

    Description: Boxplot of AVAL by ATPTN, AVISITN and TRTPN. See plot footnote for boxplot details.
    Dataset:     ADVS
    Variables:   USUBJID SAFFL TRTP TRTPN PARAM PARAMCD AVAL ANRLO ANRHI ANL: AVISIT AVISITN ATPT ATPTN
    Filter:      Measurements flagged for analysis within safety population
                 WHERE SAFFL='Y' and ANL01FL='Y'
    Notes:       � Program box plots all visits, ordered by AVISITN, with maximum of 20 boxes on a page
                   + see user option MAX_BOXES_PER_PAGE, below, to change 20 per page
                 � Program separately plots all parameters in PARAMCD
                 � Measurements within each PARAMCD and ATPTN determine precision of stats
                   + MEAN gets 1 extra decimal, STD DEV gets 2 extra decimals
                   + see macro UTIL_VALUE_FORMAT to adjust this behavior
                 � If your treatment names are too long for the summary table,
                   Change TRTP in the input data, and add a footnote that explains your short Tx codes
    TO DO:
      � Complete and confirm specifications (see Outliers & Reference limit discussions, below)
      � Move confirmed specifications to a separate document that can be referenced by the Repository Interface
          http://www.phusewiki.org/wiki/index.php?title=Standard_Script_Index
      � Set uniform y-axis scale for all pages of a plot, based on MAX measured value for PARAMCD and ATPTN
      � Color outliers RED:
          - Confirm outlier logic as either
              (1) outside normal ranges, 
              (2) outside interquartile ranges, or
              (3) user option
          - Indicate measures that are OUTSIDE NORMAL RANGES
          - Update specifications and dependency checking accordingly
            EG, to include ANRLO and ANRHI in dependencies and program logic
      � Reference limit lines. Provide options for several scenarios (see explanation in White Paper):
          - NONE:    DEFAULT. no reference lines
          - UNIFORM: reference limits are uniform for entire population
                     only display uniform ref lines, to match outlier logic, otherwise no lines
                     NB: preferred alternative to default (NONE)
          - NARROW:  reference limits vary across selected population (e.g., based on some demographic or lab)
                     display reference lines for the narrowest interval
                     EG: highest of the low limits, lowest of the high limits
                     NB: discourage, since creates confusion for reviewers
          - ALL:     reference limits vary across selected population (e.g., based on some demographic or lab)
                     display all reference lines, pairing low/high limits by color and line type
                     NB: discourage, since creates confusion for reviewers

***/



  /*** USER SETTINGS
    PHUSE_PATH: REQUIRED.
      These templates require the PhUSE/CSS macro utilities:
        https://github.com/phuse-org/phuse-scripts/tree/master/whitepapers/utilities
      User must ensure that SAS can find PhUSE/CSS macros in the SASAUTOS path (see EXECUTE ONE TIME, below)

    LIBNAME statement, assign only as needed to point to your data
      M_LB: REQUIRED. Libname containing ADaM data (measurements data such as ADVS)
      M_DS: REQUIRED. Measuments data set, typically ADVS
      P_FL: REQUIRED. Population flag variable. 'Y' indicates record in pop of interest.
      A_FL: REQUIRED. Analysis Flag variable.   'Y' indicates that record is selected for analysis.

    MAX_BOXES_PER_PAGE: Maximum number of boxes to display per plot page (see specs at top)  
  ***/


    /*** EXECUTE ONE TIME only as needed

      Ensure PhUSE/CSS utilities are in the AUTOCALL path
      NB: This line is not necessary if PhUSE/CSS utilities are in your default AUTOCALL paths

      OPTIONS sasautos=(%sysfunc(getoption(sasautos)) "C:\_Offline_\CSS\phuse_code\whitepapers\utilities");

    ***/

    %*--- ACCESS PhUSE/CSS test data, and create work copy with prefix "CSS_" ---*;
      %util_access_test_data(advs)

    *--- USER SUBSET of data, to limit number of box plot outputs, and to shorten Tx labels ---*;
      data advs_sub (rename=(trtp_short=trtp));
        set css_advs;
        where (paramcd in ('DIABP') and atptn in (815)) or 
              (paramcd in ('SYSBP') and atptn in (816));

        length trtp_short $6;
        select (trtp);
          when ('Placebo') trtp_short = 'P';
          when ('Xanomeline High Dose') trtp_short = 'X-high';
          when ('Xanomeline Low Dose')  trtp_short = 'X-low';
          otherwise trtp_short = 'UNEXPECTED';
        end;

        drop trtp;
      run;
    *--- END user subset of data to limit plots ---*;


    %let m_lb = work; 
    %let m_ds = advs_sub;
    %let p_fl = saffl;
    %let a_fl = anl01fl;

    %let max_boxes_per_page = 20;

  /*** END user settings. 
    RELAX. 
    The rest should simply work, or alert you to invalid conditions.
  ***/



  /*** SETUP & CHECK DEPENDENCIES
    Explain to user in case environment or data do not support this analysis

    Keep just those variables and records required for this analysis
    For details, see specifications at top
  ***/

    options nocenter mautosource mrecall mprint msglevel=I mergenoby=WARN
            syntaxcheck dmssynchk obs=MAX ls=max ps=max;
    goptions reset=all;
    ods show;

    %let ana_variables = USUBJID SAFFL TRTP TRTPN PARAM PARAMCD AVAL ANRLO ANRHI &a_fl AVISIT AVISITN ATPT ATPTN;

    *--- Restrict analysis to SAFETY POP and ANALYSIS RECORDS (&a_fl) ---*;
      data css_anadata;
        set &m_lb..&m_ds (keep=&ana_variables);
        where &p_fl = 'Y' and &a_fl = 'Y';
      run;

    %let CONTINUE = %assert_depend(OS=%str(AIX,WIN,HP IPF),
                                   SASV=9.2+,
                                   vars=%str(css_anadata : &ana_variables),
                                   macros=assert_continue util_labels_from_var util_count_unique_values 
                                          util_value_format util_prep_shewhart_data
                                  );

    %assert_continue(Following assertion of dependencies)


  /*** GATHER INFO for data-driven processing
    Collect required information about these measurements:

    Number, Names and Labels of PARAMCDs - used to cycle through parameters that have measurements
      &PARAMCD_N count of parameters
      &PARAMCD_VAL1 to &&&PARAMCD_VAL&PARAMCD_N series of parameter codes
      &PARAMCD_LAB1 to &&&PARAMCD_LAB&PARAMCD_N series of parameter labels

    Number of planned treatments - used for handling treatments categories
      &TRTN

  ***/

    %*--- Parameters: Number (&PARAMCD_N), Names (&PARAMCD_NAM1 ...) and Labels (&PARAMCD_LAB1 ...) ---*;
      %util_labels_from_var(css_anadata, paramcd, param)

    %*--- Number of planned treatments: &TRTN ---*;
      %util_count_unique_values(css_anadata, trtp, trtn)


  /*** BOXPLOT for each PARAMETER and ANALYSIS TIMEPOINT in selected data
    PROC SHEWHART creates the summary table of stats from "block" (stats) variables
                  and reads "phases" (visits) from a special _PHASE_ variable

    One box plot for each PARAMETER and ANALYSIS TIMEPOINT.
    By Visit and Planned Treatment.

    In case of many visits and planned treatments, each box plot will use multiple pages.
  ***/

    %macro boxplot_each_param_tp(plotds=css_anadata);
      %local pdx tdx;

      %do pdx = 1 %to &paramcd_n;
        *--- Work with one PARAMETER, but start with ALL TIMEPOINTS ---*;
          data css_nextparam;
            set &plotds (where=(paramcd = "&&paramcd_val&pdx"));
          run;

        %*--- Analysis Timepoints for this parameter: Num (&ATPTN_N), Names (&ATPTN_NAM1 ...) and Labels (&ATPTN_LAB1 ...) ---*;
          %util_labels_from_var(css_nextparam, atptn, atpt)

        %do tdx = 1 %to &atptn_n;

          *--- Work with just one TIMEPOINT for this parameter, but ALL VISITS ---*;
          *--- NB: PROC SORT here is REQUIRED, in order to merge on STAT details, below ---*;
            proc sort data=css_nextparam (where=(atptn = &&atptn_val&tdx))
                       out=css_nexttimept;
              by avisitn trtpn;
            run;

          %*--- Number of visits for this parameter and analysis timepoint: &VISN ---*;
            %util_count_unique_values(css_nexttimept, avisitn, visn)

          %*--- Create format string to display MEAN and STDDEV to default sig-digs: &UTIL_VALUE_FORMAT ---*;
            %util_value_format(css_nexttimept, aval)



          /*** TO DO
            With just these data selected for analysis and display
            - Y-AXIS SCALE:       Determine uniform min/max for y-axis
            - REF LIMIT OUTLIERS: Determine outlier values, based on Reference limits
            - REF LIMIT LINES:    Determine whether to include reference lines
          ***/



          *--- Calculate summary statistics, and merge onto measurement data for use as "block" variables ---*;
            proc summary data=css_nexttimept noprint;
              by avisitn trtpn;
              var aval;
              output out=css_stats (drop=_type_) 
                     n=n mean=mean std=std median=median min=min max=max q1=q1 q3=q3;
            run;

            *--- Reminder: PROC SHEWHART reads "phases" (visits) from a special _PHASE_ variable ---*;
            data css_plot (rename=(avisit=_PHASE_));
              merge css_nexttimept (in=in_paramcd)
                    css_stats (in=in_stats);
              by avisitn trtpn;
              label n      = 'n'
                    mean   = 'Mean'
                    std    = 'Std Dev'
                    min    = 'Min'
                    q1     = 'Q1'
                    median = 'Median'
                    q3     = 'Q3'
                    max    = 'Max';
            run;

          /*** Create TIMEPT var, Calculate visit ranges for pages
            TIMEPT variable controls the location of by-treatment boxes along the x-axis
            Create symbol BOXPLOT_TIMEPT_RANGES, a |-delimited string that groups visits onto pages
              Example of BOXPLOT_TIMEPT_RANGES: 0 <= timept <7|7 <= timept <12|
          ***/

            %util_prep_shewhart_data(css_plot, 
                                     vvisn=avisitn, vtrtn=trtpn, vtrt=trtp, vval=aval,
                                     numtrt=&trtn, numvis=&visn)


          *--- Graphics Settings ---*;
            options orientation=landscape;
            goptions reset=all hsize=14in vsize=7.5in;

            title     justify=left height=1.2 "Box Plot - &&paramcd_lab&pdx by Visit, Analysis Timepoint: &&atptn_lab&tdx";
            footnote1 justify=left height=1.0 'Box plot type=schematic, the box shows median, interquartile range (IQR, edge of the bar), min and max';
            footnote2 justify=left height=1.0 'within 1.5 IQR below 25% and above 75% (ends of the whisker). Values outside the 1.5 IQR below 25% and';
            footnote3 justify=left height=1.0 'above 75% are shown as outliers. Means plotted as different symbols by treatments.';
            axis1     value=none label=none major=none minor=none;


          *--- PDF output destination ---*;
            ods pdf file="Box_plot_&&paramcd_val&pdx.._by_visit_for_timepoint_&&atptn_val&tdx...pdf";

          *--- FINALLY, A Graph - Multiple pages in case of many visits/treatments ---*;
            %local vdx nxtvis;
            %let vdx=1;
            %do %while (%qscan(&boxplot_timept_ranges,&vdx,|) ne );
              %let nxtvis = %qscan(&boxplot_timept_ranges,&vdx,|);

              proc shewhart data=css_plot_tp (where=( &nxtvis ));
                boxchart aval*timept (max q3 median q1 min std mean n trtp) = trtp /
                         boxstyle=schematic
                         notches
                         stddeviations
                         nolegend
                         ltmargin = 5
                         blockpos = 3
                         blocklabelpos = left
                         blocklabtype=scaled
                         blockrep
                         haxis=axis1
                         idsymbol=dot
                         idcolor=red
                         nolimits
                         readphase = all
                         phaseref
                         phaselabtype=scaled
                         phaselegend;

                label aval    = "&&paramcd_lab&pdx"
                      timept  = 'Visit'
                      trtp    = 'Treatment'
                      n       = 'n'
                      mean    = 'Mean'
                      std     = 'Std'
                      median  = 'Median'
                      min     = 'Min'
                      max     = 'Max'
                      q1      = 'Q1'
                      q3      = 'Q3';
                format mean %scan(&util_value_format, 1, %str( )) std %scan(&util_value_format, 2, %str( ));
              run;

              %let vdx=%eval(&vdx+1);
            %end;

          *--- Release the PDF output file! ---*;
            ods pdf close;

        %end; %*--- TDX loop ---*;

      %end; %*--- PDX loop ---*;

      *--- Clean up temp data sets required to create box plots ---*;
        proc datasets library=WORK memtype=DATA nolist nodetails;
          delete css_plot css_plot_tp css_nextparam css_nexttimept css_stats;
        quit;

    %mend boxplot_each_param_tp;
    %boxplot_each_param_tp;

  /*** END boxplotting ***/
