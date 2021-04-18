#!/bin/bash
# This file is part of this program.
#
# Copyright 2020 Juarez Sacenti
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#######################################
# Cao format ml-sun
# GLOBALS:
#   HOME
#   experiment: running experiment. Default is 'Sacenti-JOURNAL2021'.
# FUNCTIONS:
# cao-format_ml-sun
# ARGUMENTS:
#   dataset: Input dataset, e.g, ml-sun, ml-cao
#   low_frequence: Filtering, e.g, infrequent entities filtering at 0 (sKG) and at 10 (sfKG)
# OUTPUTS:
#   None
# RETURN:
#   0 if print succeeds, non-zero on error.
#######################################
seed=0
verbose=false

#######################################
# Import ../util/util.sh
# FUNCTIONS:
#   no_exist 'path_to_file'
#   copy_dataset 'path_to_dataset' 'path_to_new_dataset'
#######################################
source $HOME/git/kg-summ-rec/util/util.sh

cao-format_ml-cao() {
    local dataset=$1 # Dataset
    local low_frequence=$2 # Filtering
    local split_type=$3
    seed=$4
    if [ "$5" = 'true' ]; then verbose=true; else verbose=false; fi

    if [ "$split_type" = 'cv' ]
    then
        cv_cao-format_ml-cao "${dataset}" "${low_frequence}"
    elif [ "$split_type" = 'ho' ]
    then
        ho_cao-format_ml-cao "${dataset}" "${low_frequence}"
    else
        echo "ERROR: split_type param of cao-format_ml-cao() must be 'ho' or 'cv'."
    fi
}


# Converts ml-sun to cao_format in hold-out
ho_cao-format_ml-cao() {
    local dataset=$1 # Dataset
    local low_frequence=$2 # Filtering

    #[Cleaning KG]
    clean_cao ${dataset}

    #[activate kg-summ-rec]
    conda deactivate
    conda activate kg-summ-rec

    mv "$HOME/git/datasets/${experiment}/${dataset}/cao-format/ml1m/train.dat" "$HOME/git/datasets/${experiment}/${dataset}/cao-format/ml1m/train.dat.old"
    mv "$HOME/git/datasets/${experiment}/${dataset}/cao-format/ml1m/valid.dat" "$HOME/git/datasets/${experiment}/${dataset}/cao-format/ml1m/valid.dat.old"
    mv "$HOME/git/datasets/${experiment}/${dataset}/cao-format/ml1m/test.dat" "$HOME/git/datasets/${experiment}/${dataset}/cao-format/ml1m/test.dat.old"
    if [ "$verbose" = true ]; then echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset}/cao-format/ml1m/train.dat"; fi
    #[train.dat, valid.dat, test.dat by splitting rating-delete-missing-item.txt]
    python cao_split.py --loadpath "$HOME/git/datasets/${experiment}/${dataset}/cao-format/ml1m/" --column 'user_id' --frac '0.1,0.2' --savepath "$HOME/git/datasets/${experiment}/${dataset}/cao-format/ml1m/" --seed "${seed}"

    if no_exist "$HOME/git/datasets/${experiment}/${dataset}/kg-ig.nt"
    then
        cd ../util
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}//${dataset}/kg-ig.nt"; fi
        python kg2rdf.py --mode 'splitkg' --kgpath "$HOME/git/datasets/${experiment}/${dataset}/cao-format/ml1m/kg/" --output "$HOME/git/datasets/${experiment}/${dataset}/kg-ig.nt"
        ln -s "$HOME/git/datasets/${experiment}/${dataset}/cao-format/ml1m/kg/e_map.dat" "$HOME/git/datasets/${experiment}/${dataset}/cao-format/ml1m/kg_map.dat"
        cd ../preprocess
    fi

    #return to starting folder
    cd "$HOME/git/kg-summ-rec/preprocess"
}


