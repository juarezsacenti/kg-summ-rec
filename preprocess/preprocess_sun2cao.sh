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

if 1
then
    #[train.dat, valid.dat, test.dat by splitting rating-delete-missing-item.txt]
    python sun2cao_split.py --loadpath ../../datasets/ml1m-sun/ml1m/ --column user_id --savepath ../../datasets/ml1m-sun2cao/ml1m/ &
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
