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
# Cao format sumamrization
# - KG type: item graph (ig) and user-item graph (uig)
# GLOBALS:
#   HOME
#   experiment: running experiment. Default is 'Sacenti-JOURNAL2021'.
# FUNCTIONS:
# cao-format_summ
# ARGUMENTS:
#   dataset: Input dataset, e.g, ml-sun, ml-cao
#   split_mode: Split mode, e.g, hold-out (ho)
#   filtering: Filtering, e.g, infrequent entities filtering at 0 (sKG) and at 10 (sfKG)
# OUTPUTS:
#   None
# RETURN:
#   0 if print succeeds, non-zero on error.
#######################################
verbose=false

#######################################
# Import ../util/util.sh
# FUNCTIONS:
#   no_exist 'path_to_file'
#   copy_dataset 'path_to_dataset' 'path_to_new_dataset'
#######################################
source $HOME/git/kg-summ-rec/util/util.sh

cao-format_summ() {
    local dataset_in=$1 # Input dataset: ml-sun, ml-cao
    local dataset_out=$2 # Output dataset: ml-sun_ho_sv_sKG, ml-cao_ho_mv_sfKG
    local low_frequence=$3 # Low Frequence: 0, 10
    if [ "$4" = 'true' ]; then verbose=true; else verbose=false; fi

    ################################################################################
    ###                       Preprocess ${DATASET}_${KGE}-${RATE}               ###
    ################################################################################
    if no_exist "$HOME/git/datasets/${experiment}/${dataset_out}/cao-format/ml1m/kg/kg_hop0.dat"
    then
        if [ "$verbose" = true ]
        then
            echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset_out}/cao-format/ml1m/kg/kg_hop0.dat"
            python sun2cao_step1.py --mode 'nt' --input "~/git/datasets/${experiment}/${dataset_out}/kg-ig.nt" --mapping "~/git/datasets/${experiment}/${dataset_out}/cao-format/ml1m" --verbose
        else
            python sun2cao_step1.py --mode 'nt' --input "~/git/datasets/${experiment}/${dataset_out}/kg-ig.nt" --mapping "~/git/datasets/${experiment}/${dataset_out}/cao-format/ml1m"
        fi
    fi

    #[sun2cao/train.dat, valid.dat, test.dat, ... from sun2cao]
    if no_exist "$HOME/git/datasets/${experiment}/${dataset_out}/cao-format/ml1m/train.dat"
    then
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset_out}/cao-format/ml1m/train.dat"; fi
        ln -s ~/git/datasets/${experiment}/${dataset_in}/cao-format/ml1m/train.dat ~/git/datasets/${experiment}/${dataset_out}/cao-format/ml1m/train.dat
        ln -s ~/git/datasets/${experiment}/${dataset_in}/cao-format/ml1m/valid.dat ~/git/datasets/${experiment}/${dataset_out}/cao-format/ml1m/valid.dat
        ln -s ~/git/datasets/${experiment}/${dataset_in}/cao-format/ml1m/test.dat ~/git/datasets/${experiment}/${dataset_out}/cao-format/ml1m/test.dat
        ln -s ~/git/datasets/${experiment}/${dataset_in}/cao-format/ml1m/i_map.dat ~/git/datasets/${experiment}/${dataset_out}/cao-format/ml1m/i_map.dat
        ln -s ~/git/datasets/${experiment}/${dataset_in}/cao-format/ml1m/u_map.dat ~/git/datasets/${experiment}/${dataset_out}/cao-format/ml1m/u_map.dat
        ln -s ~/git/datasets/${experiment}/${dataset_in}/cao-format/ml1m/i2kg_map.tsv ~/git/datasets/${experiment}/${dataset_out}/cao-format/ml1m/i2kg_map.tsv
        ln -s ~/git/datasets/${experiment}/${dataset_in}/cao-format/ml1m/kg_map.dat ~/git/datasets/${experiment}/${dataset_out}/cao-format/ml1m/kg_map.dat
    fi

    #[sun2cao_step2]
    if no_exist "$HOME/git/datasets/${experiment}/${dataset_out}/cao-format/ml1m/kg/e_map.dat"
    then
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset_out}/cao-format/ml1m/kg/e_map.dat"; fi
        python sun2cao_step2.py --data_path "~/git/datasets/${experiment}/${dataset_out}/cao-format/" --dataset 'ml1m' --lowfrequence ${low_frequence}
    fi

    cd "$HOME/git/kg-summ-rec/preprocess"
}
