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
        local dataset_out="${dataset_in}_epochs_run_$i"
        ############################################################################
        ###                        Create dataset Folders                        ###
        ############################################################################
        if [ ! -d "$HOME/git/results/${experiment}/${dataset_out}" ]
        then
            echo "[kg-summ-rec] Creating ~/git/results/${experiment}/${dataset_out}"
            mkdir ~/git/results/${experiment}/${dataset_out}/
        fi
        echo "[kg-summ-rec] kg_recommendation: Creating ~/git/results/${experiment}/${dataset_out}/*.log"

        recommend "${dataset_in}" "${dataset_out}" '11880,1188000,59400' '27410,2741000,137050' '274100,27410000,1370500' '54820,5482000,274100' 256 0.005

    done

    cd $HOME/git/kg-summ-rec
}

recommend() {
    local dataset_in=$1
    local dataset_out=$2
    # EPOCHS
    IFS=', ' read -r -a KNOWLEDGE_REPRESENTATION_EPOCHS <<< "$3"
    IFS=', ' read -r -a TUP_EPOCHS <<< "$4"
    IFS=', ' read -r -a ITEM_RECOMMENDATION_EPOCHS <<< "$5"
    IFS=', ' read -r -a KNOWLEDGABLE_RECOMMENDATION_EPOCHS <<< "$6"
    # BATCH SIZE
    local BATCH_SIZE=$7
    # LEARNING RATE
    local LEARNING_RATE=$8

    cd ~/git/joint-kg-recommender

    #[activate jointrec]
    conda deactivate
    conda activate jointrec

    local STARTTIME=0
    local ENDTIME=0
    #[TRANSE]
    if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-transe-*.log"
    then
        STARTTIME=$(date +%s)
        echo "[kg-summ-rec] recommend: Running TransE with ${dataset_out}"
        CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -log_path ~/git/results/${experiment}/${dataset_out}/ -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type transe -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate 0.001 -topn 10 -seed 3 -eval_interval_steps ${KNOWLEDGE_REPRESENTATION_EPOCHS[0]} -training_steps ${KNOWLEDGE_REPRESENTATION_EPOCHS[1]} -early_stopping_steps_to_wait ${KNOWLEDGE_REPRESENTATION_EPOCHS[2]} -optimizer_type Adam -L1_flag -norm_lambda 1 -kg_lambda 1 &
        wait $!
        mv ~/git/results/${experiment}/${dataset_out}/ml1m-transe-*.ckpt_final ~/git/results/${experiment}/${dataset_out}/ml1m-transe-pretrained.ckpt
        ENDTIME=$(date +%s)
        echo -e "recommend-TRANSE-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi

    #[TRANSH]
    # if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-transh-*.log"
    # then
    #     STARTTIME=$(date +%s)
    #     echo "[kg-summ-rec] recommend: Running TransH with ${dataset_out}"
    #     CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -log_path ~/git/results/${experiment}/${dataset_out}/ -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type transh -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate 0.001 -topn 10 -seed 3 -eval_interval_steps ${KNOWLEDGE_REPRESENTATION_EPOCHS[0]} -training_steps ${KNOWLEDGE_REPRESENTATION_EPOCHS[1]} -early_stopping_steps_to_wait ${KNOWLEDGE_REPRESENTATION_EPOCHS[2]} -optimizer_type Adam -L1_flag -norm_lambda 1 -kg_lambda 1 -load_ckpt_file "$HOME/git/results/${experiment}/${dataset_out}/ml1m-transe-pretrained.ckpt" &
    #     wait $!
    #     mv ~/git/results/${experiment}/${dataset_out}/ml1m-transh-*.ckpt_final ~/git/results/${experiment}/${dataset_out}/ml1m-transh-pretrained.ckpt
    #     ENDTIME=$(date +%s)
    #     echo -e "recommend-TRANSH-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    # fi

    #BPRMF - Steffen Rendle, Christoph Freudenthaler, Zeno Gantner, and Lars Schmidt-Thieme. 2009. BPR: Bayesian personalized ranking from implicit feedback. In UAI.
    if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-bprmf-*.log"
    then
        STARTTIME=$(date +%s)
        echo "[kg-summ-rec] recommend: Running BPRMF with ${dataset_out}"
        CUDA_VISIBLE_DEVICES=0 nohup python run_item_recommendation.py -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -log_path ~/git/results/${experiment}/${dataset_out}/ -rec_test_files valid.dat:test.dat -l2_lambda 1e-5 -negtive_samples 1 -model_type bprmf -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate ${LEARNING_RATE} -topn 10 -seed 3 -eval_interval_steps ${ITEM_RECOMMENDATION_EPOCHS[0]} -training_steps ${ITEM_RECOMMENDATION_EPOCHS[1]} -early_stopping_steps_to_wait ${ITEM_RECOMMENDATION_EPOCHS[2]} -optimizer_type Adagrad &
        wait $!
        mv ~/git/results/${experiment}/${dataset_out}/ml1m-bprmf-*.ckpt ~/git/results/${experiment}/${dataset_out}/ml1m-bprmf-pretrained.ckpt
        ENDTIME=$(date +%s)
        echo -e "recommend-BPRMF-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi

    #TransUP
    # if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-transup-*.log"
    # then
    #     STARTTIME=$(date +%s)
    #     echo "[kg-summ-rec] recommend: Running TransUP with ${dataset_out}"
    #     CUDA_VISIBLE_DEVICES=0 nohup python run_item_recommendation.py -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -log_path ~/git/results/${experiment}/${dataset_out}/ -rec_test_files valid.dat:test.dat -l2_lambda 1e-5 -negtive_samples 1 -model_type transup -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate ${LEARNING_RATE} -topn 10 -seed 3 -eval_interval_steps ${TUP_EPOCHS[0]} -training_steps ${TUP_EPOCHS[1]} -early_stopping_steps_to_wait ${TUP_EPOCHS[2]} -optimizer_type Adagrad -L1_flag -num_preferences 3 -nouse_st_gumbel -load_ckpt_file "$HOME/git/results/${experiment}/${dataset_out}/ml1m-bprmf-pretrained.ckpt" & # ml-cao num_preferences = 3
    #     wait $!
    #     mv ~/git/results/${experiment}/${dataset_out}/ml1m-transup-*.ckpt ~/git/results/${experiment}/${dataset_out}/ml1m-transup-pretrained.ckpt
    #     ENDTIME=$(date +%s)
    #     echo -e "recommend-TRANSUP-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    # fi

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

    #JTransUP - eval: 1 epoch; early: 5 epochs; max: 1500 epochs
    # if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-jtransup-*.log"
    # then
    #     STARTTIME=$(date +%s)
    #     echo "[kg-summ-rec] recommend:  Running JTransUP with ${dataset_out}"
    #     CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -log_path ~/git/results/${experiment}/${dataset_out}/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type jtransup -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate ${LEARNING_RATE} -topn 10 -seed 3 -eval_interval_steps '547' -training_steps '820500' -early_stopping_steps_to_wait '2735' -optimizer_type Adam -joint_ratio 0.5 -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -nouse_st_gumbel -load_ckpt_file "$HOME/git/results/${experiment}/${dataset_out}/ml1m-transup-pretrained.ckpt:$HOME/git/results/${experiment}/${dataset_out}/ml1m-transh-pretrained.ckpt" &
    #     wait $!
    #     ENDTIME=$(date +%s)
    #     echo -e "recommend-KTUP-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    # fi
    #
    # #JTransUP - eval: 1 epochs; early: 50 epochs; max: 1500 epochs
    # #if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-jtransup-*.log"
    # #then
    # STARTTIME=$(date +%s)
    # echo "[kg-summ-rec] recommend:  Running JTransUP with ${dataset_out}"
    # CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -log_path ~/git/results/${experiment}/${dataset_out}/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type jtransup -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate ${LEARNING_RATE} -topn 10 -seed 3 -eval_interval_steps '547' -training_steps '820500' -early_stopping_steps_to_wait '27350' -optimizer_type Adam -joint_ratio 0.5 -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -nouse_st_gumbel -load_ckpt_file "$HOME/git/results/${experiment}/${dataset_out}/ml1m-transup-pretrained.ckpt:$HOME/git/results/${experiment}/${dataset_out}/ml1m-transh-pretrained.ckpt" &
    # wait $!
    # ENDTIME=$(date +%s)
    # echo -e "recommend-KTUP-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    # #fi
    #
    # #JTransUP - eval: 1 epochs; early: 100 epochs; max: 1500 epochs
    # #if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-jtransup-*.log"
    # #then
    # STARTTIME=$(date +%s)
    # echo "[kg-summ-rec] recommend:  Running JTransUP with ${dataset_out}"
    # CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -log_path ~/git/results/${experiment}/${dataset_out}/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type jtransup -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate ${LEARNING_RATE} -topn 10 -seed 3 -eval_interval_steps '547' -training_steps '820500' -early_stopping_steps_to_wait '54700' -optimizer_type Adam -joint_ratio 0.5 -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -nouse_st_gumbel -load_ckpt_file "$HOME/git/results/${experiment}/${dataset_out}/ml1m-transup-pretrained.ckpt:$HOME/git/results/${experiment}/${dataset_out}/ml1m-transh-pretrained.ckpt" &
    # wait $!
    # ENDTIME=$(date +%s)
    # echo -e "recommend-KTUP-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    # #fi
    #
    # #JTransUP - eval: 5 epochs; early: 50 epochs; max: 1500 epochs
    # #if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-jtransup-*.log"
    # #then
    # STARTTIME=$(date +%s)
    # echo "[kg-summ-rec] recommend:  Running JTransUP with ${dataset_out}"
    # CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -log_path ~/git/results/${experiment}/${dataset_out}/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type jtransup -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate ${LEARNING_RATE} -topn 10 -seed 3 -eval_interval_steps '2735' -training_steps '820500' -early_stopping_steps_to_wait '27350' -optimizer_type Adam -joint_ratio 0.5 -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -nouse_st_gumbel -load_ckpt_file "$HOME/git/results/${experiment}/${dataset_out}/ml1m-transup-pretrained.ckpt:$HOME/git/results/${experiment}/${dataset_out}/ml1m-transh-pretrained.ckpt" &
    # wait $!
    # ENDTIME=$(date +%s)
    # echo -e "recommend-KTUP-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    # #fi
    #
    # #JTransUP - eval: 5 epochs; early: 100 epochs; max: 1500 epochs
    # #if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-jtransup-*.log"
    # #then
    # STARTTIME=$(date +%s)
    # echo "[kg-summ-rec] recommend:  Running JTransUP with ${dataset_out}"
    # CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -log_path ~/git/results/${experiment}/${dataset_out}/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type jtransup -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate ${LEARNING_RATE} -topn 10 -seed 3 -eval_interval_steps '2735' -training_steps '820500' -early_stopping_steps_to_wait '54700' -optimizer_type Adam -joint_ratio 0.5 -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -nouse_st_gumbel -load_ckpt_file "$HOME/git/results/${experiment}/${dataset_out}/ml1m-transup-pretrained.ckpt:$HOME/git/results/${experiment}/${dataset_out}/ml1m-transh-pretrained.ckpt" &
    # wait $!
    # ENDTIME=$(date +%s)
    # echo -e "recommend-KTUP-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    # #fi
    #
    # #JTransUP - eval: 20 epochs; early: 100 epochs; max: 1500 epochs
    # #if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-jtransup-*.log"
    # #then
    # STARTTIME=$(date +%s)
    # echo "[kg-summ-rec] recommend:  Running JTransUP with ${dataset_out}"
    # CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -log_path ~/git/results/${experiment}/${dataset_out}/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type jtransup -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate ${LEARNING_RATE} -topn 10 -seed 3 -eval_interval_steps '10940' -training_steps '820500' -early_stopping_steps_to_wait '54700' -optimizer_type Adam -joint_ratio 0.5 -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -nouse_st_gumbel -load_ckpt_file "$HOME/git/results/${experiment}/${dataset_out}/ml1m-transup-pretrained.ckpt:$HOME/git/results/${experiment}/${dataset_out}/ml1m-transh-pretrained.ckpt" &
    # wait $!
    # ENDTIME=$(date +%s)
    # echo -e "recommend-KTUP-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    # #fi
    #
    # #JTransUP - eval: 1 epoch; early: 501 epochs; max: 500 epochs
    # #if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-jtransup-*.log"
    # #then
    # STARTTIME=$(date +%s)
    # echo "[kg-summ-rec] recommend:  Running JTransUP with ${dataset_out}"
    # CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -log_path ~/git/results/${experiment}/${dataset_out}/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type jtransup -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate ${LEARNING_RATE} -topn 10 -seed 3 -eval_interval_steps '547' -training_steps '273500' -early_stopping_steps_to_wait '273501' -optimizer_type Adam -joint_ratio 0.5 -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -nouse_st_gumbel -load_ckpt_file "$HOME/git/results/${experiment}/${dataset_out}/ml1m-transup-pretrained.ckpt:$HOME/git/results/${experiment}/${dataset_out}/ml1m-transh-pretrained.ckpt" &
    # wait $!
    # ENDTIME=$(date +%s)
    # echo -e "recommend-KTUP-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    # #fi
    #
    # #JTransUP - eval: 5 epoch; early: 501 epochs; max: 500 epochs
    # #if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-jtransup-*.log"
    # #then
    # STARTTIME=$(date +%s)
    # echo "[kg-summ-rec] recommend:  Running JTransUP with ${dataset_out}"
    # CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -log_path ~/git/results/${experiment}/${dataset_out}/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type jtransup -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate ${LEARNING_RATE} -topn 10 -seed 3 -eval_interval_steps '2735' -training_steps '273500' -early_stopping_steps_to_wait '273501' -optimizer_type Adam -joint_ratio 0.5 -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -nouse_st_gumbel -load_ckpt_file "$HOME/git/results/${experiment}/${dataset_out}/ml1m-transup-pretrained.ckpt:$HOME/git/results/${experiment}/${dataset_out}/ml1m-transh-pretrained.ckpt" &
    # wait $!
    # ENDTIME=$(date +%s)
    # echo -e "recommend-KTUP-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    # #fi
    #
    # #JTransUP - eval: 20 epoch; early: 501 epochs; max: 500 epochs
    # #if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-jtransup-*.log"
    # #then
    # STARTTIME=$(date +%s)
    # echo "[kg-summ-rec] recommend:  Running JTransUP with ${dataset_out}"
    # CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -log_path ~/git/results/${experiment}/${dataset_out}/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type jtransup -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate ${LEARNING_RATE} -topn 10 -seed 3 -eval_interval_steps '10940' -training_steps '273500' -early_stopping_steps_to_wait '273501' -optimizer_type Adam -joint_ratio 0.5 -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -nouse_st_gumbel -load_ckpt_file "$HOME/git/results/${experiment}/${dataset_out}/ml1m-transup-pretrained.ckpt:$HOME/git/results/${experiment}/${dataset_out}/ml1m-transh-pretrained.ckpt" &
    # wait $!
    # ENDTIME=$(date +%s)
    # echo -e "recommend-KTUP-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    # #fi
    #
    # #JTransUP - eval: 501 epoch; early: 501 epochs; max: 500 epochs
    # #if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-jtransup-*.log"
    # #then
    # STARTTIME=$(date +%s)
    # echo "[kg-summ-rec] recommend:  Running JTransUP with ${dataset_out}"
    # CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -log_path ~/git/results/${experiment}/${dataset_out}/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type jtransup -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate ${LEARNING_RATE} -topn 10 -seed 3 -eval_interval_steps '273501' -training_steps '273500' -early_stopping_steps_to_wait '273501' -optimizer_type Adam -joint_ratio 0.5 -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -nouse_st_gumbel -load_ckpt_file "$HOME/git/results/${experiment}/${dataset_out}/ml1m-transup-pretrained.ckpt:$HOME/git/results/${experiment}/${dataset_out}/ml1m-transh-pretrained.ckpt" &
    # wait $!
    # ENDTIME=$(date +%s)
    # echo -e "recommend-KTUP-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    # #fi

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
    overall_comp_cost="$HOME/git/results/${experiment}/overall_comp_cost-exp6.tsv"

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
run_experiment $1
#bash -i examples/Sacenti-JIIS2021-revised/run_exp8-cao-epochs.sh "JIIS-revised-exp8" |& tee out-exp8-1.txt
