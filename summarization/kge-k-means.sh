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
kge-k-means() {
    local experiment=$1
    local dataset_in=$2
    local dataset_out=$3
    local kg_filename=$4
    local summarization_mode=$5
    local kge=$6
    local epochs=$7
    local batch_size=$8
    local learning_rate=$9
    local low_frequence=${10}

    if [ ${summarization_mode} = 'sv' ]
    then
        sv_kge-k-means "${experiment}" "${dataset_in}" "${dataset_out}" "${kg_filename}" \
        "${kge}" "${epochs}" "${batch_size}" "${learning_rate}" "${low_frequence}" "25"
        sv_kge-k-means "${experiment}" "${dataset_in}" "${dataset_out}" "${kg_filename}" \
        "${kge}" "${epochs}" "${batch_size}" "${learning_rate}" "${low_frequence}" "50"
        sv_kge-k-means "${experiment}" "${dataset_in}" "${dataset_out}" "${kg_filename}" \
        "${kge}" "${epochs}" "${batch_size}" "${learning_rate}" "${low_frequence}" "75"
    elif [ ${summarization_mode} = 'mv' ]
    then
        mv_kge-k-means "${experiment}" "${dataset_in}" "${dataset_out}" "${kg_filename}" \
        "${kge}" "${epochs}" "${batch_size}" "${learning_rate}" "${low_frequence}" "25"
        mv_kge-k-means "${experiment}" "${dataset_in}" "${dataset_out}" "${kg_filename}" \
        "${kge}" "${epochs}" "${batch_size}" "${learning_rate}" "${low_frequence}" "50"
        mv_kge-k-means "${experiment}" "${dataset_in}" "${dataset_out}" "${kg_filename}" \
        "${kge}" "${epochs}" "${batch_size}" "${learning_rate}" "${low_frequence}" "75"
    else
        echo "[kg-summ-rec] kge-k-means: Parameter error: summarization mode ${summarization_mode} should be sv or mv."
    fi
}

sv_kge-k-means() {
    local experiment=$1
    local dataset_in=$2
    local dataset_out=$3
    local kg_filename=$4
    local kge=$5
    local epochs=$6
    local batch_size=$7
    local learning_rate=$8
    local low_frequence=$9
    local ratio=${10}

    ############################################################################
    ###                        Create dataset Folders                        ###
    ############################################################################
    if [ ! -d "$HOME/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}" ]
    then
        echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}"
        mkdir ~/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/
        mkdir ~/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/cao-format
        mkdir ~/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/cao-format/ml1m
        mkdir ~/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/cao-format/ml1m/kg
        mkdir ~/git/results/${experiment}/${dataset_out}-${kge}-${ratio}/
    fi

    ############################################################################
    ###          Clusterize ${dataset_out} with ${kge} - {ratio}          ###
    ############################################################################
    # Dependencies:
    #[~/git/datasets/${experiment}/${dataset_out}/${kg_filename}]

    if no_exist "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/${kg_filename}"
    then
        echo "[kg-summ-rec] Creating ~/git/kg-summ-rec/docker/kge-k-means_data/temp/${kg_filename}"
        yes | cp -L ~/git/datasets/${experiment}/${dataset_in}/${kg_filename} ~/git/kg-summ-rec/docker/kge-k-means_data/temp/
    fi
    if no_exist "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/i2kg_map.tsv"
    then
        echo '[kg-summ-rec] Creating ~/git/kg-summ-rec/docker/kge-k-means_data/temp/i2kg_map.tsv'
        yes | cp -L ~/git/datasets/${experiment}/${dataset_in}/cao-format/ml1m/i2kg_map.tsv  ~/git/kg-summ-rec/docker/kge-k-means_data/temp/
    fi
    if no_exist "$HOME/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/cluster${ratio}.tsv"
    then
        echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/cluster${ratio}.tsv"
        cd $HOME/git/kg-summ-rec/docker
        cp kge-k-means_Dockerfile Dockerfile
        docker build -t kge-k-means:1.0 .

        docker run --rm -it --gpus all -v "$PWD"/kge-k-means_data:/data -w /data \
        kge-k-means:1.0 /bin/bash -c "python kge-k-means.py --triples ${kg_filename} \
        --mode singleview --kge ${kge} --epochs ${epochs} --batch_size ${batch_size} \
        --learning_rate ${learning_rate} --rates ${ratio} --verbose"

        mv "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/cluster${ratio}.tsv" "$HOME/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/cluster${ratio}.tsv"
        cd $HOME/git/kg-summ-rec
    fi

    ############################################################################
    ###              Summarize ${dataset_out} with clusters                  ###
    ############################################################################
    #[activate kg-summ-rec]
    conda deactivate
    conda activate kg-summ-rec

    if no_exist "$HOME/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/kg-ig.nt"
    then
        echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/kg-ig.nt"
        cd $HOME/git/kg-summ-rec/util
        python kg2rdf.py --mode 'cluster' --input2 "$HOME/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/cluster${ratio}.tsv" \
        --input "$HOME/git/datasets/${experiment}/${dataset_in}/kg-ig.nt" --output "$HOME/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/kg-ig.nt"
        cd $HOME/git/kg-summ-rec
    fi
}

