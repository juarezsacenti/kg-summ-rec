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
# - Datasets: ml-sun, ml-cao
# - Split: hold-out (ho)
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
experiment='Sacenti-JIIS2021-revised-summ'
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
# Import ../summarization/kge-k-means-ratio.sh
# FUNCTIONS:
#   kge-k-means 'experiment' 'dataset_in' 'dataset_out' 'kg_type' 'summarization_mode' 'kge' 'epochs' 'batch_size' learning_rate' 'low_frequence' 'ratios'
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
# - Datasets: ml-sun, ml-cao
# - Split: hold-out (ho)
# - Filtering: infrequent entities filtering at 0 (oKG) and at 10 (fKG)
####
preprocess_sun_oKG() {
    local STARTTIME=$(date +%s)
    # Create folders for Sun's original KG (oKG)
    if no_exist "$HOME/git/datasets/${experiment}/ml-sun_ho_oKG"
    then
        echo "[kg-summ-rec] preprocess_sun_oKG: Creating ~/git/datasets/${experiment}/ml-sun_ho_oKG"
        cd $HOME/git/kg-summ-rec/util
        copy_ml_sun "$HOME/git/datasets/ml-sun" "$HOME/git/datasets/${experiment}/ml-sun_ho_oKG"
        cd $HOME/git/kg-summ-rec
    fi

    # Preprocess oKG
    cd $HOME/git/kg-summ-rec/preprocess
    LOW_FREQUENCE=0    #Low Frequence Filtering (0, 10)
    cao-format_ml-sun "ml-sun_ho_oKG" ${LOW_FREQUENCE}
    cd $HOME/git/kg-summ-rec

    # Collect oKG statistics
    if no_exist "$HOME/git/results/${experiment}/ml-sun_ho_oKG"
    then
        echo "[kg-summ-rec] preprocess_sun_oKG: Creating ~/git/results/${experiment}/ml-sun_ho_oKG"
        mkdir ~/git/results/${experiment}/ml-sun_ho_oKG
    fi
    if no_exist "$HOME/git/results/${experiment}/ml-sun_ho_oKG/kg-ig_stats.tsv"
    then
        echo "[kg-summ-rec] preprocess_sun_oKG: Creating ~/git/results/${experiment}/ml-sun_ho_oKG/kg-ig_stats.tsv"
        cd $HOME/git/kg-summ-rec/util
        conda deactivate
        conda activate kg-summ-rec
        python kg2rdf.py --mode 'statistics' --kgpath "~/git/datasets/${experiment}/ml-sun_ho_oKG" \
        --input "~/git/datasets/${experiment}/ml-sun_ho_oKG/kg-ig.nt" \
        --output "~/git/results/${experiment}/ml-sun_ho_oKG/kg-ig_stats.tsv"
        cd $HOME/git/kg-summ-rec
    fi

    local ENDTIME=$(date +%s)
    echo -e "preprocess_sun_oKG\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
}

####
# KG summarization
#
# - Datasets: ml-sun, ml-cao
# - Split: hold-out (ho)
# - Filtering: infrequent entities filtering at 0 (sKG) and at 10 (sfKG)
####
summarize_sun_sKG() {
    # KG summarization
    kg_summarization 'ml-sun' 'ho' 'sKG'
}

