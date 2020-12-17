#!/bin/bash

####
# Run experiments for Sacenti 2021 - JIIS.
# 
# - Datasets: ml-sun
# - Split: hold-out
# - KG Summarization: complex-75, complex-50 and complex-25
# - Filtering: fil-0 and fil-10
# - KG Recommendation: CFKG, CKE, CoFM, KTUP (JtransUp) (+ TransE, TransH, BPRMF, TUP)
# - Results: summ_effects, recomm_quality, comp_cost
####

####
# Import util/util.sh
#
# - no_exist 'path_to_file' 
# - copy_dataset 'path_to_dataset' 'path_to_new_dataset'
####
source util/util.sh

####
# Create folders (original KG and fKG)
#
# - Nomenclature: {ho: hold-out, kf: k-fold, sv: single-view, mv: multi-view,
#   sKG (infrequent entities filtering at 0), sfKG (infrequent entities filtering at 10)}
# - ml-sun_ho_originalKG
# - ml-sun_ho_fKG
####

if no_exist "$HOME/git/datasets/ml-sun_ho_originalKG"
then 
    echo "[kg-summ-rs] Creating ~/git/datasets/ml-sun_ho_originalKG"
    copy_ml_sun "$HOME/git/datasets/ml-sun" "$HOME/git/datasets/ml-sun_ho_originalKG"
fi

if no_exist "$HOME/git/datasets/ml-sun_ho_fKG"
then
    echo "[kg-summ-rs] Creating ~/git/datasets/ml-sun_ho_fKG"
    copy_ml_sun "$HOME/git/datasets/ml-sun" "$HOME/git/datasets/ml-sun_ho_fKG"
fi

####
# Preprocess originalKG and fKG
#
# - ml-sun_ho_originalKG
# - ml-sun_ho_fKG
####
cd preprocess
LOW_FREQUENCE=0    #Low Frequence Filtering (0, 10)
source cao-format_ml-sun.sh "ml-sun_ho_originalKG" ${LOW_FREQUENCE}
cd ..

cd preprocess
LOW_FREQUENCE=10    #Low Frequence Filtering (0, 10)
source cao-format_ml-sun.sh "ml-sun_ho_fKG" ${LOW_FREQUENCE}
cd ..

####
# Collect KG stats
#
# - ml-sun_ho_originalKG
# - ml-sun_ho_fKG
####
if no_exist "$HOME/git/results/ml-sun_ho_originalKG"
then
    echo "[kg-summ-rs] Creating ~/git/results/ml-sun_ho_originalKG"
    mkdir ~/git/results/ml-sun_ho_originalKG
fi

if no_exist "$HOME/git/results/ml-sun_ho_fKG"
then
    echo "[kg-summ-rs] Creating ~/git/results/ml-sun_ho_fKG"
    mkdir ~/git/results/ml-sun_ho_fKG
fi

conda deactivate
conda activate jointrec

if no_exist "$HOME/git/results/ml-sun_ho_originalKG/kg_stats.tsv"
then
    echo "[kg-summ-rs] Creating ~/git/results/ml-sun_ho_originalKG/kg_stats.tsv"
    cd util
    python kg2rdf.py --mode 'statistics' --kgpath "~/git/datasets/ml-sun_ho_originalKG" --output "~/git/results/ml-sun_ho_originalKG/kg_stats.tsv"
    cd ..
fi

if no_exist "$HOME/git/results/ml-sun_ho_fKG/kg_stats.tsv"
then
    echo "[kg-summ-rs] Creating ~/git/results/ml-sun_ho_fKG/kg_stats.tsv"
    cd util
    python kg2rdf.py --mode 'statistics' --kgpath "~/git/datasets/ml-sun_ho_fKG" --output "~/git/results/ml-sun_ho_fKG/kg_stats.tsv"
    cd ..
fi

