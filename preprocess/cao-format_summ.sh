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

# Input dataset: ml-sun_ho_originalKG, ml-cao_ho_fKG
DATASET_IN=$1
# Output dataset name: ml-sun_ho_sv_sKG, ml-cao_ho_mv_sfKG
DATASET=$2
# Translation model: complex, distmult,
KGE=$3
# Clustering rate: 25, 50, 75 
RATE=$4
# Low Frequence: 0, 10
LOW_FREQUENCE=$5

################################################################################
###                       Preprocess ${DATASET}_${KGE}-${RATE}               ###
################################################################################
if no_exist "$HOME/git/datasets/${DATASET}_${KGE}-${RATE}/cao-format/ml1m/kg/kg_hop0.dat"
then
    echo "[kg-summ-rs] Creating ~/git/datasets/${DATASET}_${KGE}-${RATE}/cao-format/ml1m/kg/kg_hop0.dat"
    python sun2cao_step1.py --mode 'nt' --input "~/git/datasets/${DATASET}_${KGE}-${RATE}/kg.nt" --mapping "~/git/datasets/${DATASET}_${KGE}-${RATE}/cao-format/ml1m"
fi

#[sun2cao/train.dat, valid.dat, test.dat, ... from sun2cao]
if no_exist "$HOME/git/datasets/${DATASET}_${KGE}-${RATE}/cao-format/ml1m/train.dat"
then
    echo "[kg-summ-rs] Creating ~/git/datasets/${DATASET}_${KGE}-${RATE}/cao-format/ml1m/train.dat"
    ln -s ~/git/datasets/${DATASET_IN}/cao-format/ml1m/train.dat ~/git/datasets/${DATASET}_${KGE}-${RATE}/cao-format/ml1m/train.dat
    ln -s ~/git/datasets/${DATASET_IN}/cao-format/ml1m/valid.dat ~/git/datasets/${DATASET}_${KGE}-${RATE}/cao-format/ml1m/valid.dat
    ln -s ~/git/datasets/${DATASET_IN}/cao-format/ml1m/test.dat ~/git/datasets/${DATASET}_${KGE}-${RATE}/cao-format/ml1m/test.dat
    ln -s ~/git/datasets/${DATASET_IN}/cao-format/ml1m/i_map.dat ~/git/datasets/${DATASET}_${KGE}-${RATE}/cao-format/ml1m/i_map.dat
    ln -s ~/git/datasets/${DATASET_IN}/cao-format/ml1m/u_map.dat ~/git/datasets/${DATASET}_${KGE}-${RATE}/cao-format/ml1m/u_map.dat
    ln -s ~/git/datasets/${DATASET_IN}/cao-format/ml1m/i2kg_map.tsv ~/git/datasets/${DATASET}_${KGE}-${RATE}/cao-format/ml1m/i2kg_map.tsv
    ln -s ~/git/datasets/${DATASET_IN}/cao-format/ml1m/kg_map.dat ~/git/datasets/${DATASET}_${KGE}-${RATE}/cao-format/ml1m/kg_map.dat
#    ln -s ~/git/datasets/${DATASET_IN}/cao-format/ml1m/kg/predicate_vocab.dat ~/git/datasets/${DATASET}_${KGE}-${RATE}/cao-format/ml1m/kg/predicate_vocab.dat
#    ln -s ~/git/datasets/${DATASET_IN}/cao-format/ml1m/kg/relation_filter.dat ~/git/datasets/${DATASET}_${KGE}-${RATE}/cao-format/ml1m/kg/relation_filter.dat
#    ln -s ~/git/datasets/${DATASET_IN}/sun-format/ml1m/sun_training.txt ~/git/datasets/${DATASET}_${KGE}-${RATE}/sun-format/sun_training.txt
#    ln -s ~/git/datasets/${DATASET_IN}/sun-format/sun_test.txt ~/git/datasets/${DATASET}_${KGE}-${RATE}/sun-format/sun_test.txt
fi

#[sun2cao_step2]
if no_exist "$HOME/git/datasets/${DATASET}_${KGE}-${RATE}/cao-format/ml1m/kg/e_map.dat"
then
    echo "[kg-summ-rs] Creating ~/git/datasets/${DATASET}_${KGE}-${RATE}/cao-format/ml1m/kg/e_map.dat"
    python sun2cao_step2.py --data_path "~/git/datasets/${DATASET}_${KGE}-${RATE}/cao-format/" --dataset 'ml1m' --lowfrequence $LOW_FREQUENCE
fi

cd "$HOME/git/know-rec/preprocess"
