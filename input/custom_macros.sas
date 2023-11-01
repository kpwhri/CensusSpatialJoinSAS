* Macro to fetch states;
%macro get_states();
    %global state_list statename_list;
        * AL  01  ALABAMA;
        * AK  02  ALASKA;
        * AZ  04  ARIZONA;
        * AR  05  ARKANSAS;        
        * CA  06  CALIFORNIA;
        * CO  08  COLORADO;
        * CT  09  CONNECTICUT;
        * DC  11  DISTRICT OF COLUMBIA;
        * DE  10  DELAWARE;
        * FL  12  FLORIDA;
        * GA  13  GEORGIA;
        * HI  15  HAWAII;
        * ID  16  IDAHO;
        * IL  17  ILLINOIS;
        * IN  18  INDIANA;
        * IA  19  IOWA;
        * KS  20  KANSAS;
        * KY  21  KENTUCKY;
        * LA  22  LOUISIANA;
        * ME  23  MAINE;
        * MD  24  MARYLAND;
        * MA  25  MASSACHUSETTS;
        * MI  26  MICHIGAN;
        * MN  27  MINNESOTA;
        * MS  28  MISSISSIPPI;
        * MO  29  MISSOURI;
        * MT  30  MONTANA;
        * NE  31  NEBRASKA;
        * NV  32  NEVADA;
        * NH  33  NEW HAMPSHIRE;
        * NJ  34  NEW JERSEY;
        * NM  35  NEW MEXICO;
        * NY  36  NEW YORK;
        * NC  37  NORTH CAROLINA;
        * ND  38  NORTH DAKOTA;
        * OH  39  OHIO;
        * OK  40  OKLAHOMA;
        * OR  41  OREGON;
        * PA  42  PENNSYLVANIA;
        * RI  44  RHODE ISLAND;
        * SC  45  SOUTH CAROLINA;
        * SD  46  SOUTH DAKOTA;
        * TN  47  TENNESSEE;
        * TX  48  TEXAS;
        * UT  49  UTAH;
        * VA  51  VIRGINIA;
        * VT  50  VERMONT;
        * WA  53  WASHINGTON;
        * WI  55  WISCONSIN;
        * WV  54  WEST VIRGINIA;
        * WY  56  WYOMING;
    * Puerto Rico sometimes has data, but the other territories not so much.;
    * 64 - Federated States of Micronesia;
    * 66 - Guam;
    * 68 - Marshall Islands;
    * 69 - Northern Mariana Islands;
    * 70 - Palau;
    * 72 - Puerto Rico;
    * 78 - Virgin Islands of the US;
    %let state_list = 01 02 04 05 06 08 09 10 11 12 13 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 44 45 46 47 48 49 50 51 53 54 55 56;
%mend get_states;

* create a macro to extract the contents of a zip file;
%macro extract_file_from_zip(unzip_fileref, file_to_unzip, dest_dir);
    /* hat tip: "data _null_" on SAS-L */
    data _null_;
       /* using member syntax here */
        filename want "&dest_dir./&file_to_unzip." ;
        infile &unzip_fileref(&file_to_unzip) 
        lrecl=256 recfm=F length=length eof=eof unbuf;
        file want lrecl=256 recfm=N;
        input;
        put _infile_ $varying256. length;
        return;
     eof:
       stop;
    run;
%mend;

