*! log2html 1.2.9  cfb/njc/br 08jun2006
*! log2html 1.2.8  cfb/njc/br 09feb2005
*! log2html 1.2.7  cfb/njc/br 12oct2004 
*! log2html 1.2.6  cfb/njc/br 2oct2003
*! log2html 1.2.5  cfb/njc/br 17Jun2003
*! log2html 1.2.0  cfb/njc  3Mar2003
*! log2html 1.1.1  cfb/njc  17Dec2001
program log2html
	version 8.0
	syntax anything(name=smclfile id="The name of a .smcl logfile is")  ///
	[, ERASE replace TItle(str) INput(str) Result(str) BG(str) LINEsize(integer `c(linesize)') ///
	TExt(str) ERRor(str) PERcentsize(integer 100) BOLD CSS(str) SCHeme(str)]

	// syntax processing 
	
	if "`css'" != "" & `"`input'`result'`text'`error'`bg'`scheme'"' != "" {
		di as err "if CSS is specified, you may not specify any colors"
		exit 198
	}
			
	if "`scheme'" != "" {
		if `"`input'`result'`text'`error'`bg'"' != "" {
			di as err ///
		"if a scheme is specified, you may not specify any colors"
			exit 198 
		}
		
		local names   "bg     input  result text   error"
		local cblack  "000000 ffffff ffff00 00ff00 ff0000"
		local cwhite  "ffffff 000000 000000 000000 ff0000"
		local cblue   "000090 ffffff ffff00 00ff00 ff0000"
		local cugly   "ff00ff 9999ff ff99ff 00ff00 cccc00"
		local cyellow "ffffcc cc00cc 0000cc 000000 ff0000" 

		local cnt 1
		foreach name of local names {
			local `name' : word `cnt++' of `c`scheme''
		}
		if "`bg'"=="" {
			display as error "scheme `scheme' does not exist! Available schemes are "
			display as error "  black, white, blue, and yellow."
			exit 198
		}

	}

	else {
		if "`input'" == ""  local input "CC6600"
		if "`result'" == "" local result "000099"
		if "`text'" == ""   local text "000000"
		if "`error'" == ""  local error "dd0000"
		if "`bg'" == ""     local bg "ffffff"
		else {
			if "`bg'" == "gray" | "`bg'" == "grey" {
				local bg "cccccc"
			}
		}
	}

	if !inrange(`linesize', 40, 255) {
		display as err "linesize must be between 40 and 255"
		exit 125
	}

	if `percentsize' <= 0 {
		display as err "percentsize() must be a positive integer"
		exit 198
	}

	// filenames and handles 
	
	tempname hi ho
	tempfile htmlfile
	local origfile `smclfile'
	if (!index(lower("`origfile'"),".smcl")) {
		local origfile  "`origfile'.smcl"
	}
	local smclfile : subinstr local smclfile ".smcl" "" 
	local smclfile : subinstr local smclfile ".SMCL" ""
	local smclfile : subinstr local smclfile `"""' "", all /* '"' (for fooling emacs) */
	local smclfile : subinstr local smclfile "`" "", all 
	local smclfile : subinstr local smclfile "'" "", all 
	local outfile `"`smclfile'.html"'
	local ll "ll(`linesize')" 
	qui log html `"`origfile'"' `"`htmlfile'"', `replace' yebf whbf `ll'

	// line-by-line processing 

	file open `hi' using `"`htmlfile'"', r
	file open `ho' using `"`outfile'"', w `replace'
	file write `ho'  _n
	file write `ho' "<html>" _n "<head>" _n
	if `"`title'"' ~= "" {
		file write `ho' `"<title>`title'</title>"' _n
	}
	file write `ho' `"<meta http-equiv="Content-type" content="text/html; charset=iso-8859-1">"' _newline
	file write `ho' `"<meta http-equiv="Content-Style-Type" content="text/css">"' _newline
	if "`css'" == "" {
		file write `ho' `"<style type="text/css">"' _newline
		file write `ho' "BODY{background-color: `bg';" _newline 
		file write `ho' `"    font-family: monaco, "courier new", monospace;"' _newline
		if `percentsize' != 100 {
			file write `ho' "font-size:`percentsize'%;" _newline
		}
		file write `ho' "     color: #`text'}" _newline
		if "`bold'" != "" {
			file write `ho' ".input, .result, .error{font-weight: bold}" _newline
		}
		file write `ho' ".input {color: #`input'}" _newline
		file write `ho' ".result{color: #`result'}" _newline
		file write `ho' ".error{color: #`error'}" _newline 
		file write `ho' "</style>" _newline 
	}
	else {
		file write `ho' `"<link rel="stylesheet" href="`css'">"' _newline 
	}
	file write `ho' "</head>" _newline
	file write `ho' "<body>" _newline
	if `"`title'"' != "" {
		file write `ho' `"<h2>`title'</h2>"' _n
	}

	file read `hi' line
	
	local cprev = 0 

	while r(eof) == 0 {

		// change <p> (which should be a div) to a <br><br> 
		local line : /// 
	subinstr local line "<p>" "<br><br>", all
		
		local line: /// 
	subinstr local line "<b>. " "<span class=input>. ", count(local c)
	
		// catch continuation lines
		local word1 : word 1 of `"`line'"' 
		if substr(`"`word1'"',1,7) == "<b>&gt;" & `cprev' { 
			local line : ///
	subinstr local line "<b>" "<span class=input>", count(local c) 
		} 	
		else { 
			local line: ///
		subinstr local line "<b>" "<span class=result>", all
		}
		
		local line: subinstr local line "</b>" "</span>", all

		// check for error number 
		if substr(`"`word1'"',1,2) == "r(" {
			if real(substr(`"`word1'"',3,index(`"`word1'"',")")-3)) < . {
				local line `"<div class=error> `line' </div>"'
			}
		}

		file write `ho' `"`macval(line)'"' _n
		local cprev = `c' 
		file read `hi' line
	}
	
	file write `ho' "</body>" _n "</html>" _n
	file close `ho'
	
	di _n `"HTML log file `outfile' created"' 
	if "`erase'" ~= "" { 
		erase `"`origfile'"' 
	}
end


