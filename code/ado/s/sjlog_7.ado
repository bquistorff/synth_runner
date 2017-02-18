*! version 1.1.13  06may2003
program define sjlog_7
	version 7
	local vv : di "version " _caller() ":"

	gettoken cmd 0 : 0, parse(" ,")
	local l = length(`"`cmd'"')
	if `"`cmd'"' == "using" | `"`cmd'"' == "open" {
		LogOpen `0'
	}
	else if `"`cmd'"' == "close" {
		LogClose `0'
	}
	else if `"`cmd'"' == "do" {
		`vv' LogDo `0'
	}
	else if `"`cmd'"' == "clean" {
		LogClean `0'
	}
	else if `"`cmd'"' == "type" {
		LogType `0'
	}
	else if `"`cmd'"' == substr("basename",1,`l') {
		LogBaseName `0'
	}
	else if `"`cmd'"' == "" {
		log
	}
	else {
		di as err "`cmd' invalid"
		exit 198
	}
end

program define LogSetup
	syntax [, clear ]
	if "`clear'" != "" {
		clear
		program drop _all
	}
	capture log close
	set rmsg off
	set more off
	set trace off
end

program define StripQuotes
	syntax anything(name=name id="name") [, string(string) ]
	c_local `name' `"`string'"'
end

/* basename *****************************************************************/

