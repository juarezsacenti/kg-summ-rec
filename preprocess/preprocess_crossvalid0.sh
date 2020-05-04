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


###############
#sun_sum5
###############

cd ../know-rec/preprocess

#[sun2cao/train.dat, valid.dat, test.dat, ... from sun2cao]
ln -s ~/git/datasets/ml1m-sun2cao/ml1m/i_map.dat ~/git/datasets/ml1m-sun_sum5/ml1m/i_map.dat
ln -s ~/git/datasets/ml1m-sun2cao/ml1m/u_map.dat ~/git/datasets/ml1m-sun_sum5/ml1m/u_map.dat

#[hierarchy.txt]
if no_exist "../../datasets/ml1m-sun_sum5/ml1m/hierarchy.txt"
then
    touch ../../datasets/ml1m-sun_sum5/ml1m/hierarchy.txt
    echo "Action,Action" >> ../../datasets/ml1m-sun_sum5/ml1m/hierarchy.txt
    echo "Adult,Adult" >> ../../datasets/ml1m-sun_sum5/ml1m/hierarchy.txt
    echo "Adventure,Adventure" >> ../../datasets/ml1m-sun_sum5/ml1m/hierarchy.txt
    echo "Animation,Animation" >> ../../datasets/ml1m-sun_sum5/ml1m/hierarchy.txt
    echo "Biography,Biography" >> ../../datasets/ml1m-sun_sum5/ml1m/hierarchy.txt
    echo "Comedy,Comedy" >> ../../datasets/ml1m-sun_sum5/ml1m/hierarchy.txt
    echo "Crime,Logical_Thrilling" >> ../../datasets/ml1m-sun_sum5/ml1m/hierarchy.txt
    echo "Documentary,Documentary" >> ../../datasets/ml1m-sun_sum5/ml1m/hierarchy.txt
    echo "Drama,Drama" >> ../../datasets/ml1m-sun_sum5/ml1m/hierarchy.txt
    echo "Family,Family" >> ../../datasets/ml1m-sun_sum5/ml1m/hierarchy.txt
    echo "Fantasy,Fantasy" >> ../../datasets/ml1m-sun_sum5/ml1m/hierarchy.txt
    echo "Film-Noir,Film-Noir" >> ../../datasets/ml1m-sun_sum5/ml1m/hierarchy.txt
    echo "History,Historical_Information" >> ../../datasets/ml1m-sun_sum5/ml1m/hierarchy.txt
    echo "Horror,Horror" >> ../../datasets/ml1m-sun_sum5/ml1m/hierarchy.txt
    echo "Music,Musical_Entertainment" >> ../../datasets/ml1m-sun_sum5/ml1m/hierarchy.txt
    echo "Musical,Musical_Entertainment" >> ../../datasets/ml1m-sun_sum5/ml1m/hierarchy.txt
    echo "Mystery,Sensible_Thrilling" >> ../../datasets/ml1m-sun_sum5/ml1m/hierarchy.txt
    echo "Romance,Romance" >> ../../datasets/ml1m-sun_sum5/ml1m/hierarchy.txt
    echo "Sci-Fi,Sci-Fi" >> ../../datasets/ml1m-sun_sum5/ml1m/hierarchy.txt
    echo "Short,Short" >> ../../datasets/ml1m-sun_sum5/ml1m/hierarchy.txt
    echo "Sport,Sport" >> ../../datasets/ml1m-sun_sum5/ml1m/hierarchy.txt
    echo "Thriller,Sensible_Thrilling" >> ../../datasets/ml1m-sun_sum5/ml1m/hierarchy.txt
    echo "War,War" >> ../../datasets/ml1m-sun_sum5/ml1m/hierarchy.txt
    echo "Western,Western" >> ../../datasets/ml1m-sun_sum5/ml1m/hierarchy.txt
fi

#[activate jointrec]
conda deactivate
conda activate jointrec

#[sum_auxiliary.txt]
if no_exist "../../datasets/ml1m-sun_sum5/ml1m/sum_auxiliary.txt"
then
    python sun2cao_step0.py --auxiliary '../../datasets/ml1m-sun/ml1m/auxiliary.txt' --summarize '../../datasets/ml1m-sun_sum5/ml1m/hierarchy.txt' --output '../../datasets/ml1m-sun_sum5/ml1m/sum_auxiliary.txt'
    BACK_PID=$!
    wait $BACK_PID
fi

