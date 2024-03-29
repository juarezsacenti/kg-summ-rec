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
# Run experiment kg_type for Sacenti 2021 - JOURNAL.
# - Datasets: ml-sun
# - Split: cross-validation (cv)
# - Filtering: infrequent entities filtering at 0 (sKG) and at 10 (sfKG)
# - KG Summarization:
#   - Algorithms: KGE-K-Means (ComplEx)
#   - KG type: item graph (ig)
#   - Summarization mode: single-view (sv) and multi-view (mv)
#   - Entity preservation ratio: 75, 50 and 25%
#   - Results: summ_effects, overall_comp_cost
# - KG Recommendation:
#   - Algorithms: CFKG, CKE, CoFM, JtransUp (KTUP); TransE, TransH, BPRMF,
#   TransUp (TUP)
#   - Results:  rec_quality, comp_cost
# GLOBALS:
#   HOME
#   experiment: running experiment. Default is 'Sacenti-JIIS2021-revised'.
# FUNCTIONS:
#   preprocess_sun_oKG
#   preprocess_sun_fKG
#   summarize_sun_sKG
#   summarize_sun_sfKG
#   recommend_sun_sKG
#   recommend_sun_sfKG
#   run_experiments
#######################################
experiment='JIIS-revised-exp2'
seed=0
verbose=false
overall_comp_cost="$HOME/git/results/${experiment}/overall_comp_cost.tsv"

#######################################
# Import util/util.sh
# FUNCTIONS:
#   no_exist 'path_to_file'
#   copy_dataset 'path_to_dataset' 'path_to_new_dataset'
#######################################
source $HOME/git/kg-summ-rec/util/util.sh

#######################################
# Import preprocess/cao-format_ml-sun.sh
# FUNCTIONS:
#   cao-format_ml-sun 'dataset' 'low_frequence'
#######################################
source $HOME/git/kg-summ-rec/preprocess/cao-format_ml-sun.sh

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
# - Datasets: ml-sun
# - Split: cross-validation (cv)
# - Filtering: infrequent entities filtering at 0 (oKG) and at 10 (fKG)
####
preprocess_sun_oKG() {
    if [ ! -d "$HOME/git/datasets/${experiment}/fold0/ml-sun_cv_oKG" ]
    then
        local STARTTIME=$(date +%s)
        # Create folders for Sun's original KG (oKG)
        if no_exist "$HOME/git/datasets/${experiment}/ml-sun"
        then
            if [ "$verbose" = true ]; then echo "[kg-summ-rec] preprocess_sun_oKG: Creating ~/git/datasets/${experiment}/ml-sun"; fi
            cd $HOME/git/kg-summ-rec/util
            copy_ml_sun "$HOME/git/datasets/ml-sun" "$HOME/git/datasets/${experiment}/ml-sun"
            cd $HOME/git/kg-summ-rec
        fi

        # Preprocess oKG
        cd $HOME/git/kg-summ-rec/preprocess
        LOW_FREQUENCE=0    #Low Frequence Filtering (0, 10)
        if [ "$verbose" = true ]
        then
            cao-format_ml-sun "ml-sun_cv_oKG" ${LOW_FREQUENCE} 'cv' ${seed} 'true'
        else
            cao-format_ml-sun "ml-sun_cv_oKG" ${LOW_FREQUENCE} 'cv' ${seed} 'false'
        fi
        cd $HOME/git/kg-summ-rec

        folds=(0 1 2 3 4)
        for fold_number in "${folds[@]}"
        do
            if no_exist "$HOME/git/results/${experiment}/fold${fold_number}"
            then
                if [ "$verbose" = true ]; then echo "[kg-summ-rec] preprocess_sun_oKG: Creating ~/git/results/${experiment}/fold${fold_number}"; fi
                mkdir ~/git/results/${experiment}/fold${fold_number}
            fi
            if no_exist "$HOME/git/results/${experiment}/fold${fold_number}/ml-sun_cv_oKG"
            then
                if [ "$verbose" = true ]; then echo "[kg-summ-rec] preprocess_sun_oKG: Creating ~/git/results/${experiment}/fold${fold_number}/ml-sun_cv_oKG"; fi
                mkdir ~/git/results/${experiment}/fold${fold_number}/ml-sun_cv_oKG
            fi
            # Collect ml-sun_cv_oKG statistics
            if no_exist "$HOME/git/results/${experiment}/fold${fold_number}/ml-sun_cv_oKG/kg-ig_stats.tsv"
            then
                if [ "$verbose" = true ]; then echo "[kg-summ-rec] preprocess_sun_oKG: Creating ~/git/results/${experiment}/fold${fold_number}/ml-sun_cv_oKG/kg-ig_stats.tsv"; fi
                cd $HOME/git/kg-summ-rec/util
                conda deactivate
                conda activate kg-summ-rec
                python kg2rdf.py --mode 'statistics' --kgpath "~/git/datasets/${experiment}/fold${fold_number}/ml-sun_cv_oKG" \
                --input "~/git/datasets/${experiment}/fold${fold_number}/ml-sun_cv_oKG/kg-ig.nt" \
                --output "~/git/results/${experiment}/fold${fold_number}/ml-sun_cv_oKG/kg-ig_stats.tsv"
                cd $HOME/git/kg-summ-rec
            fi
        done

        local ENDTIME=$(date +%s)
        echo -e "preprocess_sun_oKG\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi
}