# Converts ml-sun to cao_format in cross-validation 5-fold
cv_cao-format_ml-cao() {
    local dataset=$1 # Dataset
    local low_frequence=$2 # Filtering

    #[Cleaning KG]
    clean_cao ml-cao

    # Create folds, fold0, ..., folders
    if [ ! -d "$HOME/git/datasets/${experiment}/folds" ]
    then
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/folds"; fi
        mkdir ~/git/datasets/${experiment}/folds
        mkdir ~/git/datasets/${experiment}/fold0
        mkdir ~/git/datasets/${experiment}/fold1
        mkdir ~/git/datasets/${experiment}/fold2
        mkdir ~/git/datasets/${experiment}/fold3
        mkdir ~/git/datasets/${experiment}/fold4
    fi

    #[activate kg-summ-rec]
    conda deactivate
    conda activate kg-summ-rec

    # Create files in folds, fold0, ..., folders
    if no_exist "$HOME/git/datasets/${experiment}/folds/fold0.dat"
    then
        mv "$HOME/git/datasets/${experiment}/ml-cao/cao-format/ml1m/train.dat" "$HOME/git/datasets/${experiment}/ml-cao/cao-format/ml1m/train.dat.old"
        mv "$HOME/git/datasets/${experiment}/ml-cao/cao-format/ml1m/valid.dat" "$HOME/git/datasets/${experiment}/ml-cao/cao-format/ml1m/valid.dat.old"
        mv "$HOME/git/datasets/${experiment}/ml-cao/cao-format/ml1m/test.dat" "$HOME/git/datasets/${experiment}/ml-cao/cao-format/ml1m/test.dat.old"
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/folds"; fi
        python cao_split.py --loadpath "$HOME/git/datasets/${experiment}/ml-cao/cao-format/ml1m/" --column 'user_id' --frac '0.2,0.2,0.2,0.2' --savepath "$HOME/git/datasets/${experiment}/folds/" --seed "${seed}"
    fi

    if no_exist "$HOME/git/datasets/${experiment}/${dataset}/kg-ig.nt"
    then
        cd ../util
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/ml-cao/kg-ig.nt"; fi
        python kg2rdf.py --mode 'splitkg' --kgpath "$HOME/git/datasets/${experiment}/ml-cao/cao-format/ml1m/kg/" --output "$HOME/git/datasets/${experiment}/ml-cao/kg-ig.nt"
        ln -s "$HOME/git/datasets/${experiment}/ml-cao/cao-format/ml1m/kg/e_map.dat" "$HOME/git/datasets/${experiment}/ml-cao/cao-format/ml1m/kg_map.dat"
        cd ../preprocess
    fi

    if [ ! -d "$HOME/git/datasets/${experiment}/fold0/${dataset}" ]
    then
        folds=(0 1 2 3 4)
        for fold_number in "${folds[@]}"
        do
            if [ -e "$HOME/git/datasets/${experiment}/folds/runs.csv" ]
            then
                rm "$HOME/git/datasets/${experiment}/folds/runs.csv"
            fi
            if [ ! -d "$HOME/git/datasets/${experiment}/fold${fold_number}/${dataset}" ]
            then
                if [ "$verbose" = true ]; then echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/ml1m/kg"; fi
                mkdir ~/git/datasets/${experiment}/fold${fold_number}/${dataset}
                mkdir ~/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format
                mkdir ~/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/ml1m
                mkdir ~/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/ml1m/kg
            fi

            if no_exist "$HOME/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/ml1m/train.dat"
            then
                if [ "$verbose" = true ]; then echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/ml1m/train.dat"; fi
                cd "$HOME/git/kg-summ-rec/util"
                python select_fold.py --foldpath "$HOME/git/datasets/${experiment}/folds/" --ammount '5' --savepath "$HOME/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/ml1m/" --seed "${seed}"
                ln -s "$HOME/git/datasets/${experiment}/${dataset}/i_map.dat" "$HOME/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/ml1m/i_map.dat"
                ln -s "$HOME/git/datasets/${experiment}/${dataset}/u_map.dat" "$HOME/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/ml1m/u_map.dat"
                ln -s "$HOME/git/datasets/${experiment}/${dataset}/i2kg_map.tsv" "$HOME/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/ml1m/i2kg_map.dat"
                ln -s "$HOME/git/datasets/${experiment}/${dataset}/kg/e_map.dat" "$HOME/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/ml1m/kg/e_map.dat"
                ln -s "$HOME/git/datasets/${experiment}/${dataset}/kg/r_map.dat" "$HOME/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/ml1m/kg/r_map.dat"
                ln -s "$HOME/git/datasets/${experiment}/${dataset}/kg/train.dat" "$HOME/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/ml1m/kg/train.dat"
                ln -s "$HOME/git/datasets/${experiment}/${dataset}/kg/valid.dat" "$HOME/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/ml1m/kg/valid.dat"
                ln -s "$HOME/git/datasets/${experiment}/${dataset}/kg/test.dat" "$HOME/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/ml1m/kg/test.dat"
                ln -s "$HOME/git/datasets/${experiment}/ml-cao/cao-format/ml1m/kg/kg-ig.nt" "$HOME/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/ml1m/kg-ig.nt"
                ln -s "$HOME/git/datasets/${experiment}/ml-cao/cao-format/ml1m/kg/e_map.dat" "$HOME/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/ml1m/kg_map.dat"
                cd "$HOME/git/kg-summ-rec/preprocess"
            fi

        done
    fi

    #return to starting folder
    cd "$HOME/git/kg-summ-rec/preprocess"
}