#[sun2cao_step1]
if no_exist "../../datasets/ml1m-sun_sum5/ml1m/kg/kg_hop0_sun.dat"
then
    python sun2cao_step1.py --auxiliary '../../datasets/ml1m-sun_sum5/ml1m/sum_auxiliary.txt' --i2kg_map '../../datasets/ml1m-cao/ml1m/i2kg_map.tsv' --mapping '../../datasets/ml1m-sun_sum5/ml1m/'
    BACK_PID=$!
    wait $BACK_PID
fi

#[sun2cao_step2]
if no_exist "../../datasets/ml1m-sun_sum5/ml1m/kg/e_map.dat"
then
    python sun2cao_step2.py --data_path '../../datasets/ml1m-sun_sum5/' --dataset 'ml1m'
    BACK_PID=$!
    wait $BACK_PID
fi

#[activate rkge]
conda deactivate
conda activate rkge

cd ../../Recurrent-Knowledge-Graph-Embedding

#[rkge preprocessing]
if no_exist "../../datasets/ml1m-sun_sum5/positive-path.txt" || no_exist "../../datasets/ml1m-sun_sum5/negative-path.txt"
then
    python auxiliary-mapping-ml.py --auxiliary ../datasets/ml1m-sun_sum5/ml1m/sum_auxiliary.txt --mapping ../datasets/ml1m-sun_sum5/ml1m/auxiliary-mapping.txt
fi


###############
#sun_sum4
###############

cd ../know-rec/preprocess

#[sun2cao/train.dat, valid.dat, test.dat, ... from sun2cao]
ln -s ~/git/datasets/ml1m-sun2cao/ml1m/i_map.dat ~/git/datasets/ml1m-sun_sum4/ml1m/i_map.dat
ln -s ~/git/datasets/ml1m-sun2cao/ml1m/u_map.dat ~/git/datasets/ml1m-sun_sum4/ml1m/u_map.dat

#[hierarchy.txt]
if no_exist "../../datasets/ml1m-sun_sum4/ml1m/hierarchy.txt"
then
    touch ../../datasets/ml1m-sun_sum4/ml1m/hierarchy.txt
    echo "Action,Brute_Action" >> ../../datasets/ml1m-sun_sum4/ml1m/hierarchy.txt
    echo "Adult,Porn" >> ../../datasets/ml1m-sun_sum4/ml1m/hierarchy.txt
    echo "Adventure,Adventure" >> ../../datasets/ml1m-sun_sum4/ml1m/hierarchy.txt
    echo "Animation,Fun" >> ../../datasets/ml1m-sun_sum4/ml1m/hierarchy.txt
    echo "Biography,Documentarial_Information" >> ../../datasets/ml1m-sun_sum4/ml1m/hierarchy.txt
    echo "Comedy,Fun" >> ../../datasets/ml1m-sun_sum4/ml1m/hierarchy.txt
    echo "Crime,Thrilling" >> ../../datasets/ml1m-sun_sum4/ml1m/hierarchy.txt
    echo "Documentary,Documentarial_Information" >> ../../datasets/ml1m-sun_sum4/ml1m/hierarchy.txt
    echo "Drama,Heavy_Sensible" >> ../../datasets/ml1m-sun_sum4/ml1m/hierarchy.txt
    echo "Family,Kids" >> ../../datasets/ml1m-sun_sum4/ml1m/hierarchy.txt
    echo "Fantasy,Sci-Fi_and_Fantasy" >> ../../datasets/ml1m-sun_sum4/ml1m/hierarchy.txt
    echo "Film-Noir,Heavy_Sensible" >> ../../datasets/ml1m-sun_sum4/ml1m/hierarchy.txt
    echo "History,Documentarial_Information" >> ../../datasets/ml1m-sun_sum4/ml1m/hierarchy.txt
    echo "Horror,Thrilling" >> ../../datasets/ml1m-sun_sum4/ml1m/hierarchy.txt
    echo "Music,Intelectual_Entertainment" >> ../../datasets/ml1m-sun_sum4/ml1m/hierarchy.txt
    echo "Musical,Intelectual_Entertainment" >> ../../datasets/ml1m-sun_sum4/ml1m/hierarchy.txt
    echo "Mystery,Thrilling" >> ../../datasets/ml1m-sun_sum4/ml1m/hierarchy.txt
    echo "Romance,Love" >> ../../datasets/ml1m-sun_sum4/ml1m/hierarchy.txt
    echo "Sci-Fi,Sci-Fi_and_Fantasy" >> ../../datasets/ml1m-sun_sum4/ml1m/hierarchy.txt
    echo "Short,Short" >> ../../datasets/ml1m-sun_sum4/ml1m/hierarchy.txt
    echo "Sport,Sport" >> ../../datasets/ml1m-sun_sum4/ml1m/hierarchy.txt
    echo "Thriller,Thrilling" >> ../../datasets/ml1m-sun_sum4/ml1m/hierarchy.txt
    echo "War,Brute_Action" >> ../../datasets/ml1m-sun_sum4/ml1m/hierarchy.txt
    echo "Western,Old_Action" >> ../../datasets/ml1m-sun_sum4/ml1m/hierarchy.txt
