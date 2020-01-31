#!/bin/bash
cd ../../joint-kg-recommender


#[TRANSE]
log_file="../results/ml1m-sun/ml1m-transe-*.log"
if [ -f "$log_file" ]
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -data_path ~/git/joint-kg-recommender/datasets/ -log_path ~/git/joint-kg-recommender/log/ -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type transe -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.001 -topn 10 -seed 3 -eval_interval_steps 9150 -training_steps 915000 -early_stopping_steps_to_wait 45750 -optimizer_type Adam -L1_flag -norm_lambda 1 -kg_lambda 1 &
    BACK_PID=$!
    wait $BACK_PID
fi

#[TRANSR]
log_file="../results/ml1m-sun/ml1m-transr-*.log"
if [ -f "$log_file" ]
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -data_path ~/git/joint-kg-recommender/datasets/ -log_path ~/git/joint-kg-recommender/log/ -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type transr -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.001 -topn 10 -seed 3 -eval_interval_steps 9150 -training_steps 915000 -early_stopping_steps_to_wait 45750 -optimizer_type Adam -L1_flag -norm_lambda 1 -kg_lambda 1 -load_ckpt_file /home/juarez/git/joint-kg-recommender/log/ml1m-transe-pretrained1.ckpt &
    BACK_PID=$!
    wait $BACK_PID
fi

#[TRANSH]
log_file="../results/ml1m-sun/ml1m-transh-*.log"
if [ -f "$log_file" ]
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -data_path ~/git/joint-kg-recommender/datasets/ -log_path ~/git/joint-kg-recommender/log/ -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type transh -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.001 -topn 10 -seed 3 -eval_interval_steps 9150 -training_steps 915000 -early_stopping_steps_to_wait 45750 -optimizer_type Adam -L1_flag -norm_lambda 1 -kg_lambda 1 -load_ckpt_file /home/juarez/git/joint-kg-recommender/log/ml1m-transe-pretrained1.ckpt &
    BACK_PID=$!
    wait $BACK_PID
fi

#TransUP
log_file="../results/ml1m-sun/ml1m-transup-*.log"
if [ -f "$log_file" ]
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_item_recommendation.py -data_path ~/git/joint-kg-recommender/datasets/ -log_path ~/git/joint-kg-recommender/log/ -rec_test_files valid.dat:test.dat -l2_lambda 1e-5 -negtive_samples 1 -model_type transup -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 500 -training_steps 50000 -early_stopping_steps_to_wait 2500 -optimizer_type Adagrad -L1_flag -num_preferences 20 -nouse_st_gumbel -load_ckpt_file /home/juarez/git/joint-kg-recommender/log/ml1m-bprmf-pretrained1.ckpt &
    BACK_PID=$!
    wait $BACK_PID
fi

#FM - Steffen Rendle. 2010. Factorization machines.
log_file="../results/ml1m-sun/ml1m-fm-*.log"
if [ -f "$log_file" ]
then
    CUDA_VISIBLE_DEVICES=1 nohup python run_item_recommendation.py -data_path ~/git/joint-kg-recommender/datasets/ -log_path ~/git/joint-kg-recommender/log/ -rec_test_files valid.dat:test.dat -l2_lambda 1e-5 -negtive_samples 1 -model_type fm -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 500 -training_steps 50000 -early_stopping_steps_to_wait 2500 -optimizer_type Adagrad &
    BACK_PID=$!
    wait $BACK_PID
fi

#BPRMF - Steffen Rendle, Christoph Freudenthaler, Zeno Gantner, and Lars Schmidt-Thieme. 2009. BPR: Bayesian personalized ranking from implicit feedback. In UAI.
log_file="../results/ml1m-sun/ml1m-bprmf-*.log"
if [ -f "$log_file" ]
then
    CUDA_VISIBLE_DEVICES=1 nohup python run_item_recommendation.py -data_path ~/git/joint-kg-recommender/datasets/ -log_path ~/git/joint-kg-recommender/log/ -rec_test_files valid.dat:test.dat -l2_lambda 1e-5 -negtive_samples 1 -model_type bprmf -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 5000 -training_steps 500000 -early_stopping_steps_to_wait 25000 -optimizer_type Adagrad &
    BACK_PID=$!
    wait $BACK_PID
fi

#CFKG (TransE) - Yongfeng Zhang, Qingyao Ai, Xu Chen, and Pengfei Wang. 2018. Learning over Knowledge-Base Embeddings for Recommendation. In SIGIR.
log_file="../results/ml1m-sun/ml1m-cfkg-*.log"
if [ -f "$log_file" ]
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/joint-kg-recommender/datasets/ -log_path ~/git/joint-kg-recommender/log/ -rec_test_files valid.dat:test.dat  -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type cfkg -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 19520 -training_steps 1952000 -early_stopping_steps_to_wait 97600 -optimizer_type Adam -joint_ratio 0.5 -share_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -use_st_gumbel -load_ckpt_file /home/juarez/git/joint-kg-recommender/log/ml1m-transup-pretrained1.ckpt:/home/juarez/git/joint-kg-recommender/log/ml1m-transh-pretrained1.ckpt &
    BACK_PID=$!
    wait $BACK_PID
fi

#CKE (TransR) - Fuzheng Zhang, Nicholas Jing Yuan, Defu Lian, Xing Xie, and Wei-Ying Ma. 2016. Collaborative Knowledge Base Embedding for Recommender Systems. In SIGKDD.
log_file="../results/ml1m-sun/ml1m-cke-*.log"
if [ -f "$log_file" ]
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/joint-kg-recommender/datasets/ -log_path ~/git/joint-kg-recommender/log/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type cke -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 19520 -training_steps 1952000 -early_stopping_steps_to_wait 97600 -optimizer_type Adam -joint_ratio 0.5 -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -use_st_gumbel -load_ckpt_file /home/juarez/git/joint-kg-recommender/log/ml1m-bprmf-pretrained1.ckpt:/home/juarez/git/joint-kg-recommender/log/ml1m-transe-pretrained1.ckpt &
    BACK_PID=$!
    wait $BACK_PID
fi

#CoFM (FM+TransE) - Guangyuan Piao and John G. Breslin. 2018. Transfer Learning for Item Recommendations and Knowledge Graph Completion in Item Related Domains via a Co-Factorization Model. In ESWC.
log_file="../results/ml1m-sun/ml1m-cofm-*.log"
if [ -f "$log_file" ]
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/joint-kg-recommender/datasets/ -log_path ~/git/joint-kg-recommender/log/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type cofm -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 19520 -training_steps 1952000 -early_stopping_steps_to_wait 97600 -optimizer_type Adam -joint_ratio 0.5 -load_ckpt_file /home/juarez/git/joint-kg-recommender/log/ml1m-bprmf-pretrained1.ckpt:/home/juarez/git/joint-kg-recommender/log/ml1m-transe-pretrained1.ckpt -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 &
    BACK_PID=$!
    wait $BACK_PID
fi

#JTransUP
log_file="../results/ml1m-sun/ml1m-jtransup-*.log"
if [ -f "$log_file" ]
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/joint-kg-recommender/datasets/ -log_path ~/git/joint-kg-recommender/log/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type jtransup -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 19520 -training_steps 1952000 -early_stopping_steps_to_wait 97600 -optimizer_type Adam -joint_ratio 0.5 -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -nouse_st_gumbel -load_ckpt_file /home/juarez/git/joint-kg-recommender/log/ml1m-bprmf-pretrained1.ckpt:/home/juarez/git/joint-kg-recommender/log/ml1m-transe-pretrained1.ckpt &
    BACK_PID=$!
    wait $BACK_PID
fi
