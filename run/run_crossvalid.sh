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

#[Selecting folds]

cd ../util

#[activate rkge]
conda deactivate
conda activate rkge

python select_fold.py --foldpath ../../datasets/ml1m-sun2cao/ml1m/ --savepath ../../datasets/ml1m-sun2cao/ml1m/


#[Preprocessing]

cd ../../Recurrent-Knowledge-Graph-Embedding

#[rkge prepocessing]
python negative-sample.py --train ../datasets/ml1m-sun2cao/ml1m/sun_training.txt --negative ../datasets/ml1m-sun2cao/ml1m/negative.txt --shrink 0.05
python path-extraction-ml.py --training ../datasets/ml1m-sun2cao/ml1m/sun_training.txt --negtive ../datasets/ml1m-sun2cao/ml1m/negative.txt --auxiliary ../datasets/ml1m-sun2cao/ml1m/auxiliary-mapping.txt --positivepath ../datasets/ml1m-sun2cao/ml1m/positive-path.txt --negativepath ../datasets/ml1m-sun2cao/ml1m/negative-path.txt --pathlength 3 --samplesize 5

#[sun2cao/train.dat, valid.dat, test.dat, ... from sun2cao]
ln -s ~/git/datasets/ml1m-sun2cao/ml1m/train.dat ~/git/datasets/ml1m-sun_sum0/ml1m/train.dat
ln -s ~/git/datasets/ml1m-sun2cao/ml1m/valid.dat ~/git/datasets/ml1m-sun_sum0/ml1m/valid.dat
ln -s ~/git/datasets/ml1m-sun2cao/ml1m/test.dat ~/git/datasets/ml1m-sun_sum0/ml1m/test.dat
ln -s ~/git/datasets/ml1m-sun2cao/ml1m/sun_training.txt ~/git/datasets/ml1m-sun_sum0/ml1m/sun_training.txt
ln -s ~/git/datasets/ml1m-sun2cao/ml1m/sun_test.txt ~/git/datasets/ml1m-sun_sum0/ml1m/sun_test.txt
ln -s ~/git/datasets/ml1m-sun2cao/ml1m/negative.txt ~/git/datasets/ml1m-sun_sum0/ml1m/negative.txt

#[rkge preprocessing]
python path-extraction-ml.py --training ../datasets/ml1m-sun_sum0/ml1m/sun_training.txt --negtive ../datasets/ml1m-sun_sum0/ml1m/negative.txt --auxiliary ../datasets/ml1m-sun_sum0/ml1m/auxiliary-mapping.txt --positivepath ../datasets/ml1m-sun_sum0/ml1m/positive-path.txt --negativepath ../datasets/ml1m-sun_sum0/ml1m/negative-path.txt --pathlength 3 --samplesize 5


#[Running]

#[activate jointrec]
conda deactivate
conda activate jointrec

cd ../joint-kg-recommender

#[TRANSE]
if no_exist "../results/ml1m-sun/ml1m-transe-*.log"
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -data_path ~/git/datasets/ml1m-sun2cao/ -log_path ~/git/results/ml1m-sun/ -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type transe -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.001 -topn 10 -seed 3 -eval_interval_steps 9150 -training_steps 915000 -early_stopping_steps_to_wait 45750 -optimizer_type Adam -L1_flag -norm_lambda 1 -kg_lambda 1 &
    BACK_PID=$!
    wait $BACK_PID
    mv "../results/ml1m-sun/ml1m-transe-*.ckpt_final" "../results/ml1m-sun/ml1m-transe-pretrained.ckpt"
fi

#[TRANSR]
if no_exist "../results/ml1m-sun/ml1m-transr-*.log"
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -data_path ~/git/datasets/ml1m-sun2cao/ -log_path ~/git/results/ml1m-sun/ -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type transr -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.001 -topn 10 -seed 3 -eval_interval_steps 9150 -training_steps 915000 -early_stopping_steps_to_wait 45750 -optimizer_type Adam -L1_flag -norm_lambda 1 -kg_lambda 1 -load_ckpt_file ~/git/results/ml1m-sun/ml1m-transe-pretrained.ckpt &
    BACK_PID=$!
    wait $BACK_PID
