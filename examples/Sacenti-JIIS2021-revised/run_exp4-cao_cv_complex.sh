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
# Run experiment Cao's item-graph cross-validation for JIIS2021.
# - Datasets: ml-cao
# - Split: cross-validation (cv)
# - Filtering: infrequent entities filtering at 0 (sKG) and at 10 (sfKG)
# - KG Summarization:
#   - Algorithms: KGE-K-Means (ComplEx)
#   - KG type: item-graph (ig)
#   - Summarization mode: single-view (sv) and multi-view (mv)
#   - Summarization ratio: 25, 50 and 75%
#   - Results: summ_effects, overall_comp_cost
# - KG Recommendation:
#   - Algorithms: CFKG, CKE, CoFM, JtransUp (KTUP); TransE, TransH, BPRMF,
#   TransUp (TUP)
#   - Results:  summ_impacts, rec_effectiveness, rec_efficiency
# GLOBALS:
#   HOME
#   experiment: running experiment. Default is 'JIIS2021-revised-exp4'.
# FUNCTIONS:
#   preprocess_cao_oKG
#   preprocess_cao_fKG
#   summarize_cao_sKG
#   summarize_cao_sfKG
#   recommend_cao_sKG
#   recommend_cao_sfKG
#   run_experiments
#######################################
experiment='JIIS-revised-exp4'
seed=0
verbose=false
overall_comp_cost="$HOME/git/results/${experiment}/overall_efficiency.tsv"

#######################################
# Import util/util.sh
# FUNCTIONS:
#   no_exist 'path_to_file'
#   no_exist_dir 'path_to_dir'
#   copy_ml_sun 'path_to_dataset' 'path_to_new_dataset'
#   copy_ml_cao 'path_to_dataset' 'path_to_new_dataset'
#######################################
source $HOME/git/kg-summ-rec/util/util.sh

#######################################
# Import preprocess/cao-format_ml-cao.sh
# FUNCTIONS:
#   cao-format_ml-cao 'dataset' 'low_frequence'
#######################################
source $HOME/git/kg-summ-rec/preprocess/cao-format_ml-cao.sh

#######################################
# Import ../summarization/kge-k-means.sh
# FUNCTIONS:
#   kge-k-means 'experiment' 'dataset_in' 'dataset_out' 'kg_type' 'summarization_mode' 'kge' 'epochs' 'batch_size' learning_rate' 'low_frequence'
#######################################
source $HOME/git/kg-summ-rec/summarization/kge-k-means-ratio.sh

#######################################
# Import ../summarization/cao-format_summ.sh
# FUNCTIONS:
#   cao-format_summ
#######################################
source $HOME/git/kg-summ-rec/preprocess/cao-format_summ.sh

#######################################
# Import ../util/clean_kge-k-means.sh
# FUNCTIONS:
#   clean_kge-k-means
#######################################
source $HOME/git/kg-summ-rec/util/clean_kge-k-means.sh

#######################################
# Import ../util/comp_cost.sh
# FUNCTIONS:
#   comp_cost 'experiment' 'dataset_in'
#   elipsed_time 'sec1' 'sec2'
#   log_duration 'file_in'
#######################################
source $HOME/git/kg-summ-rec/util/comp_cost.sh

####
# KG preprocessing
#
# - Datasets: ml-cao
# - Split: cross-validation (cv)
# - Filtering: infrequent entities filtering at 0 (oKG) and at 10 (fKG)
####
preprocess_cao_oKG() {
    if [ ! -d "$HOME/git/datasets/${experiment}/fold0/ml-cao_cv_oKG" ]
    then
        local STARTTIME=$(date +%s)
        # Create folders for Cao's original KG (oKG)
        if no_exist "$HOME/git/datasets/${experiment}/ml-cao"
        then
            if [ "$verbose" = true ]; then echo "[kg-summ-rec] preprocess_cao_oKG: Creating ~/git/datasets/${experiment}/ml-cao"; fi
            cd $HOME/git/kg-summ-rec/util
            copy_ml_cao "$HOME/git/datasets/ml-cao" "$HOME/git/datasets/${experiment}/ml-cao"
            cd $HOME/git/kg-summ-rec
        fi

        # Preprocess oKG
        cd $HOME/git/kg-summ-rec/preprocess
        LOW_FREQUENCE=0    #Low Frequence Filtering (0, 10)
        if [ "$verbose" = true ]
        then
            cao-format_ml-cao "ml-cao_cv_oKG" ${LOW_FREQUENCE} 'cv' ${seed} 'true'
        else
            cao-format_ml-cao "ml-cao_cv_oKG" ${LOW_FREQUENCE} 'cv' ${seed} 'false'
        fi
        cd $HOME/git/kg-summ-rec

        folds=(0 1 2 3 4)
        for fold_number in "${folds[@]}"
        do
            if no_exist "$HOME/git/results/${experiment}/fold${fold_number}"
            then
                if [ "$verbose" = true ]; then echo "[kg-summ-rec] preprocess_cao_oKG: Creating ~/git/results/${experiment}/fold${fold_number}"; fi
                mkdir ~/git/results/${experiment}/fold${fold_number}
            fi
            if no_exist "$HOME/git/results/${experiment}/fold${fold_number}/ml-cao_cv_oKG"
            then
                if [ "$verbose" = true ]; then echo "[kg-summ-rec] preprocess_cao_oKG: Creating ~/git/results/${experiment}/fold${fold_number}/ml-cao_cv_oKG"; fi
                mkdir ~/git/results/${experiment}/fold${fold_number}/ml-cao_cv_oKG
            fi
            # Collect ml-cao_cv_oKG statistics
            if no_exist "$HOME/git/results/${experiment}/fold0/ml-cao_cv_oKG/kg-ig_stats.tsv"
            then
                if [ "$verbose" = true ]; then echo "[kg-summ-rec] preprocess_cao_oKG: Creating ~/git/results/${experiment}/fold${fold_number}/ml-cao_cv_oKG/kg-ig_stats.tsv"; fi
                cd $HOME/git/kg-summ-rec/util
                conda deactivate
                conda activate kg-summ-rec
                python kg2rdf.py --mode 'statistics' --kgpath "~/git/datasets/${experiment}/fold${fold_number}/ml-cao_cv_oKG" \
                --input "~/git/datasets/${experiment}/fold${fold_number}/ml-cao_cv_oKG/kg-ig.nt" \
                --output "~/git/results/${experiment}/fold${fold_number}/ml-cao_cv_oKG/kg-ig_stats.tsv"
                cd $HOME/git/kg-summ-rec
            fi
        done

        local ENDTIME=$(date +%s)
        echo -e "preprocess_cao_oKG\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi
}