kg_summarization() {
    local dataset=$1 # Input dataset: ml-sun, ml-cao
    local split_mode=$2 # Split mode: hold-out (ho)
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
    local kge='transe'
    local epochs='300'
    local batch_size='10'
    local learning_rate='0.0005'
    local kg_filename="kg-${kg_type}.nt"
    #local ratios='5,25,50,75'
    local ratios='5'
    local summarization_mode='sv'

    local STARTTIME=$(date +%s)
    # TODO IF no exist
    clean_kge-k-means
    kge-k-means ${experiment} ${dataset_in} "${dataset_out}_${kg_type}-${summarization_mode}" ${kg_filename} ${summarization_mode} ${kge} ${epochs} ${batch_size} ${learning_rate} ${low_frequence} ${ratios}
    local ENDTIME=$(date +%s)
    echo -e "summarize-${dataset_out}_${kg_type}-${summarization_mode}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}

    summarization_mode='mv'

    STARTTIME=$(date +%s)
    # TODO IF no exist
    clean_kge-k-means
    kge-k-means ${experiment} ${dataset_in} "${dataset_out}_${kg_type}-${summarization_mode}" ${kg_filename} ${summarization_mode} ${kge} ${epochs} ${batch_size} ${learning_rate} ${low_frequence} ${ratios}
    ENDTIME=$(date +%s)
    echo -e "summarize-${dataset_out}_${kg_type}-${summarization_mode}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}

    local kge='complex'
    local summarization_mode='sv'

    local STARTTIME=$(date +%s)
    # TODO IF no exist
    clean_kge-k-means
    kge-k-means ${experiment} ${dataset_in} "${dataset_out}_${kg_type}-${summarization_mode}" ${kg_filename} ${summarization_mode} ${kge} ${epochs} ${batch_size} ${learning_rate} ${low_frequence} ${ratios}
    local ENDTIME=$(date +%s)
    echo -e "summarize-${dataset_out}_${kg_type}-${summarization_mode}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}

    summarization_mode='mv'

    STARTTIME=$(date +%s)
    # TODO IF no exist
    clean_kge-k-means
    kge-k-means ${experiment} ${dataset_in} "${dataset_out}_${kg_type}-${summarization_mode}" ${kg_filename} ${summarization_mode} ${kge} ${epochs} ${batch_size} ${learning_rate} ${low_frequence} ${ratios}
    ENDTIME=$(date +%s)
    echo -e "summarize-${dataset_out}_${kg_type}-${summarization_mode}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
}

preprocess_summ() {
    local dataset_in=$1
    local dataset_out=$2
    local kg_type=$3
    local low_frequence=$4

    cd $HOME/git/kg-summ-rec/preprocess

    summ_modes=(sv mv)
    summ_algos=(transe complex)
    #summ_rates=(5 25 50 75)
    summ_rates=(5)
    local STARTTIME=0
    local ENDTIME=0
    for m in "${summ_modes[@]}"
    do
        for a in "${summ_algos[@]}"
        do
            for r in "${summ_rates[@]}"
            do
                STARTTIME=$(date +%s)
                cao-format_summ "${dataset_in}" "${dataset_out}_${kg_type}-${m}-${a}-${r}" "${low_frequence}"
                ENDTIME=$(date +%s)
                echo -e "preprocess_summ-${dataset_out}_${kg_type}-${m}-${a}-${r}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
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
    summ_algos=(transe complex)
    #summ_rates=(5 25 50 75)
    summ_rates=(5)
    local STARTTIME=0
    local ENDTIME=0
    for m in "${summ_modes[@]}"
    do
        for a in "${summ_algos[@]}"
        do
            for r in "${summ_rates[@]}"
            do
                local dirName="${dataset_out}_${kg_type}-${m}-${a}-${r}"
                if no_exist "$HOME/git/results/${experiment}/${dirName}/kg-ig_stats.tsv"
                then
                    STARTTIME=$(date +%s)
                    echo "[kg-summ-rec] measure_summ_impact: Creating ~/git/results/${experiment}/${dirName}/kg-ig_stats.tsv"
                    python kg2rdf.py --mode 'statistics' --kgpath "$HOME/git/datasets/${experiment}/${dirName}" \
                    --input "$HOME/git/datasets/${experiment}/${dirName}/kg-ig.nt" \
                    --output "$HOME/git/results/${experiment}/${dirName}/kg-ig_stats.tsv"
                    ENDTIME=$(date +%s)
                    echo -e "measure_summ_impact-${dirName}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
                fi
            done
        done
    done

    cd $HOME/git/kg-summ-rec
}