preprocess_sun_fKG() {
    if [ ! -d "$HOME/git/datasets/${experiment}/fold0/ml-sun_cv_fKG" ]
    then
        local STARTTIME=$(date +%s)

        # Create folders for Sun's filtered KG (fKG)
        if no_exist "$HOME/git/datasets/${experiment}/ml-sun"
        then
            if [ "$verbose" = true ]; then echo "[kg-summ-rec] preprocess_sun_fKG: Creating ~/git/datasets/${experiment}/ml-sun"; fi
            cd $HOME/git/kg-summ-rec/util
            copy_ml_sun "$HOME/git/datasets/ml-sun" "$HOME/git/datasets/${experiment}/ml-sun"
            cd $HOME/git/kg-summ-rec
        fi

        # Preprocess fKG
        cd $HOME/git/kg-summ-rec/preprocess
        LOW_FREQUENCE=10    #Low Frequence Filtering (0, 10)
        if [ "$verbose" = true ]
        then
            cao-format_ml-sun "ml-sun_cv_fKG" ${LOW_FREQUENCE} 'cv' ${seed} 'true'
        else
            cao-format_ml-sun "ml-sun_cv_fKG" ${LOW_FREQUENCE} 'cv' ${seed} 'false'
        fi
        cd $HOME/git/kg-summ-rec

        folds=(0 1 2 3 4)
        for fold_number in "${folds[@]}"
        do
            if no_exist "$HOME/git/results/${experiment}/fold${fold_number}"
            then
                if [ "$verbose" = true ]; then echo "[kg-summ-rec] preprocess_sun_fKG: Creating ~/git/results/${experiment}/fold${fold_number}"; fi
                mkdir ~/git/results/${experiment}/fold${fold_number}
            fi
            if no_exist "$HOME/git/results/${experiment}/fold${fold_number}/ml-sun_cv_fKG"
            then
                if [ "$verbose" = true ]; then echo "[kg-summ-rec] preprocess_sun_fKG: Creating ~/git/results/${experiment}/fold${fold_number}/ml-sun_cv_fKG"; fi
                mkdir ~/git/results/${experiment}/fold${fold_number}/ml-sun_cv_fKG
            fi
            # Collect ml-sun_cv_oKG statistics
            if no_exist "$HOME/git/results/${experiment}/fold${fold_number}/ml-sun_cv_fKG/kg-ig_stats.tsv"
            then
                if [ "$verbose" = true ]; then echo "[kg-summ-rec] preprocess_sun_fKG: Creating ~/git/results/${experiment}/fold${fold_number}/ml-sun_cv_fKG/kg-ig_stats.tsv"; fi
                cd $HOME/git/kg-summ-rec/util
                conda deactivate
                conda activate kg-summ-rec
                python kg2rdf.py --mode 'statistics' --kgpath "~/git/datasets/${experiment}/fold${fold_number}/ml-sun_cv_fKG" \
                --input "~/git/datasets/${experiment}/fold${fold_number}/ml-sun_cv_fKG/kg-ig.nt" \
                --output "~/git/results/${experiment}/fold${fold_number}/ml-sun_cv_fKG/kg-ig_stats.tsv"
                cd $HOME/git/kg-summ-rec
            fi
        done

        local ENDTIME=$(date +%s)
        echo -e "preprocess_sun_fKG\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi
}

