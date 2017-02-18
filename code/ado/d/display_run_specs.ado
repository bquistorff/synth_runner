*! version 1.1
*! For numerical replication need to list operating system, application version, and processor type
*! Essentially a different take on -about- (but I don't care about memory, license, copyright)
* Ref: http://www.stata.com/support/faqs/windows/results-in-different-versions/
* Note that log open/close timestamps don't happen for the batch-mode logs
* Environment variables should be noted as well. 
*  Some are consequential so list them in $envvars_show and the others in $envvars_hide
program display_run_specs
	version 11.0 //Just a guess at the version
	
	stata_flavor
	di _skip(17) as text "Flavor = " as result "`r(product_name)'"
	
	qui update
	di _skip(15) as text "Revision = " as result %td r(inst_exe)
	
	*query compilenumber //This executable should be identified completely from other info
	
	local c_opts_str os osdtl machine_type byteorder hostname pwd
	
	*local c_opts_str = `c_opts_str' sysdir_stata //are you really playing with this given the version?
	
	*S_ADO should be standardized per-project
	*local c_opts_str = `c_opts_str' adopath sysdir_base sysdir_site sysdir_plus sysdir_personal sysdir_oldplace
	
	foreach c_opt of local c_opts_str {
		local skip = 23 - (length("`c_opt'")+3)
		di _skip(`skip') as text "c(`c_opt') = " as result `""`c(`c_opt')'""'
	}
	
	local c_opts_num stata_version processors
	foreach c_opt of local c_opts_num {
		local skip = 23 - (length("`c_opt'")+3)
		di  _skip(`skip') as text "c(`c_opt') = " as result "`c(`c_opt')'"
	}
	
	foreach vname in $envvars_show {
		di `"env `vname': `: environment `vname''"'
	}
	foreach vname in $envvars_hide {
		di `"LOGREMOVE env `vname': `: environment `vname''"'
	}
	
end

*Get the real flavor (not c(flavor)!)
*The cl_ext aren't correct for Windows
program stata_flavor, rclass
	if "`c(flavor)'"=="Small"{
		return local flavor = "Small"
		return local product_name = "Small Stata"
		*return local cl_ext  = "-sm"
	}
	else{
		if c(SE)==0{
			return local flavor = "IC"
			return local product_name = "Stata/IC"
			*return local cl_ext  = ""
		}
		else{
			if c(MP)==0{
				return local flavor = "SE"
				return local product_name = "Stata/SE"
				*return local cl_ext  = "-se"
			}
			else{
				return local flavor = "MP"
				return local product_name = "Stata/MP"
				*return local cl_ext  = "-mp"
			}
		}
	}
end
