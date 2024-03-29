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

#[activate jointrec]
conda deactivate
conda activate jointrec

#[sun2cao/train.dat, valid.dat, test.dat by splitting rating-delete-missing-item.txt]
if no_exist "~/git/datasets/ml1m-sun2cao/ml1m/train.dat" || no_exist "~/git/datasets/ml1m-sun2cao/ml1m/sun_training.txt"
then
    python sun_split.py --loadfile '../../datasets/ml1m-sun/ml1m/rating-delete-missing-itemid.txt' --column 'user_id' --frac '0.2,0.2,0.2,0.2' --savepath '../../datasets/ml1m-sun2cao/ml1m/' &
    BACK_PID=$!
    wait $BACK_PID
fi

#[sun2cao/clean_auxiliary.txt]
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
    ## Removed because use train.dat
    #python negative-sample.py --train ../datasets/ml1m-sun2cao/ml1m/sun_training.txt --negative ../datasets/ml1m-sun2cao/ml1m/negative.txt --shrink 0.05
    #python path-extraction-ml.py --training ../datasets/ml1m-sun2cao/ml1m/sun_training.txt --negtive ../datasets/ml1m-sun2cao/ml1m/negative.txt --auxiliary ../datasets/ml1m-sun2cao/ml1m/auxiliary-mapping.txt --positivepath ../datasets/ml1m-sun2cao/ml1m/positive-path.txt --negativepath ../datasets/ml1m-sun2cao/ml1m/negative-path.txt --pathlength 3 --samplesize 5
fi

###############
#sun_sum0
###############

cd ../know-rec/preprocess

#[sun2cao/train.dat, valid.dat, test.dat, ... from sun2cao]
## Removed because use train.dat
#ln -s ~/git/datasets/ml1m-sun2cao/ml1m/train.dat ~/git/datasets/ml1m-sun_sum0/ml1m/train.dat
#ln -s ~/git/datasets/ml1m-sun2cao/ml1m/valid.dat ~/git/datasets/ml1m-sun_sum0/ml1m/valid.dat
#ln -s ~/git/datasets/ml1m-sun2cao/ml1m/test.dat ~/git/datasets/ml1m-sun_sum0/ml1m/test.dat
ln -s ~/git/datasets/ml1m-sun2cao/ml1m/i_map.dat ~/git/datasets/ml1m-sun_sum0/ml1m/i_map.dat
ln -s ~/git/datasets/ml1m-sun2cao/ml1m/u_map.dat ~/git/datasets/ml1m-sun_sum0/ml1m/u_map.dat
#ln -s ~/git/datasets/ml1m-sun2cao/ml1m/sun_training.txt ~/git/datasets/ml1m-sun_sum0/ml1m/sun_training.txt
#ln -s ~/git/datasets/ml1m-sun2cao/ml1m/sun_test.txt ~/git/datasets/ml1m-sun_sum0/ml1m/sun_test.txt
#ln -s ~/git/datasets/ml1m-sun2cao/ml1m/negative.txt ~/git/datasets/ml1m-sun_sum0/ml1m/negative.txt

#[hierarchy.txt]
if no_exist "../../datasets/ml1m-sun_sum0/ml1m/hierarchy.txt"
then
    touch ../../datasets/ml1m-sun_sum0/ml1m/hierarchy.txt
    echo "Action,Brute_Action" >> ../../datasets/ml1m-sun_sum0/ml1m/hierarchy.txt
    echo "Adult,Porn" >> ../../datasets/ml1m-sun_sum0/ml1m/hierarchy.txt
    echo "Adventure,Imaginational_Entertainment" >> ../../datasets/ml1m-sun_sum0/ml1m/hierarchy.txt
    echo "Animation,Fun" >> ../../datasets/ml1m-sun_sum0/ml1m/hierarchy.txt
    echo "Biography,Documentarial_Information" >> ../../datasets/ml1m-sun_sum0/ml1m/hierarchy.txt
    echo "Comedy,Fun" >> ../../datasets/ml1m-sun_sum0/ml1m/hierarchy.txt
    echo "Crime,Logical_Thrilling" >> ../../datasets/ml1m-sun_sum0/ml1m/hierarchy.txt
    echo "Documentary,Documentarial_Information" >> ../../datasets/ml1m-sun_sum0/ml1m/hierarchy.txt
    echo "Drama,Heavy_Sensible" >> ../../datasets/ml1m-sun_sum0/ml1m/hierarchy.txt
    echo "Family,Kids" >> ../../datasets/ml1m-sun_sum0/ml1m/hierarchy.txt
    echo "Fantasy,Sci-Fi_and_Fantasy" >> ../../datasets/ml1m-sun_sum0/ml1m/hierarchy.txt
    echo "Film-Noir,Heavy_Sensible" >> ../../datasets/ml1m-sun_sum0/ml1m/hierarchy.txt
    echo "History,Historical_Information" >> ../../datasets/ml1m-sun_sum0/ml1m/hierarchy.txt
    echo "Horror,Thrilling" >> ../../datasets/ml1m-sun_sum0/ml1m/hierarchy.txt
    echo "Music,Musical_Entertainment" >> ../../datasets/ml1m-sun_sum0/ml1m/hierarchy.txt
    echo "Musical,Musical_Entertainment" >> ../../datasets/ml1m-sun_sum0/ml1m/hierarchy.txt
    echo "Mystery,Sensible_Thrilling" >> ../../datasets/ml1m-sun_sum0/ml1m/hierarchy.txt
    echo "Romance,Love" >> ../../datasets/ml1m-sun_sum0/ml1m/hierarchy.txt
    echo "Sci-Fi,Sci-Fi_and_Fantasy" >> ../../datasets/ml1m-sun_sum0/ml1m/hierarchy.txt
    echo "Short,Genre" >> ../../datasets/ml1m-sun_sum0/ml1m/hierarchy.txt
    echo "Sport,Entertaining_Information" >> ../../datasets/ml1m-sun_sum0/ml1m/hierarchy.txt
    echo "Thriller,Sensible_Thrilling" >> ../../datasets/ml1m-sun_sum0/ml1m/hierarchy.txt
    echo "War,Brute_Action" >> ../../datasets/ml1m-sun_sum0/ml1m/hierarchy.txt
    echo "Western,Old_Action" >> ../../datasets/ml1m-sun_sum0/ml1m/hierarchy.txt
