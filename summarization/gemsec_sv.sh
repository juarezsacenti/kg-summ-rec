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
# Import ../util/util.sh
# FUNCTIONS:
#   no_exist 'path_to_file'
#   copy_dataset 'path_to_dataset' 'path_to_new_dataset'
#######################################
source ../util/util.sh

#######################################
# Summarize using Gemsec
# GLOBALS:
#   HOME, PWD
# ARGUMENTS:
#   dataset_in: Input dataset, e.g., ml-sun_ho_originalKG, ml-cao_ho_fKG
#   dataset_out: Output dataset name, e.g., ml-sun_ho_sv_sKG, ml-cao_ho_mv_sfKG
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
gemsec() {
    local dataset_in=$1 # Default is "ml-sun_ho_originalKG"
    local dataset_out=$2 # Default is "ml-sun_ho_sv_sKG"
    local model=$3 # Default is "GEMSECWithRegularization"
    local learning_rate_init=$4 # Default is 0.001
    local learning_rate_min=$5 # Default is 0.0001

    ############################################################################
    ###                        Create dataset Folders                        ###
    ############################################################################
    if [ ! -d "$HOME/git/datasets/${dataset_out}_gemsec-25" ]
    then
        echo "[kg-summ-rs] Creating ~/git/datasets/${dataset_out}_gemsec-25"
        mkdir ~/git/datasets/${dataset_out}_gemsec-25/
        mkdir ~/git/datasets/${dataset_out}_gemsec-25/cao-format
        mkdir ~/git/datasets/${dataset_out}_gemsec-25/cao-format/ml1m
        mkdir ~/git/datasets/${dataset_out}_gemsec-25/cao-format/ml1m/kg
        mkdir ~/git/results/${dataset_out}_gemsec-25/
    fi
    if [ ! -d "$HOME/git/datasets/${dataset_out}_gemsec-50" ]
    then
        echo "[kg-summ-rs] Creating ~/git/datasets/${dataset_out}_gemsec-50"
        mkdir ~/git/datasets/${dataset_out}_gemsec-50/
        mkdir ~/git/datasets/${dataset_out}_gemsec-50/cao-format
        mkdir ~/git/datasets/${dataset_out}_gemsec-50/cao-format/ml1m
        mkdir ~/git/datasets/${dataset_out}_gemsec-50/cao-format/ml1m/kg
        mkdir ~/git/results/${dataset_out}_gemsec-50/
    fi
    if [ ! -d "$HOME/git/datasets/${dataset_out}_gemsec-75" ]
    then
        echo "[kg-summ-rs] Creating ~/git/datasets/${dataset_out}_gemsec-75"
        mkdir ~/git/datasets/${dataset_out}_gemsec-75/
        mkdir ~/git/datasets/${dataset_out}_gemsec-75/cao-format
        mkdir ~/git/datasets/${dataset_out}_gemsec-75/cao-format/ml1m
        mkdir ~/git/datasets/${dataset_out}_gemsec-75/cao-format/ml1m/kg
        mkdir ~/git/results/${dataset_out}_gemsec-75/
    fi

    ############################################################################
    ###                  Clusterize ${dataset_in} with gemsec                ###
    ############################################################################
    # Dependencies:
    #[~/git/datasets/${dataset_out}/kg.nt]

    if no_exist "$HOME/git/know-rec/docker/gemsec_data/temp/kg.csv"
    then
        echo '[kg-summ-rs] Creating ~/git/know-rec/docker/gemsec_data/temp/kg.csv'
        cd ../util
        #[activate jointrec]
        conda deactivate
        conda activate jointrec
        python kg2rdf.py --mode 'nt2edges' --input "$HOME/git/datasets/${dataset_in}/kg.nt" \
        --output "$HOME/git/know-rec/docker/gemsec_data/temp/kg.csv" \
        --output2 "$HOME/git/know-rec/docker/gemsec_data/temp/edge_map.csv"
        cd ../summarization
    fi
    local num_entities=($(wc -l "$HOME/git/datasets/${dataset_in}/cao-format/ml1m/kg/e_map.dat"))
    local rate25=$((${num_entities[0]}*25/100))
    local rate50=$((${num_entities[0]}*50/100))
    local rate75=$((${num_entities[0]}*75/100))
    if no_exist "$HOME/git/datasets/${dataset_out}_gemsec-25/assignment.json"
    then
        echo "[kg-summ-rs] Creating ~/git/datasets/${dataset_out}_gemsec-25/assignment.json"
        cd ../docker
        cp gemsec_Dockerfile Dockerfile
        docker build -t gemsec:1.0 .

        docker run --rm -it --gpus all -v "$PWD"/gemsec_data:/data -w /data \
        gemsec:1.0 /bin/bash -c "cd /notebooks/GEMSEC && python3 src/embedding_clustering.py \
        --input "/data/temp/kg.csv" --embedding-output "/data/temp/embedding.csv" \
        --cluster-mean-output "/data/temp/means.csv" --log-output "/data/temp/log.json" \
        --assignment-output "/data/temp/assignment.json" --dump-matrices True \
        --model "GEMSECWithRegularization" --P 1 --Q 1 --walker "first" \
        --dimensions 16 --random-walk-length 80 --num-of-walks 5 --window-size 5 \
        --distortion 0.75 --negative-sample-number 10 --initial-learning-rate ${learning_rate_init} \
        --minimal-learning-rate ${learning_rate_min} --annealing-factor 1 --initial-gamma 0.1 \
        --final-gamma 0.5 --lambd 0.0625 --cluster-number ${rate25} --overlap-weighting \
        "normalized_overlap" --regularization-noise 1e-8"

        cp "$HOME/git/know-rec/docker/gemsec_data/temp/assignment.json" "$HOME/git/datasets/${dataset_out}_gemsec-25/assignment.json"
        cd ../summarization
    fi
    if no_exist "$HOME/git/datasets/${dataset_out}_gemsec-50/assignment.json"
    then
        echo "[kg-summ-rs] Creating ~/git/datasets/${dataset_out}_gemsec-50/assignment.json"
        cd ../docker
        cp gemsec_Dockerfile Dockerfile
        docker build -t gemsec:1.0 .

        docker run --rm -it --gpus all -v "$PWD"/gemsec_data:/data -w /data \
        gemsec:1.0 /bin/bash -c "cd /notebooks/GEMSEC && python3 src/embedding_clustering.py \
        --input "/data/temp/kg.csv" --embedding-output "/data/temp/embedding.csv" \
        --cluster-mean-output "/data/temp/means.csv" --log-output "/data/temp/log.json" \
        --assignment-output "/data/temp/assignment.json" --dump-matrices True \
        --model "GEMSECWithRegularization" --P 1 --Q 1 --walker "first" \
        --dimensions 16 --random-walk-length 80 --num-of-walks 5 --window-size 5 \
        --distortion 0.75 --negative-sample-number 10 --initial-learning-rate ${learning_rate_init} \
        --minimal-learning-rate ${learning_rate_min} --annealing-factor 1 --initial-gamma 0.1 \
        --final-gamma 0.5 --lambd 0.0625 --cluster-number ${rate50} --overlap-weighting \
        "normalized_overlap" --regularization-noise 1e-8"

        cp "$HOME/git/know-rec/docker/gemsec_data/temp/assignment.json" "$HOME/git/datasets/${dataset_out}_gemsec-50/assignment.json"
        cd ../summarization
    fi
    if no_exist "$HOME/git/datasets/${dataset_out}_gemsec-75/assignment.json"
    then
        echo "[kg-summ-rs] Creating ~/git/datasets/${dataset_out}_gemsec-75/assignment.json"
        cd ../docker
        cp gemsec_Dockerfile Dockerfile
        docker build -t gemsec:1.0 .

        docker run --rm -it --gpus all -v "$PWD"/gemsec_data:/data -w /data \
        gemsec:1.0 /bin/bash -c "cd /notebooks/GEMSEC && python3 src/embedding_clustering.py \
        --input "/data/temp/kg.csv" --embedding-output "/data/temp/embedding.csv" \
        --cluster-mean-output "/data/temp/means.csv" --log-output "/data/temp/log.json" \
        --assignment-output "/data/temp/assignment.json" --dump-matrices True \
        --model "GEMSECWithRegularization" --P 1 --Q 1 --walker "first" \
        --dimensions 16 --random-walk-length 80 --num-of-walks 5 --window-size 5 \
        --distortion 0.75 --negative-sample-number 10 --initial-learning-rate ${learning_rate_init} \
        --minimal-learning-rate ${learning_rate_min} --annealing-factor 1 --initial-gamma 0.1 \
        --final-gamma 0.5 --lambd 0.0625 --cluster-number ${rate75} --overlap-weighting \
        "normalized_overlap" --regularization-noise 1e-8"

        cp "$HOME/git/know-rec/docker/gemsec_data/temp/assignment.json" "$HOME/git/datasets/${dataset_out}_gemsec-75/assignment.json"
        cd ../summarization
    fi

    ############################################################################
    ###                Summarize ${dataset_out} with gemsec                  ###
    ############################################################################
    #[activate jointrec]
    conda deactivate
    conda activate jointrec

    if no_exist "$HOME/git/datasets/${dataset_out}_gemsec/kg.nt"
    then
        echo "[kg-summ-rs] Creating ~/git/datasets/${dataset_out}_gemsec-25/kg.nt"
        cd ../util
        python kg2rdf.py --mode 'assignment2cluster' --input "$HOME/git/datasets/${dataset_out}_gemsec-25/assignment.json" \
        --input2 "$HOME/git/know-rec/docker/gemsec_data/temp/edge_map.csv" --output "$HOME/git/datasets/${dataset_out}_gemsec-25/cluster.tsv"
        python kg2rdf.py --mode 'cluster' --input2 "$HOME/git/datasets/${dataset_out}_gemsec-25/cluster.tsv" \
        --input "$HOME/git/datasets/${dataset_in}/kg.nt"  --output "$HOME/git/datasets/${dataset_out}_gemsec-25/kg.nt"
        cd ../summarization
    fi
    if no_exist "$HOME/git/datasets/${dataset_out}_gemsec-50/kg.nt"
    then
        echo "[kg-summ-rs] Creating ~/git/datasets/${dataset_out}_gemsec-50/kg.nt"
        cd ../util
        python kg2rdf.py --mode 'assignment2cluster' --input "$HOME/git/datasets/${dataset_out}_gemsec-50/assignment.json" \
        --input2 "$HOME/git/know-rec/docker/gemsec_data/temp/edge_map.csv" --output "$HOME/git/datasets/${dataset_out}_gemsec-50/cluster.tsv"
        python kg2rdf.py --mode 'cluster' --input2 "$HOME/git/datasets/${dataset_out}_gemsec-50/cluster.tsv" \
        --input "$HOME/git/datasets/${dataset_in}/kg.nt"  --output "$HOME/git/datasets/${dataset_out}_gemsec-50/kg.nt"
        cd ../summarization
    fi
    if no_exist "$HOME/git/datasets/${dataset_out}_gemsec/kg.nt"
    then
        echo "[kg-summ-rs] Creating ~/git/datasets/${dataset_out}_gemsec/kg.nt"
        cd ../util
        python kg2rdf.py --mode 'assignment2cluster' --input "$HOME/git/datasets/${dataset_out}_gemsec-75/assignment.json" \
        --input2 "$HOME/git/know-rec/docker/gemsec_data/temp/edge_map.csv" --output "$HOME/git/datasets/${dataset_out}_gemsec-75/cluster.tsv"
        python kg2rdf.py --mode 'cluster' --input2 "$HOME/git/datasets/${dataset_out}_gemsec-75/cluster.tsv" \
        --input "$HOME/git/datasets/${dataset_in}/kg.nt"  --output "$HOME/git/datasets/${dataset_out}_gemsec-75/kg.nt"
        cd ../summarization
    fi
}

gemsec "ml-sun_ho_originalKG" "ml-sun_ho_sv_sKG" "GEMSECWithRegularization" 0.001 0.0001