recommend_sun_sKG() {
    # kg-summ-rec/evaluation
    if [[ ! $PYTHONPATH = *git/kg-summ-rec/evaluation* ]]
    then
        export PYTHONPATH="${HOME}/git/kg-summ-rec/evaluation:${PYTHONPATH}"
    fi

    kg_recommendation "ml-sun_ho_oKG" "ml-sun_ho_sKG"
}

kg_recommendation() {
    local dataset_in=$1
    local dataset_out=$2

    summ_types=(ig)
    summ_modes=(sv mv)
    summ_algos=(transe complex)
    #summ_rates=(5 25 50 75)
    summ_rates=(50)
    for t in "${summ_types[@]}"
    do
        for m in "${summ_modes[@]}"
        do
            for a in "${summ_algos[@]}"
            do
                for r in "${summ_rates[@]}"
                do
                    local dirName="${dataset_out}_${t}-${m}-${a}-${r}"
                    echo "[kg-summ-rec] kg_recommendation: Creating ~/git/results/${experiment}/${dirName}/*.log"
                    recommend "${dirName}" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005
                done
            done
        done
    done


    echo "[kg-summ-rec] kg_recommendation: Creating ~/git/results/${experiment}/${dataset_in}/*.log"
    recommend "${dataset_in}" '4873,487300,24363' '2663,266300,13317' '266,26630,1331' '10392,1039200,51960' 256 0.005

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
        echo "[kg-summ-rec] recommend: Running TransE with $DATASET"
        CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -data_path ~/git/datasets/$experiment/$DATASET/cao-format/ -log_path ~/git/results/$experiment/$DATASET/ -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type transe -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate 0.001 -topn 10 -seed 3 -eval_interval_steps ${KNOWLEDGE_REPRESENTATION_EPOCHS[0]} -training_steps ${KNOWLEDGE_REPRESENTATION_EPOCHS[1]} -early_stopping_steps_to_wait ${KNOWLEDGE_REPRESENTATION_EPOCHS[2]} -optimizer_type Adam -L1_flag -norm_lambda 1 -kg_lambda 1 &
        wait $!
        mv ~/git/results/$experiment/$DATASET/ml1m-transe-*.ckpt_final ~/git/results/$experiment/$DATASET/ml1m-transe-pretrained.ckpt
        ENDTIME=$(date +%s)
        echo -e "recommend-TRANSE-${DATASET}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi

    #[TRANSH]
    if no_exist "$HOME/git/results/$experiment/$DATASET/ml1m-transh-*.log"
    then
        STARTTIME=$(date +%s)
        echo "[kg-summ-rec] recommend: Running TransH with $DATASET"
        CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -data_path ~/git/datasets/$experiment/$DATASET/cao-format/ -log_path ~/git/results/$experiment/$DATASET/ -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type transh -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate 0.001 -topn 10 -seed 3 -eval_interval_steps ${KNOWLEDGE_REPRESENTATION_EPOCHS[0]} -training_steps ${KNOWLEDGE_REPRESENTATION_EPOCHS[1]} -early_stopping_steps_to_wait ${KNOWLEDGE_REPRESENTATION_EPOCHS[2]} -optimizer_type Adam -L1_flag -norm_lambda 1 -kg_lambda 1 -load_ckpt_file "$HOME/git/results/$experiment/$DATASET/ml1m-transe-pretrained.ckpt" &
        wait $!
        mv ~/git/results/$experiment/$DATASET/ml1m-transh-*.ckpt_final ~/git/results/$experiment/$DATASET/ml1m-transh-pretrained.ckpt
        ENDTIME=$(date +%s)
        echo -e "recommend-TRANSH-${DATASET}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi

    #BPRMF - Steffen Rendle, Christoph Freudenthaler, Zeno Gantner, and Lars Schmidt-Thieme. 2009. BPR: Bayesian personalized ranking from implicit feedback. In UAI.
    if no_exist "$HOME/git/results/$experiment/$DATASET/ml1m-bprmf-*.log"
    then
        STARTTIME=$(date +%s)
        echo "[kg-summ-rec] recommend: Running BPRMF with $DATASET"
        CUDA_VISIBLE_DEVICES=0 nohup python run_item_recommendation.py -data_path ~/git/datasets/$experiment/$DATASET/cao-format/ -log_path ~/git/results/$experiment/$DATASET/ -rec_test_files valid.dat:test.dat -l2_lambda 1e-5 -negtive_samples 1 -model_type bprmf -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate ${LEARNING_RATE} -topn 10 -seed 3 -eval_interval_steps ${ITEM_RECOMMENDATION_EPOCHS[0]} -training_steps ${ITEM_RECOMMENDATION_EPOCHS[1]} -early_stopping_steps_to_wait ${ITEM_RECOMMENDATION_EPOCHS[2]} -optimizer_type Adagrad &
        wait $!
        mv ~/git/results/$experiment/$DATASET/ml1m-bprmf-*.ckpt ~/git/results/$experiment/$DATASET/ml1m-bprmf-pretrained.ckpt
        ENDTIME=$(date +%s)
        echo -e "recommend-BPRMF-${DATASET}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi

    #TransUP
    if no_exist "$HOME/git/results/$experiment/$DATASET/ml1m-transup-*.log"
    then
        STARTTIME=$(date +%s)
        echo "[kg-summ-rec] recommend: Running TransUP with $DATASET"
        CUDA_VISIBLE_DEVICES=0 nohup python run_item_recommendation.py -data_path ~/git/datasets/$experiment/$DATASET/cao-format/ -log_path ~/git/results/$experiment/$DATASET/ -rec_test_files valid.dat:test.dat -l2_lambda 1e-5 -negtive_samples 1 -model_type transup -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate ${LEARNING_RATE} -topn 10 -seed 3 -eval_interval_steps ${TUP_EPOCHS[0]} -training_steps ${TUP_EPOCHS[1]} -early_stopping_steps_to_wait ${TUP_EPOCHS[2]} -optimizer_type Adagrad -L1_flag -num_preferences 3 -nouse_st_gumbel -load_ckpt_file "$HOME/git/results/$experiment/$DATASET/ml1m-bprmf-pretrained.ckpt" & # ml-sun num_preferences = 3
        wait $!
        mv ~/git/results/$experiment/$DATASET/ml1m-transup-*.ckpt ~/git/results/$experiment/$DATASET/ml1m-transup-pretrained.ckpt
        ENDTIME=$(date +%s)
        echo -e "recommend-TRANSUP-${DATASET}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi
    #JTransUP
    if no_exist "$HOME/git/results/$experiment/$DATASET/ml1m-jtransup-*.log"
    then
        STARTTIME=$(date +%s)
        echo "[kg-summ-rec] recommend:  Running JTransUP with $DATASET"
        CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/$experiment/$DATASET/cao-format/ -log_path ~/git/results/$experiment/$DATASET/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type jtransup -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate ${LEARNING_RATE} -topn 10 -seed 3 -eval_interval_steps ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[0]} -training_steps ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[1]} -early_stopping_steps_to_wait ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[2]} -optimizer_type Adam -joint_ratio 0.5 -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -nouse_st_gumbel -load_ckpt_file "$HOME/git/results/$experiment/$DATASET/ml1m-transup-pretrained.ckpt:$HOME/git/results/$experiment/$DATASET/ml1m-transh-pretrained.ckpt" &
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

run_experiment() {
    experiment=$1
    overall_comp_cost="$HOME/git/results/${experiment}/overall_comp_cost.tsv"

    if [ ! -d "$HOME/git/datasets/${experiment}" ]
    then
       echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}"
       mkdir "$HOME/git/datasets/${experiment}"
       mkdir "$HOME/git/results/${experiment}"
       touch ${overall_comp_cost}
    fi

    # Preprocessing
    preprocess_sun_oKG

    # Summarization
    summarize_sun_sKG

    # Recomendation
    recommend_sun_sKG

}
run_experiment $1
