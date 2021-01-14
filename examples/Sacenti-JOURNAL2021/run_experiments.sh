#!/bin/bash
# This file is part of this program.
#
# Copyright 2020 Juarez Sacenti
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#######################################
# Run experiments for Sacenti 2021 - JOURNAL.
# - Datasets: ml-sun, ml-cao
# - Split: hold-out (ho)
# - Filtering: infrequent entities filtering at 0 (sKG) and at 10 (sfKG)
# - KG Summarization:
#   - Algorithms: KGE-K-Means (complex) and GEMSEC (gemsec)
#   - KG type: item graph (ig) and user-item graph (uig)
#   - Summarization mode: single-view (sv) and multi-view (mv)
#   - Entity preservation ratio: 75, 50 and 25%
#   - Results: summ_effects
# - KG Recommendation:
#   - Algorithms: CFKG, CKE, CoFM, JtransUp (KTUP); TransE, TransH, BPRMF,
#   TransUp (TUP)
#   - Results: recomm_quality, comp_cost
# GLOBALS:
#   HOME
#   experiment: running experiment. Default is 'Sacenti-JOURNAL2021'.
# FUNCTIONS:
#   preprocess_sun_oKG
#   preprocess_sun_fKG
#   summarize_sun_sKG
#   summarize_sun_sfKG
#   recommend_sun_sKG
#   recommend_sun_sfKG
#   run_experiments
#######################################
experiment='Sacenti-JOURNAL2021'

#######################################
# Import util/util.sh
# FUNCTIONS:
#   no_exist 'path_to_file'
#   copy_dataset 'path_to_dataset' 'path_to_new_dataset'
#######################################
source $HOME/git/kg-summ-rec/util/util.sh

#######################################
# Import preprocess/cao-format_ml-sun.sh
# FUNCTIONS:
#   cao-format_ml-sun 'dataset' 'low_frequence'
#######################################
source $HOME/git/kg-summ-rec/preprocess/cao-format_ml-sun.sh

#######################################
# Import kg_summarization.sh
# FUNCTIONS:
#   kg_summarization 'dataset' 'split_mode' 'filtering'
#######################################
source $HOME/git/kg-summ-rec/examples/${experiment}/kg_summarization.sh

#######################################
# Import kg_recommendation.sh
# FUNCTIONS:
#   kg_recommendation 'dataset' 'split_mode' 'filtering'
#######################################
#source $HOME/git/kg-summ-rec/examples/${experiment}/kg_recommendation.sh


####
# KG preprocessing
#
# - Datasets: ml-sun, ml-cao
# - Split: hold-out (ho)
# - Filtering: infrequent entities filtering at 0 (oKG) and at 10 (fKG)
####
preprocess_sun_oKG() {
    # Create folders for Sun's original KG (oKG)
    if no_exist "$HOME/git/datasets/${experiment}/ml-sun_ho_oKG"
    then
        echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/ml-sun_ho_oKG"
        cd $HOME/git/kg-summ-rec/util
        copy_ml_sun "$HOME/git/datasets/ml-sun" "$HOME/git/datasets/${experiment}/ml-sun_ho_oKG"
        cd $HOME/git/kg-summ-rec/examples/${experiment}
    fi

    # Preprocess oKG
    cd $HOME/git/kg-summ-rec/preprocess
    LOW_FREQUENCE=0    #Low Frequence Filtering (0, 10)
    cao-format_ml-sun "ml-sun_ho_oKG" ${LOW_FREQUENCE}
    cd $HOME/git/kg-summ-rec/examples/${experiment}

    # Collect oKG statistics
    if no_exist "$HOME/git/results/${experiment}/ml-sun_ho_oKG"
    then
        echo "[kg-summ-rec] Creating ~/git/results/${experiment}/ml-sun_ho_oKG"
        mkdir ~/git/results/${experiment}/ml-sun_ho_oKG
    fi
    if no_exist "$HOME/git/results/${experiment}/ml-sun_ho_oKG/kg-ig_stats.tsv"
    then
        echo "[kg-summ-rec] Creating ~/git/results/${experiment}/ml-sun_ho_oKG/kg-ig_stats.tsv"
        cd $HOME/git/kg-summ-rec/util
        conda deactivate
        conda activate kg-summ-rec
        python kg2rdf.py --mode 'statistics' --kgpath "~/git/datasets/${experiment}/ml-sun_ho_oKG" \
        --input "~/git/datasets/${experiment}/ml-sun_ho_oKG/kg-ig.nt" \
        --output "~/git/results/${experiment}/ml-sun_ho_oKG/kg-ig_stats.tsv"
        cd $HOME/git/kg-summ-rec/examples/${experiment}
    fi
}