fi

#[activate jointrec]
conda deactivate
conda activate jointrec

#[sum_auxiliary.txt]
if no_exist "../../datasets/ml1m-sun_sum0/ml1m/sum_auxiliary.txt"
then
    python sun2cao_step0.py --auxiliary '../../datasets/ml1m-sun/ml1m/auxiliary.txt' --summarize '../../datasets/ml1m-sun_sum0/ml1m/hierarchy.txt' --output '../../datasets/ml1m-sun_sum0/ml1m/sum_auxiliary.txt'
    BACK_PID=$!
    wait $BACK_PID
fi

#[sun2cao_step1]
if no_exist "../../datasets/ml1m-sun_sum0/ml1m/kg/kg_hop0_sun.dat"
then
    python sun2cao_step1.py --auxiliary '../../datasets/ml1m-sun_sum0/ml1m/sum_auxiliary.txt' --i2kg_map '../../datasets/ml1m-cao/ml1m/i2kg_map.tsv' --mapping '../../datasets/ml1m-sun_sum0/ml1m/'
    BACK_PID=$!
    wait $BACK_PID
fi

#[sun2cao_step2]
if no_exist "../../datasets/ml1m-sun_sum0/ml1m/kg/e_map.dat"
then
    python sun2cao_step2.py --data_path '../../datasets/ml1m-sun_sum0/' --dataset 'ml1m'
    BACK_PID=$!
    wait $BACK_PID
fi

#[activate rkge]
conda deactivate
conda activate rkge

cd ../../Recurrent-Knowledge-Graph-Embedding

#[rkge preprocessing]
if no_exist "../../datasets/ml1m-sun_sum0/positive-path.txt" || no_exist "../../datasets/ml1m-sun_sum0/negative-path.txt"
then
    python auxiliary-mapping-ml.py --auxiliary ../datasets/ml1m-sun_sum0/ml1m/sum_auxiliary.txt --mapping ../datasets/ml1m-sun_sum0/ml1m/auxiliary-mapping.txt
    ## Removed because use train.dat
    #python path-extraction-ml.py --training ../datasets/ml1m-sun_sum0/ml1m/sun_training.txt --negtive ../datasets/ml1m-sun_sum0/ml1m/negative.txt --auxiliary ../datasets/ml1m-sun_sum0/ml1m/auxiliary-mapping.txt --positivepath ../datasets/ml1m-sun_sum0/ml1m/positive-path.txt --negativepath ../datasets/ml1m-sun_sum0/ml1m/negative-path.txt --pathlength 3 --samplesize 5
fi

###############
#sun_sum1
###############

cd ../know-rec/preprocess

#[sun2cao/train.dat, valid.dat, test.dat, ... from sun2cao]
ln -s ~/git/datasets/ml1m-sun2cao/ml1m/i_map.dat ~/git/datasets/ml1m-sun_sum1/ml1m/i_map.dat
ln -s ~/git/datasets/ml1m-sun2cao/ml1m/u_map.dat ~/git/datasets/ml1m-sun_sum1/ml1m/u_map.dat

