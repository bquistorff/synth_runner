*! version 1.0 Brian Quistorff <bquistorff@gmail.com>
*! Produces p-value graphs for post-treatment per-period effects
program pval_graphs
	version 12 //haven't tested on earlier versions
	syntax [, pvals_gname(string) pvals_t_gname(string)]
	
	if "`pvals_gname'"=="" local pvals_gname pvals
	if "`pvals_t_gname'"=="" local pvals_t_gname pvals_t
	preserve
	drop _all
	tempname comb_mat
	mat `comb_mat' = e(pvals)' , e(pvals_t)'
	qui svmat `comb_mat', names(p)
	rename (p1 p2) (pvals pvals_t)
	gen int lead = _n
	local N = _N

	foreach ptype in pvals pvals_t{
		twoway (scatter `ptype' lead), name(``ptype'_gname', replace) ///
			plotregion(margin(zero)) xlabel(1(1)`N') xscale(r(0 `=`N'+1')) ///
			ylabel(0(0.1)1) xtitle("Number of periods after event (Leads)") ///	
			ytitle("Probability that this would happen by Chance")
	}

end