####
# KG summarization
#
# - ml-sun_ho_sv_sKG_complex-75
# - ml-sun_ho_sv_sKG_complex-50
# - ml-sun_ho_sv_sKG_complex-25
# - ml-sun_ho_sv_sfKG_complex-75
# - ml-sun_ho_sv_sfKG_complex-50
# - ml-sun_ho_sv_sfKG_complex-25
# - ml-sun_ho_mv_sKG_complex-75
# - ml-sun_ho_mv_sKG_complex-50
# - ml-sun_ho_mv_sKG_complex-25
# - ml-sun_ho_mv_sfKG_complex-75
# - ml-sun_ho_mv_sfKG_complex-50
# - ml-sun_ho_mv_sfKG_complex-25
####
yes | rm -r ~/git/know-rec/docker/kge-k-means_data/temp/*.*
LOW_FREQUENCE=0    #Low Frequence Filtering (0, 10)
source kg_summarization_ho_sv.sh "ml-sun_ho_originalKG" "ml-sun_ho_sv_sKG" 'complex' 150 100 '0.005' ${LOW_FREQUENCE}

yes | rm -r ~/git/know-rec/docker/kge-k-means_data/temp/*.*
LOW_FREQUENCE=10    #Low Frequence Filtering (0, 10)
source kg_summarization_ho_sv.sh "ml-sun_ho_fKG" "ml-sun_ho_sv_sfKG" 'complex' 150 100 '0.005' ${LOW_FREQUENCE}

yes | rm -r ~/git/know-rec/docker/kge-k-means_data/temp/*.*
LOW_FREQUENCE=0    #Low Frequence Filtering (0, 10)
source kg_summarization_ho_mv.sh "ml-sun_ho_originalKG" "ml-sun_ho_mv_sKG" 'complex' 150 100 '0.005' ${LOW_FREQUENCE}

yes | rm -r ~/git/know-rec/docker/kge-k-means_data/temp/*.*
LOW_FREQUENCE=10    #Low Frequence Filtering (0, 10)
source kg_summarization_ho_mv.sh "ml-sun_ho_fKG" "ml-sun_ho_mv_sfKG" 'complex' 150 100 '0.005' ${LOW_FREQUENCE}

####
# KG recommendation
#
# - ml-sun_ho_originalKG
# - ml-sun_ho_fKG
# - ml-sun_ho_sv_sKG_complex-75
# - ml-sun_ho_sv_sKG_complex-50
# - ml-sun_ho_sv_sKG_complex-25
# - ml-sun_ho_sv_sfKG_complex-75
# - ml-sun_ho_sv_sfKG_complex-50
# - ml-sun_ho_sv_sfKG_complex-25
# - ml-sun_ho_mv_sKG_complex-75
# - ml-sun_ho_mv_sKG_complex-50
# - ml-sun_ho_mv_sKG_complex-25
# - ml-sun_ho_mv_sfKG_complex-75
# - ml-sun_ho_mv_sfKG_complex-50
# - ml-sun_ho_mv_sfKG_complex-25
####
source kg_recommendation_ho_ml-sun.sh "ml-sun_ho_originalKG" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
source kg_recommendation_ho_ml-sun.sh "ml-sun_ho_fKG" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
source kg_recommendation_ho_ml-sun.sh "ml-sun_ho_sv_sKG_complex-75" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
source kg_recommendation_ho_ml-sun.sh "ml-sun_ho_sv_sKG_complex-50" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
source kg_recommendation_ho_ml-sun.sh "ml-sun_ho_sv_sKG_complex-25" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
source kg_recommendation_ho_ml-sun.sh "ml-sun_ho_sv_sfKG_complex-75" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
source kg_recommendation_ho_ml-sun.sh "ml-sun_ho_sv_sfKG_complex-50" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
source kg_recommendation_ho_ml-sun.sh "ml-sun_ho_sv_sfKG_complex-25" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
source kg_recommendation_ho_ml-sun.sh "ml-sun_ho_mv_sKG_complex-75" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
source kg_recommendation_ho_ml-sun.sh "ml-sun_ho_mv_sKG_complex-50" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
source kg_recommendation_ho_ml-sun.sh "ml-sun_ho_mv_sKG_complex-25" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
source kg_recommendation_ho_ml-sun.sh "ml-sun_ho_mv_sfKG_complex-75" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
source kg_recommendation_ho_ml-sun.sh "ml-sun_ho_mv_sfKG_complex-50" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
source kg_recommendation_ho_ml-sun.sh "ml-sun_ho_mv_sfKG_complex-25" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005