####
# KG summarization
#
# - Datasets: ml-sun
# - Split: cross-validation (cv)
# - Filtering: infrequent entities filtering at 0 (sKG) and at 10 (sfKG)
####
summarize_sun_sKG() {
    # KG summarization
    kg_summarization 'ml-sun' 'cv' 'sKG'
}

summarize_sun_sfKG() {
    # KG summarization
    kg_summarization 'ml-sun' 'cv' 'sfKG'
}

kg_summarization() {
    local dataset=$1 # Input dataset: ml-sun
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
    local epochs='150'
    local batch_size='100'
    local learning_rate='0.005'
    local kg_filename="kg-${kg_type}.nt"
    local relations='<http://ml1m-sun/actor>,<http://ml1m-sun/director>,<http://ml1m-sun/genre>'

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
                    ENDTIME=$(date +%s)
                    echo -e "summarize-fold${fold_number}/${dataset_out}_${kg_type}-${summarization_mode}-${kge}-${ratio}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
                fi
            done
            yes | rm "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/cluster${ratio}.tsv"
            yes | rm "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/cluster${ratio}.png"
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
# recommend_sun_sKG
#
# - ml-sun_cv_oKG
#
# - ml-sun_cv_sKG_complex-ig-sv-75, ml-sun_cv_sKG_complex-ig-sv-50, ml-sun_cv_sKG_complex-ig-sv-25
# - ml-sun_cv_sKG_complex-ig-mv-75, ml-sun_cv_sKG_complex-ig-mv-50, ml-sun_cv_sKG_complex-ig-mv-25
####
recommend_sun_sKG() {
    # kg-summ-rec/evaluation
    if [[ ! $PYTHONPATH = *git/kg-summ-rec/evaluation* ]]
    then
        export PYTHONPATH="${HOME}/git/kg-summ-rec/evaluation:${PYTHONPATH}"
    fi

    kg_recommendation "ml-sun_cv_oKG" "ml-sun_cv_sKG"
}

####
# recommend_sun_sfKG
#
# - ml-sun_cv_fKG
#
# - ml-sun_cv_sfKG_complex-ig-sv-75, ml-sun_cv_sfKG_complex-ig-sv-50, ml-sun_cv_sfKG_complex-ig-sv-25
# - ml-sun_cv_sfKG_complex-ig-mv-75, ml-sun_cv_sfKG_complex-ig-mv-50, ml-sun_cv_sfKG_complex-ig-mv-25
####
recommend_sun_sfKG() {
    # kg-summ-rec/evaluation
    if [[ ! $PYTHONPATH = *git/kg-summ-rec/evaluation* ]]
    then
        export PYTHONPATH="${HOME}/git/kg-summ-rec/evaluation:${PYTHONPATH}"
    fi

    folds=(0 1 2 3 4)
    for fold_number in "${folds[@]}"
    do
        cp ~/git/results/$experiment/fold${fold_number}/ml-sun_cv_oKG/ml1m-bprmf-pretrained.ckpt ~/git/results/$experiment/fold${fold_number}/ml-sun_cv_fKG/ml1m-bprmf-pretrained.ckpt
        cp ~/git/results/$experiment/fold${fold_number}/ml-sun_cv_oKG/ml1m-bprmf-1*.log ~/git/results/$experiment/fold${fold_number}/ml-sun_cv_fKG/
        cp ~/git/results/$experiment/fold${fold_number}/ml-sun_cv_oKG/ml1m-transup-pretrained.ckpt ~/git/results/$experiment/fold${fold_number}/ml-sun_cv_fKG/ml1m-transup-pretrained.ckpt
        cp ~/git/results/$experiment/fold${fold_number}/ml-sun_cv_oKG/ml1m-transup-1*.log ~/git/results/$experiment/fold${fold_number}/ml-sun_cv_fKG/

        if [ "$verbose" = true ]; then echo "[kg-summ-rec] kg_recommendation: Creating ~/git/results/${experiment}/ml-sun_ho_fKG/*.log"; fi
        recommend "fold${fold_number}/ml-sun_cv_fKG" '540,27000,27027' '2350,235000,11750' '235,23500,1175' '9380,234500,234969' 256 0.005 # KNOWLEDGE_REPRESENTATION 1000-epochs, TUP early_stop 10-1000-50, BPRMF early_stop 1-100-5, KNOWLEDGABLE_RECOMMENDATION 500-epochs. One epoch has 27, 235, 235, 469 steps. Proportion 20-501-500.
    done

    kg_recommendation "ml-sun_cv_oKG" "ml-sun_cv_sfKG"
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
        recommend "fold${fold_number}/${dataset_in}" '540,27000,27027' '2350,235000,11750' '235,23500,1175' '9380,234500,234969' 256 0.005 # KNOWLEDGE_REPRESENTATION 1000-epochs, TUP early_stop 10-1000-50, BPRMF early_stop 1-100-5, KNOWLEDGABLE_RECOMMENDATION 500-epochs. One epoch has 27, 235, 235, 469 steps. Proportion 20-501-500.

        for a in "${summ_algos[@]}"
        do
            for t in "${summ_types[@]}"
            do
                for r in "${summ_ratios[@]}"
                do
                    for m in "${summ_modes[@]}"
                    do
                        local dirName="fold${fold_number}/${dataset_out}_${t}-${m}-${a}-${r}"

                        cp ~/git/results/$experiment/fold${fold_number}/${dataset_in}/ml1m-bprmf-pretrained.ckpt ~/git/results/$experiment/${dirName}/ml1m-bprmf-pretrained.ckpt
                        cp ~/git/results/$experiment/fold${fold_number}/${dataset_in}/ml1m-bprmf-1*.log ~/git/results/$experiment/${dirName}/
                        cp ~/git/results/$experiment/fold${fold_number}/${dataset_in}/ml1m-transup-pretrained.ckpt ~/git/results/$experiment/${dirName}/ml1m-transup-pretrained.ckpt
                        cp ~/git/results/$experiment/fold${fold_number}/${dataset_in}/ml1m-transup-1*.log ~/git/results/$experiment/${dirName}/

                        if [ "$verbose" = true ]; then echo "[kg-summ-rec] kg_recommendation: Creating ~/git/results/${experiment}/${dirName}/*.log"; fi
                        #recommend "${dirName}" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005 # Early stopping parameters
                        recommend "${dirName}" '540,27000,27027' '2350,235000,11750' '235,23500,1175' '9380,234500,234969' 256 0.005 # KNOWLEDGE_REPRESENTATION 1000-epochs, TUP early_stop 10-1000-50, BPRMF early_stop 1-100-5, KNOWLEDGABLE_RECOMMENDATION 500-epochs. One epoch has 27, 235, 235, 469 steps. Proportion 20-501-500.
                    done
                done
            done
        done
    done

    cd $HOME/git/kg-summ-rec
}

recommend() {
    local DATASET=$1
    # EPOCHS
    IFS=', ' read -r -a KNOWLEDGE_REPRESENTATION_EPOCHS <<< "$2"
    IFS=', ' read -r -a TUP_EPOCHS <<< "$3"
    IFS=', ' read -r -a ITEM_RECOMMENDATION_EPOCHS <<< "$4"
    IFS=', ' read -r -a KNOWLEDGABLE_RECOMMENDATION_EPOCHS <<< "$5"
    # BATCH SIZE
    local BATCH_SIZE=$6
    # LEARNING RATE
    local LEARNING_RATE=$7

    cd ~/git/joint-kg-recommender

    #[activate jointrec]
    conda deactivate
    conda activate jointrec

    local STARTTIME=0
    local ENDTIME=0
    #[TRANSE]
    if no_exist "$HOME/git/results/$experiment/$DATASET/ml1m-transe-*.log"
    then
        STARTTIME=$(date +%s)
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] recommend: Running TransE with $DATASET"; fi
        CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -data_path ~/git/datasets/$experiment/$DATASET/cao-format/ -log_path ~/git/results/$experiment/$DATASET/ -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type transe -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate 0.001 -topn 10 -seed ${seed} -eval_interval_steps ${KNOWLEDGE_REPRESENTATION_EPOCHS[0]} -training_steps ${KNOWLEDGE_REPRESENTATION_EPOCHS[1]} -early_stopping_steps_to_wait ${KNOWLEDGE_REPRESENTATION_EPOCHS[2]} -optimizer_type Adam -L1_flag -norm_lambda 1 -kg_lambda 1 &
        wait $!
        mv ~/git/results/$experiment/$DATASET/ml1m-transe-*.ckpt_final ~/git/results/$experiment/$DATASET/ml1m-transe-pretrained.ckpt
        ENDTIME=$(date +%s)
        echo -e "recommend-TRANSE-${DATASET}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi

    #[TRANSH]
    if no_exist "$HOME/git/results/$experiment/$DATASET/ml1m-transh-*.log"
    then
        STARTTIME=$(date +%s)
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] recommend: Running TransH with $DATASET"; fi
        CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -data_path ~/git/datasets/$experiment/$DATASET/cao-format/ -log_path ~/git/results/$experiment/$DATASET/ -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type transh -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate 0.001 -topn 10 -seed ${seed} -eval_interval_steps ${KNOWLEDGE_REPRESENTATION_EPOCHS[0]} -training_steps ${KNOWLEDGE_REPRESENTATION_EPOCHS[1]} -early_stopping_steps_to_wait ${KNOWLEDGE_REPRESENTATION_EPOCHS[2]} -optimizer_type Adam -L1_flag -norm_lambda 1 -kg_lambda 1 -load_ckpt_file "$HOME/git/results/$experiment/$DATASET/ml1m-transe-pretrained.ckpt" &
        wait $!
        mv ~/git/results/$experiment/$DATASET/ml1m-transh-*.ckpt_final ~/git/results/$experiment/$DATASET/ml1m-transh-pretrained.ckpt
        ENDTIME=$(date +%s)
        echo -e "recommend-TRANSH-${DATASET}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi

    #BPRMF - Steffen Rendle, Christoph Freudenthaler, Zeno Gantner, and Lars Schmidt-Thieme. 2009. BPR: Bayesian personalized ranking from implicit feedback. In UAI.
    if no_exist "$HOME/git/results/$experiment/$DATASET/ml1m-bprmf-pretrained.ckpt"
    then
        STARTTIME=$(date +%s)
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] recommend: Running BPRMF with $DATASET"; fi
        CUDA_VISIBLE_DEVICES=0 nohup python run_item_recommendation.py -data_path ~/git/datasets/$experiment/$DATASET/cao-format/ -log_path ~/git/results/$experiment/$DATASET/ -rec_test_files valid.dat:test.dat -l2_lambda 1e-5 -negtive_samples 1 -model_type bprmf -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate ${LEARNING_RATE} -topn 10 -seed ${seed} -eval_interval_steps ${ITEM_RECOMMENDATION_EPOCHS[0]} -training_steps ${ITEM_RECOMMENDATION_EPOCHS[1]} -early_stopping_steps_to_wait ${ITEM_RECOMMENDATION_EPOCHS[2]} -optimizer_type Adagrad &
        wait $!
        mv ~/git/results/$experiment/$DATASET/ml1m-bprmf-*.ckpt ~/git/results/$experiment/$DATASET/ml1m-bprmf-pretrained.ckpt
        ENDTIME=$(date +%s)
        echo -e "recommend-BPRMF-${DATASET}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi

    #TransUP
    if no_exist "$HOME/git/results/$experiment/$DATASET/ml1m-transup-pretrained.ckpt"
    then
        STARTTIME=$(date +%s)
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] recommend: Running TransUP with $DATASET"; fi
        CUDA_VISIBLE_DEVICES=0 nohup python run_item_recommendation.py -data_path ~/git/datasets/$experiment/$DATASET/cao-format/ -log_path ~/git/results/$experiment/$DATASET/ -rec_test_files valid.dat:test.dat -l2_lambda 1e-5 -negtive_samples 1 -model_type transup -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate ${LEARNING_RATE} -topn 10 -seed ${seed} -eval_interval_steps ${TUP_EPOCHS[0]} -training_steps ${TUP_EPOCHS[1]} -early_stopping_steps_to_wait ${TUP_EPOCHS[2]} -optimizer_type Adagrad -L1_flag -num_preferences 3 -nouse_st_gumbel -load_ckpt_file "$HOME/git/results/$experiment/$DATASET/ml1m-bprmf-pretrained.ckpt" & # ml-sun num_preferences = 3
        wait $!
        mv ~/git/results/$experiment/$DATASET/ml1m-transup-*.ckpt ~/git/results/$experiment/$DATASET/ml1m-transup-pretrained.ckpt
        ENDTIME=$(date +%s)
        echo -e "recommend-TRANSUP-${DATASET}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi


    #CFKG (TransE) - Yongfeng Zhang, Qingyao Ai, Xu Chen, and Pengfei Wang. 2018. Learning over Knowledge-Base Embeddings for Recommendation. In SIGIR.
    if no_exist "$HOME/git/results/$experiment/$DATASET/ml1m-cfkg-*.log"
    then
       STARTTIME=$(date +%s)
       if [ "$verbose" = true ]; then echo "[kg-summ-rec] recommend: Running CFKG with $DATASET"; fi
       CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/$experiment/$DATASET/cao-format/ -log_path ~/git/results/$experiment/$DATASET/ -rec_test_files valid.dat:test.dat  -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type cfkg -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate ${LEARNING_RATE} -topn 10 -seed ${seed} -eval_interval_steps ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[0]} -training_steps ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[1]} -early_stopping_steps_to_wait ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[2]} -optimizer_type Adam -joint_ratio 0.5 -share_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -use_st_gumbel -load_ckpt_file "$HOME/git/results/$experiment/$DATASET/ml1m-bprmf-pretrained.ckpt:$HOME/git/results/$experiment/$DATASET/ml1m-transe-pretrained.ckpt" &
       wait $!
       ENDTIME=$(date +%s)
       echo -e "recommend-CFKG-${DATASET}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi
    #CKE (TransR) - Fuzheng Zhang, Nicholas Jing Yuan, Defu Lian, Xing Xie, and Wei-Ying Ma. 2016. Collaborative Knowledge Base Embedding for Recommender Systems. In SIGKDD.
    if no_exist "$HOME/git/results/$experiment/$DATASET/ml1m-cke-*.log"
    then
       STARTTIME=$(date +%s)
       if [ "$verbose" = true ]; then echo "[kg-summ-rec] recommend: Running CKE with $DATASET"; fi
       CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/$experiment/$DATASET/cao-format/ -log_path ~/git/results/$experiment/$DATASET/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type cke -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate ${LEARNING_RATE} -topn 10 -seed ${seed} -eval_interval_steps ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[0]} -training_steps ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[1]} -early_stopping_steps_to_wait ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[2]} -optimizer_type Adam -joint_ratio 0.5 -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -use_st_gumbel -load_ckpt_file "$HOME/git/results/$experiment/$DATASET/ml1m-bprmf-pretrained.ckpt:$HOME/git/results/$experiment/$DATASET/ml1m-transe-pretrained.ckpt" &
       wait $!
       ENDTIME=$(date +%s)
       echo -e "recommend-CKE-${DATASET}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi
    #CoFM (FM+TransE) - Guangyuan Piao and John G. Breslin. 2018. Transfer Learning for Item Recommendations and Knowledge Graph Completion in Item Related Domains via a Co-Factorization Model. In ESWC.
    if no_exist "$HOME/git/results/$experiment/$DATASET/ml1m-cofm-*.log"
    then
       STARTTIME=$(date +%s)
       if [ "$verbose" = true ]; then echo "[kg-summ-rec] recommend: Running CoFM with $DATASET"; fi
       CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/$experiment/$DATASET/cao-format/ -log_path ~/git/results/$experiment/$DATASET/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type cofm -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate ${LEARNING_RATE} -topn 10 -seed ${seed} -eval_interval_steps ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[0]} -training_steps ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[1]} -early_stopping_steps_to_wait ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[2]} -optimizer_type Adam -joint_ratio 0.5 -load_ckpt_file "$HOME/git/results/$experiment/$DATASET/ml1m-bprmf-pretrained.ckpt:$HOME/git/results/$experiment/$DATASET/ml1m-transe-pretrained.ckpt" -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 &
       wait $!
       ENDTIME=$(date +%s)
       echo -e "recommend-CoFM-${DATASET}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi

    #JTransUP
    if no_exist "$HOME/git/results/$experiment/$DATASET/ml1m-jtransup-*.log"
    then
        STARTTIME=$(date +%s)
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] recommend: Running JTransUP with $DATASET"; fi
        CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/$experiment/$DATASET/cao-format/ -log_path ~/git/results/$experiment/$DATASET/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type jtransup -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate ${LEARNING_RATE} -topn 10 -seed ${seed} -eval_interval_steps ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[0]} -training_steps ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[1]} -early_stopping_steps_to_wait ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[2]} -optimizer_type Adam -joint_ratio 0.5 -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -nouse_st_gumbel -load_ckpt_file "$HOME/git/results/$experiment/$DATASET/ml1m-transup-pretrained.ckpt:$HOME/git/results/$experiment/$DATASET/ml1m-transh-pretrained.ckpt" &
        wait $!
        ENDTIME=$(date +%s)
        echo -e "recommend-KTUP-${DATASET}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi

    ####
    # Collect computational cost of $DATASET
    ####
    cd ~/git/kg-summ-rec
    if no_exist "$HOME/git/results/${experiment}/${DATASET}/comp_cost.tsv"
    then
        comp_cost "${experiment}" "${DATASET}" > "$HOME/git/results/${experiment}/${DATASET}/comp_cost.tsv"
    fi
}


