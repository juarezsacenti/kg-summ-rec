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
# Import util/util.sh
# FUNCTIONS:
#   no_exist 'path_to_file'
#   copy_dataset 'path_to_dataset' 'path_to_new_dataset'
#######################################
source util/util.sh


#######################################
# Summarize using KGE-K-Means
# GLOBALS:
#   HOME, PWD
# ARGUMENTS:
#   dataset_in: Input dataset, e.g., ml-sun_ho_originalKG, ml-cao_ho_fKG
#   dataset_out: Output dataset name, e.g., ml-sun_ho_sv_sKG, ml-cao_ho_mv_sfKG
#   kge: Translation model, e.g., complex, distmult,
#   epochs: The iterations of the training loop.
#   batch_size: The number of batches in which the training set must be split
#     during the training loop
#   learning_rate: Optimizer learning rate
#   low_frequence: Low Frequence Filtering
# OUTPUTS:
#   None
# RETURN:
#   0 if print succeeds, non-zero on error.
#######################################
kge_k_means() {
    local dataset_in=$1
    local dataset_out=$2
    local kge=$3
    local epochs=$4
    local batch_size=$5
    local learning_rate=$6
    local low_frequence=$7

    ############################################################################
    ###                   Create dataset Folders - {25,50,75}                ###
    ############################################################################
    if [ ! -d "$HOME/git/datasets/${dataset_out}_${kge}-25" ]
    then
        echo "[kg-summ-rs] Creating ~/git/datasets/${dataset_out}_${kge}-25"
        mkdir ~/git/datasets/${dataset_out}_${kge}-25/
        mkdir ~/git/datasets/${dataset_out}_${kge}-25/cao-format
        mkdir ~/git/datasets/${dataset_out}_${kge}-25/cao-format/ml1m
        mkdir ~/git/datasets/${dataset_out}_${kge}-25/cao-format/ml1m/kg
        mkdir ~/git/results/${dataset_out}_${kge}-25/
    fi
    if [ ! -d "$HOME/git/datasets/${dataset_out}_${kge}-50" ]
    then
        echo "[kg-summ-rs] Creating ~/git/datasets/${dataset_out}_${kge}-50"
        mkdir ~/git/datasets/${dataset_out}_${kge}-50/
        mkdir ~/git/datasets/${dataset_out}_${kge}-50/cao-format
        mkdir ~/git/datasets/${dataset_out}_${kge}-50/cao-format/ml1m
        mkdir ~/git/datasets/${dataset_out}_${kge}-50/cao-format/ml1m/kg
        mkdir ~/git/results/${dataset_out}_${kge}-50/
    fi
    if [ ! -d "$HOME/git/datasets/${dataset_out}_${kge}-75" ]
    then
        echo "[kg-summ-rs] Creating ~/git/datasets/${dataset_out}_${kge}-75"
        mkdir ~/git/datasets/${dataset_out}_${kge}-75/
        mkdir ~/git/datasets/${dataset_out}_${kge}-75/cao-format
        mkdir ~/git/datasets/${dataset_out}_${kge}-75/cao-format/ml1m
        mkdir ~/git/datasets/${dataset_out}_${kge}-75/cao-format/ml1m/kg
        mkdir ~/git/results/${dataset_out}_${kge}-75/
    fi

    ############################################################################
    ###          Clusterize ${dataset_out} with ${kge} - {25,50,75}          ###
    ############################################################################
    # Dependencies:
    #[~/git/datasets/${dataset_out}/kg.nt]

    if no_exist "$HOME/git/know-rec/docker/kge-k-means_data/temp/kg.nt"
    then
        echo '[kg-summ-rs] Creating ~/git/know-rec/docker/kge-k-means_data/temp/kg.nt'
        yes | cp -L ~/git/datasets/${dataset_in}/kg.nt docker/kge-k-means_data/temp/
    fi
    if no_exist "$HOME/git/know-rec/docker/kge-k-means_data/temp/i2kg_map.tsv"
    then
        echo '[kg-summ-rs] Creating ~/git/know-rec/docker/kge-k-means_data/temp/i2kg_map.tsv'
        yes | cp -L ~/git/datasets/${dataset_in}/cao-format/ml1m/i2kg_map.tsv docker/kge-k-means_data/temp/
    fi
    if no_exist "$HOME/git/datasets/${dataset_out}_${kge}-25/cluster25.tsv"
    then
        echo "[kg-summ-rs] Creating ~/git/datasets/${dataset_out}_${kge}-25/cluster25.tsv"
        cd docker
        cp kge-k-means_Dockerfile Dockerfile
        docker build -t kge-k-means:1.0 .

        docker run --rm -it --gpus all -v "$PWD"/kge-k-means_data:/data -w /data \
        kge-k-means:1.0 /bin/bash -c "python kge-k-means.py --mode 'singleview' \
        --kge ${kge} --epochs ${epochs} --batch_size ${batch_size} --learning_rate \
        ${learning_rate} --verbose"

        cp "$HOME/git/know-rec/docker/kge-k-means_data/temp/cluster25.tsv" "$HOME/git/datasets/${dataset_out}_${kge}-25/cluster25.tsv"
        cp "$HOME/git/know-rec/docker/kge-k-means_data/temp/cluster50.tsv" "$HOME/git/datasets/${dataset_out}_${kge}-50/cluster50.tsv"
        cp "$HOME/git/know-rec/docker/kge-k-means_data/temp/cluster75.tsv" "$HOME/git/datasets/${dataset_out}_${kge}-75/cluster75.tsv"
        cd ..
    fi

    ############################################################################
    ###              Summarize ${dataset_out} with clusters                  ###
    ############################################################################
    #[activate jointrec]
    conda deactivate
    conda activate jointrec

    if no_exist "$HOME/git/datasets/${dataset_out}_${kge}-25/kg.nt"
    then
        echo "[kg-summ-rs] Creating ~/git/datasets/${dataset_out}_${kge}-25/kg.nt"
        cd util
        python kg2rdf.py --mode 'cluster' --input2 "$HOME/git/datasets/${dataset_out}_${kge}-25/cluster25.tsv" \
        --input "$HOME/git/datasets/${dataset_in}/kg.nt" --output "$HOME/git/datasets/${dataset_out}_${kge}-25/kg.nt"
        cd ..
    fi
    if no_exist "$HOME/git/datasets/${dataset_out}_${kge}-50/kg.nt"
    then
        echo "[kg-summ-rs] Creating ~/git/datasets/${dataset_out}_${kge}-50/kg.nt"
        cd util
        python kg2rdf.py --mode 'cluster' --input2 "$HOME/git/datasets/${dataset_out}_${kge}-50/cluster50.tsv" \
        --input "$HOME/git/datasets/${dataset_in}/kg.nt"  --output "$HOME/git/datasets/${dataset_out}_${kge}-50/kg.nt"
        cd ..
    fi
    if no_exist "$HOME/git/datasets/${dataset_out}_${kge}-75/kg.nt"
    then
        echo "[kg-summ-rs] Creating ~/git/datasets/${dataset_out}_${kge}-75/kg.nt"
        cd util
        python kg2rdf.py --mode 'cluster' --input2 "$HOME/git/datasets/${dataset_out}_${kge}-75/cluster75.tsv" \
        --input "$HOME/git/datasets/${dataset_in}/kg.nt"  --output "$HOME/git/datasets/${dataset_out}_${kge}-75/kg.nt"
        cd ..
    fi
}
