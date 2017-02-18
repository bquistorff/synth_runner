# Github targets depend on relative path to those repos (../GitHub/)
# The deliverables automatically overwrite
# Comments that begin with ## will be shown from target help

##Work-flow
## Open Stata 12, navigate to the folder, and do:
##  do code/test.do
## Then, if no errors:
##  make usage-cleanup
## If making module, next:
##  make check
##  make github-deliverable

.PHONY: list help
help : 
	@echo "Output comments:"
	@echo
	@sed -n 's/^##//p' makefile
	@printf "\nList of all targets: "
	@$(MAKE) -s list

# List targets (http://stackoverflow.com/a/26339924/3429373)
list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$' | xargs

.PHONY: sj-deliverable usage-cleanup usage-delete clean check_smcl check_version check module

	
# get the list of eps files from
#. grepr eps writeups/synth_runner_sj.lyx | grep filename | cut -c14- | tr '\n' ' '
sj-deliverable:
	-rm deliverables/sj/*.zip
	zip -j deliverables/sj/figs.zip fig/eps/cigsale1_raw.eps fig/eps/cigsale1_effects.eps fig/eps/cigsale1_effect.eps fig/eps/cigsale1_tc.eps fig/eps/cigsale2_pval.eps fig/eps/cigsale2_pval_t.eps fig/eps/cigsale2_raw.eps fig/eps/cigsale2_effects.eps fig/eps/cigsale3_effect.eps fig/eps/cigsale3_tc.eps
	zip -j deliverables/sj/program_files.zip code/ado/calc_RMSPE.ado code/ado/effect_graphs.ado code/ado/pval_graphs.ado code/ado/single_treatment_graphs.ado code/ado/synth_runner.ado code/ado/synth_runner.pkg code/ado/synth_runner.sthlp code/ado/synth_wrapper.ado code/usage.do
	cp writeups/synth_runner_sj.pdf deliverables/sj
	# README.txt is already there
	
usage-cleanup:
	-mv *.log log/do/
	-mv *.gph fig/gph/
	-mv *.eps fig/eps/
	-mv *.pdf fig/pdf/

usage-delete:
	-rm *.log
	-rm *.gph
	-rm *.eps
	-rm *.pdf
	
clean:
	-rm -f temp/* temp/lastrun/*

check : check_smcl check_version inc_dist_date
	
inc_dist_date:
	sed -i "s/\(d Distribution-Date: \).\+/\1$$(date +%Y%m%d)/g" code/ado/synth_runner.pkg

#Smcl has problems displaying lines over 244 characters
check_smcl:
	@echo "Will display lines if error"
	-grep '.\{245\}' code/ado/synth_runner.sthlp
	@echo ""

check_version:
	@echo "Visually ensure numbers are the same:"
	grep Version code/ado/synth_runner.sthlp
	@echo
	grep Version code/ado/synth_runner.pkg
	@echo
	@echo code/ado/synth_runner.ado
	@grep "! version" code/ado/synth_runner.ado
	@grep "local version" code/ado/synth_runner.ado
	@grep '"version" as' code/ado/synth_runner.ado
	@echo ""