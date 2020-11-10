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

################################################################################
###                      Evaluate ml-sun_complex-25                          ###
################################################################################

################################################################################
###                            Create Result folder                          ###
################################################################################
if [ ! -d "$HOME/git/results/ml-sun_complex-25" ]
then 
    echo '[kg-summ-rs] Creating ~git/results/ml-sun_complex-25'
    mkdir ~/git/results/ml-sun_complex-25/
fi

################################################################################
###                          Run Cao's RS algorithms                         ###
################################################################################
#[activate jointrec]
conda deactivate
conda activate jointrec

cd ~/git/joint-kg-recommender

#[TRANSE]
if no_exist "$HOME/git/results/ml-sun_complex-25/ml1m-transe-*.log"
then
    echo '[kg-summ-rs] Running TransE with ml-sun_complex-25'
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -data_path ~/git/datasets/ml-sun_complex-25/cao-format/ -log_path ~/git/results/ml-sun_complex-25/ -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type transe -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.001 -topn 10 -seed 3 -eval_interval_steps 9150 -training_steps 915000 -early_stopping_steps_to_wait 45750 -optimizer_type Adam -L1_flag -norm_lambda 1 -kg_lambda 1 &
    wait $!
    mv ~/git/results/ml-sun_complex-25/ml1m-transe-*.ckpt_final ~/git/results/ml-sun_complex-25/ml1m-transe-pretrained.ckpt
fi

#[TRANSR]
if no_exist "$HOME/git/results/ml-sun_complex-25/ml1m-transr-*.log"
then
    echo '[kg-summ-rs] Running TransR with ml-sun_complex-25'
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -data_path ~/git/datasets/ml-sun_complex-25/cao-format/ -log_path ~/git/results/ml-sun_complex-25/ -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type transr -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.001 -topn 10 -seed 3 -eval_interval_steps 9150 -training_steps 915000 -early_stopping_steps_to_wait 45750 -optimizer_type Adam -L1_flag -norm_lambda 1 -kg_lambda 1 -load_ckpt_file "$HOME/git/results/ml-sun_complex-25/ml1m-transe-pretrained.ckpt" &
    wait $!
fi

#[TRANSH]
if no_exist "$HOME/git/results/ml-sun_complex-25/ml1m-transh-*.log"
then
    echo '[kg-summ-rs] Running TransH with ml-sun_complex-25'
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -data_path ~/git/datasets/ml-sun_complex-25/cao-format/ -log_path ~/git/results/ml-sun_complex-25/ -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type transh -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.001 -topn 10 -seed 3 -eval_interval_steps 9150 -training_steps 915000 -early_stopping_steps_to_wait 45750 -optimizer_type Adam -L1_flag -norm_lambda 1 -kg_lambda 1 -load_ckpt_file "$HOME/git/results/ml-sun_complex-25/ml1m-transe-pretrained.ckpt" &
    wait $!
    mv ~/git/results/ml-sun_complex-25/ml1m-transh-*.ckpt_final ~/git/results/ml-sun_complex-25/ml1m-transh-pretrained.ckpt
fi

#FM - Steffen Rendle. 2010. Factorization machines.
if no_exist "$HOME/git/results/ml-sun_complex-25/ml1m-fm-*.log"
then
    echo '[kg-summ-rs] Running FM with ml-sun_complex-25'
    CUDA_VISIBLE_DEVICES=0 nohup python run_item_recommendation.py -data_path ~/git/datasets/ml-sun_complex-25/cao-format/ -log_path ~/git/results/ml-sun_complex-25/ -rec_test_files valid.dat:test.dat -l2_lambda 1e-5 -negtive_samples 1 -model_type fm -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 500 -training_steps 50000 -early_stopping_steps_to_wait 2500 -optimizer_type Adagrad &    wait $!
fi

#BPRMF - Steffen Rendle, Christoph Freudenthaler, Zeno Gantner, and Lars Schmidt-Thieme. 2009. BPR: Bayesian personalized ranking from implicit feedback. In UAI.
if no_exist "$HOME/git/results/ml-sun_complex-25/ml1m-bprmf-*.log"
then
    echo '[kg-summ-rs] Running BPRMF with ml-sun_complex-25'
    CUDA_VISIBLE_DEVICES=0 nohup python run_item_recommendation.py -data_path ~/git/datasets/ml-sun_complex-25/cao-format/ -log_path ~/git/results/ml-sun_complex-25/ -rec_test_files valid.dat:test.dat -l2_lambda 1e-5 -negtive_samples 1 -model_type bprmf -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 5000 -training_steps 500000 -early_stopping_steps_to_wait 25000 -optimizer_type Adagrad &
    wait $!
    mv ~/git/results/ml-sun_complex-25/ml1m-bprmf-*.ckpt ~/git/results/ml-sun_complex-25/ml1m-bprmf-pretrained.ckpt
