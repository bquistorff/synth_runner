*! log2html 1.1.1  cfb/njc  17Dec2001
program define log2html7, rclass
	version 7.0
	syntax anything(name=smclfile id="The name of a .smcl logfile is") /*
	*/ [, replace TItle(string asis) INput(string) Result(string) BG(string)]
	
	tempname hi ho
	tempfile htmlfile
	local smclfile : subinstr local smclfile ".smcl" "" 
	local smclfile : subinstr local smclfile ".SMCL" "" 
	local outfile `"`smclfile'.html"'
	qui log html `"`smclfile'"' `"`htmlfile'"', `replace' yebf whbf
	
	local cinput = cond("`input'" == "", "CC6600", "`input'") 
	local cresult = cond("`result'" == "", "000099", "`result'") 
	
	local cbg "ffffff"
	if "`bg'" ~= "" { 
		if "`bg'" == "gray" | "`bg'" == "grey" { local bg "cccccc" }
		local cbg `bg'
	}
	
	file open `hi' using `"`htmlfile'"', r
	file open `ho' using `"`outfile'"', w `replace'
	file write `ho'  _n
	file write `ho' "<html>" _n "<head>" _n
	if `"`title'"' ~= "" {
		file write `ho' `"<title>`title'</title>"' _n
		file write `ho' `"<h2>`title'</h2>"' _n
	}
	file write `ho' "</head>" _n	
	file write `ho' "<body bgcolor=`cbg'>" _n
	file read `hi' line
	
	local cprev = 0 
	
	while r(eof)==0 {
		* command lines 
		local line: /* 
	*/ subinstr local line "<b>. " "<font color=`cinput'>. ", count(local c)
	
		* catch continuation lines
		if substr(`"`line'"',1,7) == "<b>&gt;" & `cprev' { 
			local line : /* 
	*/ subinstr local line "<b>" "<font color=`cinput'>", count(local c) 
		} 	
	 	else { 
			local line: /* 
		*/ subinstr local line "<b>" "<font color=`cresult'>", all
		}
		
		local line: subinstr local line "</b>" "</font>", all
		file write `ho' `"`line'"' _n
		local cprev = `c' 
		file read `hi' line
	}
	file write `ho' "</body>" _n "</html>" _n
	file close `ho'
	di _n `"HTML log file `outfile' created"' 
end

