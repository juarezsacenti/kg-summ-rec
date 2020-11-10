#!/bin/bash
no_exist() {
for f in $1;
do
    ## Check if the glob gets expanded to existing files.
    ## If not, f here will be exactly the pattern above
    ## and the exists test will evaluate to false.
    if [ -e "$f" ]
    then
         return 1
    else
         return 0
    fi
done
}

################################################################################
###            Evaluate Sun's original KG without filtering                  ###
################################################################################
source ~/git/know-rec/hold-out_evaluate.sh "ml-sun_fil-0"

################################################################################
###              Evaluate Sun's original KG with filtering                   ###
################################################################################
source ~/git/know-rec/hold-out_evaluate.sh "ml-sun_fil-10"

################################################################################
###         Evaluate Sun's sKG without filtering using complex-25            ###
################################################################################
source ~/git/know-rec/hold-out_evaluate.sh "ml-sun_fil-0_complex-25"
source speedup_results.sh "ml-sun_fil-0" "complex" "25" > "$HOME/git/results/ml-sun_fil-0_complex-25/rec_cost.dat"

################################################################################
###          Evaluate Sun's sKG with filtering using complex-25              ###
################################################################################
source ~/git/know-rec/hold-out_evaluate.sh "ml-sun_fil-10_complex-25"
source speedup_results.sh "ml-sun_fil-10" "complex" "25" > "$HOME/git/results/ml-sun_fil-10_complex-25/rec_cost.dat"

################################################################################
###         Evaluate Sun's sKG without filtering using complex-50            ###
################################################################################
source ~/git/know-rec/hold-out_evaluate.sh "ml-sun_fil-0_complex-50"
source speedup_results.sh "ml-sun_fil-0" "complex" "50" > "$HOME/git/results/ml-sun_fil-0_complex-50/rec_cost.dat"

################################################################################
###          Evaluate Sun's sKG with filtering using complex-50              ###
################################################################################
source ~/git/know-rec/hold-out_evaluate.sh "ml-sun_fil-10_complex-50"
source speedup_results.sh "ml-sun_fil-10" "complex" "50" > "$HOME/git/results/ml-sun_fil-10_complex-50/rec_cost.dat"

################################################################################
###         Evaluate Sun's sKG without filtering using complex-75            ###
################################################################################
source ~/git/know-rec/hold-out_evaluate.sh "ml-sun_fil-0_complex-75"
source speedup_results.sh "ml-sun_fil-0" "complex" "75" > "$HOME/git/results/ml-sun_fil-0_complex-75/rec_cost.dat"

################################################################################
###          Evaluate Sun's sKG with filtering using complex-75              ###
################################################################################
source ~/git/know-rec/hold-out_evaluate.sh "ml-sun_fil-10_complex-75"
source speedup_results.sh "ml-sun_fil-10" "complex" "75" > "$HOME/git/results/ml-sun_fil-10_complex-75/rec_cost.dat"

################################################################################
###                       Evaluate Sun's sKG multiview                       ###
################################################################################
source ~/git/know-rec/hold-out_evaluate.sh "ml-sun_fil-0_complex-25_mv"
source ~/git/know-rec/hold-out_evaluate.sh "ml-sun_fil-0_complex-50_mv"
source ~/git/know-rec/hold-out_evaluate.sh "ml-sun_fil-0_complex-75_mv"

################################################################################
###                       Evaluate Cao's original KG                         ###
################################################################################
source ~/git/know-rec/hold-out_evaluate.sh "ml-cao"

################################################################################
###               Evaluate Cao's sKG with chosen parameters                  ###
################################################################################
source ~/git/know-rec/hold-out_evaluate.sh "ml-cao_complex-75"
source speedup_results.sh "ml-cao" "complex" "75" > "$HOME/git/results/ml-cao_complex-75/rec_cost.dat"

################################################################################
###         Evaluate Cao's sKG multiview with chosen parameters              ###
################################################################################
#source ~/git/know-rec/hold-out_evaluate.sh "ml-cao_mv_complex-X"

