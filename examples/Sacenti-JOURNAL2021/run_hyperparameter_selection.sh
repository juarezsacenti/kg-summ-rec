#!/bin/bash

####
# Run hyper-parameter selection for experiments from Sacenti 2021 - JIIS
# 
# - Datasets: ml-sun
# - Split: hold-out
# - KG Summarization: Mult-view complex-50
# - Filtering: Low frequence at 0 
# - KG Recommendation: CFKG
# - Results: summ_effects, recomm_quality, comp_cost
# - Tests: epoch threshold {a-j}, batch {32,256}, learning rate {0.1, 0.005}, 
####

####
# Import util/util.sh
#
# - no_exist 'path_to_file' 
# - copy_dataset 'path_to_dataset' 'path_to_new_dataset'
####
source util/util.sh

####
# Create folders (original KG)
#
# - Nomenclature: {hs: hyperparameter selection, ho: hold-out, kf: k-fold, sv: single-view, mv: multi-view,
#   sKG (infrequent entities filtering at 0), sfKG (infrequent entities filtering at 10)}
# - hs_ml-sun_ho_originalKG
####

if no_exist "$HOME/git/datasets/hs_ml-sun_ho_originalKG"
then 
    echo "[kg-summ-rs] Creating ~/git/datasets/hs_ml-sun_ho_originalKG"
    copy_ml_sun "$HOME/git/datasets/ml-sun" "$HOME/git/datasets/hs_ml-sun_ho_originalKG"
fi

####
# Preprocess originalKG
#
# - ml-sun_ho_originalKG
####
cd preprocess
LOW_FREQUENCE=0    #Low Frequence Filtering (0, 10)
source cao-format_ml-sun.sh "hs_ml-sun_ho_originalKG" ${LOW_FREQUENCE}
cd ..

####
# Collect KG stats
#
# - ml-sun_ho_originalKG
####
if no_exist "$HOME/git/results/hs_ml-sun_ho_originalKG"
then
    echo "[kg-summ-rs] Creating ~/git/results/hs_ml-sun_ho_originalKG"
    mkdir ~/git/results/hs_ml-sun_ho_originalKG
fi

conda deactivate
conda activate jointrec

if no_exist "$HOME/git/results/hs_ml-sun_ho_originalKG/kg_stats.tsv"
then
    echo "[kg-summ-rs] Creating ~/git/results/hs_ml-sun_ho_originalKG/kg_stats.tsv"
    cd util
    python kg2rdf.py --mode 'statistics' --kgpath "~/git/datasets/hs_ml-sun_ho_originalKG" --output "~/git/results/hs_ml-sun_ho_originalKG/kg_stats.tsv"
    cd ..
fi

####
# KG summarization
#
# - ml-sun_ho_mv_sKG_complex-75
# - ml-sun_ho_mv_sKG_complex-50
# - ml-sun_ho_mv_sKG_complex-25
####
source clean_kge-k-means.sh
LOW_FREQUENCE=0    #Low Frequence Filtering (0, 10)
source kg_summarization_ho_mv.sh "hs_ml-sun_ho_originalKG" "hs_ml-sun_ho_mv_sKG" 'complex' 300 50 '1e-4' ${LOW_FREQUENCE}