clean_cao() {
    local dataset_clean=$1 # Dataset
    #[Cleaning KG]
    sed -i 's/14584	2967	18/14584	2967	7/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/train.dat"
    sed -i 's/14171	963	18/14171	963	7/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/train.dat"
    sed -i 's/3250	10992	10/10992	3250	10/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/train.dat"
    sed -i 's/3250	4736	10/4736	3250	10/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/train.dat"
    sed -i 's/3250	3032	10/3032	3250	10/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/train.dat"
    sed -i 's/3250	13432	10/13432	3250	10/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/train.dat"
    sed -i 's/3250	10625	10/10625	3250	10/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/train.dat"
    sed -i 's/3250	11194	10/11194	3250	10/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/train.dat"
    sed -i 's/3250	5364	10/5364	3250	10/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/train.dat"
    sed -i 's/12003	4156	1/4156	12003	1/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/train.dat"
    sed -i 's/12003	13841	1/13841	12003	1/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/train.dat"
    sed -i 's/12003	6579	1/6579	12003	1/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/train.dat"
    sed -i 's/3992	10293	1/10293	3992	1/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/train.dat"
    sed -i 's/9140	5381	13/5381	9140	13/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/train.dat"
    sed -i 's/5089	1707	5/1707	5089	7/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/train.dat"

    sed -i 's/14584	2967	18/14584	2967	7/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/valid.dat"
    sed -i 's/14171	963	18/14171	963	7/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/valid.dat"
    sed -i 's/3250	10992	10/10992	3250	10/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/valid.dat"
    sed -i 's/3250	4736	10/4736	3250	10/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/valid.dat"
    sed -i 's/3250	3032	10/3032	3250	10/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/valid.dat"
    sed -i 's/3250	13432	10/13432	3250	10/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/valid.dat"
    sed -i 's/3250	10625	10/10625	3250	10/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/valid.dat"
    sed -i 's/3250	11194	10/11194	3250	10/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/valid.dat"
    sed -i 's/3250	5364	10/5364	3250	10/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/valid.dat"
    sed -i 's/12003	13841	1/13841	12003	1/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/valid.dat"
    sed -i 's/12003	4156	1/4156	12003	1/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/valid.dat"
    sed -i 's/12003	6579	1/6579	12003	1/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/valid.dat"
    sed -i 's/3992	10293	1/10293	3992	1/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/valid.dat"
    sed -i 's/9140	5381	13/5381	9140	13/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/valid.dat"

    sed -i 's/5089	1707	5/1707	5089	7/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/valid.dat"
    sed -i 's/14584	2967	18/14584	2967	7/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/test.dat"
    sed -i 's/14171	963	18/14171	963	7/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/test.dat"
    sed -i 's/3250	10992	10/10992	3250	10/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/test.dat"
    sed -i 's/3250	4736	10/4736	3250	10/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/test.dat"
    sed -i 's/3250	3032	10/3032	3250	10/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/test.dat"
    sed -i 's/3250	13432	10/13432	3250	10/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/test.dat"
    sed -i 's/3250	10625	10/10625	3250	10/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/test.dat"
    sed -i 's/3250	11194	10/11194	3250	10/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/test.dat"
    sed -i 's/3250	5364	10/5364	3250	10/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/test.dat"
    sed -i 's/12003	4156	1/4156	12003	1/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/test.dat"
    sed -i 's/12003	13841	1/13841	12003	1/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/test.dat"
    sed -i 's/12003	6579	1/6579	12003	1/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/test.dat"
    sed -i 's/3992	10293	1/10293	3992	1/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/test.dat"
    sed -i 's/9140	5381	13/5381	9140	13/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/test.dat"
    sed -i 's/5089	1707	5/1707	5089	7/' "$HOME/git/datasets/${experiment}/${dataset_clean}/cao-format/ml1m/kg/test.dat"
}
