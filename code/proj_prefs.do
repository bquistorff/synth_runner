*Preferences

* Usage: -include proj_prefs.do- //more/trace are local only. Can't -do ..-

set linesize 140
version 13
if `c(matsize)'!=10000 set matsize 10000
set more off
mata: mata set matafavor speed
set matalnum on
set varabbrev off

set scheme s2mono
set tracedepth 1

*Defaults
set seed 1337
set sortseed 123456 //undocumented. Makes normal sort stable
if ("${testing}"=="") global testing = 0

if ${testing}{
	pause on
	set trace on
}

* Machine-specific stuff from environment

global defnumclusters = 2
if "`: environment DEFNUMCLUSTERS'"!="" {
	global defnumclusters = `: environment DEFNUMCLUSTERS'
}

*All of the above env vars should be in one category
global envvars_show ""
global envvars_hide "DEFNUMCLUSTERS"
