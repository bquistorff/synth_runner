** Make sure to run the main usage.do (and "make usage-cleanup", or put the gphs in place)
graph use "fig/gph/cigsale1_raw.gph"
gr_edit .title.text = {"State Annual Cigarette Sales"}
gr_edit .yaxis1.title.text = {"Cigarette sales per capita (in packs)"}
gr_edit .legend.plotregion1.label[1].text = {"California"}
gr_edit .legend.plotregion1.label[2].text = {"Other states"}
graph export "fig/png/cigsale1_raw.png", replace

graph use "fig/gph/cigsale1_tc.gph"
gr_edit .title.text = {"Passage of California's Proposition 99 and Cigarette Sales"}
gr_edit .yaxis1.title.text = {"Cigarette sales per capita (in packs)"}
gr_edit .xaxis1.title.text = {"Year"}
gr_edit .legend.plotregion1.label[1].text = {"California"}
graph export "fig/png/cigsale1_tc.png", replace

graph use "fig/gph/cigsale1_effect.gph"
gr_edit .title.text = {"Difference between California and its Synthetic Control"}
gr_edit .xaxis1.title.text = {"Year"}
gr_edit .yaxis1.title.text = {"Cigarette sales per capita (in packs)"}
graph export "fig/png/cigsale1_effect.png", replace

graph use "fig/gph/cigsale1_effects.gph"
gr_edit .title.text = {"Differences between each State and its Synthetic Control"}
gr_edit .xaxis1.title.text = {"Year"}
gr_edit .yaxis1.title.text = {"Cigarette sales per capita (in packs)"}
gr_edit .legend.plotregion1.label[1].text = {"California"}
gr_edit .legend.plotregion1.label[2].text = {"Other states"}
graph export "fig/png/cigsale1_effects.png", replace

graph use "fig/gph/cigsale2_pval_t.gph"
gr_edit .title.text = {"Inference for Effects in Post-Treatment Years"}
gr_edit .yaxis1.title.text = {"Probability that effect would happen by chance"}
gr_edit .xaxis1.title.text = {"Number of years after Proposition 99"}
graph export "fig/png/cigsale2_pval_t.png", replace
