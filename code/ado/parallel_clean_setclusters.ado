*! cleans up from old parallel and sets the number of clusters (has default for automatic #)
*! Globals required: numclusters
program parallel_clean_setclusters
	syntax [anything] [, noclean]

	if "`anything'"==""{
		if "${doparallel}"!="1" | "${numclusters}"=="1"{
			global numclusters 1
			exit 0
		}
		
		if "${numclusters}"==""{
			global numclusters = ${defnumclusters}
		}
	}
	else{
		global numclusters "`anything'"
	}

	* For now only one parallel instance per FS in interactive mode, so default is clean
	if "`clean'"!="noclean" & "`c(mode)'"==""{
		cap parallel clean , all force
		if _rc != 0{
			closeallmatafiles
			parallel clean , all force
		}
	}
	
	parallel setclusters ${numclusters}, force
end