fi

#TransUP
if no_exist "$HOME/git/results/ml-sun_complex-25/ml1m-transup-*.log"
then
    echo '[kg-summ-rs] Running TransUP with ml-sun_complex-25'
    CUDA_VISIBLE_DEVICES=0 nohup python run_item_recommendation.py -data_path ~/git/datasets/ml-sun_complex-25/cao-format/ -log_path ~/git/results/ml-sun_complex-25/ -rec_test_files valid.dat:test.dat -l2_lambda 1e-5 -negtive_samples 1 -model_type transup -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 500 -training_steps 50000 -early_stopping_steps_to_wait 2500 -optimizer_type Adagrad -L1_flag -num_preferences 20 -nouse_st_gumbel -load_ckpt_file "$HOME/git/results/ml-sun_complex-25/ml1m-bprmf-pretrained.ckpt" &
    wait $!
    mv ~/git/results/ml-sun_complex-25/ml1m-transup-*.ckpt ~/git/results/ml-sun_complex-25/ml1m-transup-pretrained.ckpt
fi

#CFKG (TransE) - Yongfeng Zhang, Qingyao Ai, Xu Chen, and Pengfei Wang. 2018. Learning over Knowledge-Base Embeddings for Recommendation. In SIGIR.
if no_exist "$HOME/git/results/ml-sun_complex-25/ml1m-cfkg-*.log"
then
    echo '[kg-summ-rs] Running CFKG with ml-sun_complex-25'
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/ml-sun_complex-25/cao-format/ -log_path ~/git/results/ml-sun_complex-25/ -rec_test_files valid.dat:test.dat  -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type cfkg -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 19520 -training_steps 1952000 -early_stopping_steps_to_wait 97600 -optimizer_type Adam -joint_ratio 0.5 -share_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -use_st_gumbel -load_ckpt_file "$HOME/git/results/ml-sun_complex-25/ml1m-transup-pretrained.ckpt:$HOME/git/results/ml-sun_complex-25/ml1m-transh-pretrained.ckpt" &
    wait $!

    #cd ~/git/results/ml-sun_complex-25/
    #fVar=$(find . -type f -iname "ml1m-cfkg-*.log");
    #fT=${fVar:2}  # removing first two characters'./'
    #experiment_name=${fT%.log}

    #CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/ml-sun_complex-25/cao-format -log_path ~/git/results/ml-sun_complex-25/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type cfkg -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 19520 -training_steps 1952000  -early_stopping_steps_to_wait 97600 -optimizer_type Adam -joint_ratio 0.5 -share_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -use_st_gumbel -eval_only_mode -load_experiment_name "${experiment_name}" -load_ckpt_file "${experiment_name}.ckpt_final" &
    #wait $!

    #cd ~/git/joint-kg-recommender
fi

#CKE (TransR) - Fuzheng Zhang, Nicholas Jing Yuan, Defu Lian, Xing Xie, and Wei-Ying Ma. 2016. Collaborative Knowledge Base Embedding for Recommender Systems. In SIGKDD.
if no_exist "$HOME/git/results/ml-sun_complex-25/ml1m-cke-*.log"
then
    echo '[kg-summ-rs] Running CKE with ml-sun_complex-25'
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/ml-sun_complex-25/cao-format/ -log_path ~/git/results/ml-sun_complex-25/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type cke -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 19520 -training_steps 1952000 -early_stopping_steps_to_wait 97600 -optimizer_type Adam -joint_ratio 0.5 -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -use_st_gumbel -load_ckpt_file "$HOME/git/results/ml-sun_complex-25/ml1m-bprmf-pretrained.ckpt:$HOME/git/results/ml-sun_complex-25/ml1m-transe-pretrained.ckpt" &
    wait $!

    #cd ~/git/results/ml-sun_complex-25/
    #fVar=$(find . -type f -iname "ml1m-cke-*.log");
    #fT=${fVar:2}  # removing first two characters'./'
    #experiment_name=${fT%.log}

    #CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/ml-sun_complex-25/cao-format -log_path ~/git/results/ml-sun_complex-25/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -model_type cke -nohas_visualization -dataset ml1m -embedding_size 100 -topn 10 -seed 3 -eval_only_mode -load_experiment_name "${experiment_name}" -load_ckpt_file "${experiment_name}.ckpt_final" &
    #wait $!

    #cd ~/git/joint-kg-recommender