fi

#[TRANSH]
if no_exist "../results/ml1m-sun/ml1m-transh-*.log"
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -data_path ~/git/datasets/ml1m-sun2cao/ -log_path ~/git/results/ml1m-sun/ -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type transh -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.001 -topn 10 -seed 3 -eval_interval_steps 9150 -training_steps 915000 -early_stopping_steps_to_wait 45750 -optimizer_type Adam -L1_flag -norm_lambda 1 -kg_lambda 1 -load_ckpt_file ~/git/results/ml1m-sun/ml1m-transe-pretrained.ckpt &
    BACK_PID=$!
    wait $BACK_PID
    mv "../results/ml1m-sun/ml1m-transh-*.ckpt_final" "../results/ml1m-sun/ml1m-transh-pretrained.ckpt"
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
    mv "../results/ml1m-sun/ml1m-bprmf-*.ckpt" "../results/ml1m-sun/ml1m-bprmf-pretrained.ckpt"
fi

#TransUP
if no_exist "../results/ml1m-sun/ml1m-transup-*.log"
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_item_recommendation.py -data_path ~/git/datasets/ml1m-sun2cao/ -log_path ~/git/results/ml1m-sun/ -rec_test_files valid.dat:test.dat -l2_lambda 1e-5 -negtive_samples 1 -model_type transup -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 500 -training_steps 50000 -early_stopping_steps_to_wait 2500 -optimizer_type Adagrad -L1_flag -num_preferences 20 -nouse_st_gumbel -load_ckpt_file ~/git/results/ml1m-sun/ml1m-bprmf-pretrained.ckpt &
    BACK_PID=$!
    wait $BACK_PID
    mv "../results/ml1m-sun/ml1m-transup-*.ckpt" "../results/ml1m-sun/ml1m-transup-pretrained.ckpt"
fi

#CFKG (TransE) - Yongfeng Zhang, Qingyao Ai, Xu Chen, and Pengfei Wang. 2018. Learning over Knowledge-Base Embeddings for Recommendation. In SIGIR.
if no_exist "../results/ml1m-sun/ml1m-cfkg-*.log"
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/ml1m-sun2cao/ -log_path ~/git/results/ml1m-sun/ -rec_test_files valid.dat:test.dat  -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type cfkg -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 19520 -training_steps 1952000 -early_stopping_steps_to_wait 97600 -optimizer_type Adam -joint_ratio 0.5 -share_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -use_st_gumbel -load_ckpt_file ~/git/results/ml1m-sun/ml1m-transup-pretrained.ckpt:~/git/results/ml1m-sun/ml1m-transh-pretrained.ckpt &
    BACK_PID=$!
    wait $BACK_PID
fi

#CKE (TransR) - Fuzheng Zhang, Nicholas Jing Yuan, Defu Lian, Xing Xie, and Wei-Ying Ma. 2016. Collaborative Knowledge Base Embedding for Recommender Systems. In SIGKDD.
if no_exist "../results/ml1m-sun/ml1m-cke-*.log"
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/ml1m-sun2cao/ -log_path ~/git/results/ml1m-sun/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type cke -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 19520 -training_steps 1952000 -early_stopping_steps_to_wait 97600 -optimizer_type Adam -joint_ratio 0.5 -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -use_st_gumbel -load_ckpt_file ~/git/results/ml1m-sun/ml1m-bprmf-pretrained.ckpt:~/git/results/ml1m-sun/ml1m-transe-pretrained.ckpt &
    BACK_PID=$!
    wait $BACK_PID
fi

