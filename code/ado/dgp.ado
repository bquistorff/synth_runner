program dgp
	syntax , n(int) n_treat(int) t(int) t0(int) alpha0_vec(string) [t2(int 0) rho(real 0)  f(int 0)]
	local F = `f'
	*change to t2 being start period
	local t2 = `t'-`t2'+1
	tempvar prop_treat max_prop_treat D_pre1 ever_treated treat_epoch D_init mu lambda phi e D_effect
	
	if "$N"!="`n'" | "$T"!="`t'"{
		drop _all
		qui set obs `=`n'*`t''
		gen long id = int((_n-1)/`t')+1
		gen long period = mod(_n-1,`t')+1
		xtset_fast id period
		global N = `n'
		global T = `t'
	}
	else{
		keep id period
	}
	
	forval r_i=1/`F'{
		gen `mu' = rnormal()
		qui bys id: replace `mu' = `mu'[1]
		gen `lambda' = rnormal()
		qui bys period: replace `lambda' = `lambda'[1]
		gen `phi' = `mu'*`lambda'
		local phis "`phis' `phi'"
	}
	if `F'>0 egen phi = rowtotal(`phis')
	
	*Picked the treated units and period
	gen byte `treat_epoch' = (period>`t0') & (period<`t2')
	gen `prop_treat' = rnormal()
	if `F'>0 qui replace `prop_treat' = `rho'*phi + `prop_treat'
	bys `treat_epoch' id: egen `max_prop_treat' = max(`prop_treat')
	gsort -`treat_epoch' +period -`max_prop_treat'
	gen byte `D_pre1' = (_n<=`n_treat') //just pick which ones treated (not treated in this period)
	bys id: egen byte `ever_treated' = max(`D_pre1')
	gen byte D = `ever_treated' & `treat_epoch' & (`prop_treat'==`max_prop_treat')
	sort id period
	qui replace D=D[_n]+1 if (period>`t0') & D[_n-1]>0 //for now have it count up
	*gen the alpha affect
	gen `D_effect'=0
	forval i=1/`=rowsof(`alpha0_vec')'{
		qui replace `D_effect'= `alpha0_vec'[`i',1] if D==`i'
	}
	qui replace D=(D>0) //turn back to binary
	
	gen `e' = rnormal()
	if `F'>0 gen u = `e'+phi
	else 	gen u = `e'
	
	gen y = `D_effect'+u
	
	qui compress
end

*For when the data are generated regularly so you don't have have run xtset and it's calculations
program xtset_fast
	args pvar tvar

	qui describe, varlist
	if "`r(sortlist)'"!="`pvar' `tvar'" sort `pvar' `tvar' //can't set this separately
	
	char _dta[iis]                  `pvar'
	char _dta[tis]                  `tvar'
	char _dta[_TSitrvl]             1
	char _dta[_TSdelta]             +1.0000000000000X+000
	char _dta[_TSpanel]             `pvar'
	char _dta[_TStvar]              `tvar'
end