####
# Hyperparameter selection for KG recommendation step
#
# - KG summarization: KGE-K-MEANS using multi-view ComplEx, Adam 
#   optimizer, L3 regularizer and K-Means with k rate at 50
# - KG recommendation: CFKG using epoch at alternative g, batch size at
#   256, learning rate at 0.005 
# - Tests: epochs, batch size, learning rate 
#
# ---- EPOCHS ----
# - Cao's project parameters: {knowledge_representation: '-eval_interval_steps 9150 -training_steps 915000 -early_stopping_steps_to_wait 45750', item_recommendation: '-eval_interval_steps 5000 -training_steps 500000 -early_stopping_steps_to_wait 25000', knowledgable_recommendation: '-eval_interval_steps 19520 -training_steps 1952000 -early_stopping_steps_to_wait 97600'} for dataset dbbook2014: {ratings: '65961', triples: '334511'}
# Cao's project epochs rate: {knowledge_representation: 'training 700 epochs, evaluating every 7 epochs an waiting for 35 epochs', item_recommendation: 'training 2000 epochs, evaluating every 20 epochs an waiting for 100 epochs', knowledgable_recommendation: 'training 1300 epochs, evaluating every 13 epochs an waiting for 65 epochs'} -> 'training 100 epochs, evaluating every 1 epochs an waiting for 5 epochs'
# - Sun's dataset: {ratings: '99975', triples: '12311'} -> 10% of Cao's ratings, ~3% of Cao's triples
# - Datasets split ratio: 7:1:2 (training, validation, test)
# - Our evaluation: 'training 100 epochs, evaluating every 1 epochs an waiting for 5 epochs', 'training 100 epochs, evaluating every 5 epochs an waiting for 25 epochs', 'training 500 epochs, evaluating every 5 epochs an waiting for 25 epochs', 'training 4500 epochs, evaluating every 45 epochs an waiting for 255 epochs'
#
# ---- LEARNING RATE ----
# - Cao's project parameters: {0.0005, 0.005, 0.001, 0.05, 0.01}
# - Our evaluation: {0.005, 0.1}
#
# ---- BATCH_SIZE ----
# - Our evaluation: {32, 256}
#
####

DATASET='hs_ml-sun_ho_mv_sKG_complex-50'

if no_exist "$HOME/git/results/${DATASET}_epoch-i"
then
    echo "[kg-summ-rs] Creating ~/git/results/${DATASET}_epoch-i"
    mkdir "$HOME/git/results/${DATASET}_epoch-a"
    mkdir "$HOME/git/results/${DATASET}_epoch-b"
    mkdir "$HOME/git/results/${DATASET}_epoch-c"
    mkdir "$HOME/git/results/${DATASET}_epoch-d"
    mkdir "$HOME/git/results/${DATASET}_epoch-e"
    mkdir "$HOME/git/results/${DATASET}_epoch-f"
    mkdir "$HOME/git/results/${DATASET}_epoch-g"
    mkdir "$HOME/git/results/${DATASET}_epoch-h"
    mkdir "$HOME/git/results/${DATASET}_epoch-i"
    mkdir "$HOME/git/results/${DATASET}_epoch-j"
    mkdir "$HOME/git/results/${DATASET}_lr-a"
    mkdir "$HOME/git/results/${DATASET}_bs-a"
    mkdir "$HOME/git/results/${DATASET}_bs-b"
fi

# ---- BASELINE* ----
# baseline epoch 'training 6357 epochs, evaluating every 63 epochs and waiting for 315 epochs'
source kg_recommendation_ho_hs_ml-sun.sh "hs_ml-sun_ho_mv_sKG_complex-50" "hs_ml-sun_ho_mv_sKG_complex-50" '9150,915000,45750' '5000,500000,25000' '500,50000,2500' '19520,1952000,97600' 256 0.005