mv_kge-k-means() {
    local experiment=$1
    local dataset_in=$2
    local dataset_out=$3
    local kg_filename=$4
    local kge=$5
    local epochs=$6
    local batch_size=$7
    local learning_rate=$8
    local low_frequence=$9
    local ratio=${10}

    ############################################################################
    ###                        Create dataset Folders                        ###
    ############################################################################
    if [ ! -d "$HOME/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}" ]
    then
        echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}"
        mkdir ~/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/
        mkdir ~/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/cao-format
        mkdir ~/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/cao-format/ml1m
        mkdir ~/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/cao-format/ml1m/kg
        mkdir ~/git/results/${experiment}/${dataset_out}-${kge}-${ratio}/
    fi
    ############################################################################
    ###                              Split views                             ###
    ############################################################################
    if no_exist "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/${kg_filename}"
    then
        echo "[kg-summ-rec] Creating ~/git/kg-summ-rec/docker/kge-k-means_data/temp/${kg_filename}"
        yes | cp -L ~/git/datasets/${experiment}/${dataset_in}/${kg_filename} ~/git/kg-summ-rec/docker/kge-k-means_data/temp/
    fi

    local mode='relation'
    if [ ${kg_filename} = 'kg-euig.nt' ]
    then
        mode='sun_mo'
    fi

    if no_exist "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/${kg_filename%.*}-0.nt"
    then
        echo "[kg-summ-rec] kge-k-means: Creating ~/git/kg-summ-rec/docker/kge-k-means_data/temp/${kg_filename%.*}-0.nt ${kg_filename}"
        #[activate kg-summ-rec]
        conda deactivate
        conda activate kg-summ-rec
        cd $HOME/git/kg-summ-rec/summarization
        python split_views.py --datahome '../docker/kge-k-means_data' --folder 'temp' \
        --input ${kg_filename} --mode ${mode} --output '../docker/kge-k-means_data/temp/' \
        --verbose
        cd $HOME/git/kg-summ-rec
    fi
    
    if [ ${kg_filename} = 'kg-uig.nt' ]
    then
	cd $HOME/git/kg-summ-rec/docker/kge-k-means_data/temp
        cat kg-ig-0.nt > kg-uig-0.nt
        cat kg-ig-1.nt > kg-uig-1.nt
        cat kg-ig-2.nt > kg-uig-2.nt
	cat kg-ig-3.nt >> kg-uig-0.nt
	cat kg-ig-3.nt >> kg-uig-1.nt
	cat kg-ig-3.nt >> kg-uig-2.nt
	rm kg-ig-3.nt
        cd $HOME/git/kg-summ-rec
    fi

    if [ -f "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/${kg_filename}" ]
    then
        cd $HOME/git/kg-summ-rec/docker/kge-k-means_data/temp
        rm ${kg_filename}
        cd $HOME/git/kg-summ-rec
    fi
    ############################################################################
    ###          Clusterize ${dataset_out} with ${kge} - {ratio}          ###
    ############################################################################
    if no_exist "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/i2kg_map.tsv"
    then
        echo '[kg-summ-rec] Creating ~/git/kg-summ-rec/docker/kge-k-means_data/temp/i2kg_map.tsv'
        yes | cp -L ~/git/datasets/${experiment}/${dataset_in}/cao-format/ml1m/i2kg_map.tsv  ~/git/kg-summ-rec/docker/kge-k-means_data/temp/
    fi

    if no_exist "$HOME/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/cluster${ratio}.tsv"
    then
        echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/cluster${ratio}.tsv"
        cd $HOME/git/kg-summ-rec/docker
        cp kge-k-means_Dockerfile Dockerfile
        docker build -t kge-k-means:1.0 .

        for i in "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/${kg_filename%.*}-*.nt"
        do
            local basename=${i##*/}
            local prefix=${basename%.*}
            local viewnumber=$(echo "$prefix" | cut -d '-' -f 3)
            echo -e "Basename: ${basename};\tView number: ${viewnumber}\n"
            
            docker run --rm -it --gpus all -v "$PWD"/kge-k-means_data:/data -w /data \
            kge-k-means:1.0 /bin/bash -c "python kge-k-means.py --triples ${basename} \
            --mode splitview --kge ${kge} --epochs ${epochs} --batch_size ${batch_size} \
            --learning_rate ${learning_rate} --rates ${ratio} --view ${viewnumber} --verbose"
        done

        cd $HOME/git/kg-summ-rec/summarization
        #[activate kg-summ-rec]
        conda deactivate
        conda activate kg-summ-rec
        python join_views.py --datahome '../docker/kge-k-means_data' --folder 'temp' \
        --pattern "cluster${ratio}-*.tsv" --mode 'clusters' --output "../docker/kge-k-means_data/temp/cluster${ratio}.tsv" \
        --verbose

        mv "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/cluster${ratio}.tsv" "$HOME/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/cluster${ratio}.tsv"
        cd $HOME/git/kg-summ-rec
    fi

    ############################################################################
    ###              Summarize ${dataset_out} with clusters                  ###
    ############################################################################
    #[activate kg-summ-rec]
    conda deactivate
    conda activate kg-summ-rec

    if no_exist "$HOME/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/kg-ig.nt"
    then
        echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/kg-ig.nt"
        cd $HOME/git/kg-summ-rec/util
        python kg2rdf.py --mode 'mv_cluster' --input2 "$HOME/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/cluster${ratio}.tsv" \
        --input "$HOME/git/datasets/${experiment}/${dataset_in}/kg-ig.nt" --output "$HOME/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/kg-ig.nt"
        cd $HOME/git/kg-summ-rec
    fi
}