preprocess_cao_fKG() {
    if [ ! -d "$HOME/git/datasets/${experiment}/fold0/ml-cao_cv_fKG" ]
    then
        local STARTTIME=$(date +%s)

        # Create folders for Cao's filtered KG (fKG)
        if no_exist "$HOME/git/datasets/${experiment}/ml-cao"
        then
            if [ "$verbose" = true ]; then echo "[kg-summ-rec] preprocess_cao_fKG: Creating ~/git/datasets/${experiment}/ml-cao"; fi
            cd $HOME/git/kg-summ-rec/util
            copy_ml_cao "$HOME/git/datasets/ml-cao" "$HOME/git/datasets/${experiment}/ml-cao"
            cd $HOME/git/kg-summ-rec
        fi

        # Preprocess fKG
        cd $HOME/git/kg-summ-rec/preprocess
        LOW_FREQUENCE=10    #Low Frequence Filtering (0, 10)
        if [ "$verbose" = true ]
        then
            cao-format_ml-cao "ml-cao_cv_fKG" ${LOW_FREQUENCE} 'cv' ${seed} 'true'
        else
            cao-format_ml-cao "ml-cao_cv_fKG" ${LOW_FREQUENCE} 'cv' ${seed} 'false'
        fi
        cd $HOME/git/kg-summ-rec

        folds=(0 1 2 3 4)
        for fold_number in "${folds[@]}"
        do
            if no_exist "$HOME/git/results/${experiment}/fold${fold_number}"
            then
                if [ "$verbose" = true ]; then echo "[kg-summ-rec] preprocess_cao_fKG: Creating ~/git/results/${experiment}/fold${fold_number}"; fi
                mkdir ~/git/results/${experiment}/fold${fold_number}
            fi
            if no_exist "$HOME/git/results/${experiment}/fold${fold_number}/ml-cao_cv_fKG"
            then
                if [ "$verbose" = true ]; then echo "[kg-summ-rec] preprocess_cao_fKG: Creating ~/git/results/${experiment}/fold${fold_number}/ml-cao_cv_fKG"; fi
                mkdir ~/git/results/${experiment}/fold${fold_number}/ml-cao_cv_fKG
            fi
            # Collect ml-cao_cv_oKG statistics
            if no_exist "$HOME/git/results/${experiment}/fold0/ml-cao_cv_fKG/kg-ig_stats.tsv"
            then
                if [ "$verbose" = true ]; then echo "[kg-summ-rec] preprocess_cao_fKG: Creating ~/git/results/${experiment}/fold${fold_number}/ml-cao_cv_fKG/kg-ig_stats.tsv"; fi
                cd $HOME/git/kg-summ-rec/util
                conda deactivate
                conda activate kg-summ-rec
                python kg2rdf.py --mode 'statistics' --kgpath "~/git/datasets/${experiment}/fold${fold_number}/ml-cao_cv_fKG" \
                --input "~/git/datasets/${experiment}/fold${fold_number}/ml-cao_cv_fKG/kg-ig.nt" \
                --output "~/git/results/${experiment}/fold${fold_number}/ml-cao_cv_fKG/kg-ig_stats.tsv"
                cd $HOME/git/kg-summ-rec
            fi
        done

        local ENDTIME=$(date +%s)
        echo -e "preprocess_cao_fKG\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi
}

####
# KG summarization
#
# - Datasets: ml-cao
# - Split: cross-validation (cv)
# - Filtering: infrequent entities filtering at 0 (sKG) and at 10 (sfKG)
####
summarize_cao_sKG() {
    # KG summarization
    kg_summarization 'ml-cao' 'cv' 'sKG'
}

summarize_cao_sfKG() {
    # KG summarization
    kg_summarization 'ml-cao' 'cv' 'sfKG'
}