fi

#[activate jointrec]
conda deactivate
conda activate jointrec

#[sum_auxiliary.txt]
if no_exist "../../datasets/ml1m-sun_sum4/ml1m/sum_auxiliary.txt"
then
    python sun2cao_step0.py --auxiliary '../../datasets/ml1m-sun/ml1m/auxiliary.txt' --summarize '../../datasets/ml1m-sun_sum4/ml1m/hierarchy.txt' --output '../../datasets/ml1m-sun_sum4/ml1m/sum_auxiliary.txt'
    BACK_PID=$!
    wait $BACK_PID
fi

#[sun2cao_step1]
if no_exist "../../datasets/ml1m-sun_sum4/ml1m/kg/kg_hop0_sun.dat"
then
    python sun2cao_step1.py --auxiliary '../../datasets/ml1m-sun_sum4/ml1m/sum_auxiliary.txt' --i2kg_map '../../datasets/ml1m-cao/ml1m/i2kg_map.tsv' --mapping '../../datasets/ml1m-sun_sum4/ml1m/'
    BACK_PID=$!
    wait $BACK_PID
fi

#[sun2cao_step2]
if no_exist "../../datasets/ml1m-sun_sum4/ml1m/kg/e_map.dat"
then
    python sun2cao_step2.py --data_path '../../datasets/ml1m-sun_sum4/' --dataset 'ml1m'
    BACK_PID=$!
    wait $BACK_PID
fi

#[activate rkge]
conda deactivate
conda activate rkge

cd ../../Recurrent-Knowledge-Graph-Embedding

#[rkge preprocessing]
if no_exist "../../datasets/ml1m-sun_sum4/positive-path.txt" || no_exist "../../datasets/ml1m-sun_sum4/negative-path.txt"
then
    python auxiliary-mapping-ml.py --auxiliary ../datasets/ml1m-sun_sum4/ml1m/sum_auxiliary.txt --mapping ../datasets/ml1m-sun_sum4/ml1m/auxiliary-mapping.txt
fi


###############
#sun_sum3
###############

cd ../know-rec/preprocess

#[sun2cao/train.dat, valid.dat, test.dat, ... from sun2cao]
ln -s ~/git/datasets/ml1m-sun2cao/ml1m/i_map.dat ~/git/datasets/ml1m-sun_sum3/ml1m/i_map.dat
ln -s ~/git/datasets/ml1m-sun2cao/ml1m/u_map.dat ~/git/datasets/ml1m-sun_sum3/ml1m/u_map.dat

#[hierarchy.txt]
if no_exist "../../datasets/ml1m-sun_sum3/ml1m/hierarchy.txt"
then
    touch ../../datasets/ml1m-sun_sum3/ml1m/hierarchy.txt
    echo "Action,Actionreach" >> ../../datasets/ml1m-sun_sum3/ml1m/hierarchy.txt
    echo "Adult,Experience" >> ../../datasets/ml1m-sun_sum3/ml1m/hierarchy.txt
    echo "Adventure,Actionreach" >> ../../datasets/ml1m-sun_sum3/ml1m/hierarchy.txt
    echo "Adventure,Imaginational_Entertainment" >> ../../datasets/ml1m-sun_sum3/ml1m/hierarchy.txt
    echo "Animation,SocialActive" >> ../../datasets/ml1m-sun_sum3/ml1m/hierarchy.txt
    echo "Biography,Special-Info" >> ../../datasets/ml1m-sun_sum3/ml1m/hierarchy.txt
    echo "Comedy,SocialActive" >> ../../datasets/ml1m-sun_sum3/ml1m/hierarchy.txt
    echo "Crime,Imaginational_Entertainment" >> ../../datasets/ml1m-sun_sum3/ml1m/hierarchy.txt
    echo "Documentary,Special-Info" >> ../../datasets/ml1m-sun_sum3/ml1m/hierarchy.txt
    echo "Drama,Sensible" >> ../../datasets/ml1m-sun_sum3/ml1m/hierarchy.txt
    echo "Family,SocialActive" >> ../../datasets/ml1m-sun_sum3/ml1m/hierarchy.txt
    echo "Fantasy,Imaginational_Entertainment" >> ../../datasets/ml1m-sun_sum3/ml1m/hierarchy.txt
    echo "Film-Noir,Sensible" >> ../../datasets/ml1m-sun_sum3/ml1m/hierarchy.txt
    echo "History,Special-Info" >> ../../datasets/ml1m-sun_sum3/ml1m/hierarchy.txt
    echo "Horror,Imaginational_Entertainment" >> ../../datasets/ml1m-sun_sum3/ml1m/hierarchy.txt
    echo "Music,Experience" >> ../../datasets/ml1m-sun_sum3/ml1m/hierarchy.txt
    echo "Musical,Experience" >> ../../datasets/ml1m-sun_sum3/ml1m/hierarchy.txt
    echo "Mystery,Imaginational_Entertainment" >> ../../datasets/ml1m-sun_sum3/ml1m/hierarchy.txt
    echo "Romance,Sensible" >> ../../datasets/ml1m-sun_sum3/ml1m/hierarchy.txt
    echo "Sci-Fi,Imaginational_Entertainment" >> ../../datasets/ml1m-sun_sum3/ml1m/hierarchy.txt
    echo "Short,Short" >> ../../datasets/ml1m-sun_sum3/ml1m/hierarchy.txt
    echo "Sport,Entertaining_Information" >> ../../datasets/ml1m-sun_sum3/ml1m/hierarchy.txt
    echo "Thriller,Imaginational_Entertainment" >> ../../datasets/ml1m-sun_sum3/ml1m/hierarchy.txt
    echo "War,Actonreach" >> ../../datasets/ml1m-sun_sum3/ml1m/hierarchy.txt
    echo "Western,Actonreach" >> ../../datasets/ml1m-sun_sum3/ml1m/hierarchy.txt