# ---- EPOCHS ----
# a) 'training 100 epochs, evaluating every 1 epochs and waiting for 5 epochs'
# triples: (12311*0.7)/256 ~= 34, (99975*0.7)/256 ~= 274, ((12311*0.7)+(99975*0.7))/256 ~= 308
source kg_recommendation_ho_hs_ml-sun.sh "hs_ml-sun_ho_mv_sKG_complex-50" "hs_ml-sun_ho_mv_sKG_complex-50_epoch-a" '34,3400,170' '274,27400,1370' '27,2740,137' '308,30800,1540' 256 0.005
# b) 'training 100 epochs, evaluating every 5 epochs and waiting for 25 epochs'
source kg_recommendation_ho_hs_ml-sun.sh "hs_ml-sun_ho_mv_sKG_complex-50" "hs_ml-sun_ho_mv_sKG_complex-50_epoch-b" '170,3400,850' '1370,27400,6850' '137,2740,685' '1540,30800,7700' 256 0.005
# c) 'training 500 epochs, evaluating every 5 epochs and waiting for 25 epochs'
source kg_recommendation_ho_hs_ml-sun.sh "hs_ml-sun_ho_mv_sKG_complex-50" "hs_ml-sun_ho_mv_sKG_complex-50_epoch-c" '170,17000,850' '1370,137000,6850' '137,13700,685' '1540,154000,7700' 256 0.005
# d) 'training 635 epochs, evaluating every 6 epochs and waiting for 30 epochs' - 10% Cao's parameters
source kg_recommendation_ho_hs_ml-sun.sh "hs_ml-sun_ho_mv_sKG_complex-50" "hs_ml-sun_ho_mv_sKG_complex-50_epoch-d" '915,91500,4575' '500,50000,2500' '50,5000,250' '1952,195200,9760' 256 0.005
# e) 'training 1899 epochs, evaluating every 18 epochs an waiting for 90 epochs' - based on dbbook2014 number of triples (334511). 
source kg_recommendation_ho_hs_ml-sun.sh "hs_ml-sun_ho_mv_sKG_complex-50" "hs_ml-sun_ho_mv_sKG_complex-50_epoch-e" '2735,273500,13675' '1495,149500,7475' '149,14950,747' '5833,583300,29165' 256 0.005
# f) 'training 1270 epochs, evaluating every 13 epochs an waiting for 65 epochs'
source kg_recommendation_ho_hs_ml-sun.sh "hs_ml-sun_ho_mv_sKG_complex-50" "hs_ml-sun_ho_mv_sKG_complex-50_epoch-f" '1587,158700,7937' '1000,100000,5000' '100,10000,500' '3899,389900,19495' 256 0.005
# g) 'training 3385 epochs, evaluating every 34 epochs an waiting for 170 epochs'
source kg_recommendation_ho_hs_ml-sun.sh "hs_ml-sun_ho_mv_sKG_complex-50" "hs_ml-sun_ho_mv_sKG_complex-50_epoch-g" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
# h) 'training 4870 epochs, evaluating every 48 epochs an waiting for 240 epochs'
source kg_recommendation_ho_hs_ml-sun.sh "hs_ml-sun_ho_mv_sKG_complex-50" "hs_ml-sun_ho_mv_sKG_complex-50_epoch-h" '7010,470100,35050' '3832,383200,19160' '383,38320,1331' '14950,1495000,74750' 256 0.005
# i) 'training 3880 epochs, evaluating every 38 epochs an waiting for 190 epochs'
source kg_recommendation_ho_hs_ml-sun.sh "hs_ml-sun_ho_mv_sKG_complex-50" "hs_ml-sun_ho_mv_sKG_complex-50_epoch-i" '5584,558400,27923' '3051,305100,15258' '305,30510,1525' '11914,1191400,59570' 256 0.005
# j) 'training 4375 epochs, evaluating every 43 epochs an waiting for 215 epochs'
source kg_recommendation_ho_hs_ml-sun.sh "hs_ml-sun_ho_mv_sKG_complex-50" "hs_ml-sun_ho_mv_sKG_complex-50_epoch-j" '6297,629700,31485' '3441,344100,17205' '344,34410,1720' '13434,1343400,67170' 256 0.005

# ---- BATCH SIZE ----
# a) 32
source kg_recommendation_ho_hs_ml-sun.sh "hs_ml-sun_ho_mv_sKG_complex-50" "hs_ml-sun_ho_mv_sKG_complex-50_bs-a" '9150,915000,45750' '5000,500000,25000' '500,50000,2500' '19520,1952000,97600' 32 0.005
# b) 512
source kg_recommendation_ho_hs_ml-sun.sh "hs_ml-sun_ho_mv_sKG_complex-50" "hs_ml-sun_ho_mv_sKG_complex-50_bs-b" '9150,915000,45750' '5000,500000,25000' '500,50000,2500' '19520,1952000,97600' 512 0.005

