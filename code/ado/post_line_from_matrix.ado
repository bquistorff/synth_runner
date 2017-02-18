*See the matrix_post_lines command. Try to merge
program post_line_from_matrix
	syntax namelist(max=1 name=matname), local(string)
	
	local n = colsof(`matname')
	mata: st_local("str",invtokens(J(1,`n',"(`matname'[1,") + strofreal(1..`n')+J(1,`n',"])")))
	c_local `local' `str'
end
