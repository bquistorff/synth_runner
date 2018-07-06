*Used post -synth- to calculat RMSPE for certain sections of time periods,
* uses indexes into e(Y_treated) and e(Y_synthetic)
program calc_rmspe
	version 12 //haven't tested on earlier versions
	syntax , i_start(int) i_end(int) local(string)
	tempname pe
	mat `pe' = e(Y_treated) - e(Y_synthetic)
	mat `pe' = `pe'[`i_start'..`i_end',1]
	mat `pe' = `pe''*`pe'
	local rmspe = sqrt(`pe'[1,1]/`=1+`i_end'-`i_start'')
	
	c_local `local' = `rmspe'
end
