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

cd ../summarization

#[sum_auxiliary.txt]
if no_exist "../../datasets/ml1m-summarized_sun/ml1m/sum_auxiliary.txt"
then
    python sun_genre.py --auxiliary '../../datasets/ml1m-sun/ml1m/auxiliary.txt' --summarize '../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt' --output '../../datasets/ml1m-summarized_sun/ml1m/sum_auxiliary.txt'
    BACK_PID=$!
    wait $BACK_PID
fi

cd ../preprocess

#[sun2cao_step1]
if no_exist "../../datasets/ml1m-summarized_sun/ml1m/kg_hop0_sun.dat"
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
