*! version 0.1.0 Brian Quistorff <bquistorff@gmail.com>
*! installs packages to a directory in a way that all platforms can use the same shared directory.
program adostorer
	syntax anything, adofolder(string) [all mkdirs replace from(string)]
	gettoken cmd pkglist : anything
	
	if "`cmd'"=="remove" local cmd "uninstall"
	_assert inlist("`cmd'","install","update","uninstall"), msg("Only install, update, uninstall")
	
	_assert (`: list sizeof pkglist'==1 | "`cmd'"=="update"), msg("Only one package per time for install/uninstall") 
	
	local poss_plats "WIN64A WIN LINUX64 LINUX MAC OSX.PPC OSX.X86 MACINTEL OSX.X8664 MACINTEL64 SOL64 SOLX8664"
	
	*If doing an update, get only the packages that will change
	if "`cmd'"=="update" {
		qui adoupdate `pkglist'
		local pkglist "`r(pkglist)'"
		if "`pkglist'"=="" exit
	}
	
	tempname trk
	
	*Get available platform directories
	local pwd "`c(pwd)'"
	foreach plat of local poss_plats{
		cap cd "`adofolder'/`plat'"
		if !_rc local avail_plats "`avail_plats' `plat'"
		qui cd "`pwd'"
	}
	
	*********************************************
	*        Phase 1: Removals
	*********************************************
	if inlist("`cmd'","uninstall","update"){
		** Read stata.trk and uninstall all g files
		* But "g" files get written as "f" files, so try removing all those but in the platform dirs
		file open `trk' using "`adofolder'/stata.trk", read text
		while 1 {
			file read `trk' line
			if r(eof) continue, break
			
			mata: st_local("first_let", substr(st_local("line"),1,1))
			mata: st_local("len", strofreal(strlen(st_local("line"))))
			if "`first_let'"=="N"{
				local pkgname = substr("`line'",3,`len'-6) 
				local in_target_entry = `: list posof "`pkgname'" in pkglist'>0
			}
			if "`first_let'"=="e" local in_target_entry 0
			if "`first_let'"=="f" & "`in_target_entry'"=="1"{
				local filen = substr("`line'",5,`len'-4)
				foreach plat_dir of local avail_plats {
					cap erase "`adofolder'/`plat_dir'/`filen'"
				}
			}
		}
		file close `trk'
		
		if "`cmd'"=="uninstall"{
			ado uninstall `pkglist'
		}
		*update will do main file removal later
	}
	
	
	*********************************************
	*  Phase 2: Installations
	*********************************************
	if inlist("`cmd'","install","update"){
		if "`cmd'"=="install"{
			if "`from'"==""	ssc install `pkglist', `all' `replace'
			else net install `pkglist', from(`from') `all' `replace'
		}
		if "`cmd'"=="update" {
			adoupdate `pkglist', update dir(`adofolder')
		}
		
		*Now download the "g/G" files
		* Do this by reading the trk file, finding the source pkg file and reading it.
		file open `trk' using "`adofolder'/stata.trk", read text
		
		*Burn through the first block
		while 1{
			file read `trk' line
			mata: st_local("first_let", substr(st_local("line"),1,1))
			if (r(eof) | "`first_let'"=="S") continue, break
		}
		while "`first_let'"=="S"{
			local rem_pkg_dir = substr("`line'",3,length("`line'")-2)
			file read `trk' line_n
			mata: st_local("first_let_n", substr(st_local("line_n"),1,1))
			_assert "`first_let_n'"=="N", msg("Expected N line")
			local pkgname = substr("`line_n'",3,length("`line_n'")-6)
			if `: list posof "`pkgname'" in pkglist'!=0{
				tempfile rem_pkg_copy_fname
				tempname rem_pkg_copy_fhandle
				copy "`rem_pkg_dir'/`pkgname'.pkg" `rem_pkg_copy_fname'
				file open `rem_pkg_copy_fhandle' using "`rem_pkg_copy_fname'", read text
				while(1){
					file read `rem_pkg_copy_fhandle' line2
					mata: st_local("first_let2", substr(st_local("line2"),1,1))
					if r(eof) continue, break
					if "`first_let2'"=="g"{
						local plat : word 2 of `line2'
						local localname : word 4 of `line2'
						local pos_dir : list posof "`plat'" in avail_plats
						if `pos_dir'==0 & "`mkdirs'"==""{
							di "Did not install `localname' for `plat' platform (no existing directory)."
							continue
						}
						if `pos_dir'==0 & "`mkdirs'"!=""{
							mkdir "`adofolder'/`plat'"
						}
						local serverpath : word 3 of `line2'
						
						local localname_let = substr("`localname'",1,1)
						cap erase "`adofolder'/`localname_let'/`localname'"
						
						*download to the right spot
						qui copy "`rem_pkg_dir'/`serverpath'" "`adofolder'/`plat'/`localname'", replace
					}
				}
				*file close `rem_pkg_copy_fhandle'
			}
			*read through the rest of this entry
			while 1{
				file read `trk' line
				mata: st_local("first_let", substr(st_local("line"),1,1))
				if (r(eof) | "`first_let'"=="S") continue, break
			}		
		}
		file close `trk'
	}

end
