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

cd ../../Recurrent-Knowledge-Graph-Embedding

#[TRANSE]
if no_exist "../results/ml1m-cao/ml1m-rkge-results.log"
then
    CUDA_VISIBLE_DEVICES=0 nohup python recurrent-neural-network.py --results ~/git/results/ml1m-sun/ml1m-rkge-results.log &
    BACK_PID=$!
    wait $BACK_PID
fi
