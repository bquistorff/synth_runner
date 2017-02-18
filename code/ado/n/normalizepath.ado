*! vers 12.12.20 20dec2012
cap program drop normalizepath
program def normalizepath, rclass
	args myfile
	
	vers 9.0
	
	local file = subinstr(`"`myfile'"', "\", "/",.)
	
	// Exists file
	cap confirm file "`myfile'"
	
	// If exists
	if _rc == 0 {
		if regexm(`"`myfile'"',"\.[a-zA-Z0-9]*$") local ext = regexs(0) 
		
		// Gets the file name
		local nchar = 0
		local filename = `"`myfile'"'
		while `nchar' == 0 {
			local filename = regexr(`"`myfile'"', ".*/","")
			local nchar = `"`filename'"' == regexr(`"`filename'"', ".*/", "")
		}
		
		// Gets the dirpath
		local dirpath = subinstr(`"`file'"', `"`filename'"', "", .)
		local dirpath = regexr(`"`dirpath'"', regexr(`"`myfile'"', `"`filename'$"', "")+"$", "")
		
		// Gets the fullpath
		cap confirm file "`c(pwd)'/`myfile'"
		
		if _rc == 0 local dirpath = c(pwd)+"/`dirpath'"
				
		return local filedir = "`dirpath'"
		return local filename = "`filename'"		
		return local fileext = "`ext'"		
		return local fullpath = "`dirpath'`filename'"
		return local myfile = `"`myfile'"'
		
		di as text `"`dirpath'`filename'"'
		di "({stata return list:see more})"
	
	}
	// Else
	else {
		di as result "`myfile'" as error " does not exists"
		exit 601
	}
	
end