#CoFM (FM+TransE) - Guangyuan Piao and John G. Breslin. 2018. Transfer Learning for Item Recommendations and Knowledge Graph Completion in Item Related Domains via a Co-Factorization Model. In ESWC.
if no_exist "../results/ml1m-sun/ml1m-cofm-*.log"
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/ml1m-sun2cao/ -log_path ~/git/results/ml1m-sun/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type cofm -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 19520 -training_steps 1952000 -early_stopping_steps_to_wait 97600 -optimizer_type Adam -joint_ratio 0.5 -load_ckpt_file ~/git/results/ml1m-sun/ml1m-bprmf-pretrained.ckpt:~/git/results/ml1m-sun/ml1m-transe-pretrained.ckpt -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 &
    BACK_PID=$!
    wait $BACK_PID
fi

#JTransUP
if no_exist "../results/ml1m-sun/ml1m-jtransup-*.log"
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/ml1m-sun2cao/ -log_path ~/git/results/ml1m-sun/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type jtransup -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 19520 -training_steps 1952000 -early_stopping_steps_to_wait 97600 -optimizer_type Adam -joint_ratio 0.5 -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -nouse_st_gumbel -load_ckpt_file ~/git/results/ml1m-sun/ml1m-bprmf-pretrained.ckpt:~/git/results/ml1m-sun/ml1m-transe-pretrained.ckpt &
    BACK_PID=$!
    wait $BACK_PID
fi

#[activate rkge]
conda deactivate
conda activate rkge

cd ../Recurrent-Knowledge-Graph-Embedding

#[RKGE]
if no_exist "../results/ml1m-sun/ml1m-rkge-results.log"
then
    CUDA_VISIBLE_DEVICES=0 nohup python recurrent-neural-network.py --inputdim 10 --hiddendim 16 --outdim 1 --iteration 5 --learingrate 0.2 --positivepath ~/git/datasets/ml1m-sun2cao/ml1m/positive-path.txt --negativepath ~/git/datasets/ml1m-sun2cao/ml1m/negative-path.txt --pretrainuserembedding ~/git/datasets/ml1m-sun/ml1m/pre-train-user-embedding.txt --pretrainmovieembedding ~/git/datasets/ml1m-sun/ml1m/pre-train-item-embedding.txt --train ~/git/datasets/ml1m-sun2cao/ml1m/sun_training.txt --test ~/git/datasets/ml1m-sun2cao/ml1m/sun_test.txt --results ~/git/results/ml1m-sun/ml1m-rkge-results.log &
    BACK_PID=$!
    wait $BACK_PID
fi

###############
#sun_sum0
###############

#[activate jointrec]
conda deactivate
conda activate jointrec

cd ../joint-kg-recommender

#[TRANSE]
if no_exist "../results/ml1m-sun_sum0/ml1m-transe-*.log"
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -data_path ~/git/datasets/ml1m-sun_sum0/ -log_path ~/git/results/ml1m-sun_sum0/ -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type transe -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.001 -topn 10 -seed 3 -eval_interval_steps 9150 -training_steps 915000 -early_stopping_steps_to_wait 45750 -optimizer_type Adam -L1_flag -norm_lambda 1 -kg_lambda 1 &
    BACK_PID=$!
    wait $BACK_PID
    mv "../results/ml1m-sun_sum0/ml1m-transe-*.ckpt_final" "../results/ml1m-sun_sum0/ml1m-transe-pretrained.ckpt"
fi

#[TRANSR]
if no_exist "../results/ml1m-sun_sum0/ml1m-transr-*.log"
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -data_path ~/git/datasets/ml1m-sun_sum0/ -log_path ~/git/results/ml1m-sun_sum0/ -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type transr -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.001 -topn 10 -seed 3 -eval_interval_steps 9150 -training_steps 915000 -early_stopping_steps_to_wait 45750 -optimizer_type Adam -L1_flag -norm_lambda 1 -kg_lambda 1 -load_ckpt_file ~/git/results/ml1m-sun_sum0/ml1m-transe-pretrained.ckpt &
    BACK_PID=$!
    wait $BACK_PID
fi

