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

recommend() {
    local dataset_in=$1
    local dataset_out=$2
    # EPOCHS
    IFS=', ' read -r -a KNOWLEDGE_REPRESENTATION_EPOCHS <<< "$3"
    IFS=', ' read -r -a ITEM_RECOMMENDATION_EPOCHS <<< "$4"
    IFS=', ' read -r -a TUP_EPOCHS <<< "$5"
    IFS=', ' read -r -a KNOWLEDGABLE_RECOMMENDATION_EPOCHS <<< "$6"
    # BATCH SIZE
    IFS=', ' read -r -a BATCH_SIZES <<< "$7"
    # LEARNING RATE
    IFS=', ' read -r -a LEARNING_RATES <<< "$8"

    cd ~/git/joint-kg-recommender

    #[activate jointrec]
    conda deactivate
    conda activate jointrec

    echo "experiment: $experiment"
    echo "seed: $seed"
    echo "verbose: $verbose"

    local STARTTIME=0
    local ENDTIME=0
    #[TRANSE]
    if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-transe-*.log"
    then
        STARTTIME=$(date +%s)
        echo "[kg-summ-rec] recommend: Running TransE with ${dataset_out}"
        CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -L1_flag -batch_size ${BATCH_SIZES[0]} -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -dataset ml1m -early_stopping_steps_to_wait ${KNOWLEDGE_REPRESENTATION_EPOCHS[2]} -embedding_size 100 -eval_interval_steps ${KNOWLEDGE_REPRESENTATION_EPOCHS[0]} -nohas_visualization -kg_lambda 1 -kg_test_files valid.dat:test.dat -l2_lambda 0 -learning_rate ${LEARNING_RATES[0]} -log_path ~/git/results/${experiment}/${dataset_out}/ -model_type transe -norm_lambda 1 -optimizer_type Adam -seed ${seed} -topn 10 -training_steps ${KNOWLEDGE_REPRESENTATION_EPOCHS[1]} &
        wait $!
        mv ~/git/results/${experiment}/${dataset_out}/ml1m-transe-*.ckpt_final ~/git/results/${experiment}/${dataset_out}/ml1m-transe-pretrained.ckpt
        ENDTIME=$(date +%s)
        echo -e "recommend-TRANSE-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi
    #FM
    if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-fm-*.log"
    then
        STARTTIME=$(date +%s)
        echo "[kg-summ-rec] recommend: Running FM with ${dataset_out}"
        CUDA_VISIBLE_DEVICES=0 nohup python run_item_recommendation.py -batch_size ${BATCH_SIZES[1]} -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -dataset ml1m -early_stopping_steps_to_wait ${ITEM_RECOMMENDATION_EPOCHS[2]} -embedding_size 100 -eval_interval_steps ${ITEM_RECOMMENDATION_EPOCHS[0]} -nohas_visualization -kg_lambda 0.5 -l2_lambda 1e-5 -learning_rate ${LEARNING_RATES[1]} -log_path ~/git/results/${experiment}/${dataset_out}/ -model_type fm -negtive_samples 1 -norm_lambda 1 -optimizer_type Adagrad -rec_test_files valid.dat:test.dat -seed ${seed} -topn 10 -training_steps ${ITEM_RECOMMENDATION_EPOCHS[1]} &
        wait $!
        mv ~/git/results/${experiment}/${dataset_out}/ml1m-fm-1*.ckpt ~/git/results/${experiment}/${dataset_out}/ml1m-fm-pretrained.ckpt
        ENDTIME=$(date +%s)
        echo -e "recommend-BPRMF-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi
    #BPRMF - Steffen Rendle, Christoph Freudenthaler, Zeno Gantner, and Lars Schmidt-Thieme. 2009. BPR: Bayesian personalized ranking from implicit feedback. In UAI.
    if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-bprmf-*.log"
    then
        STARTTIME=$(date +%s)
        echo "[kg-summ-rec] recommend: Running BPRMF with ${dataset_out}"
        CUDA_VISIBLE_DEVICES=0 nohup python run_item_recommendation.py -batch_size ${BATCH_SIZES[1]} -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -dataset ml1m -early_stopping_steps_to_wait ${ITEM_RECOMMENDATION_EPOCHS[2]} -embedding_size 100 -eval_interval_steps ${ITEM_RECOMMENDATION_EPOCHS[0]} -nohas_visualization -kg_lambda 0.5 -l2_lambda 1e-5 -learning_rate ${LEARNING_RATES[1]} -log_path ~/git/results/${experiment}/${dataset_out}/ -model_type bprmf -negtive_samples 1 -norm_lambda 1 -optimizer_type Adagrad -rec_test_files valid.dat:test.dat -seed ${seed} -topn 10 -training_steps ${ITEM_RECOMMENDATION_EPOCHS[1]} &
        wait $!
        mv ~/git/results/${experiment}/${dataset_out}/ml1m-bprmf-*.ckpt ~/git/results/${experiment}/${dataset_out}/ml1m-bprmf-pretrained.ckpt
        ENDTIME=$(date +%s)
        echo -e "recommend-BPRMF-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi
    #CFKG (TransE) - Yongfeng Zhang, Qingyao Ai, Xu Chen, and Pengfei Wang. 2018. Learning over Knowledge-Base Embeddings for Recommendation. In SIGIR.
    if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-cfkg-*.log"
    then
       STARTTIME=$(date +%s)
       if [ "$verbose" = true ]; then echo "[kg-summ-rec] recommend: Running CFKG with ${dataset_out}"; fi
       CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -L1_flag -batch_size ${BATCH_SIZES[3]} -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -dataset ml1m -early_stopping_steps_to_wait ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[2]} -embedding_size 100 -eval_interval_steps ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[0]} -nohas_visualization -joint_ratio 0.5 -kg_lambda 1 -kg_test_files valid.dat:test.dat -l2_lambda 0 -learning_rate ${LEARNING_RATES[3]} -load_ckpt_file "$HOME/git/results/${experiment}/${dataset_out}/ml1m-bprmf-pretrained.ckpt:$HOME/git/results/${experiment}/${dataset_out}/ml1m-transe-pretrained.ckpt" -log_path ~/git/results/${experiment}/${dataset_out}/ -model_type cfkg -negtive_samples 1 -norm_lambda 1 -optimizer_type Adam -rec_test_files valid.dat:test.dat -seed ${seed} -share_embeddings -topn 10 -training_steps ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[1]} -nouse_st_gumbel &
       wait $!
       ENDTIME=$(date +%s)
       echo -e "recommend-CFKG-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi
    #CoFM (FM+TransE) - Guangyuan Piao and John G. Breslin. 2018. Transfer Learning for Item Recommendations and Knowledge Graph Completion in Item Related Domains via a Co-Factorization Model. In ESWC.
    if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-cofm-*.log"
    then
      STARTTIME=$(date +%s)
      if [ "$verbose" = true ]; then echo "[kg-summ-rec] recommend: Running CoFM with ${dataset_out}"; fi
      CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -L1_flag -batch_size ${BATCH_SIZES[3]} -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -dataset ml1m -early_stopping_steps_to_wait ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[2]} -embedding_size 100 -eval_interval_steps ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[0]} -nohas_visualization -joint_ratio 0.5 -kg_lambda 1 -kg_test_files valid.dat:test.dat -l2_lambda 0 -learning_rate ${LEARNING_RATES[3]} -load_ckpt_file "$HOME/git/results/${experiment}/${dataset_out}/ml1m-fm-pretrained.ckpt:$HOME/git/results/${experiment}/${dataset_out}/ml1m-transe-pretrained.ckpt" -log_path ~/git/results/${experiment}/${dataset_out}/ -model_type cofm -negtive_samples 1 -norm_lambda 1 -optimizer_type Adam -rec_test_files valid.dat:test.dat -seed ${seed} -share_embeddings -topn 10 -training_steps ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[1]} -nouse_st_gumbel &
      wait $!
      ENDTIME=$(date +%s)
      echo -e "recommend-CoFM-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
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
        CUDA_VISIBLE_DEVICES=0 nohup python run_item_recommendation.py -batch_size 1024 -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -dataset ml1m -early_stopping_steps_to_wait 35000 -embedding_size 100 -eval_interval_steps 7000 -nohas_visualization -joint_ratio 0.5 -kg_lambda 0.5 -l2_lambda 1e-5 -learning_rate 0.005 -log_path ~/git/results/${experiment}/${dataset_out}/ -model_type fm -negtive_samples 1 -norm_lambda 1 -optimizer_type Adagrad -rec_test_files valid.dat:test.dat -seed 3 -topn 10 -training_steps 700000 &
        resource_usage $! 1800 "${HOME}/git/results/${experiment}/${dataset_out}/fm-resource_usage.csv"
        wait $!
        mv ~/git/results/${experiment}/${dataset_out}/ml1m-fm-1*.ckpt ~/git/results/${experiment}/${dataset_out}/ml1m-fm-pretrained.ckpt
        ENDTIME=$(date +%s)
        echo -e "recommend-FM-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi
    #[BPRMF] - Steffen Rendle, Christoph Freudenthaler, Zeno Gantner, and Lars Schmidt-Thieme. 2009. BPR: Bayesian personalized ranking from implicit feedback. In UAI.
    if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-bprmf-*.log"
    then
        STARTTIME=$(date +%s)
        echo "[kg-summ-rec] recommend: Running BPRMF1 with ${dataset_out}"
        CUDA_VISIBLE_DEVICES=0 nohup python run_item_recommendation.py -batch_size 1024 -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -dataset ml1m -early_stopping_steps_to_wait 35000 -embedding_size 100 -eval_interval_steps 7000 -nohas_visualization -joint_ratio 0.5 -kg_lambda 0.5 -l2_lambda 1e-5 -learning_rate 0.005 -log_path ~/git/results/${experiment}/${dataset_out}/ -model_type bprmf -negtive_samples 1 -norm_lambda 1 -optimizer_type Adagrad -rec_test_files valid.dat:test.dat -seed 3 -topn 10 -training_steps 700000 &
        resource_usage $! 1800 "${HOME}/git/results/${experiment}/${dataset_out}/bprmf1-resource_usage.csv"
        wait $!
        mv ~/git/results/${experiment}/${dataset_out}/ml1m-bprmf-1*.ckpt ~/git/results/${experiment}/${dataset_out}/ml1m-bprmf-pretrained1.ckpt
        ENDTIME=$(date +%s)
        echo -e "recommend-BPRMF1-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    #[BPRMF] - Steffen Rendle, Christoph Freudenthaler, Zeno Gantner, and Lars Schmidt-Thieme. 2009. BPR: Bayesian personalized ranking from implicit feedback. In UAI.
        STARTTIME=$(date +%s)
        echo "[kg-summ-rec] recommend: Running BPRMF2 with ${dataset_out}"
        CUDA_VISIBLE_DEVICES=0 nohup python run_item_recommendation.py -batch_size 512 -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -dataset ml1m -early_stopping_steps_to_wait 70000 -embedding_size 100 -eval_interval_steps 14000 -nohas_visualization -joint_ratio 0.5 -kg_lambda 0.5 -l2_lambda 1e-5 -learning_rate 0.005 -log_path ~/git/results/${experiment}/${dataset_out}/ -model_type bprmf -negtive_samples 1 -norm_lambda 1 -optimizer_type Adagrad -rec_test_files valid.dat:test.dat -seed 3 -topn 10 -training_steps 1400000 &
        resource_usage $! 1800 "${HOME}/git/results/${experiment}/${dataset_out}/bprmf2-resource_usage.csv"
        wait $!
        mv ~/git/results/${experiment}/${dataset_out}/ml1m-bprmf-1*.ckpt ~/git/results/${experiment}/${dataset_out}/ml1m-bprmf-pretrained2.ckpt
        ENDTIME=$(date +%s)
        echo -e "recommend-BPRMF2-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi
    #[TUP]
    if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-transup-*.log"
    then
        STARTTIME=$(date +%s)
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] recommend: Running TUP with ${dataset_out}"; fi
        CUDA_VISIBLE_DEVICES=0 nohup python run_item_recommendation.py -L1_flag -batch_size 1024 -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -dataset ml1m -early_stopping_steps_to_wait 35000 -embedding_size 100 -eval_interval_steps 7000 -nohas_visualization -joint_ratio 0.5 -kg_lambda 0.5 -l2_lambda 0 -learning_rate 0.001 -load_ckpt_file "$HOME/git/results/${experiment}/${dataset_out}/ml1m-bprmf-pretrained2.ckpt" -log_path ~/git/results/${experiment}/${dataset_out}/ -model_type transup -negtive_samples 1 -norm_lambda 1 -num_preferences 20 -optimizer_type Adam -rec_test_files valid.dat:test.dat -seed 3 -topn 10 -training_steps 700000 -use_st_gumbel &
        resource_usage $! 1800 "${HOME}/git/results/${experiment}/${dataset_out}/tup-resource_usage.csv"
        wait $!
        mv ~/git/results/${experiment}/${dataset_out}/ml1m-transup-1*.ckpt ~/git/results/${experiment}/${dataset_out}/ml1m-transup-pretrained.ckpt
        ENDTIME=$(date +%s)
        echo -e "recommend-TRANSUP-${DATASET}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi
    #[TRANSE1]
    if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-transe-*.log"
    then
        STARTTIME=$(date +%s)
        echo "[kg-summ-rec] recommend: Running TransE1 with ${dataset_out}"
        CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -L1_flag -batch_size 100 -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -dataset ml1m -early_stopping_steps_to_wait 150000 -embedding_size 100 -eval_interval_steps 30000 -nohas_visualization -joint_ratio 0.5 -kg_lambda 1 -kg_test_files valid.dat:test.dat -l2_lambda 0 -learning_rate 0.001 -log_path ~/git/results/${experiment}/${dataset_out}/ -model_type transe -norm_lambda 1 -optimizer_type Adam -seed 3 -topn 10 -training_steps 3000000 &
        resource_usage $! 1800 "${HOME}/git/results/${experiment}/${dataset_out}/transe1-resource_usage.csv"
        wait $!
        mv ~/git/results/${experiment}/${dataset_out}/ml1m-transe-1*.ckpt_final ~/git/results/${experiment}/${dataset_out}/ml1m-transe-pretrained1.ckpt
        ENDTIME=$(date +%s)
        echo -e "recommend-TRANSE1-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    #[TRANSE2]
        STARTTIME=$(date +%s)
        echo "[kg-summ-rec] recommend: Running TransE1 with ${dataset_out}"
        CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -L1_flag -batch_size 400 -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -dataset ml1m -early_stopping_steps_to_wait 38000 -embedding_size 100 -eval_interval_steps 7600 -nohas_visualization -joint_ratio 0.5 -kg_lambda 1 -kg_test_files valid.dat:test.dat -l2_lambda 0 -learning_rate 0.001 -log_path ~/git/results/${experiment}/${dataset_out}/ -model_type transe -negtive_samples 1 -norm_lambda 1 -optimizer_type Adam -seed 3 -topn 10 -training_steps 760000 &
        resource_usage $! 1800 "${HOME}/git/results/${experiment}/${dataset_out}/transe2-resource_usage.csv"
        wait $!
        mv ~/git/results/${experiment}/${dataset_out}/ml1m-transe-1*.ckpt_final ~/git/results/${experiment}/${dataset_out}/ml1m-transe-pretrained2.ckpt
        ENDTIME=$(date +%s)
        echo -e "recommend-TRANSE2-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi
    #[TRANSH]
    if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-transh-*.log"
    then
        STARTTIME=$(date +%s)
        echo "[kg-summ-rec] recommend: Running TransH with ${dataset_out}"
        CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -L1_flag -batch_size 100 -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -dataset ml1m -early_stopping_steps_to_wait 150000 -embedding_size 100 -eval_interval_steps 30000 -nohas_visualization -joint_ratio 0.5 -kg_lambda 0.5 -kg_test_files valid.dat:test.dat -l2_lambda 0 -learning_rate 0.001 -load_ckpt_file "$HOME/git/results/${experiment}/${dataset_out}/ml1m-transe-pretrained1.ckpt"  -log_path ~/git/results/${experiment}/${dataset_out}/ -model_type transh -norm_lambda 1 -optimizer_type Adam -seed 3 -topn 10 -training_steps 3000000 &
        resource_usage $! 1800 "${HOME}/git/results/${experiment}/${dataset_out}/transh-resource_usage.csv"
        wait $!
        mv ~/git/results/${experiment}/${dataset_out}/ml1m-transh-1*.ckpt_final ~/git/results/${experiment}/${dataset_out}/ml1m-transh-pretrained.ckpt
        ENDTIME=$(date +%s)
        echo -e "recommend-TRANSH-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi
    #[CFKG] (TransE) - Yongfeng Zhang, Qingyao Ai, Xu Chen, and Pengfei Wang. 2018. Learning over Knowledge-Base Embeddings for Recommendation. In SIGIR.
    if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-cfkg-*.log"
    then
       STARTTIME=$(date +%s)
       if [ "$verbose" = true ]; then echo "[kg-summ-rec] recommend: Running CFKG with ${dataset_out}"; fi
       CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -L1_flag -batch_size 400 -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -dataset ml1m -early_stopping_steps_to_wait 175000 -embedding_size 100 -eval_interval_steps 35000 -nohas_visualization -joint_ratio 0.5 -kg_lambda 1 -kg_test_files valid.dat:test.dat -l2_lambda 0 -learning_rate 0.001 -load_ckpt_file "$HOME/git/results/${experiment}/${dataset_out}/ml1m-bprmf-pretrained1.ckpt:$HOME/git/results/${experiment}/${dataset_out}/ml1m-transe-pretrained2.ckpt" -log_path ~/git/results/${experiment}/${dataset_out}/ -model_type cfkg -negtive_samples 1 -norm_lambda 1 -optimizer_type Adam -rec_test_files valid.dat:test.dat -seed 3 -share_embeddings -topn 10 -training_steps 3500000 -nouse_st_gumbel &
       resource_usage $! 1800 "${HOME}/git/results/${experiment}/${dataset_out}/cfkg-resource_usage.csv"
       wait $!
       ENDTIME=$(date +%s)
       echo -e "recommend-CFKG-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi
    #CKE (TransR) - Fuzheng Zhang, Nicholas Jing Yuan, Defu Lian, Xing Xie, and Wei-Ying Ma. 2016. Collaborative Knowledge Base Embedding for Recommender Systems. In SIGKDD.
    if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-cke-*.log"
    then
       STARTTIME=$(date +%s)
       if [ "$verbose" = true ]; then echo "[kg-summ-rec] recommend: Running CKE with ${dataset_out}"; fi
       CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -L1_flag -batch_size 256 -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -dataset ml1m -early_stopping_steps_to_wait 275000 -embedding_size 100 -eval_interval_steps 55000 -nohas_visualization -joint_ratio 0.5 -kg_lambda 1 -kg_test_files valid.dat:test.dat -l2_lambda 0 -learning_rate 0.001 -log_path ~/git/results/${experiment}/${dataset_out}/ -model_type cke -negtive_samples 1 -norm_lambda 1 -optimizer_type Adam -rec_test_files valid.dat:test.dat -seed 3 -topn 10 -training_steps 5500000 -nouse_st_gumbel &
       resource_usage $! 1800 "${HOME}/git/results/${experiment}/${dataset_out}/cke-resource_usage.csv"
       wait $!
       ENDTIME=$(date +%s)
       echo -e "recommend-CKE-${DATASET}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi
    #[CoFM] (FM+TransE) - Guangyuan Piao and John G. Breslin. 2018. Transfer Learning for Item Recommendations and Knowledge Graph Completion in Item Related Domains via a Co-Factorization Model. In ESWC.
    if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-cofm-*.log"
    then
      STARTTIME=$(date +%s)
      if [ "$verbose" = true ]; then echo "[kg-summ-rec] recommend: Running CoFM with ${dataset_out}"; fi
      CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -L1_flag -batch_size 400 -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -dataset ml1m -early_stopping_steps_to_wait 175000 -embedding_size 100 -eval_interval_steps 35000 -nohas_visualization -joint_ratio 0.5 -kg_lambda 1 -kg_test_files valid.dat:test.dat -l2_lambda 0 -learning_rate 0.001 -load_ckpt_file "$HOME/git/results/${experiment}/${dataset_out}/ml1m-fm-pretrained.ckpt:$HOME/git/results/${experiment}/${dataset_out}/ml1m-transe-pretrained1.ckpt" -log_path ~/git/results/${experiment}/${dataset_out}/ -model_type cofm -negtive_samples 1 -norm_lambda 1 -optimizer_type Adam -rec_test_files valid.dat:test.dat -seed 3 -share_embeddings -topn 10 -training_steps 3500000 -nouse_st_gumbel &
      resource_usage $! 1800 "${HOME}/git/results/${experiment}/${dataset_out}/cofm-resource_usage.csv"
      wait $!
      ENDTIME=$(date +%s)
      echo -e "recommend-CoFM-${dataset_out}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    fi
    #[JTransUP1]
    if no_exist "$HOME/git/results/${experiment}/${dataset_out}/ml1m-jtransup-*.log"
    then
        STARTTIME=$(date +%s)
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] recommend: Running KTUP1 with ${dataset_out}"; fi
        CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -L1_flag -batch_size 400 -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -dataset ml1m -early_stopping_steps_to_wait 175000 -embedding_size 100 -eval_interval_steps 35000 -nohas_visualization -joint_ratio 0.5 -kg_lambda 1 -kg_test_files valid.dat:test.dat -l2_lambda 0 -learning_rate 0.001 -load_ckpt_file "$HOME/git/results/${experiment}/${dataset_out}/ml1m-transup-pretrained.ckpt:$HOME/git/results/${experiment}/${dataset_out}/ml1m-transh-pretrained.ckpt" -log_path ~/git/results/${experiment}/${dataset_out}/ -model_type jtransup -negtive_samples 1 -norm_lambda 1 -optimizer_type Adam -rec_test_files valid.dat:test.dat -seed 3 -topn 10 -training_steps 3500000 -use_st_gumbel &
        resource_usage $! 1800 "${HOME}/git/results/${experiment}/${dataset_out}/ktup1-resource_usage.csv"
        wait $!
        ENDTIME=$(date +%s)
        echo -e "recommend-KTUP1-${DATASET}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
    #[JTransUP2]
        STARTTIME=$(date +%s)
        if [ "$verbose" = true ]; then echo "[kg-summ-rec] recommend: Running KTUP2 with ${dataset_out}"; fi
        CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -L1_flag -batch_size 400 -data_path ~/git/datasets/${experiment}/${dataset_in}/cao-format/ -dataset ml1m -early_stopping_steps_to_wait 175000 -embedding_size 100 -eval_interval_steps 35000 -nohas_visualization -joint_ratio 0.5 -kg_lambda 1 -kg_test_files valid.dat:test.dat -l2_lambda 0 -learning_rate 0.001 -load_ckpt_file "$HOME/git/results/${experiment}/${dataset_out}/ml1m-transup-pretrained.ckpt:$HOME/git/results/${experiment}/${dataset_out}/ml1m-transh-pretrained.ckpt" -log_path ~/git/results/${experiment}/${dataset_out}/ -model_type jtransup -negtive_samples 1 -norm_lambda 1 -optimizer_type Adam -rec_test_files valid.dat:test.dat -seed 3 -topn 10 -training_steps 3500000 -nouse_st_gumbel &
        resource_usage $! 1800 "${HOME}/git/results/${experiment}/${dataset_out}/ktup2-resource_usage.csv"
        wait $!
        ENDTIME=$(date +%s)
        echo -e "recommend-KTUP2-${DATASET}\t$(($ENDTIME - $STARTTIME))\t${STARTTIME}\t${ENDTIME}" >> ${overall_comp_cost}
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
