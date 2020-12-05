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

copy_ml_sun() {
mkdir "$2"
mkdir "$2/sun-format"
ln -s "$1/sun-format/auxiliary.txt" "$2/sun-format/auxiliary.txt"
ln -s "$1/sun-format/auxiliary-mapping.txt" "$2/sun-format/auxiliary-mapping.txt"
ln -s "$1/sun-format/negative-path.txt" "$2/sun-format/negative-path.txt"
ln -s "$1/sun_format/negative.txt" "$2/sun-format/negative.txt"
ln -s "$1/sun-format/positive-path.txt" "$2/sun-format/positive-path.txt"
ln -s "$1/sun_format/pre-train-item-embedding.txt" "$2/sun-format/pre-train-item-embedding.txt"
ln -s "$1/sun-format/pre-train-user-embedding.txt" "$2/sun-format/pre-train-user-embedding.txt"
ln -s "$1/sun-format/rating-delete-missing-itemid.txt" "$2/sun-format/rating-delete-missing-itemid.txt"
ln -s "$1/sun-format/test.txt" "$2/sun-format/test.txt"
ln -s "$1/sun-format/training.txt" "$2/sun-format/training.txt"
}
