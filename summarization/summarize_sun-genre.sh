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

#[hierarchy.txt]
if no_exist "../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt"
then
    touch ../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt
    echo "Action,Brute_Action" >> ../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt
    echo "Adult,Porn" >> ../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt
    echo "Adventure,Imaginational_Entertainment" >> ../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt
    echo "Animation,Fun" >> ../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt
    echo "Biography,Documentarial_Information" >> ../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt
    echo "Comedy,Fun" >> ../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt
    echo "Crime,Logical_Thrilling" >> ../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt
    echo "Documentary,Documentarial_Information" >> ../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt
    echo "Drama,Heavy_Sensible" >> ../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt
    echo "Family,Kids" >> ../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt
    echo "Fantasy,Sci-Fi_and_Fantasy" >> ../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt
    echo "Film-Noir,Heavy_Sensible" >> ../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt
    echo "History,Historical_Information" >> ../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt
    echo "Horror,Thrilling" >> ../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt
    echo "Music,Musical_Entertainment" >> ../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt
    echo "Musical,Musical_Entertainment" >> ../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt
    echo "Mystery,Sensible_Thrilling" >> ../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt
    echo "Romance,Love" >> ../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt
    echo "Sci-Fi,Sci-Fi_and_Fantasy" >> ../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt
    echo "Short,Genre" >> ../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt
    echo "Sport,Entertaining_Information" >> ../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt
    echo "Thriller,Sensible_Thrilling" >> ../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt
    echo "War,Brute_Action" >> ../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt
    echo "Western,Old_Action" >> ../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt
fi

#[activate jointrec]
conda deactivate
conda activate jointrec

cd ../preprocess

if true
then
    #[train.dat, valid.dat, test.dat by splitting rating-delete-missing-item.txt]
    python sun2cao_split.py --loadfile '../../datasets/ml1m-sun/ml1m/rating-delete-missing-itemid.txt' --column 'user_id' --umapfile '../../datasets/ml1m-summarized_sun/ml1m/u_map.dat' --imapfile '../../datasets/ml1m-summarized_sun/ml1m/u_map.dat' --savepath '../../datasets/ml1m-summarized_sun/ml1m/' &
    BACK_PID=$!
    wait $BACK_PID
else
    #[train.dat, valid.dat, test.dat symbolic links]
    ln -s ~/git/datasets/ml1m-cao/ml1m/train.dat ~/git/datasets/ml1m-summarized_sun/ml1m/train.dat
    ln -s ~/git/datasets/ml1m-cao/ml1m/valid.dat ~/git/datasets/ml1m-summarized_sun/ml1m/valid.dat
    ln -s ~/git/datasets/ml1m-cao/ml1m/test.dat ~/git/datasets/ml1m-summarized_sun/ml1m/test.dat
    ln -s ~/git/datasets/ml1m-cao/ml1m/i_map.dat ~/git/datasets/ml1m-summarized_sun/ml1m/i_map.dat
    ln -s ~/git/datasets/ml1m-cao/ml1m/u_map.dat ~/git/datasets/ml1m-summarized_sun/ml1m/u_map.dat
fi

#[sum_auxiliary.txt]
if no_exist "../../datasets/ml1m-summarized_sun/ml1m/sum_auxiliary.txt"
then
    python sun2cao_step0.py --auxiliary '../../datasets/ml1m-sun/ml1m/auxiliary.txt' --summarize '../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt' --output '../../datasets/ml1m-summarized_sun/ml1m/sum_auxiliary.txt'
    BACK_PID=$!
    wait $BACK_PID
fi

#[sun2cao_step1]
if no_exist "../../datasets/ml1m-summarized_sun/ml1m/kg/kg_hop0_sun.dat"
then
    python sun2cao_step1.py --auxiliary '../../datasets/ml1m-summarized_sun/ml1m/sum_auxiliary.txt' --i2kg_map '../../datasets/ml1m-cao/ml1m/i2kg_map.tsv' --mapping '../../datasets/ml1m-summarized_sun/ml1m/'
    BACK_PID=$!
    wait $BACK_PID
fi

#[sun2cao_step2]
if no_exist "../../datasets/ml1m-summarized_sun/ml1m/kg/e_map.dat"
then
    python sun2cao_step2.py --data_path '../../datasets/ml1m-summarized_sun/' --dataset 'ml1m'
    BACK_PID=$!
    wait $BACK_PID
fi

#[activate rkge]
conda deactivate
conda activate rkge

cd ../../Recurrent-Knowledge-Graph-Embedding

#[rkge prepocessing]
if no_exist "../../datasets/ml1m-summarized_sun/ml1m/negative.txt" || no_exist "../../datasets/ml1m-summarized_sun/positive-path.txt" || no_exist "../../datasets/ml1m-summarized_sun/negative-path.txt"
then
    python auxiliary-mapping-ml.py --auxiliary ../datasets/ml1m-summarized_sun/ml1m/sum_auxiliary.txt --mapping ../datasets/ml1m-summarized_sun/ml1m/auxiliary-mapping.txt
    python data-split.py --rating ../datasets/ml1m-sun/ml1m/rating-delete-missing-itemid.txt --train ../datasets/ml1m-summarized_sun/ml1m/training.txt --test ../datasets/ml1m-summarized_sun/ml1m/test.txt --ratio 0.8
    python negative-sample.py --train ../datasets/ml1m-summarized_sun/ml1m/training.txt --negative ../datasets/ml1m-summarized_sun/ml1m/negative.txt --shrink 0.05
    python path-extraction-ml.py --training ../datasets/ml1m-summarized_sun/ml1m/training.txt --negtive ../datasets/ml1m-summarized_sun/ml1m/negative.txt --auxiliary ../datasets/ml1m-summarized_sun/ml1m/auxiliary-mapping.txt --positivepath ../datasets/ml1m-summarized_sun/ml1m/positive-path.txt --negativepath ../datasets/ml1m-summarized_sun/ml1m/negative-path.txt --pathlength 3 --samplesize 5
fi
