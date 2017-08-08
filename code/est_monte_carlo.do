/* 
 * (Currrently unused) An Monte Carlos simulator to test speed and estimation quality.
 */ 

*Header
*local rootname "testing" //testing mode
local do_name gen_sim_data
include ${main_root}code/proj_header.do

local do_parallel = 0 /*1*/

*local DO_GEN		="NO"
local DO_ANALYSIS	="NO"
global rho .5
global nreps = 100 /*300*/
*global S_LEVEL 95
mat alpha0 = (3\2.5\2\1.5)
local t2 = rowsof(alpha0)-1
global scr_est_period 6
local alpha0_1 = alpha0[1,1]

if "`DO_GEN'"!="NO"{

*pause on
*set trace on
set tracedepth 2

if "`do_parallel'"=="1" parallel_clean_setclusters $defnumclusters
local treat_ratio = `=1/10'

foreach n in 40 /*200 400 600*/{
	local n_treat = int(`n'*`treat_ratio')
	foreach T0 in 6 10 14{
		local T = `T0' + ${scr_est_period}
		global PRINTDOTS_WIDTH = cond(`n'>100,"20","")
		foreach F in 0 /*1*/ {
			di "MC n=`n' T0=`T0' F=`F'"
			forval rep=1/${nreps}{
				if ${nreps}>5 print_dots `rep' ${nreps}
				
				local startseed = c(rngstate)
				
				mat row = (`n',`T0',`F',`rep')
				dgp, n(`n') n_treat(`n_treat') t(`T') t0(`T0') t2(`t2') alpha0_vec(alpha0) f(`F') rho(${rho})
				qui synth_runner y, d(D) ci training_propr(0.5) max_lead(1)
				mat ci = e(ci)
				scalar wid95 = ci[2,1]-ci[1,1]
				scalar reject = (ci[1,1]> `alpha0_1' | ci[2,1]< `alpha0_1')
				mat row = (row, _b[l1], reject, wid95)
				
				if "`postname'"==""{
					tempname postname
					qui postfile `postname' str41 seed long(n T0 F rep) float b_scr`suff' reject_scr`suff' wid95_scr`suff' using data/estimates/mc_results.dta, every(1) replace
				}
				post_line_from_matrix row, local(post_line)
				post `postname' ("`startseed'") `post_line'
			}
		}
	}
}
postclose `postname'

} //endif DO_GEN

include ${main_root}code/proj_footer.do
