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
        "${model}" "${learning_rate_init}" "${learning_rate_min}" "75"
        sv_gemsec "${experiment}" "${dataset_in}" "${dataset_out}" "${kg_filename}" \
        "${model}" "${learning_rate_init}" "${learning_rate_min}" "50"
        sv_gemsec "${experiment}" "${dataset_in}" "${dataset_out}" "${kg_filename}" \
        "${model}" "${learning_rate_init}" "${learning_rate_min}" "25"
    elif [ ${summarization_mode} = 'mv' ]
    then
        mv_gemsec "${experiment}" "${dataset_in}" "${dataset_out}" "${kg_filename}" \
        "${model}" "${learning_rate_init}" "${learning_rate_min}" "75"
        mv_gemsec "${experiment}" "${dataset_in}" "${dataset_out}" "${kg_filename}" \
        "${model}" "${learning_rate_init}" "${learning_rate_min}" "50"
        mv_gemsec "${experiment}" "${dataset_in}" "${dataset_out}" "${kg_filename}" \
        "${model}" "${learning_rate_init}" "${learning_rate_min}" "25"
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
    if no_exist "$HOME/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/cluster${ratio}.tsv"
    then
        echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/cluster${ratio}.tsv"

        # KG ntriples format to edges
        if [ -f "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/kg.csv" ]
        then
            echo '[kg-summ-rec] Deleting ~/git/kg-summ-rec/docker/gemsec_data/temp/kg.csv'
            yes | rm "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/kg.csv"
            yes | rm "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/edge_map.csv"
        fi
        echo '[kg-summ-rec] Creating ~/git/kg-summ-rec/docker/gemsec_data/temp/kg.csv'
        #[activate kg-summ-rec]
        conda deactivate
        conda activate kg-summ-rec
        cd $HOME/git/kg-summ-rec/util
        python kg2rdf.py --mode 'nt2edges' --input "$HOME/git/datasets/${experiment}/${dataset_in}/${kg_filename}" \
        --output "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/kg.csv" \
        --output2 "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/edge_map.csv"
        cd $HOME/git/kg-summ-rec/summarization

        # Define number of clusters based on ratio value
        #local num_nodes=($(wc -l "$HOME/git/datasets/${experiment}/${dataset_in}/cao-format/ml1m/kg/e_map.dat"))
        local num_nodes=($(tr '.' ' ' < "$HOME/git/datasets/${experiment}/${dataset_in}/${kg_filename}" | tr -s ' ' '\n' | awk '!a[$0]++{c++} END{print c}' | awk -v c=2 '{print $0-c}'))
        local num_user_nodes=($(wc -l "$HOME/git/datasets/${experiment}/${dataset_in}/cao-format/ml1m/u_map.dat" | awk -v c=1 '{print $0-c}'))
        local num_entities=${num_nodes[0]}
        if [ ${kg_filename} = 'kg-uig.nt' ]
        then
            num_entities=$((num_nodes[0] + num_user_nodes[0]))
        fi
        if [ ${kg_filename} = 'kg-euig.nt' ]
        then
            local num_superclasses=($(wc -l "$HOME/git/kg-summ-rec/util/mo/mo-genre-t-box.nt" | awk -v c=2 '{print $0-c}'))
            num_entities=$((num_nodes[0] + num_user_nodes[0] + num_superclasses[0]))
        fi
        local cluster_number=$((num_entities * ratio / 100))
        local edges=($(wc -l "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/edge_map.csv"))
        echo "[kg-summ-rec] mv_gemsec: Number of clusters is ${cluster_number}, nodes is ${num_entities}  and edges is ${edges}, ."

        # GEMSEC
        if [ -f "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/assignment.json" ]
        then
            echo '[kg-summ-rec] Deleting ~/git/kg-summ-rec/docker/gemsec_data/temp/assignment.json'
            yes | rm "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/assignment.json"
        fi
        echo "[kg-summ-rec] Creating ~/git/kg-summ-rec/docker/gemsec_data/temp/assignment.json"
        cd $HOME/git/kg-summ-rec/docker
        cp gemsec_Dockerfile Dockerfile
        docker build -t gemsec:1.0 .

        docker run --rm -it --gpus all -v "$PWD"/gemsec_data:/data -w /data \
        gemsec:1.0 /bin/bash -c "cd /notebooks/GEMSEC && python3 src/embedding_clustering.py \
        --input '/data/temp/kg.csv' --embedding-output '/data/temp/embedding.csv' \
        --cluster-mean-output '/data/temp/means.csv' --log-output '/data/temp/log.json' \
        --assignment-output '/data/temp/assignment.json' --dump-matrices True \
        --model ${model} --P 1 --Q 1 --walker 'first' \
        --dimensions 16 --random-walk-length 80 --num-of-walks 5 --window-size 5 \
        --distortion 0.75 --negative-sample-number 10 --initial-learning-rate ${learning_rate_init} \
        --minimal-learning-rate ${learning_rate_min} --annealing-factor 1 --initial-gamma 0.1 \
        --final-gamma 0.5 --lambd 0.0625 --cluster-number ${cluster_number} --overlap-weighting \
        'normalized_overlap' --regularization-noise 1e-8"

        #[activate kg-summ-rec]
        conda deactivate
        conda activate kg-summ-rec
        cd $HOME/git/kg-summ-rec/util
        python kg2rdf.py --mode 'assignment2cluster' \
        --input "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/assignment.json" \
        --input2 "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/edge_map.csv" \
        --output "$HOME/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/cluster${ratio}.tsv"
        cd $HOME/git/kg-summ-rec
    fi

    ############################################################################
    ###                Summarize ${dataset_out} with gemsec                  ###
    ############################################################################

    if no_exist "$HOME/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/kg-ig.nt"
    then
        echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/kg-ig.nt"
        #[activate kg-summ-rec]
        conda deactivate
        conda activate kg-summ-rec
        cd $HOME/git/kg-summ-rec/util
        python kg2rdf.py --mode 'cluster' --input2 "$HOME/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/cluster${ratio}.tsv" \
        --input "$HOME/git/datasets/${experiment}/${dataset_in}/kg-ig.nt" --output "$HOME/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/kg-ig.nt"
        cd $HOME/git/kg-summ-rec
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
    # Split KG in views
    if no_exist "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/${kg_filename%.*}-0.nt"
    then
        # Copy KG file to gemsec_data
        if no_exist "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/${kg_filename}"
        then
            echo "[kg-summ-rec] mv_gemsec: Creating ~/git/kg-summ-rec/docker/gemsec_data/temp/${kg_filename}"
            cp ~/git/datasets/${experiment}/${dataset_in}/${kg_filename} ~/git/kg-summ-rec/docker/gemsec_data/temp/
        fi

        echo "[kg-summ-rec] mv_gemsec: Creating ~/git/kg-summ-rec/docker/gemsec_data/temp/${kg_filename%.*}-0.nt"

        # Define split mode
        local mode='relation'
        if [ ${kg_filename} = 'kg-euig.nt' ]
        then
            mode='sun_mo'
        fi

        #[activate kg-summ-rec]
        conda deactivate
        conda activate kg-summ-rec
        cd $HOME/git/kg-summ-rec/summarization
        python split_views.py --datahome '../docker/gemsec_data' --folder 'temp' \
        --input ${kg_filename} --mode ${mode} --output '../docker/gemsec_data/temp/' \
        --verbose
        cd $HOME/git/kg-summ-rec

        # Complete kg-uig
        if [ ${kg_filename} = 'kg-uig.nt' ]
        then
            cd $HOME/git/kg-summ-rec/docker/gemsec_data/temp
            cat kg-ig-0.nt > kg-uig-0.nt
            cat kg-ig-1.nt > kg-uig-1.nt
            cat kg-ig-2.nt > kg-uig-2.nt
            cat kg-ig-3.nt >> kg-uig-0.nt
            cat kg-ig-3.nt >> kg-uig-1.nt
            cat kg-ig-3.nt >> kg-uig-2.nt
            rm kg-ig-3.nt
            cd $HOME/git/kg-summ-rec
        fi

        # Clean (remove) kg_filename
        if [ -f "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/${kg_filename}" ]
        then
            cd $HOME/git/kg-summ-rec/docker/gemsec_data/temp
            rm ${kg_filename}
            cd $HOME/git/kg-summ-rec
        fi
    fi

    if no_exist "$HOME/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/cluster${ratio}.tsv"
    then
        echo "[kg-summ-rec] Clustering ~/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/cluster${ratio}.tsv"
        cd $HOME/git/kg-summ-rec/docker
        cp gemsec_Dockerfile Dockerfile
        docker build -t gemsec:1.0 .

        for i in $HOME/git/kg-summ-rec/docker/gemsec_data/temp/${kg_filename%.*}-*.nt
        do
            local basename=${i##*/}
            local prefix=${basename%.*}
            local viewnumber=$(echo "$prefix" | cut -d '-' -f 3)
            echo -e "Basename: ${basename};\tView number: ${viewnumber}\n"

            # KG ntriples format to edges
            if [ -f "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/kg.csv" ]
            then
                echo '[kg-summ-rec] Deleting ~/git/kg-summ-rec/docker/gemsec_data/temp/kg.csv'
                yes | rm "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/kg.csv"
                yes | rm "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/edge_map.csv"
                yes | rm "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/embedding.csv"
                yes | rm "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/log.json"
                yes | rm "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/means.csv"
            fi
            echo "[kg-summ-rec] Creating ~/git/kg-summ-rec/docker/gemsec_data/temp/kg.csv from ${i}"
            #[activate kg-summ-rec]
            conda deactivate
            conda activate kg-summ-rec
            cd $HOME/git/kg-summ-rec/util
            python kg2rdf.py --mode 'nt2edges' --input "${i}" \
            --output "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/kg.csv" \
            --output2 "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/edge_map.csv"
            cd $HOME/git/kg-summ-rec

            # Define number of clusters based on ratio value
            #local num_nodes=($(wc -l "$HOME/git/datasets/${experiment}/${dataset_in}/cao-format/ml1m/kg/e_map.dat"))
            local num_nodes=($(tr '.' ' ' < "${i}" | tr -s ' ' '\n' | awk '!a[$0]++{c++} END{print c}' | awk -v c=2 '{print $0-c}'))
            local num_user_nodes=($(wc -l "$HOME/git/datasets/${experiment}/${dataset_in}/cao-format/ml1m/u_map.dat" | awk -v c=1 '{print $0-c}'))
            local num_entities=${num_nodes[0]}
            if [ ${kg_filename} = 'kg-uig.nt' ]
            then
                num_entities=$((num_nodes[0] + num_user_nodes[0]))
            fi
            if [ ${kg_filename} = 'kg-euig.nt' ]
            then
                local num_superclasses=($(wc -l "$HOME/git/kg-summ-rec/util/mo/mo-genre-t-box.nt" | awk -v c=2 '{print $0-c}'))
                num_entities=$((num_nodes[0] + num_user_nodes[0] + num_superclasses[0]))
            fi
            local cluster_number=$((num_entities * ratio / 100))
            local edges=($(wc -l "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/edge_map.csv"))
            echo "[kg-summ-rec] mv_gemsec: Number of clusters is ${cluster_number}, nodes is ${num_entities}  and edges is ${edges}, ."

            # GEMSEC
            if [ -f "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/assignment.json" ]
            then
                echo '[kg-summ-rec] Deleting ~/git/kg-summ-rec/docker/gemsec_data/temp/assignment.json'
                yes | rm "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/assignment.json"
            fi
            echo "[kg-summ-rec] Creating ~/git/kg-summ-rec/docker/gemsec_data/temp/assignment.json"


            cd $HOME/git/kg-summ-rec/docker

            #ls $HOME/git/kg-summ-rec/docker/gemsec_data/temp/
            #docker run --rm -it --gpus all -v "$PWD"/gemsec_data:/data -w /data gemsec:1.0 /bin/bash -c "ls ./temp/"

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

            cd $HOME/git/kg-summ-rec

            #[activate kg-summ-rec]
            conda deactivate
            conda activate kg-summ-rec
            cd $HOME/git/kg-summ-rec/util
            python kg2rdf.py --mode 'assignment2cluster' \
            --input "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/assignment.json" \
            --input2 "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/edge_map.csv" \
            --output "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/cluster${ratio}-${viewnumber}.tsv"
            cd $HOME/git/kg-summ-rec
        done

        #[activate kg-summ-rec]
        conda deactivate
        conda activate kg-summ-rec
        cd $HOME/git/kg-summ-rec/summarization
        python join_views.py --datahome '../docker/gemsec_data' --folder 'temp' \
        --pattern "cluster${ratio}-*.tsv" --mode 'clusters' --output "../docker/gemsec_data/temp/cluster${ratio}.tsv" \
        --verbose

        mv "$HOME/git/kg-summ-rec/docker/gemsec_data/temp/cluster${ratio}.tsv" "$HOME/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/cluster${ratio}.tsv"
        cd $HOME/git/kg-summ-rec
    fi

    ############################################################################
    ###                Summarize ${dataset_out} with gemsec                  ###
    ############################################################################
    if no_exist "$HOME/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/kg-ig.nt"
    then
        echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/kg-ig.nt"
        #[activate kg-summ-rec]
        conda deactivate
        conda activate kg-summ-rec
        cd $HOME/git/kg-summ-rec/util
        python kg2rdf.py --mode 'mv_cluster' \
        --input2 "$HOME/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/cluster${ratio}.tsv" \
        --input "$HOME/git/datasets/${experiment}/${dataset_in}/kg-ig.nt" \
        --output "$HOME/git/datasets/${experiment}/${dataset_out}-gemsec-${ratio}/kg-ig.nt"
        cd $HOME/git/kg-summ-rec
    fi
}

#gemsec "Sacenti-JOURNAL2021" "ml-sun_ho_oKG" "ml-sun_ho_sKG_ig" "kg-ig.nt" "sv" "GEMSECWithRegularization" 0.001 0.0001