%macro fetch_shapefile(year, state, geolevel, dest_dir);
    %* Define global variables;
    *input year and state;
    * set macro variable year; 
    * set macro variable state; 
    * set macro variable suf as the last two characters of the year.;     
    * create an a filename reference _shzip in the target directory.;
    %global _tmp_shp suf zip_dir;
    %let geolevel_up = %sysfunc(upcase(&geolevel.));
    %if %eval((&year. = 2000) or (&year. = 2010)) %then %do;
        %let suf = %sysfunc(substr(&year.,3,2));
        %let fileyr = 2010;
        %let url="https://www2.census.gov/geo/tiger/TIGER&fileyr./&geolevel_up./&year./tl_&fileyr._&state._&geolevel.&suf..zip";
    %end;
    %else %if &year. = 2020 %then %do;
        %let suf = ;
        %let fileyr = 2020;
        %let url="https://www2.census.gov/geo/tiger/TIGER&fileyr./&geolevel_up./tl_&fileyr._&state._&geolevel..zip";
    %end;
    %else %do;
        %put ERROR: year must be 2000, 2010, or 2020.;
    %end;
    
    %put INFO: Querying &url.;
    %put INFO: Destination directory: &dest_dir.;

    %let zip_dir = &dest_dir.;
    %let zip_shp = &zip_dir./tl_&fileyr._&state._&geolevel.&suf..zip;

    filename _shzip "&zip_shp.";

    proc http
        url=&url.
        out=_shzip
        method='get'
        ; 
    run;
    filename uz_shape zip "&zip_shp.";

    %let _tmp_dbf = tl_&fileyr._&state._&geolevel.&suf..dbf;
    %let _tmp_prj = tl_&fileyr._&state._&geolevel.&suf..prj;
    %let _tmp_shp = tl_&fileyr._&state._&geolevel.&suf..shp;
    %let _tmp_xml = tl_&fileyr._&state._&geolevel.&suf..shp.xml;
    %let _tmp_shx = tl_&fileyr._&state._&geolevel.&suf..shx;

    %* do we need to extract everything? How about just the shp file?;
    %put INFO: unpacking the shp, prj, and shx files.;
    %extract_file_from_zip(uz_shape,&_tmp_shp.,&dest_dir.);
    %extract_file_from_zip(uz_shape,&_tmp_dbf.,&dest_dir.);
    %extract_file_from_zip(uz_shape,&_tmp_prj.,&dest_dir.);
    %extract_file_from_zip(uz_shape,&_tmp_shx.,&dest_dir.);
    %* %extract_file_from_zip(uz_shape,&_tmp_xml., &dest_dir.); *NOTE: Does not appear to be necessary to have XML;
%mend fetch_shapefile;


%macro spatial_join(inds, outds, shapefile, year, geolevel=tract);
    filename _shp "&shapefile.";
    %let suf = %sysfunc(substr(&year.,3,2));
    %put INFO: shapefile = &shapefile.;
    %put INFO: year = &year.;
    %put INFO: geolevel = &geolevel.;

    %if &suf. = %str(00) %then %do;
        %if &geolevel. = tract %then %do;            
            %let geoid = CTIDFP00;      
            %put INFO: GEOID = &geoid.;      
        %end;
        %else %if &geolevel. = bg %then %do;
            %let geoid = BKGPIDFP00;
        %end;
        %let select_st = select aland&suf. awater&suf. &geoid.;
        %let rename_st = rename 
            aland&suf. = aland
            awater&suf. = awater
            &geoid. = GEOID
            ;
    %end;

    %else %if &suf = 10 %then %do;
        %let geoid = geoid&suf.;
        %let select_st = select aland&suf. awater&suf. &geoid.;
        %let rename_st = rename 
            aland&suf. = aland
            awater&suf. = awater
            &geoid. = GEOID
            ;
    %end;
    %else %if &suf. = 20 %then %do;
        %let select_st = select aland awater geoid;
        %let rename_st = ;
    %end;

    proc mapimport datafile=_shp out=tmp_map;
        &select_st.;
        &rename_st.;
    run;

    proc ginside 
        data= &inds.
        map = tmp_map
        out = &outds.;
        id geoid;
    run;

    data &outds.;
        set &outds.;
        if missing(geoid) then delete;
    run;    
%mend;

%macro base_append( inds                    /*The dataset we will append to the dataset. */
                    ,basetable=basetable    /*Just the name of the base table to house the raw counts. It could be named anything */
                    ,new_basetable=true     /*Set to false if you have a structure and just need to append data. */
                    );
    %if &new_basetable. = true %then %do;
    %put INFO: creating a new base table: &basetable..;
    proc sql;
        create table &basetable. like &inds.;
    quit;
    %end;
    %else %do;
    %put INFO: not creating a new base table.;
    %end;
    %put INFO: Appending to &basetable..;
    proc datasets library=work nolist;
        append base=&basetable. data=&inds.;
    run;
%mend base_append;

%macro sj_pipeline(inds, outds, year=, geolevel=tract, temp_dir=, base_setup=true);
    %get_states();
    %do i=1 %to %sysfunc(countw(&state_list));
        %let next_state = %scan(&state_list, &i);
        %put INFO: Retrieving state=&next_state..;
        %** Fetch the &next_state;
        %fetch_shapefile(&year, &next_state, &geolevel., &temp_dir.);
        %* Perform a spatial join;
        %spatial_join(&inds., _sj_tmp,&temp_dir./&_tmp_shp., &year, geolevel=&geolevel);
        %put INFO: base_setup = &base_setup..;
        %base_append(_sj_tmp, basetable=_sj_tmp, new_basetable=&base_setup.);
        %let base_setup = false;
        data &outds.;
            set _sj_tmp;
        run;
    %end;   
%mend;