program define LogBaseName, rclass
	syntax anything(name=file id="filename") [, Display ]

	StripQuotes file , string(`file')
	local dirsep "/"

	/* strip off the directory path */
	gettoken dir rest : file, parse("/\:")
	while `"`rest'"' != "" {
		if `"`dir'"' == "\" {
			local dir `"`dirsep'"'
		}
		local dirname `"`dirname'`dir'"'
		gettoken dir rest : rest , parse("\/:")
	}
	if `"`dirname'"' == "" {
		local dirname .`dirsep'
	}

	/* strip off the extension */
	gettoken ext rest : dir, parse(".")
	while `"`rest'"' != "" {
		local basename `basename'`ext'
		gettoken ext rest : rest , parse(".")
	}
	if `"`basename'"' == "" {
		local basename `ext'
		local ext
	}
	else {
		/* remove the last "." from `basename' */
		local l = length(`"`basename'"') - 1
		local basename = substr(`"`basename'"',1,`l')
	}

	/* saved results */
	return local ext = cond(`"`ext'"'=="","",".") + `"`ext'"'
	return local base `"`basename'"'
	return local dir `"`dirname'"'
	return local fn `"`file'"'

	if `"`display'"' != "" {
		display as txt `"fn:   `return(fn)'"'
		display as txt `"dir:  `return(dir)'"'
		display as txt `"base: `return(base)'"'
		display as txt `"ext:  `return(ext)'"'
	}
end

/* using/close/do: subroutines **********************************************/

program define LogOpen
	syntax anything(name=file id="filename") [, append replace ]

	LogSetup

	LogBaseName `file'
	local ext	`"`r(ext)'"'
	if `"`ext'"' != ".smcl" {
		local file `"`r(fn)'.smcl"'
	}

	quietly log using `"`file'"', smcl `append' `replace'
end

program define LogClose, rclass
	syntax [,		/*
	*/	book		/*
	*/	replace		/*
	*/	noCLEAN		/*
	*/	noLOGfile	/*
	*/	sjlogdo		/* internal only, NOT documented
	*/	]

	if `"`sjlogdo'"' == "" {
		local logtype sjlog
	}
	else	local logtype `sjlogdo'

	quietly log 

	LogBaseName	`"`r(filename)'"'
	local dir	`"`r(dir)'"'
	local base	`"`r(base)'"'
	local ext	`"`r(ext)'"'
	local file	`"`r(fn)'"'
	local dbase	`"`dir'`base'"'

	quietly log close 

	/* log assumed to be a smcl file */
	if `"`ext'"' != ".smcl" {
	        di in red "assumption failed -- log file not smcl"
	        exit 198
	}
	if `"`clean'"' == "" {
		LogClean `"`file'"', `logtype'
		erase `r(fnbak)'
	}

	/* get TeX version of log */
	qui log texman `"`file'"' `"`dbase'.log.tex"', `replace' `book'
	if `"`logfile'"' == "" {
		/* get plain text version of log */
		qui translate `"`file'"' `"`dbase'.log"', `replace'
	}

	/* saved results */
	if `"`logfile'"' == "" {
		return local fn_log `"`dbase'.log"'
	}
	return local fn_tex `"`dbase'.log.tex"'
	return local fn_smcl `"`dbase'.smcl"'
end

program define LogDo
	version 7.0
	local vv : display "version " _caller() ":"
	syntax anything(name=file id="filename") [,	/*
		*/ clear				/*
		*/ replace				/*
		*/ book					/*
		*/ nostop				/*
		*/ SAVing(string)			/*
		*/ ]

	if "`saving'" != "" {
		capture confirm name `saving'
		if _rc {
			di as err /*
	*/ "'`saving'' found where saving() option requires a valid name"
			exit 198
		}
	}

	LogSetup, `clear'

	LogBaseName	`file'
	local base = cond("`saving'"=="","`r(base)'","`saving'")
	local dbase	`"`r(dir)'`base'"'
	local ext	`"`r(ext)'"'
	local file	`"`r(fn)'"'
	if `"`ext'"' != ".do" {
		local dbase `"`dbase'`ext'"'
	}

	LogOpen `dbase', `replace'
	capture noisily `vv' do `file', `stop'
	local rc = _rc 
	if `rc' {
		local cap capture
	}
	`cap' LogClose, `replace' sjlogdo `book'
	exit `rc'
end

/* clean: subroutines *******************************************************/

program define LogClean, rclass
	syntax anything(name=file id="filename") [,	/*
	*/		log				/*
	*/		logclose			/*
	*/		sjlog				/*
	*/		sjlogdo 			/*
	*/	]

	/* validate arguments and options */
	local logsrc `log' `logclose' `sjlog' `sjlogdo'
	local wc : word count `logsrc'
	if `wc' > 1 {
		di as err "options `logsrc' may not be combined"
		exit 198
	}
	StripQuotes file , string(`file')
	confirm file `"`file'"'

	/* open files */
	tempname rf wf
	tempfile newfile
	file open `rf' using `"`file'"', read text
	file open `wf' using `"`newfile'"', write text

	/* clean file */
	capture noisily {
		initMacros
		if `"`logsrc'"' == "logclose" {
			CleanLogclose `rf' `wf'
		}
		else if `"`logsrc'"' == "sjlog" {
			CleanSJLog `rf' `wf'
		}
		else if `"`logsrc'"' == "sjlogdo" {
			CleanSJLogDo `rf' `wf'
		}
		else {	/* Default: `"`logsrc'"' == "log" */
			CleanLog `rf' `wf'
		}
	}
	local rc = _rc

	/* close files */
	file close `wf'
	file close `rf'

	removeMacros `rc'

	/* make a backup copy of the input file (rf) and save the output file
	 * (wf) using the given filename
	 */

	local backup `file'.bak
	copy `"`file'"' `"`backup'"', replace
	copy `"`newfile'"' `"`file'"', replace

	/* saved results */
	return local fnbak `"`backup'"'
	return local fn `"`file'"'
end

program define initMacros
	global SJL_maxn		10
	global SJL_n		0
	global SJL_parity	0
end

program define removeMacros
	args rc

	if "$SJL_parity" != "0" & "$SJL_parity" != "" {
		di as err "$SJL_parity nonempty global macros"
		forval i = 1/$SJL_maxn {
			if `"${SJL_`i'}"' != "" {
				di _asis as txt /*
			*/ `"SJL_`i' is |${SJL_`i'}{reset}{text}|"'
			}
			global SJL_`i'
		}
		if ! `rc' {
			local rc 459
		}
	}
	global SJL_parity
	global SJL_maxn
	global SJL_n

	exit `rc'
end

program define removeLine
	args line

	global `line'
	/* decrease number of lines read */
	global SJL_parity = $SJL_parity - 1
end

