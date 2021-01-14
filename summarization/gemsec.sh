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
source $HOME/git/kg-summ-rec/util/util.sh

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
    local experiment=$1
    local dataset_in=$2 # Default is "ml-sun_ho_oKG"
    local dataset_out=$3 # Default is "ml-sun_ho_ig_sKG"
    local kg_filename=$4
    local summarization_mode=$5
    local model=$6 # Default is "GEMSECWithRegularization"
    local learning_rate_init=$7 # Default is 0.001
    local learning_rate_min=$8 # Default is 0.0001

    if [ ${summarization_mode} = 'sv' ]
    then
        sv_gemsec "${experiment}" "${dataset_in}" "${dataset_out}" "${kg_filename}" \ 
        "${model}" "${learning_rate_init}" "${learning_rate_min}" "25"
        sv_gemsec "${experiment}" "${dataset_in}" "${dataset_out}" "${kg_filename}" \ 
        "${model}" "${learning_rate_init}" "${learning_rate_min}" "50"
        sv_gemsec "${experiment}" "${dataset_in}" "${dataset_out}" "${kg_filename}" \ 
        "${model}" "${learning_rate_init}" "${learning_rate_min}" "75"
    elif [ ${summarization_mode} = 'mv' ]
    then
        mv_gemsec "${experiment}" "${dataset_in}" "${dataset_out}" "${kg_filename}" \ 
        "${model}" "${learning_rate_init}" "${learning_rate_min}" "25"
        mv_gemsec "${experiment}" "${dataset_in}" "${dataset_out}" "${kg_filename}" \ 
        "${model}" "${learning_rate_init}" "${learning_rate_min}" "50"
        mv_gemsec "${experiment}" "${dataset_in}" "${dataset_out}" "${kg_filename}" \ 
        "${model}" "${learning_rate_init}" "${learning_rate_min}" "75"
    else
        echo "[kg-summ-rec] gemsec: Parameter error: summarization mode ${summarization_mode} should be sv or mv."
    fi
}

sv_gemsec() {
    local experiment=$1
    local dataset_in=$2 # Default is "ml-sun_ho_oKG"
    local dataset_out=$3 # Default is "ml-sun_ho_ig_sKG"
    local kg_filename=$4
    local model=$5 # Default is "GEMSECWithRegularization"
    local learning_rate_init=$6 # Default is 0.001
    local learning_rate_min=$7 # Default is 0.0001
    local ratio=$8

    ############################################################################
    ###                        Create dataset Folders                        ###
    ############################################################################
    if [ ! -d "$HOME/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}" ]
    then
        echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}"
        mkdir ~/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/
        mkdir ~/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/cao-format
        mkdir ~/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/cao-format/ml1m
        mkdir ~/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/cao-format/ml1m/kg
        mkdir ~/git/results/${experiment}/${dataset_out}-gemsec-${ratio}/
    fi

    ############################################################################
    ###                  Clusterize ${dataset_in} with gemsec                ###
    ############################################################################
    # Dependencies:
    #[~/git/datasets/${experiment}/${dataset_out}/${kg_filename}]
    if no_exist "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/kg.csv"
    then
        echo '[kg-summ-rec] Creating ~/git/kg-summ-rec/docker/gemsec_data/temp/kg.csv'
        cd $HOME/git/kg-summ-rec/util
        #[activate kg-summ-rec]
        conda deactivate
        conda activate kg-summ-rec
        python kg2rdf.py --mode 'nt2edges' --input "$HOME/git/datasets/${experiment}/${dataset_in}/${kg_filename}" \
        --output "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/kg.csv" \
        --output2 "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/edge_map.csv"
        cd $HOME/git/kg-summ-rec/summarization
    fi
    
    local num_entities=($(wc -l "$HOME/git/datasets/${experiment}/${dataset_in}/cao-format/ml1m/kg/e_map.dat"))
    local cluster_number=$((${num_entities[0]}*${ratio}/100))
    
    if no_exist "$HOME/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/assignment.json"
    then
        echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/assignment.json"
        cd $HOME/git/kg-summ-rec/docker
        cp gemsec_Dockerfile Dockerfile
        docker build -t gemsec:1.0 .

        docker run --rm -it --gpus all -v "$PWD"/gemsec_data:/data -w /data \
        gemsec:1.0 /bin/bash -c "cd /notebooks/GEMSEC && python3 src/embedding_clustering.py \
        --input '/data/temp/kg.csv' --embedding-output '/data/temp/embedding.csv' \
        --cluster-mean-output '/data/temp/means.csv' --log-output '/data/temp/log.json' \
        --assignment-output '/data/temp/assignment.json' --dump-matrices True \
        --model 'GEMSECWithRegularization' --P 1 --Q 1 --walker 'first' \
        --dimensions 16 --random-walk-length 80 --num-of-walks 5 --window-size 5 \
        --distortion 0.75 --negative-sample-number 10 --initial-learning-rate ${learning_rate_init} \
        --minimal-learning-rate ${learning_rate_min} --annealing-factor 1 --initial-gamma 0.1 \
        --final-gamma 0.5 --lambd 0.0625 --cluster-number ${cluster_number} --overlap-weighting \
        'normalized_overlap' --regularization-noise 1e-8"

        cp "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/assignment.json" "$HOME/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/assignment.json"
        cd $HOME/git/kg-summ-rec/summarization
    fi
    ############################################################################
    ###                Summarize ${dataset_out} with gemsec                  ###
    ############################################################################
    #[activate kg-summ-rec]
    conda deactivate
    conda activate kg-summ-rec

    if no_exist "$HOME/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/kg-ig.nt"
    then
        echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/kg-ig.nt"
        cd $HOME/git/kg-summ-rec/util
        python kg2rdf.py --mode 'assignment2cluster' --input "$HOME/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/assignment.json" \
        --input2 "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/edge_map.csv" --output "$HOME/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/cluster.tsv"
        python kg2rdf.py --mode 'cluster' --input2 "$HOME/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/cluster.tsv" \
        --input "$HOME/git/datasets/${experiment}/${dataset_in}/kg-ig.nt" --output "$HOME/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/kg-ig.nt"
        cd $HOME/git/kg-summ-rec/summarization
    fi
}

