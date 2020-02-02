#!/bin/bash
no_exist() {
for f in $1;
do
    ## Check if the glob gets expanded to existing files.
    ## If not, f here will be exactly the pattern above
    ## and the exists test will evaluate to false.
    if [ -e "$f" ]
    then
         return 1
    else
         return 0
    fi
done
}

cd ../../joint-kg-recommender

#[TRANSE]
if no_exist "../results/ml1m-sun/ml1m-transe-*.log"
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -data_path ~/git/datasets/ml1m-sun2cao/ -log_path ~/git/results/ml1m-sun/ -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type transe -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.001 -topn 10 -seed 3 -eval_interval_steps 9150 -training_steps 915000 -early_stopping_steps_to_wait 45750 -optimizer_type Adam -L1_flag -norm_lambda 1 -kg_lambda 1 &
    BACK_PID=$!
    wait $BACK_PID
    mv ../results/ml1m-sun/ml1m-transe-*.ckpt_final ../results/ml1m-sun/ml1m-transe-pretrained.ckpt
fi

#[TRANSR]
if no_exist "../results/ml1m-sun/ml1m-transr-*.log"
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -data_path ~/git/datasets/ml1m-sun2cao/ -log_path ~/git/results/ml1m-sun/ -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type transr -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.001 -topn 10 -seed 3 -eval_interval_steps 9150 -training_steps 915000 -early_stopping_steps_to_wait 45750 -optimizer_type Adam -L1_flag -norm_lambda 1 -kg_lambda 1 -load_ckpt_file /home/juarez/git/results/ml1m-sun/ml1m-transe-pretrained.ckpt &
    BACK_PID=$!
    wait $BACK_PID
fi

#[TRANSH]
if no_exist "../results/ml1m-sun/ml1m-transh-*.log"
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -data_path ~/git/datasets/ml1m-sun2cao/ -log_path ~/git/results/ml1m-sun/ -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type transh -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.001 -topn 10 -seed 3 -eval_interval_steps 9150 -training_steps 915000 -early_stopping_steps_to_wait 45750 -optimizer_type Adam -L1_flag -norm_lambda 1 -kg_lambda 1 -load_ckpt_file /home/juarez/git/results/ml1m-sun/ml1m-transe-pretrained.ckpt &
    BACK_PID=$!
    wait $BACK_PID
    mv ../results/ml1m-sun/ml1m-transh-*.ckpt_final ../results/ml1m-sun/ml1m-transh-pretrained.ckpt
fi

#FM - Steffen Rendle. 2010. Factorization machines.
if no_exist "../results/ml1m-sun/ml1m-fm-*.log"
then
    CUDA_VISIBLE_DEVICES=1 nohup python run_item_recommendation.py -data_path ~/git/datasets/ml1m-sun2cao/ -log_path ~/git/results/ml1m-sun/ -rec_test_files valid.dat:test.dat -l2_lambda 1e-5 -negtive_samples 1 -model_type fm -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 500 -training_steps 50000 -early_stopping_steps_to_wait 2500 -optimizer_type Adagrad &
    BACK_PID=$!
    wait $BACK_PID
fi

#BPRMF - Steffen Rendle, Christoph Freudenthaler, Zeno Gantner, and Lars Schmidt-Thieme. 2009. BPR: Bayesian personalized ranking from implicit feedback. In UAI.
if no_exist "../results/ml1m-sun/ml1m-bprmf-*.log"
then
    CUDA_VISIBLE_DEVICES=1 nohup python run_item_recommendation.py -data_path ~/git/datasets/ml1m-sun2cao/ -log_path ~/git/results/ml1m-sun/ -rec_test_files valid.dat:test.dat -l2_lambda 1e-5 -negtive_samples 1 -model_type bprmf -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 5000 -training_steps 500000 -early_stopping_steps_to_wait 25000 -optimizer_type Adagrad &
    BACK_PID=$!
    wait $BACK_PID
    mv ../results/ml1m-sun/ml1m-bprmf-*.ckpt ../results/ml1m-sun/ml1m-bprmf-pretrained.ckpt
fi

