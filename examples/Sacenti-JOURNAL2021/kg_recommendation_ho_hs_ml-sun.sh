#!/bin/bash

####
# Evaluate Recommendation quality of given dataset using parameters for Sun's KG and derivatives. Experiments of Sacenti 2021 - JIIS.
#
# - Datasets: ml-sun and derivatives
# - Split: hold-out
# - KG Recommendation: CFKG, CKE, CoFM, KTUP (TransE, TransH, BPRMF, TUP)
# - Results: rec_quality, comp_cost
# - Parameters:
#    - Knowledge representation: bs at 256, lr at 0.001, 'training 100 epochs, evaluating every 1 epochs and waiting for 5 epochs', L2 at 0, optimizer at Adam, embedding size at 100
#    - Item Recommendation: bs at 256, lr at 0.005, 'training 100 epochs, evaluating every 1 epochs and waiting for 5 epochs', L2 at $10^-5$, optimizer at Adagrad, embedding size at 100, number of preferences at 3 (TUP)
#    - Knowledgable recommendation: bs at 256, lr at 0.005, 'training 100 epochs, evaluating every 1 epochs and waiting for 5 epochs', L2 at 0, optimizer at Adam, embedding size at 100, joint ratio at 0.5
####

####
# Import util/util.sh
#
# - no_exist 'path_to_file'
####
source util/util.sh

# Evaluate given $DATASET
DATASET_IN=$1
DATASET=$2
# EPOCHS
IFS=', ' read -r -a KNOWLEDGE_REPRESENTATION_EPOCHS <<< "$3"
IFS=', ' read -r -a TUP_EPOCHS <<< "$4"
IFS=', ' read -r -a ITEM_RECOMMENDATION_EPOCHS <<< "$5"
IFS=', ' read -r -a KNOWLEDGABLE_RECOMMENDATION_EPOCHS <<< "$6"
# BATCH SIZE
BATCH_SIZE=$7
# LEARNING RATE
LEARNING_RATE=$8

################################################################################
###                            Create Result folder                          ###
################################################################################
if [ ! -d "$HOME/git/results/$DATASET" ]
then 
    echo "[kg-summ-rs] Creating ~git/results/$DATASET"
    mkdir ~/git/results/$DATASET
fi

################################################################################
###                          Run Cao's RS algorithms                         ###
################################################################################
cd ~/git/joint-kg-recommender

#[activate jointrec]
conda deactivate
conda activate jointrec

#[TRANSE]
if no_exist "$HOME/git/results/$DATASET/ml1m-transe-*.log"
then
    echo "[kg-summ-rs] Running TransE with $DATASET"
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -data_path ~/git/datasets/$DATASET_IN/cao-format/ -log_path ~/git/results/$DATASET/ -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type transe -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate 0.001 -topn 10 -seed 3 -eval_interval_steps ${KNOWLEDGE_REPRESENTATION_EPOCHS[0]} -training_steps ${KNOWLEDGE_REPRESENTATION_EPOCHS[1]} -early_stopping_steps_to_wait ${KNOWLEDGE_REPRESENTATION_EPOCHS[2]} -optimizer_type Adam -L1_flag -norm_lambda 1 -kg_lambda 1 &
    wait $!
    mv ~/git/results/$DATASET/ml1m-transe-*.ckpt_final ~/git/results/$DATASET/ml1m-transe-pretrained.ckpt
fi

#[TRANSH]
if no_exist "$HOME/git/results/$DATASET/ml1m-transh-*.log"
then
    echo "[kg-summ-rs] Running TransH with $DATASET"
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -data_path ~/git/datasets/$DATASET_IN/cao-format/ -log_path ~/git/results/$DATASET/ -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type transh -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate 0.001 -topn 10 -seed 3 -eval_interval_steps ${KNOWLEDGE_REPRESENTATION_EPOCHS[0]} -training_steps ${KNOWLEDGE_REPRESENTATION_EPOCHS[1]} -early_stopping_steps_to_wait ${KNOWLEDGE_REPRESENTATION_EPOCHS[2]} -optimizer_type Adam -L1_flag -norm_lambda 1 -kg_lambda 1 -load_ckpt_file "$HOME/git/results/$DATASET/ml1m-transe-pretrained.ckpt" &
    wait $!
    mv ~/git/results/$DATASET/ml1m-transh-*.ckpt_final ~/git/results/$DATASET/ml1m-transh-pretrained.ckpt
fi

#BPRMF - Steffen Rendle, Christoph Freudenthaler, Zeno Gantner, and Lars Schmidt-Thieme. 2009. BPR: Bayesian personalized ranking from implicit feedback. In UAI.
if no_exist "$HOME/git/results/$DATASET/ml1m-bprmf-*.log"
then
    echo "[kg-summ-rs] Running BPRMF with $DATASET"
    CUDA_VISIBLE_DEVICES=0 nohup python run_item_recommendation.py -data_path ~/git/datasets/$DATASET_IN/cao-format/ -log_path ~/git/results/$DATASET/ -rec_test_files valid.dat:test.dat -l2_lambda 1e-5 -negtive_samples 1 -model_type bprmf -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate ${LEARNING_RATE} -topn 10 -seed 3 -eval_interval_steps ${ITEM_RECOMMENDATION_EPOCHS[0]} -training_steps ${ITEM_RECOMMENDATION_EPOCHS[1]} -early_stopping_steps_to_wait ${ITEM_RECOMMENDATION_EPOCHS[2]} -optimizer_type Adagrad &
    wait $!
    mv ~/git/results/$DATASET/ml1m-bprmf-*.ckpt ~/git/results/$DATASET/ml1m-bprmf-pretrained.ckpt