fi

#[activate jointrec]
conda deactivate
conda activate jointrec

#[sum_auxiliary.txt]
if no_exist "../../datasets/ml1m-sun_sum3/ml1m/sum_auxiliary.txt"
then
    python sun2cao_step0.py --auxiliary '../../datasets/ml1m-sun/ml1m/auxiliary.txt' --summarize '../../datasets/ml1m-sun_sum3/ml1m/hierarchy.txt' --output '../../datasets/ml1m-sun_sum3/ml1m/sum_auxiliary.txt'
    BACK_PID=$!
    wait $BACK_PID
fi

#[sun2cao_step1]
if no_exist "../../datasets/ml1m-sun_sum3/ml1m/kg/kg_hop0_sun.dat"
then
    python sun2cao_step1.py --auxiliary '../../datasets/ml1m-sun_sum3/ml1m/sum_auxiliary.txt' --i2kg_map '../../datasets/ml1m-cao/ml1m/i2kg_map.tsv' --mapping '../../datasets/ml1m-sun_sum3/ml1m/'
    BACK_PID=$!
    wait $BACK_PID
fi

#[sun2cao_step2]
if no_exist "../../datasets/ml1m-sun_sum3/ml1m/kg/e_map.dat"
then
    python sun2cao_step2.py --data_path '../../datasets/ml1m-sun_sum3/' --dataset 'ml1m'
    BACK_PID=$!
    wait $BACK_PID
fi

#[activate rkge]
conda deactivate
conda activate rkge

cd ../../Recurrent-Knowledge-Graph-Embedding

#[rkge preprocessing]
if no_exist "../../datasets/ml1m-sun_sum3/positive-path.txt" || no_exist "../../datasets/ml1m-sun_sum3/negative-path.txt"
then
    python auxiliary-mapping-ml.py --auxiliary ../datasets/ml1m-sun_sum3/ml1m/sum_auxiliary.txt --mapping ../datasets/ml1m-sun_sum3/ml1m/auxiliary-mapping.txt
fi


###############
#sun_sum2
###############

cd ../know-rec/preprocess

#[sun2cao/train.dat, valid.dat, test.dat, ... from sun2cao]
ln -s ~/git/datasets/ml1m-sun2cao/ml1m/i_map.dat ~/git/datasets/ml1m-sun_sum2/ml1m/i_map.dat
ln -s ~/git/datasets/ml1m-sun2cao/ml1m/u_map.dat ~/git/datasets/ml1m-sun_sum2/ml1m/u_map.dat