preprocess_sun_fKG() {
    # Create folders for Sun's filtered KG (fKG)
    if no_exist "$HOME/git/datasets/${experiment}/ml-sun_ho_fKG"
    then
        echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/ml-sun_ho_fKG"
        cd $HOME/git/kg-summ-rec/util
        copy_ml_sun "$HOME/git/datasets/ml-sun" "$HOME/git/datasets/${experiment}/ml-sun_ho_fKG"
        cd $HOME/git/kg-summ-rec/examples/${experiment}
    fi

    # Preprocess fKG
    cd $HOME/git/kg-summ-rec/preprocess
    LOW_FREQUENCE=10    #Low Frequence Filtering (0, 10)
    cao-format_ml-sun "ml-sun_ho_fKG" ${LOW_FREQUENCE}
    cd $HOME/git/kg-summ-rec/examples/${experiment}

    # Collect oKG statistics
    if no_exist "$HOME/git/results/${experiment}/ml-sun_ho_fKG"
    then
        echo "[kg-summ-rec] Creating ~/git/results/${experiment}/ml-sun_ho_fKG"
        mkdir ~/git/results/${experiment}/ml-sun_ho_fKG
    fi
    if no_exist "$HOME/git/results/${experiment}/ml-sun_ho_fKG/kg-ig_stats.tsv"
    then
        echo "[kg-summ-rec] Creating ~/git/results/${experiment}/ml-sun_ho_fKG/kg-ig_stats.tsv"
        cd $HOME/git/kg-summ-rec/util
        conda deactivate
        conda activate kg-summ-rec
        python kg2rdf.py --mode 'statistics' --kgpath "~/git/datasets/${experiment}/ml-sun_ho_fKG" \
        --input "~/git/datasets/${experiment}/ml-sun_ho_fKG/kg-ig.nt" \
        --output "~/git/results/${experiment}/ml-sun_ho_fKG/kg-ig_stats.tsv"
        cd $HOME/git/kg-summ-rec/examples/${experiment}
    fi
}

####
# KG summarization
#
# - Datasets: ml-sun, ml-cao
# - Split: hold-out (ho)
# - Filtering: infrequent entities filtering at 0 (sKG) and at 10 (sfKG)
####
summarize_sun_sKG() {
    # KG summarization
    kg_summarization 'ml-sun' 'ho' 'sKG'
}

summarize_sun_sfKG() {
    # KG summarization
    kg_summarization 'ml-sun' 'ho' 'sfKG'
}

####
# KG recommendation
#
# - TODO ml-sun_ho_sKG_complex-uig-sv-75
# - TODO ml-sun_ho_sKG_complex-uig-sv-50
# - TODO ml-sun_ho_sKG_complex-uig-sv-25
# - TODO ml-sun_ho_sKG_complex-uig-mv-75
# - TODO ml-sun_ho_sKG_complex-uig-mv-50
# - TODO ml-sun_ho_sKG_complex-uig-mv-25
#
# - ml-sun_ho_sKG_gemsec-ig-sv-75
# - ml-sun_ho_sKG_gemsec-ig-sv-50
# - ml-sun_ho_sKG_gemsec-ig-sv-25
#
# - TODO ml-sun_ho_sKG_gemsec-ig-mv-75
# - TODO ml-sun_ho_sKG_gemsec-ig-mv-50
# - TODO ml-sun_ho_sKG_gemsec-ig-mv-25
#
# - TODO ml-sun_ho_sKG_gemsec-uig-sv-75
# - TODO ml-sun_ho_sKG_gemsec-uig-sv-50
# - TODO ml-sun_ho_sKG_gemsec-uig-sv-25
#
# - TODO ml-sun_ho_sKG_gemsec-uig-mv-75
# - TODO ml-sun_ho_sKG_gemsec-uig-mv-50
# - TODO ml-sun_ho_sKG_gemsec-uig-mv-25
#
# (Sacenti-JIIS2021)
# - ml-sun_ho_oKG
# - ml-sun_ho_fKG
#
# - ml-sun_ho_sKG_complex-ig-sv-75
# - ml-sun_ho_sKG_complex-ig-sv-50
# - ml-sun_ho_sKG_complex-ig-sv-25
# - ml-sun_ho_sfKG_complex-ig-sv-75
# - ml-sun_ho_sfKG_complex-ig-sv-50
# - ml-sun_ho_sfKG_complex-ig-sv-25
#
# - ml-sun_ho_sKG_complex-ig-mv-75
# - ml-sun_ho_sKG_complex-ig-mv-50
# - ml-sun_ho_sKG_complex-ig-mv-25
# - ml-sun_ho_sfKG_complex-ig-mv-75
# - ml-sun_ho_sfKG_complex-ig-mv-50
# - ml-sun_ho_sfKG_complex-ig-mv-25
####
recommend_sun_sKG() {
    source kg_recommendation_ho_ml-sun.sh "ml-sun_ho_oKG" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
    source kg_recommendation_ho_ml-sun.sh "ml-sun_ho_sv_sKG_complex-75" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
    source kg_recommendation_ho_ml-sun.sh "ml-sun_ho_sv_sKG_complex-50" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
    source kg_recommendation_ho_ml-sun.sh "ml-sun_ho_sv_sKG_complex-25" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
    source kg_recommendation_ho_ml-sun.sh "ml-sun_ho_mv_sKG_complex-75" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
    source kg_recommendation_ho_ml-sun.sh "ml-sun_ho_mv_sKG_complex-50" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
    source kg_recommendation_ho_ml-sun.sh "ml-sun_ho_mv_sKG_complex-25" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
}

