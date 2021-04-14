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
# - Datasets: ml-cao
# - Split: hold-out (ho)
# - Filtering: infrequent entities filtering at 0 (sKG)
# - KG Summarization:
#   - Algorithms: KGE-K-Means (complex)
#   - KG type: item graph (ig)
#   - Results: kg-ig-stats.dat, logs and overall_efficiency.tsv
# - KG Recommendation:
#   - Algorithms: CFKG, CKE, CoFM, JtransUp (KTUP); TransE, TransH, BPRMF,
#   TransUp (TUP)
#   - Results: recomm_quality, comp_cost
# GLOBALS:
#   HOME
#   experiment: running experiment. Default is 'JIIS-revised-exp8'.
#   overall_comp_cost: efficiency results filepath.
# FUNCTIONS:
#   preprocess_cao_oKG
#   recommend_cao_sKG
#   run_experiments
#######################################
experiment='JIIS-revised-exp8'
overall_comp_cost="$HOME/git/results/${experiment}/overall_efficiency.tsv"

#######################################
# Import util/util.sh
# FUNCTIONS:
#   no_exist 'path_to_file'
#   copy_dataset 'path_to_dataset' 'path_to_new_dataset'
#######################################
source $HOME/git/kg-summ-rec/util/util.sh

#######################################
# Import preprocess/cao-format_ml-cao.sh
# FUNCTIONS:
#   cao-format_ml-cao 'dataset' 'low_frequence'
#######################################
source $HOME/git/kg-summ-rec/preprocess/cao-format_ml-cao.sh

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
# - Datasets: ml-cao, ml-cao
# - Split: hold-out (ho)
# - Filtering: infrequent entities filtering at 0 (oKG) and at 10 (fKG)
####
preprocess_cao_oKG() {
    if [ ! -d "$HOME/git/datasets/${experiment}/ml-cao_ho_oKG" ]
    then
        local STARTTIME=$(date +%s)
        # Create folders for cao's original KG (oKG)
        if no_exist "$HOME/git/datasets/${experiment}/ml-cao_ho_oKG"
        then
            if [ "$verbose" = true ]; then echo "[kg-summ-rec] preprocess_cao_oKG: Creating ~/git/datasets/${experiment}/ml-cao_ho_oKG"; fi
            cd $HOME/git/kg-summ-rec/util
            copy_ml_cao "$HOME/git/datasets/ml-cao" "$HOME/git/datasets/${experiment}/ml-cao_ho_oKG"
            cd $HOME/git/kg-summ-rec
        fi

        # Preprocess oKG
        cd $HOME/git/kg-summ-rec/preprocess
        LOW_FREQUENCE=0    #Low Frequence Filtering (0, 10)
        if [ "$verbose" = true ]
        then
            cao-format_ml-cao "ml-cao_ho_oKG" ${LOW_FREQUENCE} 'ho' ${seed} 'true'
        else
            cao-format_ml-cao "ml-cao_ho_oKG" ${LOW_FREQUENCE} 'ho' ${seed} 'false'
        fi
        cd $HOME/git/kg-summ-rec

        echo "experiment: $experiment"
        echo "seed: $seed"
        echo "verbose: $verbose"

        # Collect oKG statistics
        if no_exist "$HOME/git/results/${experiment}/ml-cao_ho_oKG"
        then
            if [ "$verbose" = true ]; then echo "[kg-summ-rec] preprocess_cao_oKG: Creating ~/git/results/${experiment}/ml-cao_ho_oKG"; fi
            mkdir ~/git/results/${experiment}/ml-cao_ho_oKG
        fi
        if no_exist "$HOME/git/results/${experiment}/ml-cao_ho_oKG/kg-ig_stats.tsv"
        then
            if [ "$verbose" = true ]; then echo "[kg-summ-rec] preprocess_cao_oKG: Creating ~/git/results/${experiment}/ml-cao_ho_oKG/kg-ig_stats.tsv"; fi
            cd $HOME/git/kg-summ-rec/util
            conda deactivate
            conda activate kg-summ-rec
            python kg2rdf.py --mode 'statistics' --kgpath "~/git/datasets/${experiment}/ml-cao_ho_oKG" \
            --input "~/git/datasets/${experiment}/ml-cao_ho_oKG/kg-ig.nt" \
            --output "~/git/results/${experiment}/ml-cao_ho_oKG/kg-ig_stats.tsv"
            cd $HOME/git/kg-summ-rec
        fi

        local ENDTIME=$(date +%s)
        echo -e "preprocess_cao_oKG\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi
}

####
# recommend_cao_sKG
#
# - ml-cao_ho_oKG reruns
#####
recommend_cao_oKG() {
    local reruns=$1

    # kg-summ-rec/evaluation
    if [[ ! $PYTHONPATH = *git/kg-summ-rec/evaluation* ]]
    then
        export PYTHONPATH="${HOME}/git/kg-summ-rec/evaluation:${PYTHONPATH}"
    fi

    kg_recommendation_rerun "ml-cao_ho_oKG" ${reruns}
}