#[hierarchy.txt]
if no_exist "../../datasets/ml1m-sun_sum2/ml1m/hierarchy.txt"
then
    touch ../../datasets/ml1m-sun_sum2/ml1m/hierarchy.txt
    echo "Action,Entertainment" >> ../../datasets/ml1m-sun_sum2/ml1m/hierarchy.txt
    echo "Adult,Entertainment" >> ../../datasets/ml1m-sun_sum2/ml1m/hierarchy.txt
    echo "Adventure,Entertainment" >> ../../datasets/ml1m-sun_sum2/ml1m/hierarchy.txt
    echo "Animation,Entertainment" >> ../../datasets/ml1m-sun_sum2/ml1m/hierarchy.txt
    echo "Biography,Information" >> ../../datasets/ml1m-sun_sum2/ml1m/hierarchy.txt
    echo "Comedy,Entertainment" >> ../../datasets/ml1m-sun_sum2/ml1m/hierarchy.txt
    echo "Crime,Entertainment" >> ../../datasets/ml1m-sun_sum2/ml1m/hierarchy.txt
    echo "Documentary,Information" >> ../../datasets/ml1m-sun_sum2/ml1m/hierarchy.txt
    echo "Drama,Entertainment" >> ../../datasets/ml1m-sun_sum2/ml1m/hierarchy.txt
    echo "Family,Entertainment" >> ../../datasets/ml1m-sun_sum2/ml1m/hierarchy.txt
    echo "Fantasy,Entertainment" >> ../../datasets/ml1m-sun_sum2/ml1m/hierarchy.txt
    echo "Film-Noir,Entertainment" >> ../../datasets/ml1m-sun_sum2/ml1m/hierarchy.txt
    echo "History,Information" >> ../../datasets/ml1m-sun_sum2/ml1m/hierarchy.txt
    echo "Horror,Entertainment" >> ../../datasets/ml1m-sun_sum2/ml1m/hierarchy.txt
    echo "Music,Entertainment" >> ../../datasets/ml1m-sun_sum2/ml1m/hierarchy.txt
    echo "Musical,Entertainment" >> ../../datasets/ml1m-sun_sum2/ml1m/hierarchy.txt
    echo "Mystery,Entertainment" >> ../../datasets/ml1m-sun_sum2/ml1m/hierarchy.txt
    echo "Romance,Entertainment" >> ../../datasets/ml1m-sun_sum2/ml1m/hierarchy.txt
    echo "Sci-Fi,Entertainment" >> ../../datasets/ml1m-sun_sum2/ml1m/hierarchy.txt
    echo "Short,Short" >> ../../datasets/ml1m-sun_sum2/ml1m/hierarchy.txt
    echo "Sport,Entertainment" >> ../../datasets/ml1m-sun_sum2/ml1m/hierarchy.txt
    echo "Thriller,Entertainment" >> ../../datasets/ml1m-sun_sum2/ml1m/hierarchy.txt
    echo "War,Entertainment" >> ../../datasets/ml1m-sun_sum2/ml1m/hierarchy.txt
    echo "Western,Entertainment" >> ../../datasets/ml1m-sun_sum2/ml1m/hierarchy.txt
fi

#[activate jointrec]
conda deactivate
conda activate jointrec

#[sum_auxiliary.txt]
if no_exist "../../datasets/ml1m-sun_sum2/ml1m/sum_auxiliary.txt"
then
    python sun2cao_step0.py --auxiliary '../../datasets/ml1m-sun/ml1m/auxiliary.txt' --summarize '../../datasets/ml1m-sun_sum2/ml1m/hierarchy.txt' --output '../../datasets/ml1m-sun_sum2/ml1m/sum_auxiliary.txt'
    BACK_PID=$!
    wait $BACK_PID
fi

#[sun2cao_step1]
if no_exist "../../datasets/ml1m-sun_sum2/ml1m/kg/kg_hop0_sun.dat"
then
    python sun2cao_step1.py --auxiliary '../../datasets/ml1m-sun_sum2/ml1m/sum_auxiliary.txt' --i2kg_map '../../datasets/ml1m-cao/ml1m/i2kg_map.tsv' --mapping '../../datasets/ml1m-sun_sum2/ml1m/'
    BACK_PID=$!
    wait $BACK_PID
fi

#[sun2cao_step2]
if no_exist "../../datasets/ml1m-sun_sum2/ml1m/kg/e_map.dat"
then
    python sun2cao_step2.py --data_path '../../datasets/ml1m-sun_sum2/' --dataset 'ml1m'
    BACK_PID=$!
    wait $BACK_PID
fi

#[activate rkge]
conda deactivate
conda activate rkge

cd ../../Recurrent-Knowledge-Graph-Embedding

#[rkge preprocessing]
if no_exist "../../datasets/ml1m-sun_sum2/positive-path.txt" || no_exist "../../datasets/ml1m-sun_sum2/negative-path.txt"
then
    python auxiliary-mapping-ml.py --auxiliary ../datasets/ml1m-sun_sum2/ml1m/sum_auxiliary.txt --mapping ../datasets/ml1m-sun_sum2/ml1m/auxiliary-mapping.txt
fi