#[TRANSH]
if no_exist "../results/ml1m-sun_sum0/ml1m-transh-*.log"
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledge_representation.py -data_path ~/git/datasets/ml1m-sun_sum0/ -log_path ~/git/results/ml1m-sun_sum0/ -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type transh -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.001 -topn 10 -seed 3 -eval_interval_steps 9150 -training_steps 915000 -early_stopping_steps_to_wait 45750 -optimizer_type Adam -L1_flag -norm_lambda 1 -kg_lambda 1 -load_ckpt_file ~/git/results/ml1m-sun_sum0/ml1m-transe-pretrained.ckpt &
    BACK_PID=$!
    wait $BACK_PID
    mv "../results/ml1m-sun_sum0/ml1m-transh-*.ckpt_final" "../results/ml1m-sun_sum0/ml1m-transh-pretrained.ckpt"
fi

#FM - Steffen Rendle. 2010. Factorization machines.
if no_exist "../results/ml1m-sun_sum0/ml1m-fm-*.log"
then
    CUDA_VISIBLE_DEVICES=1 nohup python run_item_recommendation.py -data_path ~/git/datasets/ml1m-sun_sum0/ -log_path ~/git/results/ml1m-sun_sum0/ -rec_test_files valid.dat:test.dat -l2_lambda 1e-5 -negtive_samples 1 -model_type fm -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 500 -training_steps 50000 -early_stopping_steps_to_wait 2500 -optimizer_type Adagrad &
    BACK_PID=$!
    wait $BACK_PID
fi

#BPRMF - Steffen Rendle, Christoph Freudenthaler, Zeno Gantner, and Lars Schmidt-Thieme. 2009. BPR: Bayesian personalized ranking from implicit feedback. In UAI.
if no_exist "../results/ml1m-sun_sum0/ml1m-bprmf-*.log"
then
    CUDA_VISIBLE_DEVICES=1 nohup python run_item_recommendation.py -data_path ~/git/datasets/ml1m-sun_sum0/ -log_path ~/git/results/ml1m-sun_sum0/ -rec_test_files valid.dat:test.dat -l2_lambda 1e-5 -negtive_samples 1 -model_type bprmf -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 5000 -training_steps 500000 -early_stopping_steps_to_wait 25000 -optimizer_type Adagrad &
    BACK_PID=$!
    wait $BACK_PID
    mv "../results/ml1m-sun_sum0/ml1m-bprmf-*.ckpt" "../results/ml1m-sun_sum0/ml1m-bprmf-pretrained.ckpt"
fi

#TransUP
if no_exist "../results/ml1m-sun_sum0/ml1m-transup-*.log"
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_item_recommendation.py -data_path ~/git/datasets/ml1m-sun_sum0/ -log_path ~/git/results/ml1m-sun_sum0/ -rec_test_files valid.dat:test.dat -l2_lambda 1e-5 -negtive_samples 1 -model_type transup -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 500 -training_steps 50000 -early_stopping_steps_to_wait 2500 -optimizer_type Adagrad -L1_flag -num_preferences 20 -nouse_st_gumbel -load_ckpt_file ~/git/results/ml1m-sun_sum0/ml1m-bprmf-pretrained.ckpt &
    BACK_PID=$!
    wait $BACK_PID
    mv "../results/ml1m-sun_sum0/ml1m-transup-*.ckpt" "../results/ml1m-sun_sum0/ml1m-transup-pretrained.ckpt"
fi

#CFKG (TransE) - Yongfeng Zhang, Qingyao Ai, Xu Chen, and Pengfei Wang. 2018. Learning over Knowledge-Base Embeddings for Recommendation. In SIGIR.
if no_exist "../results/ml1m-sun_sum0/ml1m-cfkg-*.log"
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/ml1m-sun_sum0/ -log_path ~/git/results/ml1m-sun_sum0/ -rec_test_files valid.dat:test.dat  -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type cfkg -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 19520 -training_steps 1952000 -early_stopping_steps_to_wait 97600 -optimizer_type Adam -joint_ratio 0.5 -share_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -use_st_gumbel -load_ckpt_file ~/git/results/ml1m-sun_sum0/ml1m-transup-pretrained.ckpt:~/git/results/ml1m-sun_sum0/ml1m-transh-pretrained.ckpt &
    BACK_PID=$!
    wait $BACK_PID
fi