kg_summarization() {
    local dataset=$1 # Input dataset: ml-cao
    local split_mode=$2 # Split mode: cross-validation (cv)
    local filtering=$3 # Filtering: infrequent entities filtering at 0 (sKG) and at 10 (sfKG)

    local dataset_in="${dataset}_${split_mode}_oKG"
    local dataset_out="${dataset}_${split_mode}_${filtering}"

    local low_frequence=0
    if [ "${filtering}" = "sfKG" ]
    then
        low_frequence=10
    fi

    local kg_type='ig'

    summarize ${dataset_in} ${dataset_out} ${kg_type} ${low_frequence}
    preprocess_summ ${dataset_in} ${dataset_out} ${kg_type} ${low_frequence}
    measure_summ_impact ${dataset_in} ${dataset_out} ${kg_type} ${low_frequence}
}

summarize() {
    local dataset_in=$1
    local dataset_out=$2
    local kg_type=$3
    local low_frequence=$4

    # default parameters
    local kge='complex'
    local epochs='100'
    #epochs='2'
    local batch_size='100'
    local learning_rate='0.005'
    local kg_filename="kg-${kg_type}.nt"
    local relations='<http://dbpedia.org/ontology/cinematography>,<http://dbpedia.org/property/productionCompanies>,<http://dbpedia.org/property/composer>,<http://purl.org/dc/terms/subject>,<http://dbpedia.org/ontology/openingFilm>,<http://www.w3.org/2000/01/rdf-schema#seeAlso>,<http://dbpedia.org/property/story>,<http://dbpedia.org/ontology/series>,<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>,<http://dbpedia.org/ontology/basedOn>,<http://dbpedia.org/ontology/starring>,<http://dbpedia.org/ontology/country>,<http://dbpedia.org/ontology/wikiPageWikiLink>,<http://purl.org/linguistics/gold/hypernym>,<http://dbpedia.org/ontology/editing>,<http://dbpedia.org/property/producers>,<http://dbpedia.org/property/allWriting>,<http://dbpedia.org/property/notableWork>,<http://dbpedia.org/ontology/director>,<http://dbpedia.org/ontology/award>'

    summ_modes=(sv mv)
    summ_ratios=(25 50 75)
    for summarization_mode in "${summ_modes[@]}"
    do
        for ratio in "${summ_ratios[@]}"
        do
            fold_number=0
            local dirName="fold${fold_number}/${dataset_out}_${kg_type}-${summarization_mode}"
            if [ ! -d "$HOME/git/datasets/${experiment}/${dirName}-${kge}-${ratio}" ]
            then
                STARTTIME=$(date +%s)
                if [ "${verbose}" = true ]
                then
                    kge-k-means ${experiment} "fold${fold_number}/${dataset_in}" ${dirName} ${kg_filename} ${summarization_mode} ${kge} ${epochs} ${batch_size} ${learning_rate} ${low_frequence} ${ratio} ${relations} ${seed} 'true'
                else
                    kge-k-means ${experiment} "fold${fold_number}/${dataset_in}" ${dirName} ${kg_filename} ${summarization_mode} ${kge} ${epochs} ${batch_size} ${learning_rate} ${low_frequence} ${ratio} ${relations} ${seed} 'false'
                fi
                #pid = $!
                #resource_usage $pid 600 "${HOME}/git/datasets/${experiment}/${dirName}-${kge}-${ratio}/kge-k-means-resource_usage.csv" &
                #wait $pid
                ENDTIME=$(date +%s)
                echo -e "summarize-fold${fold_number}/${dataset_out}_${kg_type}-${summarization_mode}-${kge}-${ratio}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
            fi

            folds=(1 2 3 4)
            for fold_number in "${folds[@]}"
            do
                local dirName="fold${fold_number}/${dataset_out}_${kg_type}-${summarization_mode}"
                if [ ! -d "$HOME/git/datasets/${experiment}/${dirName}-${kge}-${ratio}" ]
                then
                    STARTTIME=$(date +%s)
                    if [ "${verbose}" = true ]
                    then
                        kge-k-means ${experiment} "fold${fold_number}/${dataset_in}" ${dirName} ${kg_filename} ${summarization_mode} ${kge} ${epochs} ${batch_size} ${learning_rate} ${low_frequence} ${ratio} ${relations} ${seed} 'true'
                    else
                        kge-k-means ${experiment} "fold${fold_number}/${dataset_in}" ${dirName} ${kg_filename} ${summarization_mode} ${kge} ${epochs} ${batch_size} ${learning_rate} ${low_frequence} ${ratio} ${relations} ${seed} 'false'
                    fi
                    #pid = $!
                    #resource_usage $pid 600 "${HOME}/git/datasets/${experiment}/${dirName}-${kge}-${ratio}/kge-k-means-resource_usage.csv" &
                    #wait $pid
                    ENDTIME=$(date +%s)
                    echo -e "summarize-fold${fold_number}/${dataset_out}_${kg_type}-${summarization_mode}-${kge}-${ratio}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
                fi
            done
            yes | rm "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/cluster${ratio}.tsv"
        done
    done
}