####
# KG recommendation
#
# - TODO ml-sun_ho_sfKG_complex-uig-sv-75
# - TODO ml-sun_ho_sfKG_complex-uig-sv-50
# - TODO ml-sun_ho_sfKG_complex-uig-sv-25
# - TODO ml-sun_ho_sfKG_complex-uig-mv-75
# - TODO ml-sun_ho_sfKG_complex-uig-mv-50
# - TODO ml-sun_ho_sfKG_complex-uig-mv-25
#
# - ml-sun_ho_sfKG_gemsec-ig-sv-75
# - ml-sun_ho_sfKG_gemsec-ig-sv-50
# - ml-sun_ho_sfKG_gemsec-ig-sv-25
#
# - TODO ml-sun_ho_sfKG_gemsec-ig-mv-75
# - TODO ml-sun_ho_sfKG_gemsec-ig-mv-50
# - TODO ml-sun_ho_sfKG_gemsec-ig-mv-25
#
# - TODO ml-sun_ho_sfKG_gemsec-uig-sv-75
# - TODO ml-sun_ho_sfKG_gemsec-uig-sv-50
# - TODO ml-sun_ho_sfKG_gemsec-uig-sv-25
#
# - TODO ml-sun_ho_sfKG_gemsec-uig-mv-75
# - TODO ml-sun_ho_sfKG_gemsec-uig-mv-50
# - TODO ml-sun_ho_sfKG_gemsec-uig-mv-25
#
# (Sacenti-JIIS2021)
# - ml-sun_ho_fKG
#
# - ml-sun_ho_sfKG_complex-ig-sv-75
# - ml-sun_ho_sfKG_complex-ig-sv-50
# - ml-sun_ho_sfKG_complex-ig-sv-25
#
# - ml-sun_ho_sfKG_complex-ig-mv-75
# - ml-sun_ho_sfKG_complex-ig-mv-50
# - ml-sun_ho_sfKG_complex-ig-mv-25
####
recommend_sun_sfKG() {
    source kg_recommendation_ho_ml-sun.sh "ml-sun_ho_fKG" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
    source kg_recommendation_ho_ml-sun.sh "ml-sun_ho_sv_sfKG_complex-75" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
    source kg_recommendation_ho_ml-sun.sh "ml-sun_ho_sv_sfKG_complex-50" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
    source kg_recommendation_ho_ml-sun.sh "ml-sun_ho_sv_sfKG_complex-25" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
    source kg_recommendation_ho_ml-sun.sh "ml-sun_ho_mv_sfKG_complex-75" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
    source kg_recommendation_ho_ml-sun.sh "ml-sun_ho_mv_sfKG_complex-50" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
    source kg_recommendation_ho_ml-sun.sh "ml-sun_ho_mv_sfKG_complex-25" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
}

run_experiments() {
    if [ ! -d "$HOME/git/datasets/${experiment}" ]
    then
       echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}"
       mkdir "$HOME/git/datasets/${experiment}"
       mkdir "$HOME/git/results/${experiment}"        
    fi
    
    # Preprocessing
    preprocess_sun_oKG
    preprocess_sun_fKG

    # Summarization
    summarize_sun_sKG
    #summarize_sun_sfKG

    # Recommendation
    #recommend_sun_sKG
    #recommend_sun_sfKG
}
run_experiments
