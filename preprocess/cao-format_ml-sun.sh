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

# Dataset folder
DATASET=$1
# Low frequence filtering: 0, 10
LOWFREQUENCE=$2

if [ ! -d "$HOME/git/datasets/$DATASET/cao-format" ]
then
    echo "[kg-summ-rs] Creating ~/git/datasets/$DATASET/cao-format/ml1m/kg"
    mkdir ~/git/datasets/$DATASET/cao-format
    mkdir ~/git/datasets/$DATASET/cao-format/ml1m
    mkdir ~/git/datasets/$DATASET/cao-format/ml1m/kg
fi

#[activate jointrec]
conda deactivate
conda activate jointrec

if no_exist "$HOME/git/datasets/$DATASET/cao-format/ml1m/train.dat"
then
    if true # ml100k ratings from Sun's project
    then
        echo "[kg-summ-rs] Creating ~/git/datasets/$DATASET/cao-format/ml1m/train.dat"
        #[train.dat, valid.dat, test.dat by splitting rating-delete-missing-item.txt]
        python sun_split.py --loadfile "$HOME/git/datasets/$DATASET/sun-format/rating-delete-missing-itemid.txt" --column 'user_id' --frac '0.1,0.2' --savepath "$HOME/git/datasets/$DATASET/cao-format/ml1m/"
    else # ml1m ratings from Cao's project
        #[train.dat, valid.dat, test.dat symbolic links]
        echo 'Copying ~/git/datasets/$DATASET/cao-format/ml1m/train.dat'
        ln -s ~/git/datasets/ml-cao/cao-format/ml1m/train.dat ~/git/datasets/$DATASET/cao-format/ml1m/train.dat
        ln -s ~/git/datasets/ml-cao/cao-format/ml1m/valid.dat ~/git/datasets/$DATASET/cao-format/ml1m/valid.dat
        ln -s ~/git/datasets/ml-cao/cao-format/ml1m/test.dat ~/git/datasets/$DATASET/cao-format/ml1m/test.dat
        ln -s ~/git/datasets/ml-cao/cao-format/ml1m/i_map.dat ~/git/datasets/$DATASET/cao-format/ml1m/i_map.dat
        ln -s ~/git/datasets/ml-cao/cao-format/ml1m/u_map.dat ~/git/datasets/$DATASET/cao-format/ml1m/u_map.dat
    fi
fi

#[clean_auxiliary.txt]
if no_exist "$HOME/git/datasets/$DATASET/cao-format/ml1m/clean_auxiliary.txt"
then
    echo "[kg-summ-rs] Creating ~/git/datasets/$DATASET/cao-format/ml1m/clean_auxiliary.txt"
    python sun2cao_step0.py --auxiliary "$HOME/git/datasets/$DATASET/sun-format/auxiliary.txt" --output "$HOME/git/datasets/$DATASET/cao-format/ml1m/clean_auxiliary.txt"
fi

#[sun2cao_step1]
if no_exist "$HOME/git/datasets/$DATASET/cao-format/ml1m/kg/kg_hop0.dat"
then
    echo "[kg-summ-rs] Creating ~/git/datasets/$DATASET/cao-format/ml1m/kg/kg_hop0.dat"
    python sun2cao_step1.py --input "$HOME/git/datasets/$DATASET/cao-format/ml1m/clean_auxiliary.txt"  --mapping "$HOME/git/datasets/$DATASET/cao-format/ml1m/"
fi

#[sun2cao_step2]
if no_exist "$HOME/git/datasets/$DATASET/cao-format/ml1m/kg/e_map.dat"
then
    echo "[kg-summ-rs] Creating ~/git/datasets/$DATASET/cao-format/ml1m/kg/e_map.dat"
    python sun2cao_step2.py --data_path "~/git/datasets/$DATASET/cao-format/" --dataset 'ml1m' --lowfrequence $LOWFREQUENCE
fi

#[activate rkge]
conda deactivate
conda activate rkge

cd ../../Recurrent-Knowledge-Graph-Embedding

#[rkge prepocessing]
#if no_exist "$HOME/git/datasets/$DATASET/sun-format/negative.txt" || no_exist "$HOME/git/datasets/$DATASET/sun-format/positive-path.txt" || no_exist "$HOME/git/datasets/$DATASET/sun-format/negative-path.txt"
#then
#    echo '[kg-summ-rs] Preprocessing RKGE'
#    python auxiliary-mapping-ml.py --auxiliary '../datasets/$DATASET/cao-format/ml1m/clean_auxiliary.txt' --mapping '../datasets/$DATASET/sun-format/auxiliary-mapping.txt'
    ### REMOVED python data-split.py --rating ../datasets/ml1m-sun/ml1m/rating-delete-missing-itemid.txt --train ../datasets/ml1m-sun2cao/ml1m/training.txt --test ../datasets/ml1m-sun2cao/ml1m/test.txt --ratio 0.8
#    python negative-sample.py --train '../datasets/$DATASET/sun-format/sun_training.txt' --negative '../datasets/$DATASET/sun-format/negative.txt' --shrink 0.05
#    python path-extraction-ml.py --training '../datasets/$DATASET/sun-format/sun_training.txt' --negtive '../datasets/$DATASET/sun-format/negative.txt' --auxiliary '../datasets/$DATASET/sun-format/auxiliary-mapping.txt' --positivepath '../datasets/$DATASET/sun-format/positive-path.txt' --negativepath '../datasets/$DATASET/sun-format/negative-path.txt' --pathlength 3 --samplesize 5
#fi

#return to starting folder
cd "$HOME/git/know-rec/preprocess"
