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

if no_exist "../../datasets/ml1m-cao2sun/ml1m/auxiliary-mapping.txt" || no_exist "../../datasets/ml1m-cao2sun/rating-delete-missing-itemid.txt"
then
    python cao2sun_step1.py
    cd ../../Recurrent-Knowledge-Graph-Embedding
    python data-split.py --rating ../datasets/ml1m-cao2sun/ml1m/rating-delete-missing-itemid.txt --train ../datasets/ml1m-cao2sun/ml1m/training.txt --test ../datasets/ml1m-cao2sun/ml1m/test.txt --ratio 0.8
    python negative-sample.py --train ../datasets/ml1m-cao2sun/ml1m/training.txt --negative ../datasets/ml1m-cao2sun/ml1m/negative.txt --shrink 0.05
    cd ../know-rec/preprocess
    python cao2sun_step2.py
fi