# ---- LEARNING RATE ----
# a) 0.1
source kg_recommendation_ho_hs_ml-sun.sh "hs_ml-sun_ho_mv_sKG_complex-50" "hs_ml-sun_ho_mv_sKG_complex-50_lr-a" '9150,915000,45750' '5000,500000,25000' '500,50000,2500' '19520,1952000,97600' 256 0.1

####
# Hyperparameter selecion for KG summarization step
#
# - KG summarization: KGE-K-MEANS using multi-view ComplEx, Adam 
#   optimizer, L3 regularizer and K-Means with k rate at 50
# - KG recommendation: CFKG using epoch at alternative g, batch size at
#   256, learning rate at 0.005 
# - Tests: epochs, batch size, learning rate 
#
# ---- EPOCHS ----
# 150, 300*, 600, 1200
#
# ---- BATCH SIZE ----
# 50*, 100, 256
#
# ---- LEARNING RATE ----
# 0.005, 0.001, 0.0005, 0.0001*
####

# ---- BASELINE* ----
# "hs_ml-sun_ho_mv_sKG_complex-50_epoch-g" using epochs at 300, batch size at 50 and learning rate at 1e-4 

# ---- EPOCHS ----
# a) 150
yes | rm -r ~/git/know-rec/docker/kge-k-means_data/temp/*.*
LOW_FREQUENCE=0    #Low Frequence Filtering (0, 10)
source kg_summarization_ho_mv.sh "hs_ml-sun_ho_originalKG" "hs_ml-sun_ho_mv_sKG_epoch-a" 'complex' 150 50 '1e-4' ${LOW_FREQUENCE}
# b) 600
yes | rm -r ~/git/know-rec/docker/kge-k-means_data/temp/*.*
LOW_FREQUENCE=0    #Low Frequence Filtering (0, 10)
source kg_summarization_ho_mv.sh "hs_ml-sun_ho_originalKG" "hs_ml-sun_ho_mv_sKG_epoch-b" 'complex' 600 50 '1e-4' ${LOW_FREQUENCE}
# c) 1200
yes | rm -r ~/git/know-rec/docker/kge-k-means_data/temp/*.*
LOW_FREQUENCE=0    #Low Frequence Filtering (0, 10)
source kg_summarization_ho_mv.sh "hs_ml-sun_ho_originalKG" "hs_ml-sun_ho_mv_sKG_epoch-c" 'complex' 1200 50 '1e-4' ${LOW_FREQUENCE}

# ---- BATCH SIZE ----
# a) 100
yes | rm -r ~/git/know-rec/docker/kge-k-means_data/temp/*.*
LOW_FREQUENCE=0    #Low Frequence Filtering (0, 10)
source kg_summarization_ho_mv.sh "hs_ml-sun_ho_originalKG" "hs_ml-sun_ho_mv_sKG_bs-a" 'complex' 300 100 '1e-4' ${LOW_FREQUENCE}
# b) 256
yes | rm -r ~/git/know-rec/docker/kge-k-means_data/temp/*.*
LOW_FREQUENCE=0    #Low Frequence Filtering (0, 10)
source kg_summarization_ho_mv.sh "hs_ml-sun_ho_originalKG" "hs_ml-sun_ho_mv_sKG_bs-b" 'complex' 300 256 '1e-4' ${LOW_FREQUENCE}

# ---- LEARNING RATE ----
# a) 0.005
yes | rm -r ~/git/know-rec/docker/kge-k-means_data/temp/*.*
LOW_FREQUENCE=0    #Low Frequence Filtering (0, 10)
source kg_summarization_ho_mv.sh "hs_ml-sun_ho_originalKG" "hs_ml-sun_ho_mv_sKG_lr-a" 'complex' 300 50 0.005 ${LOW_FREQUENCE}
# b) 0.001
yes | rm -r ~/git/know-rec/docker/kge-k-means_data/temp/*.*
LOW_FREQUENCE=0    #Low Frequence Filtering (0, 10)
source kg_summarization_ho_mv.sh "hs_ml-sun_ho_originalKG" "hs_ml-sun_ho_mv_sKG_lr-b" 'complex' 300 50 0.001 ${LOW_FREQUENCE}
# c) 0.0005
yes | rm -r ~/git/know-rec/docker/kge-k-means_data/temp/*.*
LOW_FREQUENCE=0    #Low Frequence Filtering (0, 10)
source kg_summarization_ho_mv.sh "hs_ml-sun_ho_originalKG" "hs_ml-sun_ho_mv_sKG_lr-c" 'complex' 300 50 0.0005 ${LOW_FREQUENCE}

# KG recommendation step
DATASET='hs_ml-sun_ho_mv_sKG'

if no_exist "$HOME/git/results/${DATASET}_epoch-a_complex-50"
then
    echo "[kg-summ-rs] Creating ~/git/results/${DATASET}_epoch-a_complex-50"
    mkdir "$HOME/git/results/${DATASET}_epoch-a_complex-50"
    mkdir "$HOME/git/results/${DATASET}_epoch-b_complex-50"
    mkdir "$HOME/git/results/${DATASET}_epoch-c_complex-50"
    mkdir "$HOME/git/results/${DATASET}_bs-a_complex-50"
    mkdir "$HOME/git/results/${DATASET}_bs-b_complex-50"
    mkdir "$HOME/git/results/${DATASET}_lr-a_complex-50"
    mkdir "$HOME/git/results/${DATASET}_lr-b_complex-50"
    mkdir "$HOME/git/results/${DATASET}_lr-c_complex-50"
fi

source kg_recommendation_ho_hs_ml-sun.sh "hs_ml-sun_ho_mv_sKG_complex-50_epoch-g" "hs_ml-sun_ho_mv_sKG_complex-50_epoch-g" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
source kg_recommendation_ho_hs_ml-sun.sh "hs_ml-sun_ho_mv_sKG_epoch-a_complex-50" "hs_ml-sun_ho_mv_sKG_epoch-a_complex-50" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
source kg_recommendation_ho_hs_ml-sun.sh "hs_ml-sun_ho_mv_sKG_epoch-b_complex-50" "hs_ml-sun_ho_mv_sKG_epoch-b_complex-50" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
source kg_recommendation_ho_hs_ml-sun.sh "hs_ml-sun_ho_mv_sKG_epoch-c_complex-50" "hs_ml-sun_ho_mv_sKG_epoch-c_complex-50" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
source kg_recommendation_ho_hs_ml-sun.sh "hs_ml-sun_ho_mv_sKG_bs-a_complex-50" "hs_ml-sun_ho_mv_sKG_bs-a_complex-50" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
source kg_recommendation_ho_hs_ml-sun.sh "hs_ml-sun_ho_mv_sKG_bs-b_complex-50" "hs_ml-sun_ho_mv_sKG_bs-b_complex-50" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
source kg_recommendation_ho_hs_ml-sun.sh "hs_ml-sun_ho_mv_sKG_lr-a_complex-50" "hs_ml-sun_ho_mv_sKG_lr-a_complex-50" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
source kg_recommendation_ho_hs_ml-sun.sh "hs_ml-sun_ho_mv_sKG_lr-b_complex-50" "hs_ml-sun_ho_mv_sKG_lr-b_complex-50" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
source kg_recommendation_ho_hs_ml-sun.sh "hs_ml-sun_ho_mv_sKG_lr-c_complex-50" "hs_ml-sun_ho_mv_sKG_lr-c_complex-50" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005