program define FileRead
	args hh c_line

	/* read in line */
	file read `hh' rline

	/* increase number of lines read */
	local n = mod($SJL_n,$SJL_maxn) + 1

	/* increase parity index */
	global SJL_parity = $SJL_parity + 1

	/* escape quotes */
	local qline : /*
		*/ subinstr local rline "\`" "\\\`" , all count(local qc)

	/* escape dollars */
	global SJL_`n' : /*
		*/ subinstr local qline "\$" "\\\$" , all count(local dc)

	/* return name of global macro containing new line */
	c_local `c_line' SJL_`n'

	/* save number of lines read */
	global SJL_n `n'
end

program define FileWrite
	args hh line

	/* write contents of global to file */
	file write `hh' `"${`line'}"' _n

	removeLine `line'
end

/* Clean log produced by -sjlog do-.
 *
 * This subroutine has a 3 line buffer; the end of a log from -sjlog do- will
 * always have:
 *
 * 1. a blank line
 * 2. a line with the text: "."
 * 3. a line with the text: "end of do-file"
 *
 * This subroutine also works with smcl files, and TeX files generated from
 * smcl files using -log texman- (its original purpose).
 */

program define CleanSJLogDo
	args rf wf

	/* skip the smcl header lines */
	FileRead `rf' line1
	if `"${`line1'}"' == "{smcl}" {
		/* skip next line too, it is part of the smcl header */
		removeLine `line1'
		FileRead `rf' line1
		removeLine `line1'
	}
	else {
		FileWrite `wf' `line1'
	}

	FileRead `rf' line1
	FileRead `rf' line2
	local break 0
	while r(eof)==0 {
		if substr(`"${`line2'}"',-14,.) == "end of do-file" {
			local break 1
			continue, break
		}
		FileWrite `wf' `line1'
		local line1 `line2'
		FileRead `rf' line2
	}
	if ! `break' {
		FileWrite `wf' `line1'
		removeLine `line2'
	}
	else {
		removeLine `line1'
		removeLine `line2'
	}
end

/* Clean log produced by -sjlog using- and -sjlog close-. */

program define CleanSJLog
	args rf wf

	CleanLogUsingHeader `rf'

	/* skip the smcl header lines */
	FileRead `rf' line1
	if `"${`line1'}"' == "{smcl}" {
		/* skip next line too, it is part of the smcl header */
		removeLine `line1'
		FileRead `rf' line1
		removeLine `line1'
	}
	else {
		FileWrite `wf' `line1'
	}

	FileRead `rf' line1
	FileRead `rf' line2
	local break 0
	while r(eof)==0 {
		if index(`"${`line2'}"',". sjlog close") {
			local break 1
			continue, break
		}
		FileWrite `wf' `line1'
		local line1 `line2'
		FileRead `rf' line2
	}
	if ! `break' {
		FileWrite `wf' `line1'
		removeLine `line2'
	}
	else {
		removeLine `line1'
		removeLine `line2'
	}
end

/* Clean log produced by Stata's -log using- and -log close- commands. */

program define CleanLog
	args rf wf

	CleanLogUsingHeader `rf'

	FileRead `rf' line
	local break 0
	while r(eof)==0 {
		/* stop when we encounter the -log close- command. */
		if substr(`"${`line'}"',-11,.) == ". log close" {
			local break 1
			continue, break
		}
		FileWrite `wf' `line'
		FileRead `rf' line
	}
	if `break' {
		removeLine `line'
	}
end

/* Clean log produced by Stata's -log using- command and -logclose-. */

program define CleanLogclose
	args rf wf

	CleanLogUsingHeader `rf'

	FileRead `rf' line
	local break 0
	while r(eof)==0 {
		/* stop when we encounter the -log close- command. */
		if substr(`"${`line'}"',-10,.) == ". logclose" {
			local break 1
			continue, break
		}
		FileWrite `wf' `line'
		FileRead `rf' line
	}
	if `break' {
		removeLine `line'
	}
end

/* Skip first 5 lines comprising the header output from -log using-. */

program define CleanLogUsingHeader
	args rf

	/* hline */
	file read `rf' line
	if `"`line'"' == "{smcl}" {
		file read `rf' line
	}

	file read `rf' line
	if ! index(`"`line'"', "log:") {
		file seek `rf' tof
		exit
	}

	file read `rf' line
	if ! index(`"`line'"', "log type:") {
		file seek `rf' tof
		exit
	}

	file read `rf' line
	if ! index(`"`line'"', "opened on:") {
		file seek `rf' tof
		exit
	}

	/* blank line */
	file read `rf' line
end

/* type: subroutines ********************************************************/

program define LogType
	syntax anything(name=file id="filename") [,	/*
	*/		replace				/*
	*/		find				/*
	*/		path(passthru)			/*
	*/		logfile				/*
	*/	]

	LogSetup

	if "`logfile'" == "" {
		local logfile nologfile
	}
	StripQuotes file , string(`file')
	if `"`find'"' != "" {
		capture which findfile
		if _rc {
			di as err "option find requires Stata 8 or later"
			exit 111
		}
		quietly findfile `"`file'"', `path'
		local file `r(fn)'
	}

	LogBaseName	`file'
	local file	`"`r(fn)'"'
	local dbase	`"`r(dir)'`r(base)'"'
	local ext	`"`r(ext)'"'
	if ! inlist(`"`ext'"',".smcl",".hlp") {
		local dbase `"`dbase'`ext'"'
	}

capture noisily {

	tempfile tt
	LogOpen `tt'
	type `file'
	LogClose, noclean `logfile'
	copy `"`tt'.log.tex"' `"`dbase'.log.tex"', `replace'
	if "`logfile'" == "logfile" {
		copy `"`tt'.log"' `"`dbase'.log"', `replace'
	}

}

	local rc = _rc
	capture erase `"`tt'.smcl"'
	capture erase `"`tt'.log.tex"'
	exit `rc'
end

exit