mv_gemsec() {
    local experiment=$1
    local dataset_in=$2 # Default is "ml-sun_ho_oKG"
    local dataset_out=$3 # Default is "ml-sun_ho_ig_sKG"
    local kg_filename=$4
    local model=$5 # Default is "GEMSECWithRegularization"
    local learning_rate_init=$6 # Default is 0.001
    local learning_rate_min=$7 # Default is 0.0001
    local ratio=$8

    ############################################################################
    ###                        Create dataset Folders                        ###
    ############################################################################
    if [ ! -d "$HOME/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}" ]
    then
        echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}"
        mkdir ~/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/
        mkdir ~/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/cao-format
        mkdir ~/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/cao-format/ml1m
        mkdir ~/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/cao-format/ml1m/kg
        mkdir ~/git/results/${experiment}/${dataset_out}-gemsec-${ratio}/
    fi

    ############################################################################
    ###                  Clusterize ${dataset_in} with gemsec                ###
    ############################################################################
    if no_exist "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/kg-ig-0.nt"
    then
        echo '[kg-summ-rec] gemsec: Creating ~/git/kg-summ-rec/docker/gemsec_data/temp/kg-ig-0.nt'
        #[activate kg-summ-rec]
        conda deactivate
        conda activate kg-summ-rec
        python split_views.py --datahome '../docker/gemsec_data' --folder 'temp' \
        --input 'kg-ig.nt' --mode 'relation' --output '../docker/gemsec_data/temp/' \
        --verbose
        cd $HOME/git/kg-summ-rec/summarization
    fi

    for i in "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/kg-ig-*.nt"
    do
        if [ ${kg_filename} = 'kg-uig.nt' ]
        then
        
        fi
        if no_exist "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/kg.csv"
        then
            echo '[kg-summ-rec] Creating ~/git/kg-summ-rec/docker/gemsec_data/temp/kg.csv'
            cd $HOME/git/kg-summ-rec/util
            #[activate kg-summ-rec]
            conda deactivate
            conda activate kg-summ-rec
            python kg2rdf.py --mode 'nt2edges' --input "$HOME/git/datasets/${experiment}/${dataset_in}/${kg_filename}" \
            --output "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/kg.csv" \
            --output2 "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/edge_map.csv"
            cd $HOME/git/kg-summ-rec/summarization
        fi

        local num_entities=($(wc -l "$HOME/git/datasets/${experiment}/${dataset_in}/cao-format/ml1m/kg/e_map.dat"))
        local cluster_number=$((${num_entities[0]}*${ratio}/100))

        if no_exist "$HOME/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/assignment.json"
        then
            echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/assignment.json"
            cd $HOME/git/kg-summ-rec/docker
            cp gemsec_Dockerfile Dockerfile
            docker build -t gemsec:1.0 .

            docker run --rm -it --gpus all -v "$PWD"/gemsec_data:/data -w /data \
            gemsec:1.0 /bin/bash -c "cd /notebooks/GEMSEC && python3 src/embedding_clustering.py \
            --input '/data/temp/kg.csv' --embedding-output '/data/temp/embedding.csv' \
            --cluster-mean-output '/data/temp/means.csv' --log-output '/data/temp/log.json' \
            --assignment-output '/data/temp/assignment.json' --dump-matrices True \
            --model 'GEMSECWithRegularization' --P 1 --Q 1 --walker 'first' \
            --dimensions 16 --random-walk-length 80 --num-of-walks 5 --window-size 5 \
            --distortion 0.75 --negative-sample-number 10 --initial-learning-rate ${learning_rate_init} \
            --minimal-learning-rate ${learning_rate_min} --annealing-factor 1 --initial-gamma 0.1 \
            --final-gamma 0.5 --lambd 0.0625 --cluster-number ${cluster_number} --overlap-weighting \
            'normalized_overlap' --regularization-noise 1e-8"

            cp "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/assignment.json" "$HOME/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/assignment.json"
            cd $HOME/git/kg-summ-rec/summarization
        fi
    done



    ############################################################################
    ###                Summarize ${dataset_out} with gemsec                  ###
    ############################################################################
    #[activate kg-summ-rec]
    conda deactivate
    conda activate kg-summ-rec

    if no_exist "$HOME/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/kg-ig.nt"
    then
        echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/kg-ig.nt"
        cd $HOME/git/kg-summ-rec/util
        python kg2rdf.py --mode 'assignment2cluster' --input "$HOME/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/assignment.json" \
        --input2 "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/edge_map.csv" --output "$HOME/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/cluster.tsv"
        python kg2rdf.py --mode 'cluster' --input2 "$HOME/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/cluster.tsv" \
        --input "$HOME/git/datasets/${experiment}/${dataset_in}/kg-ig.nt" --output "$HOME/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/kg-ig.nt"
        cd $HOME/git/kg-summ-rec/summarization
    fi
}

#gemsec "Sacenti-JOURNAL2021" "ml-sun_ho_oKG" "ml-sun_ho_sKG_ig" "kg-ig.nt" "sv" "GEMSECWithRegularization" 0.001 0.0001
