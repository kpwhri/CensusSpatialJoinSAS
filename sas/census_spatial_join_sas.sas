************************************************************************************
Census SAS Spatial Join
************************************************************************************

Program Name:     census_spatial_join_sas.sas      
Contacts:         Alphonse.Derus@kp.org

Purpose: This code will do the following:
    1. read a dataset containing projected X,Y coordinates
    2. download related shapefiles from the US Census Bureau
    3. join the shapefiles to the dataset
    4. create a new dataset containing the joined data
;
************************************************************************************
PROGRAM DETAILS
************************************************************************************

Dependencies :
 
Other Files:  
    

-------------------------------------------------------------------------------------- 
input:
    1    custom_macros.sas

-------------------------------------------------------------------------------------- 
local_only: 
SAS List file to remain at your site - DO NOT SEND
Number of files created in this folder = [Varies]

-------------------------------------------------------------------------------------- 
share:    
Number of shared SAS Datasets created: 
Output SAS data sets to be shared outside your site: 

;

ods listing close;

*--------------------------------------------
SITE EDITS
---------------------------------------------;

*Where did you clone your repository?;
* %let root = \\fsproj\aaa...\PACKAGE_LOCATION;

* input dataset - your input library and dataset name;
* libname lib  ;
* %let input_data = ;

*--------------------------------------------;
* END EDIT SECTION *NO MORE EDITS*        ---;
*--------------------------------------------;

%include "&root./input/custom_macros.sas";

%let temp_dir = &root./local_only/temp;
* store the shapefiles in a temp folder;
libname local "&root./local_only";
libname share "&root./share";



* run the pipeline;
%sj_pipeline(&test_in., &test_out._2000,year=2000, geolevel=bg, temp_dir=&temp_dir., base_setup=true);
%sj_pipeline(&test_in., &test_out._2010,year=2010, geolevel=bg, temp_dir=&temp_dir., base_setup=true);
%sj_pipeline(&test_in., &test_out._2020,year=2020, geolevel=bg, temp_dir=&temp_dir., base_setup=true);