fi

#CoFM (FM+TransE) - Guangyuan Piao and John G. Breslin. 2018. Transfer Learning for Item Recommendations and Knowledge Graph Completion in Item Related Domains via a Co-Factorization Model. In ESWC.
if no_exist "$HOME/git/results/ml-sun_complex-25/ml1m-cofm-*.log"
then
    echo '[kg-summ-rs] Running CoFM with ml-sun_complex-25'
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/ml-sun_complex-25/cao-format/ -log_path ~/git/results/ml-sun_complex-25/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type cofm -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 19520 -training_steps 1952000 -early_stopping_steps_to_wait 97600 -optimizer_type Adam -joint_ratio 0.5 -load_ckpt_file "$HOME/git/results/ml-sun_complex-25/ml1m-bprmf-pretrained.ckpt:$HOME/git/results/ml-sun_complex-25/ml1m-transe-pretrained.ckpt" -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 &
    wait $!

    #cd ~/git/results/ml-sun_complex-25/
    #fVar=$(find . -type f -iname "ml1m-cofm-*.log");
    #fT=${fVar:2}  # removing first two characters'./'
    #experiment_name=${fT%.log}

    #CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/ml-sun_complex-25/cao-format -log_path ~/git/results/ml-sun_complex-25/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -model_type cofm -nohas_visualization -dataset ml1m -embedding_size 100 -topn 10 -seed 3 -eval_only_mode -load_experiment_name "${experiment_name}" -load_ckpt_file "${experiment_name}.ckpt_final" &
    #wait $!

    #cd ~/git/joint-kg-recommender
fi

#JTransUP
if no_exist "$HOME/git/results/ml-sun_complex-25/ml1m-jtransup-*.log"
then
    echo '[kg-summ-rs] Running JTransUP with ml-sun_complex-25'
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/ml-sun_complex-25/cao-format/ -log_path ~/git/results/ml-sun_complex-25/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type jtransup -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 19520 -training_steps 1952000 -early_stopping_steps_to_wait 97600 -optimizer_type Adam -joint_ratio 0.5 -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -nouse_st_gumbel -load_ckpt_file "$HOME/git/results/ml-sun_complex-25/ml1m-bprmf-pretrained.ckpt:$HOME/git/results/ml-sun_complex-25/ml1m-transe-pretrained.ckpt" &
    wait $!

    #cd ~/git/results/ml-sun_complex-25/
    #fVar=$(find . -type f -iname "ml1m-jtransup-*.log");
    #fT=${fVar:2}  # removing first two characters'./'
    #experiment_name=${fT%.log}

    #CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/ml-sun_complex-25/cao-format -log_path ~/git/results/ml-sun_complex-25/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -model_type jtransup -nohas_visualization -dataset ml1m -embedding_size 100 -topn 10 -seed 3 -eval_only_mode -load_experiment_name "${experiment_name}" -load_ckpt_file "${experiment_name}.ckpt_final" &
    #wait $!

    #cd ~/git/joint-kg-recommender
fi

#[activate rkge]
#conda deactivate
#conda activate rkge

#cd ~/git/Recurrent-Knowledge-Graph-Embedding

#[RKGE]
#if no_exist "$HOME/git/results/ml-sun_complex-25/ml-rkge-results.log"
#then
#    echo '[kg-summ-rs] Running RKGE with ml-sun_complex-25'
#    CUDA_VISIBLE_DEVICES=0 nohup python recurrent-neural-network.py --inputdim 10 --hiddendim 16 --outdim 1 --iteration 5 --learingrate 0.2 --positivepath ~/git/datasets/ml-sun_complex-25/sun-format/positive-path.txt --negativepath ~/git/datasets/ml-sun_complex-25/sun-format/negative-path.txt --pretrainuserembedding ~/git/datasets/ml-sun/sun-format/pre-train-user-embedding.txt --pretrainmovieembedding ~/git/datasets/ml-sun/sun-format/pre-train-item-embedding.txt --train ~/git/datasets/ml-sun_complex-25/sun-format/sun_training.txt --test ~/git/datasets/ml-sun_complex-25/sun-format/sun_test.txt --results ~/git/results/ml-sun_complex-25/ml-rkge-results.log &
#    wait $!
#fi

