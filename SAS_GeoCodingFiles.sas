/*Change these macro variables settings in ImportCSVfiles.sas:*/
/*--- Edit macro variables to specify locations on your system.            */                                                           
%let PATHIN=/sasshare/SAS_Geocoding/;       /* Directory with files from the zip archive */                                                           
%let PATHOUT=/sasshare/SAS_Geocoding/Data/; /* Location to write geocoding data sets     */

/*--- Get metadata from the ReadMe.txt file. */                                                                             
%let source= US Census Bureau TIGER/Line files; /* Original source for the lookup data   */                                                                             
%let release=2018;                              /* Year original data published          */

/*--- Set data set names.                                */                                                                             
%let MDS=USM;   /* First geocoding lookup data set name  */                                                                             
%let SDS=USS;   /* Second geocoding lookup data set name */                                                                             
%let PDS=USP;   /* Third geocoding lookup data set name  */
