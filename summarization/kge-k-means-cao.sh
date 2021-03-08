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
#   HOME, PWD, seed, verbose
# ARGUMENTS:
#   dataset_in: Input dataset, e.g., ml-sun_ho_originalKG, ml-cao_ho_fKG
#   dataset_out: Output dataset name, e.g., ml-sun_ho_sv_sKG, ml-cao_ho_mv_sfKG
#   kge: Translation model, e.g., complex, hole,
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
seed=0
verbose=false

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
    local ratios_list=${11}
    seed=${12}
    if [ "${13}" = 'true' ]; then verbose=true; else verbose=false; fi

    if [ ${summarization_mode} = 'sv' ]
    then
        IFS=',' read -r -a ratios <<< "${ratios_list}"
        for ratio in "${ratios[@]}"
        do
            sv_kge-k-means "${experiment}" "${dataset_in}" "${dataset_out}" "${kg_filename}" \
            "${kge}" "${epochs}" "${batch_size}" "${learning_rate}" "${low_frequence}" "${ratio}"
        done
    elif [ ${summarization_mode} = 'mv' ]
    then
        IFS=',' read -r -a ratios <<< "${ratios_list}"
        for ratio in "${ratios[@]}"
        do
            mv_kge-k-means "${experiment}" "${dataset_in}" "${dataset_out}" "${kg_filename}" \
            "${kge}" "${epochs}" "${batch_size}" "${learning_rate}" "${low_frequence}" "${ratio}"
        done
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
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}"; fi
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
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] Creating ~/git/kg-summ-rec/docker/kge-k-means_data/temp/${kg_filename}"; fi
        yes | cp -L ~/git/datasets/${experiment}/${dataset_in}/${kg_filename} ~/git/kg-summ-rec/docker/kge-k-means_data/temp/
    fi
    if no_exist "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/i2kg_map.tsv"
    then
        if [ "$verbose" = true ]; then echo '[kg-summ-rec] Creating ~/git/kg-summ-rec/docker/kge-k-means_data/temp/i2kg_map.tsv'; fi
        yes | cp -L ~/git/datasets/${experiment}/${dataset_in}/cao-format/ml1m/i2kg_map.tsv  ~/git/kg-summ-rec/docker/kge-k-means_data/temp/
    fi
    if no_exist "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/kg_map.dat"
    then
        if [ "$verbose" = true ]; then echo '[kg-summ-rec] Creating ~/git/kg-summ-rec/docker/kge-k-means_data/temp/kg_map.dat'; fi
        yes | cp -L ~/git/datasets/${experiment}/${dataset_in}/cao-format/ml1m/kg_map.dat  ~/git/kg-summ-rec/docker/kge-k-means_data/temp/
    fi
    if no_exist "$HOME/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/cluster${ratio}.tsv"
    then
        if no_exist "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/cluster${ratio}.tsv"
        then
            if [ "$verbose" = true ]; then echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/cluster${ratio}.tsv"; fi
            cd $HOME/git/kg-summ-rec/docker
            cp kge-k-means_Dockerfile Dockerfile
            docker build -t kge-k-means:1.0 .


            if [ "$verbose" = true ]
            then
                docker run --rm -it --gpus all -v "$PWD"/kge-k-means_data:/data -w /data \
                kge-k-means:1.0 /bin/bash -c "python kge-k-means.py --triples ${kg_filename} \
                --mode singleview --kge ${kge} --epochs ${epochs} --batch_size ${batch_size} \
                --learning_rate ${learning_rate} --rates ${ratio} --relations '<http://dbpedia.org/ontology/cinematography>,<http://dbpedia.org/property/productionCompanies>,<http://dbpedia.org/property/composer>,<http://purl.org/dc/terms/subject>,<http://dbpedia.org/ontology/openingFilm>,<http://www.w3.org/2000/01/rdf-schema#seeAlso>,<http://dbpedia.org/property/story>,<http://dbpedia.org/ontology/series>,<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>,<http://dbpedia.org/ontology/basedOn>,<http://dbpedia.org/ontology/starring>,<http://dbpedia.org/ontology/country>,<http://dbpedia.org/ontology/wikiPageWikiLink>,<http://purl.org/linguistics/gold/hypernym>,<http://dbpedia.org/ontology/editing>,<http://dbpedia.org/property/producers>,<http://dbpedia.org/property/allWriting>,<http://dbpedia.org/property/notableWork>,<http://dbpedia.org/ontology/director>,<http://dbpedia.org/ontology/award>' \
                --seed ${seed} --verbose"
            else
                docker run --rm -it --gpus all -v "$PWD"/kge-k-means_data:/data -w /data \
                kge-k-means:1.0 /bin/bash -c "python kge-k-means.py --triples ${kg_filename} \
                --mode singleview --kge ${kge} --epochs ${epochs} --batch_size ${batch_size} \
                --learning_rate ${learning_rate} --rates ${ratio} --relations '<http://dbpedia.org/ontology/cinematography>,<http://dbpedia.org/property/productionCompanies>,<http://dbpedia.org/property/composer>,<http://purl.org/dc/terms/subject>,<http://dbpedia.org/ontology/openingFilm>,<http://www.w3.org/2000/01/rdf-schema#seeAlso>,<http://dbpedia.org/property/story>,<http://dbpedia.org/ontology/series>,<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>,<http://dbpedia.org/ontology/basedOn>,<http://dbpedia.org/ontology/starring>,<http://dbpedia.org/ontology/country>,<http://dbpedia.org/ontology/wikiPageWikiLink>,<http://purl.org/linguistics/gold/hypernym>,<http://dbpedia.org/ontology/editing>,<http://dbpedia.org/property/producers>,<http://dbpedia.org/property/allWriting>,<http://dbpedia.org/property/notableWork>,<http://dbpedia.org/ontology/director>,<http://dbpedia.org/ontology/award>' \
                --seed ${seed}"
            fi
        fi

        #cp "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/triples.pickle" "$HOME/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/triples.pickle"
        cp "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/ampligraph.model" "$HOME/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/ampligraph.model"
        cp "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/embeddings.tsv" "$HOME/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/embeddings.tsv"
        cp "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/cluster${ratio}.tsv" "$HOME/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/cluster${ratio}.tsv"
        cp "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/cluster${ratio}.png" "$HOME/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/cluster${ratio}.png"
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
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/kg-ig.nt"; fi
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
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}"; fi
        mkdir ~/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/
        mkdir ~/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/cao-format
        mkdir ~/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/cao-format/ml1m
        mkdir ~/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/cao-format/ml1m/kg
        mkdir ~/git/results/${experiment}/${dataset_out}-${kge}-${ratio}/
    fi
    ############################################################################
    ###          Clusterize ${dataset_out} with ${kge} - {ratio}          ###
    ############################################################################
    if no_exist "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/${kg_filename}"
    then
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] Creating ~/git/kg-summ-rec/docker/kge-k-means_data/temp/${kg_filename}"; fi
        yes | cp -L ~/git/datasets/${experiment}/${dataset_in}/${kg_filename} ~/git/kg-summ-rec/docker/kge-k-means_data/temp/
    fi
    if no_exist "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/i2kg_map.tsv"
    then
        if [ "$verbose" = true ]; then echo '[kg-summ-rec] Creating ~/git/kg-summ-rec/docker/kge-k-means_data/temp/i2kg_map.tsv'; fi
        yes | cp -L ~/git/datasets/${experiment}/${dataset_in}/cao-format/ml1m/i2kg_map.tsv  ~/git/kg-summ-rec/docker/kge-k-means_data/temp/
    fi
    if no_exist "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/kg_map.dat"
    then
        if [ "$verbose" = true ]; then echo '[kg-summ-rec] Creating ~/git/kg-summ-rec/docker/kge-k-means_data/temp/kg_map.dat'; fi
        yes | cp -L ~/git/datasets/${experiment}/${dataset_in}/cao-format/ml1m/kg_map.dat  ~/git/kg-summ-rec/docker/kge-k-means_data/temp/
    fi
    if no_exist "$HOME/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/cluster${ratio}.tsv"
    then
        if no_exist "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/cluster${ratio}.tsv"
        then
            if [ "$verbose" = true ]; then echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/cluster${ratio}.tsv"; fi
            cd $HOME/git/kg-summ-rec/docker
            cp kge-k-means_Dockerfile Dockerfile
            docker build -t kge-k-means:1.0 .

            if [ "$verbose" = true ]
            then
                docker run --rm -it --gpus all -v "$PWD"/kge-k-means_data:/data -w /data \
                kge-k-means:1.0 /bin/bash -c "python kge-k-means.py --triples ${kg_filename} \
                --mode multiview --relations '<http://dbpedia.org/ontology/cinematography>,<http://dbpedia.org/property/productionCompanies>,<http://dbpedia.org/property/composer>,<http://purl.org/dc/terms/subject>,<http://dbpedia.org/ontology/openingFilm>,<http://www.w3.org/2000/01/rdf-schema#seeAlso>,<http://dbpedia.org/property/story>,<http://dbpedia.org/ontology/series>,<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>,<http://dbpedia.org/ontology/basedOn>,<http://dbpedia.org/ontology/starring>,<http://dbpedia.org/ontology/country>,<http://dbpedia.org/ontology/wikiPageWikiLink>,<http://purl.org/linguistics/gold/hypernym>,<http://dbpedia.org/ontology/editing>,<http://dbpedia.org/property/producers>,<http://dbpedia.org/property/allWriting>,<http://dbpedia.org/property/notableWork>,<http://dbpedia.org/ontology/director>,<http://dbpedia.org/ontology/award>' \
                --kge ${kge} --epochs ${epochs} --batch_size ${batch_size} \
                --learning_rate ${learning_rate} --rates ${ratio} --seed ${seed} --verbose"
            else
                docker run --rm -it --gpus all -v "$PWD"/kge-k-means_data:/data -w /data \
                kge-k-means:1.0 /bin/bash -c "python kge-k-means.py --triples ${kg_filename} \
                --mode multiview --relations '<http://dbpedia.org/ontology/cinematography>,<http://dbpedia.org/property/productionCompanies>,<http://dbpedia.org/property/composer>,<http://purl.org/dc/terms/subject>,<http://dbpedia.org/ontology/openingFilm>,<http://www.w3.org/2000/01/rdf-schema#seeAlso>,<http://dbpedia.org/property/story>,<http://dbpedia.org/ontology/series>,<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>,<http://dbpedia.org/ontology/basedOn>,<http://dbpedia.org/ontology/starring>,<http://dbpedia.org/ontology/country>,<http://dbpedia.org/ontology/wikiPageWikiLink>,<http://purl.org/linguistics/gold/hypernym>,<http://dbpedia.org/ontology/editing>,<http://dbpedia.org/property/producers>,<http://dbpedia.org/property/allWriting>,<http://dbpedia.org/property/notableWork>,<http://dbpedia.org/ontology/director>,<http://dbpedia.org/ontology/award>' \
                --kge ${kge} --epochs ${epochs} --batch_size ${batch_size} \
                --learning_rate ${learning_rate} --rates ${ratio} --seed ${seed}"
            fi
        fi

        #cp "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/triples.pickle" "$HOME/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/triples.pickle"
        cp "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/ampligraph.model" "$HOME/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/ampligraph.model"
        cp "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/embeddings.tsv" "$HOME/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/embeddings.tsv"
        cp "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/cluster${ratio}.tsv" "$HOME/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/cluster${ratio}.tsv"
        cp "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/cluster${ratio}.png" "$HOME/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/cluster${ratio}.png"
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
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/kg-ig.nt"; fi
        cd $HOME/git/kg-summ-rec/util
        python kg2rdf.py --mode 'mv_cluster' --input2 "$HOME/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/cluster${ratio}.tsv" \
        --input "$HOME/git/datasets/${experiment}/${dataset_in}/kg-ig.nt" --output "$HOME/git/datasets/${experiment}/${dataset_out}-${kge}-${ratio}/kg-ig.nt"
        cd $HOME/git/kg-summ-rec
    fi
}