#CKE (TransR) - Fuzheng Zhang, Nicholas Jing Yuan, Defu Lian, Xing Xie, and Wei-Ying Ma. 2016. Collaborative Knowledge Base Embedding for Recommender Systems. In SIGKDD.
if no_exist "../results/ml1m-sun_sum0/ml1m-cke-*.log"
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/ml1m-sun_sum0/ -log_path ~/git/results/ml1m-sun_sum0/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type cke -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 19520 -training_steps 1952000 -early_stopping_steps_to_wait 97600 -optimizer_type Adam -joint_ratio 0.5 -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -use_st_gumbel -load_ckpt_file ~/git/results/ml1m-sun_sum0/ml1m-bprmf-pretrained.ckpt:~/git/results/ml1m-sun_sum0/ml1m-transe-pretrained.ckpt &
    BACK_PID=$!
    wait $BACK_PID
fi

#CoFM (FM+TransE) - Guangyuan Piao and John G. Breslin. 2018. Transfer Learning for Item Recommendations and Knowledge Graph Completion in Item Related Domains via a Co-Factorization Model. In ESWC.
if no_exist "../results/ml1m-sun_sum0/ml1m-cofm-*.log"
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/ml1m-sun_sum0/ -log_path ~/git/results/ml1m-sun_sum0/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type cofm -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 19520 -training_steps 1952000 -early_stopping_steps_to_wait 97600 -optimizer_type Adam -joint_ratio 0.5 -load_ckpt_file ~/git/results/ml1m-sun_sum0/ml1m-bprmf-pretrained.ckpt:~/git/results/ml1m-sun_sum0/ml1m-transe-pretrained.ckpt -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 &
    BACK_PID=$!
    wait $BACK_PID
fi

#JTransUP
if no_exist "../results/ml1m-sun_sum0/ml1m-jtransup-*.log"
then
    CUDA_VISIBLE_DEVICES=0 nohup python run_knowledgable_recommendation.py -data_path ~/git/datasets/ml1m-sun_sum0/ -log_path ~/git/results/ml1m-sun_sum0/ -rec_test_files valid.dat:test.dat -kg_test_files valid.dat:test.dat -l2_lambda 0 -model_type jtransup -nohas_visualization -dataset ml1m -batch_size 256 -embedding_size 100 -learning_rate 0.1 -topn 10 -seed 3 -eval_interval_steps 19520 -training_steps 1952000 -early_stopping_steps_to_wait 97600 -optimizer_type Adam -joint_ratio 0.5 -noshare_embeddings -L1_flag -norm_lambda 1 -kg_lambda 1 -nouse_st_gumbel -load_ckpt_file ~/git/results/ml1m-sun_sum0/ml1m-bprmf-pretrained.ckpt:~/git/results/ml1m-sun_sum0/ml1m-transe-pretrained.ckpt &
    BACK_PID=$!
    wait $BACK_PID
fi

#[activate rkge]
conda deactivate
conda activate rkge

cd ../Recurrent-Knowledge-Graph-Embedding

#[RKGE]
if no_exist "../results/ml1m-sun_sum0/ml1m-rkge-results.log"
then
    CUDA_VISIBLE_DEVICES=0 nohup python recurrent-neural-network.py --inputdim 10 --hiddendim 16 --outdim 1 --iteration 5 --learingrate 0.2 --positivepath ~/git/datasets/ml1m-sun_sum0/ml1m/positive-path.txt --negativepath ~/git/datasets/ml1m-sun_sum0/ml1m/negative-path.txt --pretrainuserembedding ~/git/datasets/ml1m-sun/ml1m/pre-train-user-embedding.txt --pretrainmovieembedding ~/git/datasets/ml1m-sun/ml1m/pre-train-item-embedding.txt --train ~/git/datasets/ml1m-sun_sum0/ml1m/sun_training.txt --test ~/git/datasets/ml1m-sun_sum0/ml1m/sun_test.txt --results ~/git/results/ml1m-sun_sum0/ml1m-rkge-results.log &
    BACK_PID=$!
    wait $BACK_PID
fi