preprocess_summ() {
    local dataset_in=$1
    local dataset_out=$2
    local kg_type=$3
    local low_frequence=$4

    cd $HOME/git/kg-summ-rec/preprocess

    summ_modes=(sv mv)
    summ_algos=(complex)
    summ_ratios=(25 50 75)
    local STARTTIME=0
    local ENDTIME=0
    folds=(0 1 2 3 4)
    for fold_number in "${folds[@]}"
    do
        for m in "${summ_modes[@]}"
        do
            for a in "${summ_algos[@]}"
            do
                for r in "${summ_ratios[@]}"
                do
                    local dirName="fold${fold_number}/${dataset_out}_${kg_type}-${m}-${a}-${r}"
                    if no_exist "$HOME/git/datasets/${experiment}/${dirName}/cao-format/ml1m/kg/kg_hop0.dat"
                    then
                        STARTTIME=$(date +%s)
                        if [ "$verbose" = true ]
                        then
                            cao-format_summ "fold${fold_number}/${dataset_in}" "${dirName}" "${low_frequence}" "${seed}" 'true'
                        else
                            cao-format_summ "fold${fold_number}/${dataset_in}" "${dirName}" "${low_frequence}" "${seed}" 'false'
                        fi
                        ENDTIME=$(date +%s)
                        echo -e "preprocess_summ-${dirName}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
                    fi
                done
            done
        done
    done

    cd $HOME/git/kg-summ-rec
}

measure_summ_impact() {
    local dataset_in=$1
    local dataset_out=$2
    local kg_type=$3
    local low_frequence=$4

    cd $HOME/git/kg-summ-rec/util
    conda deactivate
    conda activate kg-summ-rec

    summ_modes=(sv mv)
    summ_algos=(complex)
    summ_ratios=(25 50 75)
    local STARTTIME=0
    local ENDTIME=0
    folds=(0 1 2 3 4)
    for fold_number in "${folds[@]}"
    do
        for m in "${summ_modes[@]}"
        do
            for a in "${summ_algos[@]}"
            do
                for r in "${summ_ratios[@]}"
                do
                    local dirName="fold${fold_number}/${dataset_out}_${kg_type}-${m}-${a}-${r}"
                    if no_exist "$HOME/git/results/${experiment}/${dirName}/kg-ig_stats.tsv"
                    then
                        STARTTIME=$(date +%s)
                        if [ "$verbose" = true ]; then echo "[kg-summ-rec] measure_summ_impact: Creating ~/git/results/${experiment}/${dirName}/kg-ig_stats.tsv"; fi
                        python kg2rdf.py --mode 'statistics' --kgpath "$HOME/git/datasets/${experiment}/${dirName}" \
                        --input "$HOME/git/datasets/${experiment}/${dirName}/kg-ig.nt" \
                        --output "$HOME/git/results/${experiment}/${dirName}/kg-ig_stats.tsv"
                        ENDTIME=$(date +%s)
                        echo -e "measure_summ_impact-${dirName}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
                    fi
                done
            done
        done
    done

    cd $HOME/git/kg-summ-rec
}

####
# recommend_cao_sKG
#
# - ml-cao_cv_oKG
#
# - ml-cao_cv_sKG_complex-ig-sv-75, ml-cao_cv_sKG_complex-ig-sv-50, ml-cao_cv_sKG_complex-ig-sv-25
# - ml-cao_cv_sKG_complex-ig-mv-75, ml-cao_cv_sKG_complex-ig-mv-50, ml-cao_cv_sKG_complex-ig-mv-25
####
recommend_cao_sKG() {
    # kg-summ-rec/evaluation
    if [[ ! $PYTHONPATH = *git/kg-summ-rec/evaluation* ]]
    then
        export PYTHONPATH="${HOME}/git/kg-summ-rec/evaluation:${PYTHONPATH}"
    fi

    kg_recommendation "ml-cao_cv_oKG" "ml-cao_cv_sKG"
}

