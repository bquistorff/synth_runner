program define clear_char

    version 9.2
    syntax [varlist] , [Dataset only]
    
    local vlist `varlist'
    
    if "`dataset'" ~= "" {
        local vlist _dta `vlist'
        if "`only'" != "" local vlist "_dta"
    }
    
    foreach v in `vlist' {
        local ilist: char `v'[]
        foreach i in `ilist' {
            char `v'[`i']
        }
    }
end
