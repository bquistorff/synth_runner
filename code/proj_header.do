* Notes:
*  Trying to keep all the pathing stuff (main vs testing) here and (proj_footer.do)
*
* Usage:
* local do_name XXX
* include ${main_root}code/proj_header.do

*Get paths setup
if "${main_root}"!="" cd ${main_root} //recover from testing
do code/setup_ado.do

if "`testing'"=="1" local rootname "testing"
if "`rootname'"!="" cd "temp/`rootname'-root/" //match with below
global testing = cond("`rootname'"=="testing",1,0)

*Logging. Has to go before clear_all
*For now don't allow duplicate logs coming in.
log close _all
if "`do_name'"!=""{
	*put it in the right output dir
	log using "log/do/`do_name'.log", replace /*name(`do_name')*/
	
	display_run_specs
}

clear all //use all globals and passed in locals before this!
mac drop _all

*get log name from open log file
qui log query _all
local log_fname = "`r(filename1)'" //If there are a hierarchy of logs then step through them
if regexm("`log_fname'","[/\\]([^/]+).log") local log_name = regexs(1) //do_name might be changed (to conform to name convention)
local log_fname "" //remove local as we are being -include-d

*Get root (& testing) from pwd
*Roots should be absolute and include final folder slash so that in case it's blank we get relative paths
if regexm("`c(pwd)'","[/\\]temp[/\\]([^/]+)-root$"){
	local rootname = regexs(1) 
	cd ../..
	global main_root "`c(pwd)'/"
	cd "temp/`rootname'-root/"
	global curr_root "`c(pwd)'/"
}
else{
	global main_root "`c(pwd)'/"
}
global testing  = cond("`rootname'"=="testing",1,0)

include "${main_root}code/proj_prefs.do" //needs $main_root