#[hierarchy.txt]
if no_exist "../../datasets/ml1m-sun_sum1/ml1m/hierarchy.txt"
then
    touch ../../datasets/ml1m-sun_sum1/ml1m/hierarchy.txt
    echo "Action,Actionreach" >> ../../datasets/ml1m-sun_sum1/ml1m/hierarchy.txt
    echo "Adult,Experience" >> ../../datasets/ml1m-sun_sum1/ml1m/hierarchy.txt
    echo "Adventure,Entertainment" >> ../../datasets/ml1m-sun_sum1/ml1m/hierarchy.txt
    echo "Animation,SocialActive" >> ../../datasets/ml1m-sun_sum1/ml1m/hierarchy.txt
    echo "Biography,Special_Info" >> ../../datasets/ml1m-sun_sum1/ml1m/hierarchy.txt
    echo "Comedy,SocialActive" >> ../../datasets/ml1m-sun_sum1/ml1m/hierarchy.txt
    echo "Crime,Thrilling" >> ../../datasets/ml1m-sun_sum1/ml1m/hierarchy.txt
    echo "Documentary,Special_Info" >> ../../datasets/ml1m-sun_sum1/ml1m/hierarchy.txt
    echo "Drama,Sensible" >> ../../datasets/ml1m-sun_sum1/ml1m/hierarchy.txt
    echo "Family,SocialActive" >> ../../datasets/ml1m-sun_sum1/ml1m/hierarchy.txt
    echo "Fantasy,Imaginational_Entertainment" >> ../../datasets/ml1m-sun_sum1/ml1m/hierarchy.txt
    echo "Film-Noir,Sensible" >> ../../datasets/ml1m-sun_sum1/ml1m/hierarchy.txt
    echo "History,Documentarial_Information" >> ../../datasets/ml1m-sun_sum1/ml1m/hierarchy.txt
    echo "Horror,Imaginational_Entertainment" >> ../../datasets/ml1m-sun_sum1/ml1m/hierarchy.txt
    echo "Music,Intelectual_Entertainment" >> ../../datasets/ml1m-sun_sum1/ml1m/hierarchy.txt
    echo "Musical,Intelectual_Entertainment" >> ../../datasets/ml1m-sun_sum1/ml1m/hierarchy.txt
    echo "Mystery,Thrilling" >> ../../datasets/ml1m-sun_sum1/ml1m/hierarchy.txt
    echo "Romance,Sensible" >> ../../datasets/ml1m-sun_sum1/ml1m/hierarchy.txt
    echo "Sci-Fi,Imaginational_Entertainment" >> ../../datasets/ml1m-sun_sum1/ml1m/hierarchy.txt
    echo "Short,Genre" >> ../../datasets/ml1m-sun_sum1/ml1m/hierarchy.txt
    echo "Sport,Entertainment" >> ../../datasets/ml1m-sun_sum1/ml1m/hierarchy.txt
    echo "Thriller,Thrilling" >> ../../datasets/ml1m-sun_sum1/ml1m/hierarchy.txt
    echo "War,Actionreach" >> ../../datasets/ml1m-sun_sum1/ml1m/hierarchy.txt
    echo "Western,Actionreach" >> ../../datasets/ml1m-sun_sum1/ml1m/hierarchy.txt
fi

#[activate jointrec]
conda deactivate
conda activate jointrec

#[sum_auxiliary.txt]
if no_exist "../../datasets/ml1m-sun_sum1/ml1m/sum_auxiliary.txt"
then
    python sun2cao_step0.py --auxiliary '../../datasets/ml1m-sun/ml1m/auxiliary.txt' --summarize '../../datasets/ml1m-sun_sum1/ml1m/hierarchy.txt' --output '../../datasets/ml1m-sun_sum1/ml1m/sum_auxiliary.txt'
    BACK_PID=$!
    wait $BACK_PID
fi

#[sun2cao_step1]
if no_exist "../../datasets/ml1m-sun_sum1/ml1m/kg/kg_hop0_sun.dat"
then
    python sun2cao_step1.py --auxiliary '../../datasets/ml1m-sun_sum1/ml1m/sum_auxiliary.txt' --i2kg_map '../../datasets/ml1m-cao/ml1m/i2kg_map.tsv' --mapping '../../datasets/ml1m-sun_sum1/ml1m/'
    BACK_PID=$!
    wait $BACK_PID
fi

#[sun2cao_step2]
if no_exist "../../datasets/ml1m-sun_sum1/ml1m/kg/e_map.dat"
then
    python sun2cao_step2.py --data_path '../../datasets/ml1m-sun_sum1/' --dataset 'ml1m'
    BACK_PID=$!
    wait $BACK_PID
fi

#[activate rkge]
conda deactivate
conda activate rkge

cd ../../Recurrent-Knowledge-Graph-Embedding

#[rkge preprocessing]
if no_exist "../../datasets/ml1m-sun_sum1/positive-path.txt" || no_exist "../../datasets/ml1m-sun_sum1/negative-path.txt"
then
    python auxiliary-mapping-ml.py --auxiliary ../datasets/ml1m-sun_sum1/ml1m/sum_auxiliary.txt --mapping ../datasets/ml1m-sun_sum1/ml1m/auxiliary-mapping.txt
fi