fi

#TransUP
#if no_exist "$HOME/git/results/$DATASET/ml1m-transup-*.log"
#then
#    echo "[kg-summ-rs] Running TransUP with $DATASET"
#    CUDA_VISIBLE_DEVICES=0 nohup python run_item_recommendation.py -data_path ~/git/datasets/$DATASET_IN/cao-format/ -log_path ~/git/results/$DATASET/ -rec_test_files valid.dat:test.dat -l2_lambda 1e-5 -negtive_samples 1 -model_type transup -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate ${LEARNING_RATE} -topn 10 -seed 3 -eval_interval_steps ${TUP_EPOCHS[0]} -training_steps ${TUP_EPOCHS[1]} -early_stopping_steps_to_wait ${TUP_EPOCHS[2]} -optimizer_type Adagrad -L1_flag -num_preferences 3 -nouse_st_gumbel -load_ckpt_file "$HOME/git/results/$DATASET/ml1m-bprmf-pretrained.ckpt" & # ml-sun num_preferences = 3
#    wait $!
#    mv ~/git/results/$DATASET/ml1m-transup-*.ckpt ~/git/results/$DATASET/ml1m-transup-pretrained.ckpt
#fi

#CFKG (TransE) - Yongfeng Zhang, Qingyao Ai, Xu Chen, and Pengfei Wang. 2018. Learning over Knowledge-Base Embeddings for Recommendation. In SIGIR.
if no_exist "$HOME/git/results/$DATASET/ml1m-cfkg-*.log"
then
    echo "[kg-summ-rs] Running CFKG with $DATASET"
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/$DATASET_IN/cao-format/ -log_path ~/git/results/$DATASET/ -rec_test_files valid.dat:test.dat  -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type cfkg -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate ${LEARNING_RATE} -topn 10 -seed 3 -eval_interval_steps ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[0]} -training_steps ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[1]} -early_stopping_steps_to_wait ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[2]} -optimizer_type Adam -joint_ratio 0.5 -share_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -use_st_gumbel -load_ckpt_file "$HOME/git/results/$DATASET/ml1m-bprmf-pretrained.ckpt:$HOME/git/results/$DATASET/ml1m-transe-pretrained.ckpt" &
    wait $!
fi

#CKE (TransR) - Fuzheng Zhang, Nicholas Jing Yuan, Defu Lian, Xing Xie, and Wei-Ying Ma. 2016. Collaborative Knowledge Base Embedding for Recommender Systems. In SIGKDD.
#if no_exist "$HOME/git/results/$DATASET/ml1m-cke-*.log"
#then
#    echo "[kg-summ-rs] Running CKE with $DATASET"
#    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/$DATASET_IN/cao-format/ -log_path ~/git/results/$DATASET/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type cke -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate ${LEARNING_RATE} -topn 10 -seed 3 -eval_interval_steps ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[0]} -training_steps ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[1]} -early_stopping_steps_to_wait ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[2]} -optimizer_type Adam -joint_ratio 0.5 -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -use_st_gumbel -load_ckpt_file "$HOME/git/results/$DATASET/ml1m-bprmf-pretrained.ckpt:$HOME/git/results/$DATASET/ml1m-transe-pretrained.ckpt" &
#    wait $!
#fi

#CoFM (FM+TransE) - Guangyuan Piao and John G. Breslin. 2018. Transfer Learning for Item Recommendations and Knowledge Graph Completion in Item Related Domains via a Co-Factorization Model. In ESWC.
#if no_exist "$HOME/git/results/$DATASET/ml1m-cofm-*.log"
#then
#    echo "[kg-summ-rs] Running CoFM with $DATASET"
#    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/$DATASET_IN/cao-format/ -log_path ~/git/results/$DATASET/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type cofm -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate ${LEARNING_RATE} -topn 10 -seed 3 -eval_interval_steps ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[0]} -training_steps ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[1]} -early_stopping_steps_to_wait ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[2]} -optimizer_type Adam -joint_ratio 0.5 -load_ckpt_file "$HOME/git/results/$DATASET/ml1m-bprmf-pretrained.ckpt:$HOME/git/results/$DATASET/ml1m-transe-pretrained.ckpt" -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 &
#    wait $!
#fi

#JTransUP
#if no_exist "$HOME/git/results/$DATASET/ml1m-jtransup-*.log"
#then
#    echo "[kg-summ-rs] Running JTransUP with $DATASET"
#    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/$DATASET_IN/cao-format/ -log_path ~/git/results/$DATASET/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type jtransup -nohas_visualization -dataset ml1m -batch_size ${BATCH_SIZE} -embedding_size 100 -learning_rate ${LEARNING_RATE} -topn 10 -seed 3 -eval_interval_steps ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[0]} -training_steps ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[1]} -early_stopping_steps_to_wait ${KNOWLEDGABLE_RECOMMENDATION_EPOCHS[2]} -optimizer_type Adam -joint_ratio 0.5 -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -nouse_st_gumbel -load_ckpt_file "$HOME/git/results/$DATASET/ml1m-transup-pretrained.ckpt:$HOME/git/results/$DATASET/ml1m-transh-pretrained.ckpt" &
#    wait $!
#fi

####
# Collect computational cost of $DATASET
####
cd ~/git/know-rec
source comp_cost.sh "${DATASET}" > "$HOME/git/results/${DATASET}/comp_cost.tsv"

