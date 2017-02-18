program _sr_print_dots
	version 12
	args curr end char
	
	if `c(noisily)'==0 exit 0 //only have one timer going at at time.
	
	if "`char'"=="" local char "."
	
	local timernum 13
	if "$PRINTDOTS_WIDTH"=="" local width 50
	else local width = clip(${PRINTDOTS_WIDTH},1,50)
	
	*See if passed in both
	if "`end'"==""{
		local end `curr'
		if "$PRINTDOTS_CURR"=="" global PRINTDOTS_CURR 0
		global PRINTDOTS_CURR = $PRINTDOTS_CURR+1
		local curr $PRINTDOTS_CURR
	}
	
	if `curr'==1 {
		timer off `timernum'
		timer clear `timernum'
		timer on `timernum'

		if `end'<`width'{
			di "|" _column(`end') "|" _continue
		}
		else{
			local full_header "----+--- 1 ---+--- 2 ---+--- 3 ---+--- 4 ---+--- 5"
			local header = substr("`full_header'",1,`width')
			di "`header'" _continue
		}
		di " Total: `end'"
		di "`char'" _continue
		exit 0
	}
	
	if (mod(`curr', `width')==0 | `curr'==`end'){
		timer off `timernum'
		qui timer list  `timernum'
		local used `r(t`timernum')'
		_format_time `= round(`used')', local(used_toprint)
		if `end'>`curr'{
			timer on `timernum'
			local remaining = `used'*(`end'/`curr'-1)
			_format_time `= round(`remaining')', local(remaining_toprint)
			display "`char' `used_toprint' elapsed. `remaining_toprint' remaining"
		}
		else{
			di "| `used_toprint' elapsed. "
		}
	}
	else{
		di "`char'" _continue
	}
end

program _format_time
	syntax anything(name=time), local(string)
	
	local suff "s"
	if `time'>100{
		local time=`time'/60
		local suff "m"
		if `time'>100{
			local time = `time'/60
			local suff "h"
			if `time'>36{
				local time = `time'/24
				local suff "d"
			}
		}
	}
	local str =string(`time', "%9.2f")
	c_local `local' `str'`suff'
end
