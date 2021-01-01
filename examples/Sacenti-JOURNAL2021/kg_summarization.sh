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
# KG summarization
# - Algorithms: KGE-K-Means (complex) and GEMSEC (gemsec)
# - KG type: item graph (ig) and user-item graph (uig)
# - Summarization mode: single-view (sv) and multi-view (mv)
# - Entity preservation ratio: 75, 50 and 25%
# GLOBALS:
#   HOME
#   experiment: running experiment. Default is 'Sacenti-JOURNAL2021'.
# FUNCTIONS:
#   summarize
#   preprocess_uig
#   preprocess_summ
#   measure_summ_impact
#   kg_summarization
# ARGUMENTS:
#   dataset: Input dataset, e.g, ml-sun, ml-cao
#   split_mode: Split mode, e.g, hold-out (ho)
#   filtering: Filtering, e.g, infrequent entities filtering at 0 (sKG) and at 10 (sfKG)
# OUTPUTS:
#   None
# RETURN:
#   0 if print succeeds, non-zero on error.
#######################################
experiment='Sacenti-JOURNAL2021'

#######################################
# Import ../util/util.sh
# FUNCTIONS:
#   no_exist 'path_to_file'
#   copy_dataset 'path_to_dataset' 'path_to_new_dataset'
#######################################
source $HOME/git/kg-summ-rs/util/util.sh

#######################################
# Import ../summarization/kge_k_means.sh
# FUNCTIONS:
#   kge_k_means 'experiment' 'dataset_in' 'dataset_out' 'kg_type' 'summarization_mode' 'kge' 'epochs' 'batch_size' learning_rate' 'low_frequence'
#######################################
source $HOME/git/kg-summ-rs/summarization/kge_k_means.sh

#######################################
# Import ../summarization/gemsec.sh
# FUNCTIONS:
#   gemsec 'dataset_in' 'dataset_out' 'kg_type' 'summarization_mode' 'model' 'learning_rate_init' 'learning_rate_min'
#######################################
source $HOME/git/kg-summ-rs/summarization/gemsec.sh

#######################################
# Import ../summarization/cao-format_summ.sh
# FUNCTIONS:
#   cao-format_summ
#######################################
source cao-format_summ.sh

####
# KG recommendation
#
# - TODO ml-sun_ho_sKG_complex-uig-sv-75
# - TODO ml-sun_ho_sKG_complex-uig-sv-50
# - TODO ml-sun_ho_sKG_complex-uig-sv-25
# - TODO ml-sun_ho_sKG_complex-uig-mv-75
# - TODO ml-sun_ho_sKG_complex-uig-mv-50
# - TODO ml-sun_ho_sKG_complex-uig-mv-25
#
# - ml-sun_ho_sKG_gemsec-ig-sv-75
# - ml-sun_ho_sKG_gemsec-ig-sv-50
# - ml-sun_ho_sKG_gemsec-ig-sv-25
#
# - TODO ml-sun_ho_sKG_gemsec-ig-mv-75
# - TODO ml-sun_ho_sKG_gemsec-ig-mv-50
# - TODO ml-sun_ho_sKG_gemsec-ig-mv-25
#
# - TODO ml-sun_ho_sKG_gemsec-uig-sv-75
# - TODO ml-sun_ho_sKG_gemsec-uig-sv-50
# - TODO ml-sun_ho_sKG_gemsec-uig-sv-25
#
# - TODO ml-sun_ho_sKG_gemsec-uig-mv-75
# - TODO ml-sun_ho_sKG_gemsec-uig-mv-50
# - TODO ml-sun_ho_sKG_gemsec-uig-mv-25
#
# (Sacenti-JIIS2021)
# - ml-sun_ho_oKG
# - ml-sun_ho_fKG
#
# - ml-sun_ho_sKG_complex-ig-sv-75
# - ml-sun_ho_sKG_complex-ig-sv-50
# - ml-sun_ho_sKG_complex-ig-sv-25
# - ml-sun_ho_sfKG_complex-ig-sv-75
# - ml-sun_ho_sfKG_complex-ig-sv-50
# - ml-sun_ho_sfKG_complex-ig-sv-25
#
# - ml-sun_ho_sKG_complex-ig-mv-75
# - ml-sun_ho_sKG_complex-ig-mv-50
# - ml-sun_ho_sKG_complex-ig-mv-25
# - ml-sun_ho_sfKG_complex-ig-mv-75
# - ml-sun_ho_sfKG_complex-ig-mv-50
# - ml-sun_ho_sfKG_complex-ig-mv-25
####
summarize() {
    local dataset_in=$1
    local dataset_out=$2
    local kg_type=$3
    local low_frequence=$4

    # default parameters
    local model='GEMSECWithRegularization'
    local learning_rate_init='0.001'
    local learning_rate_min='0.0001'
    local kge='complex'
    local epochs='150'
    local batch_size='100'
    local learning_rate='0.005'
    local kg_filename="kg-${kg_type}.nt"

    local summarization_mode='sv'

    gemsec ${dataset_in} "${dataset_out}_${kg_type}" ${kg_filename} ${summarization_mode} \
    ${model} ${learning_rate_init} ${learning_rate_min}
    kge_k_means ${experiment} ${dataset_in} "${dataset_out}_${kg_type}" ${kg_filename} ${summarization_mode} \
    ${kge} ${epochs} ${batch_size} ${learning_rate} ${low_frequence}

    summarization_mode='mv'

    gemsec ${dataset_in} "${dataset_out}_${kg_type}" ${kg_filename} ${summarization_mode} \
    ${model} ${learning_rate_init} ${learning_rate_min}
    kge_k_means ${experiment} ${dataset_in} "${dataset_out}_${kg_type}" ${kg_filename} ${summarization_mode} \
    ${kge} ${epochs} ${batch_size} ${learning_rate} ${low_frequence}
}

