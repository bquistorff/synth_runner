/* subroutine lossfunction: loss function for nested optimization */
program synth_ll
        version 9.2
        args todo b lnf
        tempname loss loss_final loss_var bb VV H c A l u wsol
        *matrix list `b'

       /* get abs constrained weights and create V */
        mata: getabs("`b'")
        mat `bb' = matout
        mat `VV' = diag(`bb')

       /* Set up quadratic programming */
        mat `H' =  ($Xco)' * `VV' * $Xco
        mat `c' = (-1 * (($Xtr)' * `VV' * $Xco))'
        mat `A' = J(1,rowsof(`c'),1)
        mat `l' = J(rowsof(`c'),1,0)
        mat `u' = J(rowsof(`c'),1,1)

      /* Initialize read out matrix  */
      matrix `wsol' = `l'

     /* do quadratic programming step  */
      plugin call synthopt , `c' `H'  `A' $bslack `l' `u' $bd $marg $maxit $sig `wsol'

     /* Compute loss */
      mat `loss' = ($Ztr - $Zco * `wsol')' * ( $Ztr - $Zco * `wsol')
      qui svmat  double `loss' ,names(`loss_var')
      qui gen    double `loss_final' = -1 * `loss_var'
      qui mlsum  `lnf'  = `loss_final' if `loss_var' ~=.
*      sum    `loss_final'
      qui drop   `loss_final' `loss_var'
end /* main program ends finally */

/* subroutine quadratic programming (C++ plugin) */
program synthopt, plugin