####
# recommend_cao_sfKG
#
# - ml-cao_cv_fKG
#
# - ml-cao_cv_sfKG_complex-ig-sv-75, ml-cao_cv_sfKG_complex-ig-sv-50, ml-cao_cv_sfKG_complex-ig-sv-25
# - ml-cao_cv_sfKG_complex-ig-mv-75, ml-cao_cv_sfKG_complex-ig-mv-50, ml-cao_cv_sfKG_complex-ig-mv-25
####
recommend_cao_sfKG() {
    # kg-summ-rec/evaluation
    if [[ ! $PYTHONPATH = *git/kg-summ-rec/evaluation* ]]
    then
        export PYTHONPATH="${HOME}/git/kg-summ-rec/evaluation:${PYTHONPATH}"
    fi

    folds=(0 1 2 3 4)
    for fold_number in "${folds[@]}"
    do
        cp ~/git/results/$experiment/fold${fold_number}/ml-cao_cv_oKG/ml1m-fm-pretrained.ckpt ~/git/results/$experiment/fold${fold_number}/ml-cao_cv_fKG/ml1m-fm-pretrained.ckpt
        cp ~/git/results/$experiment/fold${fold_number}/ml-cao_cv_oKG/ml1m-fm-1*.log ~/git/results/$experiment/fold${fold_number}/ml-cao_cv_fKG/
        cp ~/git/results/$experiment/fold${fold_number}/ml-cao_cv_oKG/ml1m-bprmf-pretrained2.ckpt ~/git/results/$experiment/fold${fold_number}/ml-cao_cv_fKG/ml1m-bprmf-pretrained2.ckpt
        cp ~/git/results/$experiment/fold${fold_number}/ml-cao_cv_oKG/ml1m-bprmf-1*.log ~/git/results/$experiment/fold${fold_number}/ml-cao_cv_fKG/
        cp ~/git/results/$experiment/fold${fold_number}/ml-cao_cv_oKG/ml1m-transup-pretrained.ckpt ~/git/results/$experiment/fold${fold_number}/ml-cao_cv_fKG/ml1m-transup-pretrained.ckpt
        cp ~/git/results/$experiment/fold${fold_number}/ml-cao_cv_oKG/ml1m-transup-1*.log ~/git/results/$experiment/fold${fold_number}/ml-cao_cv_fKG/

        if [ "$verbose" = true ]; then echo "[kg-summ-rec] kg_recommendation: Creating ~/git/results/${experiment}/ml-cao_cv_fKG/*.log"; fi
        #recommend "fold${fold_number}/ml-cao_cv_fKG" '540,27000,27027' '2350,235000,11750' '235,23500,1175' '9380,234500,234969' 256 0.005 # KNOWLEDGE_REPRESENTATION 1000-epochs, TUP early_stop 10-1000-50, BPRMF early_stop 1-100-5, KNOWLEDGABLE_RECOMMENDATION 500-epochs. One epoch has 27, 235, 235, 469 steps. Proportion 20-501-500.
        recommend_cao "fold${fold_number}/ml-cao_ho_fKG" "fold${fold_number}/ml-cao_ho_fKG"
    done

    kg_recommendation "ml-cao_cv_oKG" "ml-cao_cv_sfKG"
}