kg_recommendation_rerun() {
    local dataset_in=$1
    local reruns=$2

    for ((i = 0; i < reruns; i++))
    do
        local dataset_out="${dataset_in}_rec_cao"
        ############################################################################
        ###                        Create dataset Folders                        ###
        ############################################################################
        if [ ! -d "$HOME/git/results/${experiment}/${dataset_out}" ]
        then
            echo "[kg-summ-rec] Creating ~/git/results/${experiment}/${dataset_out}"
            mkdir ~/git/results/${experiment}/${dataset_out}/
        fi
        echo "[kg-summ-rec] kg_recommendation: Creating ~/git/results/${experiment}/${dataset_out}/*.log"
        recommend_cao "${dataset_in}" "${dataset_out}"
        # local dataset_out="${dataset_in}_epochs_run_${i}"
        # ############################################################################
        # ###                        Create dataset Folders                        ###
        # ############################################################################
        # if [ ! -d "$HOME/git/results/${experiment}/${dataset_out}" ]
        # then
        #     echo "[kg-summ-rec] Creating ~/git/results/${experiment}/${dataset_out}"
        #     mkdir ~/git/results/${experiment}/${dataset_out}/
        # fi
        # echo "[kg-summ-rec] kg_recommendation: Creating ~/git/results/${experiment}/${dataset_out}/*.log"
        #
        # recommend "${dataset_in}" "${dataset_out}" '11880,1188000,59400' '274100,27410000,1370500' '27410,2741000,137050' '54820,5482000,274100' '256,256,256,256' '0.001,0.005,0.005,0.005'
        #
        # local dataset_out="${dataset_in}_epochs_run_${i}-2"
        # ############################################################################
        # ###                        Create dataset Folders                        ###
        # ############################################################################
        # if [ ! -d "$HOME/git/results/${experiment}/${dataset_out}" ]
        # then
        #     echo "[kg-summ-rec] Creating ~/git/results/${experiment}/${dataset_out}"
        #     mkdir ~/git/results/${experiment}/${dataset_out}/
        # fi
        # echo "[kg-summ-rec] kg_recommendation: Creating ~/git/results/${experiment}/${dataset_out}/*.log"
        #
        # recommend "${dataset_in}" "${dataset_out}" '11880,1188000,59400' '7000,700000,35000' '7000,700000,35000' '35000,3500000,175000' '1024,1024,1024,400' '0.001,0.005,0.001,0.001'

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

    local NUM_PROCESSES=2
    #[CFKG] (TransE) - Yongfeng Zhang, Qingyao Ai, Xu Chen, and Pengfei Wang. 2018. Learning over Knowledge-Base Embeddings for Recommendation. In SIGIR.
    STARTTIME=$(date +%s)
    if [ "$verbose" = true ]; then echo "[kg-summ-rec] recommend: Running CFKG4 with ${dataset_out}"; fi
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -num_processes ${NUM_PROCESSES} -L1_flag -batch_size 400 -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -dataset ml1m -early_stopping_steps_to_wait 175000 -embedding_size 100 -eval_interval_steps 35000 -nohas_visualization -joint_ratio 0.5 -kg_lambda 1 -kg_test_files valid.dat:test.dat -l2_lambda 0 -learning_rate 0.001 -load_ckpt_file "$HOME/git/results/${experiment}/${dataset_out}/ml1m-bprmf-pretrained1.ckpt:$HOME/git/results/${experiment}/${dataset_out}/ml1m-transe-pretrained2.ckpt" -log_path ~/git/results/${experiment}/${dataset_out}/ -model_type cfkg -negtive_samples 1 -norm_lambda 1 -optimizer_type Adam -rec_test_files valid.dat:test.dat -seed 3 -share_embeddings -topn 10 -training_steps 3500000 -nouse_st_gumbel &
    resource_usage $! 1800 "${HOME}/git/results/${experiment}/${dataset_out}/cfkg4-resource_usage.csv"
    wait $!
    ENDTIME=$(date +%s)
    echo -e "recommend-CFKG4-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}

    NUM_PROCESSES=6
    #[CFKG] (TransE) - Yongfeng Zhang, Qingyao Ai, Xu Chen, and Pengfei Wang. 2018. Learning over Knowledge-Base Embeddings for Recommendation. In SIGIR.
    STARTTIME=$(date +%s)
    if [ "$verbose" = true ]; then echo "[kg-summ-rec] recommend: Running CFKG5 with ${dataset_out}"; fi
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -num_processes ${NUM_PROCESSES} -L1_flag -batch_size 400 -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -dataset ml1m -early_stopping_steps_to_wait 175000 -embedding_size 100 -eval_interval_steps 35000 -nohas_visualization -joint_ratio 0.5 -kg_lambda 1 -kg_test_files valid.dat:test.dat -l2_lambda 0 -learning_rate 0.001 -load_ckpt_file "$HOME/git/results/${experiment}/${dataset_out}/ml1m-bprmf-pretrained1.ckpt:$HOME/git/results/${experiment}/${dataset_out}/ml1m-transe-pretrained2.ckpt" -log_path ~/git/results/${experiment}/${dataset_out}/ -model_type cfkg -negtive_samples 1 -norm_lambda 1 -optimizer_type Adam -rec_test_files valid.dat:test.dat -seed 3 -share_embeddings -topn 10 -training_steps 3500000 -nouse_st_gumbel &
    resource_usage $! 1800 "${HOME}/git/results/${experiment}/${dataset_out}/cfkg5-resource_usage.csv"
    wait $!
    ENDTIME=$(date +%s)
    echo -e "recommend-CFKG5-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}


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

    echo "1. experiment: $experiment"
    echo "1. seed: $seed"
    echo "1. verbose: $verbose"

    if [ ! -d "$HOME/git/datasets/${experiment}" ]
    then
       echo "[kg-summ-rec] Creating ~/git/datasets/${experiment}"
       mkdir "$HOME/git/datasets/${experiment}"
       mkdir "$HOME/git/results/${experiment}"
       touch ${overall_comp_cost}
    fi

    # Preprocessing
    preprocess_cao_oKG

    # Recommendation
    recommend_cao_oKG '1'
}
run_experiment $1 $2 $3
#bash -i examples/Sacenti-JIIS2021-revised/run_exp8-cao-epochs.sh "JIIS-revised-exp8" 3 'true' |& tee out-exp8-1.txt
