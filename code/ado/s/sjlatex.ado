*! version 1.2.2  15may2014
program define sjlatex
	version 7
	gettoken cmd 0 : 0, parse(" ,")
	local l = length(`"`cmd'"')
	preserve
	if `"`cmd'"' == "" | `"`cmd'"' == "using" {
		Using `cmd' `0'
		di
	}
	else if `"`cmd'"' == substr("query",1,max(1,`l')) {
		Query `0'
	}
	else if `"`cmd'"' == substr("install",1,max(1,`l')) {
		Install `0'
	}
	else if `"`cmd'"' == substr("update",1,max(1,`l')) {
		capture syntax [using] [, replace * ]
		Install `using', replace `options'
	}
	else if `"`cmd'"' == substr("ado",1,max(1,`l')) {
		if _caller() >= 9 {
			di as txt /*
*/ "Use the {helpb adoupdate} command to update {cmd:sjlatex} and {cmd:sjlog}"
			exit
		}
		Ado `0'
	}
	else {
		di as error `"unrecognized command: `cmd'"'
		exit 198
	}
	exit
end

/* get the SJ parameters */
program define GetParams, sclass
	sreturn local from http://www.stata-journal.com/production
	sreturn local pkg sjlatex
	sreturn local src sjlatex
end

program define Using, rclass
	local pwd : pwd
	syntax [using/]
	if `"`using'"' != "" {
		quietly cd `"`using'"'
		local sjdir : pwd
	}
	local cwd : pwd
	di as txt _n "Stata Journal LaTeX files"
	di as txt _col(5) "folder:" _col(25) as res `"`cwd'"'
	di as txt _col(5) "installed release:" _col(25) _c

	/* The top line of this file is an example of the form of the
	 * sj.version file.
	 */

	capture infile str20 version using sj.version
	if _rc {
		di as res "(unknown)"
	}
	else {
		capture {
			assert version[1] == "*!"
			assert version[2] == "version"
		}
		if _rc {
			di as res "(unknown)"
		}
		else {
			di as res "version " version[3] " " version[4]
			return local sjver = version[3]
			return local sjdate = version[4]
		}
	}
	return local sjdir `sjdir'
	qui cd `"`pwd'"'
end

program define Query, rclass
	syntax [using] [, norecommend from(string) ]
	Using `using'
	if `"`r(sjdir)'"' != "" {
		local uusing `" using `"`r(sjdir)'"'"' /*"'*/
	}
	local sjdate `r(sjdate)'
	local sjver `r(sjver)'
	GetParams
	if `"`from'"' == "" {
		local from `s(from)'
	}
	local pkg `s(pkg)'
	local src `s(src)'
	tempfile sj_version
	qui copy `"`from'/`src'/sj.version"' `sj_version', text
	qui infile str20 version using `sj_version', clear
	di as txt _col(5) "latest release:" _col(25) /*
	*/ as res "version " version[3] " " version[4]
	local l_sjver = version[3]
	local l_sjdate = version[4]
	if `"`recommend'"' == "" {
		di as txt _n "{p 0 5}Recommendation{break}"
		if `"`sjver'`sjdate'"' == "" {
			di as txt `"type -{cmd:sjlatex install`uusing'}-"'
			return local recommend install
		}
		else if `"`sjver'`sjdate'"' != `"`l_sjver'`l_sjdate'"' {
			di as txt `"type -{cmd:sjlatex update`uusing'}-"'
			return local recommend update
		}
		else {
			di as txt `"Do nothing; all files up-to-date."'
		}
	}
end

program define Install
	syntax [using/] [, replace from(string) noLS ]
	if `"`using'"' != "" {
		local uusing `" using `using'"'
	}
	local pwd : pwd
	if `"`replace'"' == "" {
		di as txt "Installing Stata Journal LaTeX files..."
		if `"`using'"' != "" {
			capture mkdir `"`using'"'
			if _rc {
				di as err /*
				*/ `"could not create directory `using'"'
				di as txt /*
		*/ `"{p 0 4 2}This directory already existed."' /*
		*/ `"Consider supplying an alternate directory or{break}"' /*
		*/ `"type -{cmd:sjlatex update`uusing'}-.{p_end}"'
				exit _rc
			}
			qui cd `"`using'"'
		}
	}
	else {
		di as txt "Updating Stata Journal LaTeX files..."
		if `"`using'"' != "" {
			quietly cd `"`using'"'
		}
	}
	local sjdir : pwd
	set more off
	GetParams
	local src `s(src)'
	if `"`from'"' == "" {
		local from `s(from)'
	}
	capture net from `"`from'"'
	capture noisily quietly net get `src', `replace'
	if _rc == 677 {
		exit 677
	}
	if _rc {
		di as error `"could not copy the files to `sjdir'"'
		if `"`replace'"' == "" {
			di as txt `"{p}One or more files in this directory is in conflict with the Stata Journal LaTeX files.  Consider supplying an alternate directory or{break}type -{cmd:sjlatex update`uusing'}-.{p_end}"'
		}
		else {
			di as txt `"This directory may not be writable.  Consider supplying an alternate directory."'
		}
		exit _rc
	}
	if "`c(stata_version)'" == "" {
		capture /*
		*/ cp `"`from'/`src'/statapress.cls"' statapress.cls, /*
		*/ replace text
	}
	Using
	if `"`replace'"' == "" & `"`ls'"' == "" {
		di as input _n ". ls"
		ls
	}
	if `"`uusing'"' != "" {
		di as input _n ". pwd"
		pwd
	}
	di in smcl as txt _n "{p 0 0 2}" /*
		*/ "See the Getting Started instructions" /*
		*/ " in the Remarks section of the online" /*
		*/ " documentation for {help sjlatex}.{p_end}"
end

program define Ado
	set more off
	GetParams
	local from `s(from)'
	local pkg `s(pkg)'
	quietly net from `"`from'"'
	capture net install `pkg'
	if _rc {
		di as txt "updating package {cmd:sjlatex} package"
		quietly ado uninstall `pkg'
		quietly net install `pkg'
	}
	else	di as txt "package {cmd:sjlatex} is up-to-date"
end

exit