kg_recommendation() {
    local dataset_in=$1
    local dataset_out=$2

    #summ_types=(ig uig euig)
    summ_types=(ig)
    summ_modes=(sv mv)
    summ_algos=(complex)
    summ_ratios=(25 50 75)
    folds=(0 1 2 3 4)
    for fold_number in "${folds[@]}"
    do
        # original KG
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] kg_recommendation: Creating ~/git/results/${experiment}/fold${fold_number}/${dataset_in}/*.log"; fi
        #recommend "fold${fold_number}/${dataset_in}" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005 # Early stopping parameters
        #recommend "fold${fold_number}/${dataset_in}" '540,27000,27027' '2350,235000,11750' '235,23500,1175' '9380,234500,234969' 256 0.005 # KNOWLEDGE_REPRESENTATION 1000-epochs, TUP early_stop 10-1000-50, BPRMF early_stop 1-100-5, KNOWLEDGABLE_RECOMMENDATION 500-epochs. One epoch has 27, 235, 235, 469 steps. Proportion 20-501-500.
        recommend_cao "fold${fold_number}/${dataset_in}" "fold${fold_number}/${dataset_in}"

        for a in "${summ_algos[@]}"
        do
            for t in "${summ_types[@]}"
            do
                for r in "${summ_ratios[@]}"
                do
                    for m in "${summ_modes[@]}"
                    do
                        local dirName="fold${fold_number}/${dataset_out}_${t}-${m}-${a}-${r}"

                        cp ~/git/results/$experiment/fold${fold_number}/${dataset_in}/ml1m-fm-pretrained.ckpt ~/git/results/$experiment/${dirName}/ml1m-fm-pretrained.ckpt
                        cp ~/git/results/$experiment/fold${fold_number}/${dataset_in}/ml1m-fm-1*.log ~/git/results/$experiment/${dirName}/
                        cp ~/git/results/$experiment/fold${fold_number}/${dataset_in}/ml1m-bprmf-pretrained2.ckpt ~/git/results/$experiment/${dirName}/ml1m-bprmf-pretrained2.ckpt
                        cp ~/git/results/$experiment/fold${fold_number}/${dataset_in}/ml1m-bprmf-1*.log ~/git/results/$experiment/${dirName}/
                        cp ~/git/results/$experiment/fold${fold_number}/${dataset_in}/ml1m-transup-pretrained.ckpt ~/git/results/$experiment/${dirName}/ml1m-transup-pretrained.ckpt
                        cp ~/git/results/$experiment/fold${fold_number}/${dataset_in}/ml1m-transup-1*.log ~/git/results/$experiment/${dirName}/

                        if [ "$verbose" = true ]; then echo "[kg-summ-rec] kg_recommendation: Creating ~/git/results/${experiment}/${dirName}/*.log"; fi
                        #recommend "${dirName}" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005 # Early stopping parameters
                        #recommend "${dirName}" '540,27000,27027' '2350,235000,11750' '235,23500,1175' '9380,234500,234969' 256 0.005 # KNOWLEDGE_REPRESENTATION 1000-epochs, TUP early_stop 10-1000-50, BPRMF early_stop 1-100-5, KNOWLEDGABLE_RECOMMENDATION 500-epochs. One epoch has 27, 235, 235, 469 steps. Proportion 20-501-500.
                        recommend_cao "${dirName}" "${dirName}"
                    done
                done
            done
        done
    done

    cd $HOME/git/kg-summ-rec
}

recommend_cao() {
    local dataset_in=$1
    local dataset_out=$2

    #[activate jointrec]
    cd ~/git/joint-kg-recommender
    conda deactivate
    conda activate jointrec

    local STARTTIME=0
    local ENDTIME=0
    #[FM]
    if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-fm-*.log"
    then
        STARTTIME=$(date +%s)
        echo "[kg-summ-rec] recommend: Running FM with ${dataset_out}"
        local training_steps=$((686 * 350)) # step_per_epoch * limit
        #training_steps=$((686 * 2)) # step_per_epoch * limit
        CUDA_VISIBLE_DEVICES=0 nohup python run_item_recommendation.py -batch_size 1024 -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -dataset ml1m -early_stopping_steps_to_wait $((training_steps + 1)) -embedding_size 100 -eval_interval_steps $((training_steps - 1)) -nohas_visualization -joint_ratio 0.5 -kg_lambda 0.5 -l2_lambda 1e-5 -learning_rate 0.005 -log_path ~/git/results/${experiment}/${dataset_out}/ -model_type fm -negtive_samples 1 -norm_lambda 1 -optimizer_type Adagrad -rec_test_files valid.dat:test.dat -seed 3 -topn 10 -training_steps ${training_steps} &
        pid = $!
        resource_usage $pid 600 "${HOME}/git/results/${experiment}/${dataset_out}/fm-resource_usage.csv" &
        wait $pid
        mv ~/git/results/${experiment}/${dataset_out}/ml1m-fm-1*.ckpt ~/git/results/${experiment}/${dataset_out}/ml1m-fm-pretrained.ckpt
        ENDTIME=$(date +%s)
        echo -e "recommend-FM-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi
    if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-bprmf-*.log"
    then
    #[BPRMF] - Steffen Rendle, Christoph Freudenthaler, Zeno Gantner, and Lars Schmidt-Thieme. 2009. BPR: Bayesian personalized ranking from implicit feedback. In UAI.
        STARTTIME=$(date +%s)
        echo "[kg-summ-rec] recommend: Running BPRMF2 with ${dataset_out}"
        local training_steps=$((1371 * 600)) # step_per_epoch * limit
        #training_steps=$((1371 * 2)) # step_per_epoch * limit
        CUDA_VISIBLE_DEVICES=0 nohup python run_item_recommendation.py -batch_size 512 -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -dataset ml1m -early_stopping_steps_to_wait $((training_steps + 1)) -embedding_size 100 -eval_interval_steps $((training_steps - 1)) -nohas_visualization -joint_ratio 0.5 -kg_lambda 0.5 -l2_lambda 1e-5 -learning_rate 0.005 -log_path ~/git/results/${experiment}/${dataset_out}/ -model_type bprmf -negtive_samples 1 -norm_lambda 1 -optimizer_type Adagrad -rec_test_files valid.dat:test.dat -seed 3 -topn 10 -training_steps ${training_steps} &
        pid = $!
        resource_usage $pid 600 "${HOME}/git/results/${experiment}/${dataset_out}/bprmf2-resource_usage.csv" &
        wait $pid
        mv ~/git/results/${experiment}/${dataset_out}/ml1m-bprmf-1*.ckpt ~/git/results/${experiment}/${dataset_out}/ml1m-bprmf-pretrained2.ckpt
        ENDTIME=$(date +%s)
        echo -e "recommend-BPRMF2-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi
    #[TUP]
    if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-transup-*.log"
    then
        STARTTIME=$(date +%s)
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] recommend: Running TUP with ${dataset_out}"; fi
        local training_steps=$((686 * 200)) # step_per_epoch * limit
        #training_steps=$((686 * 2)) # step_per_epoch * limit
        CUDA_VISIBLE_DEVICES=0 nohup python run_item_recommendation.py -L1_flag -batch_size 1024 -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -dataset ml1m -early_stopping_steps_to_wait $((training_steps + 1)) -embedding_size 100 -eval_interval_steps $((training_steps - 1)) -nohas_visualization -joint_ratio 0.5 -kg_lambda 0.5 -l2_lambda 0 -learning_rate 0.001 -load_ckpt_file "$HOME/git/results/${experiment}/${dataset_out}/ml1m-bprmf-pretrained2.ckpt" -log_path ~/git/results/${experiment}/${dataset_out}/ -model_type transup -negtive_samples 1 -norm_lambda 1 -num_preferences 20 -optimizer_type Adam -rec_test_files valid.dat:test.dat -seed 3 -topn 10 -training_steps ${training_steps} -use_st_gumbel &
        pid = $!
        resource_usage $pid 600 "${HOME}/git/results/${experiment}/${dataset_out}/tup-resource_usage.csv" &
        wait $pid
        mv ~/git/results/${experiment}/${dataset_out}/ml1m-transup-1*.ckpt ~/git/results/${experiment}/${dataset_out}/ml1m-transup-pretrained.ckpt
        ENDTIME=$(date +%s)
        echo -e "recommend-TRANSUP-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi
    #[TRANSE2]
    if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-transe-*.log"
    then
        STARTTIME=$(date +%s)
        echo "[kg-summ-rec] recommend: Running TransE1 with ${dataset_out}"
        local training_steps=$((760 * 400)) # step_per_epoch * limit
        #training_steps=$((760 * 2)) # step_per_epoch * limit
        CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -L1_flag -batch_size 400 -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -dataset ml1m -early_stopping_steps_to_wait $((training_steps + 1)) -embedding_size 100 -eval_interval_steps $((training_steps - 1)) -nohas_visualization -joint_ratio 0.5 -kg_lambda 1 -kg_test_files valid.dat:test.dat -l2_lambda 0 -learning_rate 0.001 -log_path ~/git/results/${experiment}/${dataset_out}/ -model_type transe -negtive_samples 1 -norm_lambda 1 -optimizer_type Adam -seed 3 -topn 10 -training_steps ${training_steps} &
        pid = $!
        resource_usage $pid 600 "${HOME}/git/results/${experiment}/${dataset_out}/transe2-resource_usage.csv" &
        wait $pid
        mv ~/git/results/${experiment}/${dataset_out}/ml1m-transe-1*.ckpt_final ~/git/results/${experiment}/${dataset_out}/ml1m-transe-pretrained2.ckpt
        ENDTIME=$(date +%s)
        echo -e "recommend-TRANSE2-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi
    #[TRANSH]
    if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-transh-*.log"
    then
        STARTTIME=$(date +%s)
        echo "[kg-summ-rec] recommend: Running TransH with ${dataset_out}"
        local training_steps=$((3040 * 600)) # step_per_epoch * limit
        #training_steps=$((3040 * 2)) # step_per_epoch * limit
        CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -L1_flag -batch_size 100 -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -dataset ml1m -early_stopping_steps_to_wait $((training_steps + 1)) -embedding_size 100 -eval_interval_steps $((training_steps - 1)) -nohas_visualization -joint_ratio 0.5 -kg_lambda 0.5 -kg_test_files valid.dat:test.dat -l2_lambda 0 -learning_rate 0.001 -load_ckpt_file "$HOME/git/results/${experiment}/${dataset_out}/ml1m-transe-pretrained2.ckpt"  -log_path ~/git/results/${experiment}/${dataset_out}/ -model_type transh -norm_lambda 1 -optimizer_type Adam -seed 3 -topn 10 -training_steps ${training_steps} &
        pid = $!
        resource_usage $pid 600 "${HOME}/git/results/${experiment}/${dataset_out}/transh-resource_usage.csv" &
        wait $pid
        mv ~/git/results/${experiment}/${dataset_out}/ml1m-transh-1*.ckpt_final ~/git/results/${experiment}/${dataset_out}/ml1m-transh-pretrained.ckpt
        ENDTIME=$(date +%s)
        echo -e "recommend-TRANSH-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi
    #[CFKG] (BPRMF,TransE) - Yongfeng Zhang, Qingyao Ai, Xu Chen, and Pengfei Wang. 2018. Learning over Knowledge-Base Embeddings for Recommendation. In SIGIR.
    if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-cfkg-*.log"
    then
       STARTTIME=$(date +%s)
       if [ "$verbose" = true ]; then echo "[kg-summ-rec] recommend: Running CFKG with ${dataset_out}"; fi
       local training_steps=$((3509 * 300)) # step_per_epoch * limit
       #training_steps=$((3509 * 2)) # step_per_epoch * limit
       CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -L1_flag -batch_size 400 -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -dataset ml1m -early_stopping_steps_to_wait $((training_steps + 1)) -embedding_size 100 -eval_interval_steps $((training_steps - 1)) -nohas_visualization -joint_ratio 0.5 -kg_lambda 1 -kg_test_files valid.dat:test.dat -l2_lambda 0 -learning_rate 0.001 -load_ckpt_file "$HOME/git/results/${experiment}/${dataset_out}/ml1m-bprmf-pretrained2.ckpt:$HOME/git/results/${experiment}/${dataset_out}/ml1m-transe-pretrained2.ckpt" -log_path ~/git/results/${experiment}/${dataset_out}/ -model_type cfkg -negtive_samples 1 -norm_lambda 1 -optimizer_type Adam -rec_test_files valid.dat:test.dat -seed 3 -share_embeddings -topn 10 -training_steps ${training_steps} -nouse_st_gumbel &
       pid = $!
       resource_usage $pid 600 "${HOME}/git/results/${experiment}/${dataset_out}/cfkg-resource_usage.csv" &
       wait $pid
       ENDTIME=$(date +%s)
       echo -e "recommend-CFKG-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi
    #CKE (TransR) - Fuzheng Zhang, Nicholas Jing Yuan, Defu Lian, Xing Xie, and Wei-Ying Ma. 2016. Collaborative Knowledge Base Embedding for Recommender Systems. In SIGKDD.
    if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-cke-*.log"
    then
       STARTTIME=$(date +%s)
       if [ "$verbose" = true ]; then echo "[kg-summ-rec] recommend: Running CKE with ${dataset_out}"; fi
       local training_steps=$((5482 * 300)) # step_per_epoch * limit
       #training_steps=$((5482 * 2)) # step_per_epoch * limit
       CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -L1_flag -batch_size 256 -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -dataset ml1m -early_stopping_steps_to_wait $((training_steps + 1)) -embedding_size 100 -eval_interval_steps $((training_steps - 1)) -nohas_visualization -joint_ratio 0.5 -kg_lambda 1 -kg_test_files valid.dat:test.dat -l2_lambda 0 -learning_rate 0.001 -log_path ~/git/results/${experiment}/${dataset_out}/ -model_type cke -negtive_samples 1 -norm_lambda 1 -optimizer_type Adam -rec_test_files valid.dat:test.dat -seed 3 -topn 10 -training_steps ${training_steps} -nouse_st_gumbel &
       pid = $!
       resource_usage $pid 600 "${HOME}/git/results/${experiment}/${dataset_out}/cke-resource_usage.csv" &
       wait $pid
       ENDTIME=$(date +%s)
       echo -e "recommend-CKE-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi
    #[CoFM] (FM+TransE) - Guangyuan Piao and John G. Breslin. 2018. Transfer Learning for Item Recommendations and Knowledge Graph Completion in Item Related Domains via a Co-Factorization Model. In ESWC.
    if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-cofm-*.log"
    then
      STARTTIME=$(date +%s)
      if [ "$verbose" = true ]; then echo "[kg-summ-rec] recommend: Running CoFM with ${dataset_out}"; fi
      local training_steps=$((3509 * 300)) # step_per_epoch * limit
      #training_steps=$((3509 * 2)) # step_per_epoch * limit
      CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -L1_flag -batch_size 400 -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -dataset ml1m -early_stopping_steps_to_wait $((training_steps + 1)) -embedding_size 100 -eval_interval_steps $((training_steps - 1)) -nohas_visualization -joint_ratio 0.5 -kg_lambda 1 -kg_test_files valid.dat:test.dat -l2_lambda 0 -learning_rate 0.001 -load_ckpt_file "$HOME/git/results/${experiment}/${dataset_out}/ml1m-fm-pretrained.ckpt:$HOME/git/results/${experiment}/${dataset_out}/ml1m-transe-pretrained2.ckpt" -log_path ~/git/results/${experiment}/${dataset_out}/ -model_type cofm -negtive_samples 1 -norm_lambda 1 -optimizer_type Adam -rec_test_files valid.dat:test.dat -seed 3 -share_embeddings -topn 10 -training_steps ${training_steps} -nouse_st_gumbel &
      pid = $!
      resource_usage $pid 600 "${HOME}/git/results/${experiment}/${dataset_out}/cofm-resource_usage.csv" &
      wait $pid
      ENDTIME=$(date +%s)
      echo -e "recommend-CoFM-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi
    #[JTransUP1]
    if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-jtransup-*.log"
    then
        STARTTIME=$(date +%s)
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] recommend: Running KTUP1 with ${dataset_out}"; fi
        local training_steps=$((3509 * 300)) # step_per_epoch * limit
        #training_steps=$((3509 * 2)) # step_per_epoch * limit
        CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -L1_flag -batch_size 400 -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -dataset ml1m -early_stopping_steps_to_wait $((training_steps + 1)) -embedding_size 100 -eval_interval_steps $((training_steps - 1)) -nohas_visualization -joint_ratio 0.5 -kg_lambda 1 -kg_test_files valid.dat:test.dat -l2_lambda 0 -learning_rate 0.001 -load_ckpt_file "$HOME/git/results/${experiment}/${dataset_out}/ml1m-transup-pretrained.ckpt:$HOME/git/results/${experiment}/${dataset_out}/ml1m-transh-pretrained.ckpt" -log_path ~/git/results/${experiment}/${dataset_out}/ -model_type jtransup -negtive_samples 1 -norm_lambda 1 -optimizer_type Adam -rec_test_files valid.dat:test.dat -seed 3 -topn 10 -training_steps ${training_steps} -use_st_gumbel &
        pid = $!
        resource_usage $pid 600 "${HOME}/git/results/${experiment}/${dataset_out}/ktup1-resource_usage.csv" &
        wait $pid
        ENDTIME=$(date +%s)
        echo -e "recommend-KTUP1-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi

    ####
    # Collect computational cost of ${dataset_out}
    ####
    cd ~/git/kg-summ-rec
    if no_exist "$HOME/git/results/${experiment}/${dataset_out}/comp_cost.tsv"
    then
        comp_cost "${experiment}" "${dataset_out}" > "$HOME/git/results/${experiment}/${dataset_out}/comp_cost.tsv"
    fi
}

run_experiment() {
    experiment=$1
    seed=$2
    if [ "$3" = 'true' ]; then verbose=true; else verbose=false; fi
    overall_comp_cost="$HOME/git/results/${experiment}/overall_efficiency.tsv"

    if [ ! -d "$HOME/git/datasets/${experiment}" ]
    then
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}"; fi
        mkdir "$HOME/git/datasets/${experiment}"
        mkdir "$HOME/git/results/${experiment}"
        touch ${overall_comp_cost}
    fi

    # Preprocessing
    preprocess_cao_oKG
    #preprocess_cao_fKG

    # Summarization
    clean_kge-k-means
    summarize_cao_sKG
    #clean_kge-k-means
    #summarize_cao_sfKG

    # Recommendation
    recommend_cao_sKG
    #recommend_cao_sfKG
}

run_experiment $1 $2 $3
#bash -i examples/Sacenti-JIIS2021-revised/run_exp4-cao_cv_complex.sh "JIIS-revised-exp4" 3 'true' |& tee out-exp4-1.txt
