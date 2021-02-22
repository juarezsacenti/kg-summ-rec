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

cao-format_ml-sun() {
    local dataset=$1 # Dataset
    local low_frequence=$2 # Filtering
    local split_type=$3
    seed=$4
    if [ "$5" = 'true' ]; then verbose=true; else verbose=false; fi

    if [ "$split_type" = 'cv' ]
    then
        cv_cao-format_ml-sun "${dataset}" "${low_frequence}"
    elif [ "$split_type" = 'ho' ]
    then
        ho_cao-format_ml-sun "${dataset}" "${low_frequence}"
    else
        echo "ERROR: split_type param of cao-format_ml-sun() must be 'ho' or 'cv'."
    fi
}


# Converts ml-sun to cao_format in hold-out
ho_cao-format_ml-sun() {
    local dataset=$1 # Dataset
    local low_frequence=$2 # Filtering

    if [ ! -d "$HOME/git/datasets/${experiment}/${dataset}/cao-format" ]
    then
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset}/cao-format/ml1m/kg"; fi
        mkdir ~/git/datasets/${experiment}/${dataset}/cao-format
        mkdir ~/git/datasets/${experiment}/${dataset}/cao-format/ml1m
        mkdir ~/git/datasets/${experiment}/${dataset}/cao-format/ml1m/kg
    fi

    #[activate kg-summ-rec]
    conda deactivate
    conda activate kg-summ-rec

    if no_exist "$HOME/git/datasets/${experiment}/${dataset}/cao-format/ml1m/train.dat"
    then
        if true # ml100k ratings from Sun's project
        then
            if [ "$verbose" = true ]; then echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset}/cao-format/ml1m/train.dat"; fi
            #[train.dat, valid.dat, test.dat by splitting rating-delete-missing-item.txt]
            python sun_split.py --loadfile "$HOME/git/datasets/${experiment}/${dataset}/sun-format/rating-delete-missing-itemid.txt" --column 'user_id' --frac '0.1,0.2' --savepath "$HOME/git/datasets/${experiment}/${dataset}/cao-format/ml1m/" --seed "${seed}"
        else # ml1m ratings from Cao's project
            #[train.dat, valid.dat, test.dat symbolic links]
            if [ "$verbose" = true ]; then echo "Copying ~/git/datasets/${experiment}/${dataset}/cao-format/ml1m/train.dat"; fi
            ln -s ~/git/datasets/ml-cao/cao-format/ml1m/train.dat ~/git/datasets/${experiment}/${dataset}/cao-format/ml1m/train.dat
            ln -s ~/git/datasets/ml-cao/cao-format/ml1m/valid.dat ~/git/datasets/${experiment}/${dataset}/cao-format/ml1m/valid.dat
            ln -s ~/git/datasets/ml-cao/cao-format/ml1m/test.dat ~/git/datasets/${experiment}/${dataset}/cao-format/ml1m/test.dat
            ln -s ~/git/datasets/ml-cao/cao-format/ml1m/i_map.dat ~/git/datasets/${experiment}/${dataset}/cao-format/ml1m/i_map.dat
            ln -s ~/git/datasets/ml-cao/cao-format/ml1m/u_map.dat ~/git/datasets/${experiment}/${dataset}/cao-format/ml1m/u_map.dat
        fi
    fi

    #[clean_auxiliary.txt]
    if no_exist "$HOME/git/datasets/${experiment}/${dataset}/cao-format/ml1m/clean_auxiliary.txt"
    then
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset}/cao-format/ml1m/clean_auxiliary.txt"; fi
        python sun2cao_step0.py --auxiliary "$HOME/git/datasets/${experiment}/${dataset}/sun-format/auxiliary.txt" --output "$HOME/git/datasets/${experiment}/${dataset}/cao-format/ml1m/clean_auxiliary.txt"
    fi

    #[sun2cao_step1]
    if no_exist "$HOME/git/datasets/${experiment}/${dataset}/cao-format/ml1m/kg/kg_hop0.dat"
    then
        if [ "$verbose" = true ]
        then
            echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset}/cao-format/ml1m/kg/kg_hop0.dat"
            python sun2cao_step1.py --input "$HOME/git/datasets/${experiment}/${dataset}/cao-format/ml1m/clean_auxiliary.txt"  --mapping "$HOME/git/datasets/${experiment}/${dataset}/cao-format/ml1m/" --verbose
        else
            python sun2cao_step1.py --input "$HOME/git/datasets/${experiment}/${dataset}/cao-format/ml1m/clean_auxiliary.txt"  --mapping "$HOME/git/datasets/${experiment}/${dataset}/cao-format/ml1m/"
        fi
    fi

    #[sun2cao_step2]
    if no_exist "$HOME/git/datasets/${experiment}/${dataset}/cao-format/ml1m/kg/e_map.dat"
    then
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset}/cao-format/ml1m/kg/e_map.dat"; fi
        python sun2cao_step2.py --data_path "~/git/datasets/${experiment}/${dataset}/cao-format/" --dataset 'ml1m' --lowfrequence ${low_frequence}
    fi

    #return to starting folder
    cd "$HOME/git/kg-summ-rec/preprocess"
}


# Converts ml-sun to cao_format in cross-validation 5-fold
cv_cao-format_ml-sun() {
    local dataset=$1 # Dataset
    local low_frequence=$2 # Filtering

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
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/folds"; fi
        python sun_split.py --loadfile "$HOME/git/datasets/${experiment}/ml-sun/sun-format/rating-delete-missing-itemid.txt" --column 'user_id' --frac '0.2,0.2,0.2,0.2' --savepath "$HOME/git/datasets/${experiment}/folds/" --seed "${seed}"

        folds=(0 1 2 3 4)
        for fold_number in "${folds[@]}"
        do
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
                echo ${fold_number}
                cd "$HOME/git/kg-summ-rec/util"
                python select_fold.py --foldpath "$HOME/git/datasets/${experiment}/folds/" --ammount '5' --savepath "$HOME/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/ml1m/" --seed "${seed}"
                cd "$HOME/git/kg-summ-rec/preprocess"
            fi

            #[clean_auxiliary.txt]
            if no_exist "$HOME/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/ml1m/clean_auxiliary.txt"
            then
                if [ "$verbose" = true ]; then echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/ml1m/clean_auxiliary.txt"; fi
                python sun2cao_step0.py --auxiliary "$HOME/git/datasets/${experiment}/ml-sun/sun-format/auxiliary.txt" --output "$HOME/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/ml1m/clean_auxiliary.txt"
            fi

            #[sun2cao_step1]
            if no_exist "$HOME/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/ml1m/kg/kg_hop0.dat"
            then
                if [ "$verbose" = true ]
                then
                    echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/ml1m/kg/kg_hop0.dat"
                    python sun2cao_step1.py --input "$HOME/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/ml1m/clean_auxiliary.txt"  --mapping "$HOME/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/ml1m/" --verbose
                else
                    python sun2cao_step1.py --input "$HOME/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/ml1m/clean_auxiliary.txt"  --mapping "$HOME/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/ml1m/"
                fi
            fi

            #[sun2cao_step2]
            if no_exist "$HOME/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/ml1m/kg/e_map.dat"
            then
                if [ "$verbose" = true ]; then echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/ml1m/kg/e_map.dat"; fi
                python sun2cao_step2.py --data_path "~/git/datasets/${experiment}/fold${fold_number}/${dataset}/cao-format/" --dataset 'ml1m' --lowfrequence ${low_frequence} --seed "${seed}"
            fi
        done
    fi
    #return to starting folder
    cd "$HOME/git/kg-summ-rec/preprocess"
}