#TransUP
if no_exist "../results/ml1m-sun/ml1m-transup-*.log"
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_item_recommendation.py -data_path ~/git/datasets/ml1m-sun2cao/ -log_path ~/git/results/ml1m-sun/ -rec_test_files valid.dat:test.dat -l2_lambda 1e-5 -negtive_samples 1 -model_type transup -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 500 -training_steps 50000 -early_stopping_steps_to_wait 2500 -optimizer_type Adagrad -L1_flag -num_preferences 20 -nouse_st_gumbel -load_ckpt_file /home/juarez/git/results/ml1m-sun/ml1m-bprmf-pretrained.ckpt &
    BACK_PID=$!
    wait $BACK_PID
    mv ../results/ml1m-sun/ml1m-transup-*.ckpt ../results/ml1m-sun/ml1m-transup-pretrained.ckpt
fi

#CFKG (TransE) - Yongfeng Zhang, Qingyao Ai, Xu Chen, and Pengfei Wang. 2018. Learning over Knowledge-Base Embeddings for Recommendation. In SIGIR.
if no_exist "../results/ml1m-sun/ml1m-cfkg-*.log"
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/ml1m-sun2cao/ -log_path ~/git/results/ml1m-sun/ -rec_test_files valid.dat:test.dat  -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type cfkg -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 19520 -training_steps 1952000 -early_stopping_steps_to_wait 97600 -optimizer_type Adam -joint_ratio 0.5 -share_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -use_st_gumbel -load_ckpt_file /home/juarez/git/results/ml1m-sun/ml1m-transup-pretrained.ckpt:/home/juarez/git/results/ml1m-sun/ml1m-transh-pretrained.ckpt &
    BACK_PID=$!
    wait $BACK_PID
fi

#CKE (TransR) - Fuzheng Zhang, Nicholas Jing Yuan, Defu Lian, Xing Xie, and Wei-Ying Ma. 2016. Collaborative Knowledge Base Embedding for Recommender Systems. In SIGKDD.
if no_exist "../results/ml1m-sun/ml1m-cke-*.log"
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/ml1m-sun2cao/ -log_path ~/git/results/ml1m-sun/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type cke -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 19520 -training_steps 1952000 -early_stopping_steps_to_wait 97600 -optimizer_type Adam -joint_ratio 0.5 -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -use_st_gumbel -load_ckpt_file /home/juarez/git/results/ml1m-sun/ml1m-bprmf-pretrained.ckpt:/home/juarez/git/results/ml1m-sun/ml1m-transe-pretrained.ckpt &
    BACK_PID=$!
    wait $BACK_PID
fi

#CoFM (FM+TransE) - Guangyuan Piao and John G. Breslin. 2018. Transfer Learning for Item Recommendations and Knowledge Graph Completion in Item Related Domains via a Co-Factorization Model. In ESWC.
if no_exist "../results/ml1m-sun/ml1m-cofm-*.log"
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/ml1m-sun2cao/ -log_path ~/git/results/ml1m-sun/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type cofm -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 19520 -training_steps 1952000 -early_stopping_steps_to_wait 97600 -optimizer_type Adam -joint_ratio 0.5 -load_ckpt_file /home/juarez/git/results/ml1m-sun/ml1m-bprmf-pretrained.ckpt:/home/juarez/git/results/ml1m-sun/ml1m-transe-pretrained.ckpt -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 &
    BACK_PID=$!
    wait $BACK_PID
fi

#JTransUP
if no_exist "../results/ml1m-sun/ml1m-jtransup-*.log"
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/ml1m-sun2cao/ -log_path ~/git/results/ml1m-sun/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type jtransup -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 19520 -training_steps 1952000 -early_stopping_steps_to_wait 97600 -optimizer_type Adam -joint_ratio 0.5 -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -nouse_st_gumbel -load_ckpt_file /home/juarez/git/results/ml1m-sun/ml1m-bprmf-pretrained.ckpt:/home/juarez/git/results/ml1m-sun/ml1m-transe-pretrained.ckpt &
    BACK_PID=$!
    wait $BACK_PID
fi