preprocess_uig() {
    local dataset_in=$1

    if no_exist "$HOME/git/datasets/${experiment}/${dataset_in}/kg-uig.nt"
    then
        echo "[kg-summ-rs] Creating ~/git/datasets/${experiment}/${dataset_in}/kg-uig.nt"
        cd $HOME/git/kg-summ-rs/util
        python kg2rdf.py --mode 'ig2uig' --input "$HOME/git/datasets/${experiment}/${dataset_in}/kg-ig.nt" \
        --input2 "$HOME/git/datasets/${experiment}/${dataset_in}/cao-format/ml1m/" \
        --output "$HOME/git/datasets/${experiment}/${dataset_in}/kg-uig.nt"
        cd $HOME/git/kg-summ-rs/examples/${experiment}
    fi
}

preprocess_summ() {
    local dataset_in=$1
    local dataset_out=$2
    local kg_type=$3
    local low_frequence=$4

    cd $HOME/git/kg-summ-rs/preprocess

    summ_types=(ig uig)
    summ_modes=(sv mv)
    summ_algos=(complex gemsec)
    summ_rates=(25 50 75)
    for t in "${summ_types[@]}"
    do
        for m in "${summ_modes[@]}"
        do
            for a in "${summ_algos[@]}"
            do
                for r in "${summ_rates[@]}"
                do
                    cao-format_summ "${dataset_in}" "${dataset_out}" $t $m $a $r "${low_frequence}"
                done
            done
        done
    done

    cd $HOME/git/kg-summ-rs/examples/${experiment}
}

measure_summ_impact() {
    local dataset_in=$1
    local dataset_out=$2
    local kg_type=$3
    local low_frequence=$4

    cd $HOME/git/kg-summ-rs/util

    summ_types=(ig uig)
    summ_modes=(sv mv)
    summ_algos=(complex gemsec)
    summ_rates=(25 50 75)
    for t in "${summ_types[@]}"
    do
        for m in "${summ_modes[@]}"
        do
            for a in "${summ_algos[@]}"
            do
                for r in "${summ_rates[@]}"
                do
                    local dirName="${dataset_out}_${t}_${m}_${a}_${r}"
                    if no_exist "$HOME/git/results/${experiment}/${dirName}/kg_stats.tsv"
                    then
                        echo "[kg-summ-rs] Creating ~/git/results/${experiment}/${dirName}/kg_stats.tsv"
                        python kg2rdf.py --mode 'statistics' --kgpath "$HOME/git/datasets/${experiment}/${dirName}" \
                        --output "$HOME/git/results/${experiment}/${dirName}//kg_stats.tsv"
                    fi
                done
            done
        done
    done

    cd $HOME/git/kg-summ-rs/examples/${experiment}
}

kg_summarization() {
    local dataset=$1 # Input dataset: ml-sun, ml-cao
    local split_mode=$2 # Split mode: hold-out (ho)
    local filtering=$3 # Filtering: infrequent entities filtering at 0 (sKG) and at 10 (sfKG)

    local dataset_in="${dataset}_${split_mode}_oKG"
    local dataset_out="${dataset}_${split_mode}_${filtering}"

    local low_frequence=0
    if [ ${filtering} -eq "sfKG" ]; then
        low_frequence=10
    fi

    local kg_type='ig'

    summarize ${dataset_in} ${dataset_out} ${kg_type} ${low_frequence}
    preprocess_summ ${dataset_in} ${dataset_out} ${kg_type} ${low_frequence}
    measure_summ_impact ${dataset_in} ${dataset_out} ${kg_type} ${low_frequence}

    preprocess_uig ${dataset_in}

    local kg_type='uig'

    summarize ${dataset_in} ${dataset_out} ${kg_type} ${low_frequence}
    preprocess_summ ${dataset_in} ${dataset_out} ${kg_type} ${low_frequence}
    measure_summ_impact ${dataset_in} ${dataset_out} ${kg_type} ${low_frequence}

}