append_evaluations() {
    # kg-summ-rec/evaluation
    if [[ ! $PYTHONPATH = *git/kg-summ-rec/evaluation* ]]
    then
        export PYTHONPATH="${HOME}/git/kg-summ-rec/evaluation:${PYTHONPATH}"
    fi

    local dirName="fold0/ml-sun_cv_sfKG_ig-sv-complex-25"
    cp ~/git/results/$experiment/fold${fold_number}/ml-sun_cv_oKG/ml1m-bprmf-pretrained.ckpt ~/git/results/$experiment/${dirName}/ml1m-bprmf-pretrained.ckpt
    cp ~/git/results/$experiment/fold${fold_number}/ml-sun_cv_oKG/ml1m-bprmf-1*.log ~/git/results/$experiment/${dirName}/
    cp ~/git/results/$experiment/fold${fold_number}/ml-sun_cv_oKG/ml1m-transup-pretrained.ckpt ~/git/results/$experiment/${dirName}/ml1m-transup-pretrained.ckpt
    cp ~/git/results/$experiment/fold${fold_number}/ml-sun_cv_oKG/ml1m-transup-1*.log ~/git/results/$experiment/${dirName}/
    recommend "${dirName}" '540,27000,27027' '2350,235000,11750' '235,23500,1175' '9380,234500,234969' 256 0.005 # KNOWLEDGE_REPRESENTATION 1000-epochs, TUP early_stop 10-1000-50, BPRMF early_stop 1-100-5, KNOWLEDGABLE_RECOMMENDATION 500-epochs. One epoch has 27, 235, 235, 469 steps. Proportion 20-501-500.

    local dirName="fold0/ml-sun_cv_sfKG_ig-mv-complex-25"
    cp ~/git/results/$experiment/fold${fold_number}/ml-sun_cv_oKG/ml1m-bprmf-pretrained.ckpt ~/git/results/$experiment/${dirName}/ml1m-bprmf-pretrained.ckpt
    cp ~/git/results/$experiment/fold${fold_number}/ml-sun_cv_oKG/ml1m-bprmf-1*.log ~/git/results/$experiment/${dirName}/
    cp ~/git/results/$experiment/fold${fold_number}/ml-sun_cv_oKG/ml1m-transup-pretrained.ckpt ~/git/results/$experiment/${dirName}/ml1m-transup-pretrained.ckpt
    cp ~/git/results/$experiment/fold${fold_number}/ml-sun_cv_oKG/ml1m-transup-1*.log ~/git/results/$experiment/${dirName}/
    recommend "${dirName}" '540,27000,27027' '2350,235000,11750' '235,23500,1175' '9380,234500,234969' 256 0.005 # KNOWLEDGE_REPRESENTATION 1000-epochs, TUP early_stop 10-1000-50, BPRMF early_stop 1-100-5, KNOWLEDGABLE_RECOMMENDATION 500-epochs. One epoch has 27, 235, 235, 469 steps. Proportion 20-501-500.
}


run_experiment() {
    experiment=$1
    seed=$2
    if [ "$3" = 'true' ]; then verbose=true; else verbose=false; fi
    overall_comp_cost="$HOME/git/results/${experiment}/overall_comp_cost.tsv"

    if [ ! -d "$HOME/git/datasets/${experiment}" ]
    then
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}"; fi
        mkdir "$HOME/git/datasets/${experiment}"
        mkdir "$HOME/git/results/${experiment}"
        touch ${overall_comp_cost}
    fi

    # Preprocessing
    preprocess_sun_oKG
    preprocess_sun_fKG

    # Summarization
    clean_kge-k-means
    summarize_sun_sKG
    clean_kge-k-means
    summarize_sun_sfKG

    # Recommendation
    recommend_sun_sKG
    recommend_sun_sfKG

    #append_evaluations
}

run_experiment $1 $2 $3
#bash -i examples/Sacenti-JIIS2021-revised/run_exp2-sun_cv_complex.sh "JIIS-revised-exp2" 0 'false' |& tee out-revised-exp2-10.txt
