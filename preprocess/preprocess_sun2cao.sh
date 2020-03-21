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

if true
then
    #[train.dat, valid.dat, test.dat by splitting rating-delete-missing-item.txt]
    python sun2cao_split.py --loadfile '../../datasets/ml1m-sun/ml1m/rating-delete-missing-itemid.txt' --column 'user_id' --umapfile '../../datasets/ml1m-sun2cao/ml1m/u_map.dat' --imapfile '../../datasets/ml1m-sun2cao/ml1m/i_map.dat' --savepath '../../datasets/ml1m-sun2cao/ml1m/' &
    BACK_PID=$!
    wait $BACK_PID
else
    #[train.dat, valid.dat, test.dat symbolic links]
    ln -s ~/git/datasets/ml1m-cao/ml1m/train.dat ~/git/datasets/ml1m-sun2cao/ml1m/train.dat
    ln -s ~/git/datasets/ml1m-cao/ml1m/valid.dat ~/git/datasets/ml1m-sun2cao/ml1m/valid.dat
    ln -s ~/git/datasets/ml1m-cao/ml1m/test.dat ~/git/datasets/ml1m-sun2cao/ml1m/test.dat
    ln -s ~/git/datasets/ml1m-cao/ml1m/i_map.dat ~/git/datasets/ml1m-sun2cao/ml1m/i_map.dat
    ln -s ~/git/datasets/ml1m-cao/ml1m/u_map.dat ~/git/datasets/ml1m-sun2cao/ml1m/u_map.dat
fi

#[activate jointrec]
conda deactivate
conda activate jointrec

#[clean_auxiliary.txt]
if no_exist "../../datasets/ml1m-sun2cao/ml1m/clean_auxiliary.txt"
then
    python sun2cao_step0.py --auxiliary '../../datasets/ml1m-sun/ml1m/auxiliary.txt' --output '../../datasets/ml1m-sun2cao/ml1m/clean_auxiliary.txt'
    BACK_PID=$!
    wait $BACK_PID
fi

#[sun2cao_step1]
if no_exist "../../datasets/ml1m-sun2cao/ml1m/kg/kg_hop0_sun.dat"
then
    python sun2cao_step1.py --auxiliary '../../datasets/ml1m-sun2cao/ml1m/clean_auxiliary.txt' --i2kg_map '../../datasets/ml1m-cao/ml1m/i2kg_map.tsv' --mapping '../../datasets/ml1m-sun2cao/ml1m/'
    BACK_PID=$!
    wait $BACK_PID
fi

#[sun2cao_step2]
if no_exist "../../datasets/ml1m-sun2cao/ml1m/kg/e_map.dat"
then
    python sun2cao_step2.py --data_path '../../datasets/ml1m-sun2cao/' --dataset 'ml1m'
    BACK_PID=$!
    wait $BACK_PID
fi

#[activate rkge]
conda deactivate
conda activate rkge

cd ../../Recurrent-Knowledge-Graph-Embedding

#[rkge prepocessing]
if no_exist "../../datasets/ml1m-sun2cao/ml1m/negative.txt" || no_exist "../../datasets/ml1m-sun2cao/positive-path.txt" || no_exist "../../datasets/ml1m-sun2cao/negative-path.txt"
then
    python auxiliary-mapping-ml.py --auxiliary ../datasets/ml1m-sun2cao/ml1m/clean_auxiliary.txt --mapping ../datasets/ml1m-sun2cao/ml1m/auxiliary-mapping.txt
    python data-split.py --rating ../datasets/ml1m-sun/ml1m/rating-delete-missing-itemid.txt --train ../datasets/ml1m-sun2cao/ml1m/training.txt --test ../datasets/ml1m-sun2cao/ml1m/test.txt --ratio 0.8
    python negative-sample.py --train ../datasets/ml1m-sun2cao/ml1m/training.txt --negative ../datasets/ml1m-sun2cao/ml1m/negative.txt --shrink 0.05
    python path-extraction-ml.py --training ../datasets/ml1m-sun2cao/ml1m/training.txt --negtive ../datasets/ml1m-sun2cao/ml1m/negative.txt --auxiliary ../datasets/ml1m-sun2cao/ml1m/auxiliary-mapping.txt --positivepath ../datasets/ml1m-sun2cao/ml1m/positive-path.txt --negativepath ../datasets/ml1m-sun2cao/ml1m/negative-path.txt --pathlength 3 --samplesize 5
fi
