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

#[activate jointrec]
conda deactivate
conda activate jointrec

# RUN preprocess_sun2cao FIRST!
if no_exist "~/git/datasets/ml1m-sun2kgat/train.txt"
then
    #[train.txt, test.txt by splitting rating-delete-missing-item.txt]
    #python sun_split.py --loadfile '../../datasets/ml1m-sun/ml1m/rating-delete-missing-itemid.txt' --column 'user_id'  --frac '0.1,0.2' --savepath '../../datasets/ml1m-sun2kgat/' &
    BACK_PID=$!
    wait $BACK_PID

    #[kg_final.txt by joining sun2cao/ train.dat, valid.dat, test.dat]
    cat ~/git/datasets/ml1m-sun2cao/ml1m/kg/train.dat > ~/git/datasets/ml1m-sun2kgat/kg.txt
    cat ~/git/datasets/ml1m-sun2cao/ml1m/kg/valid.dat >> ~/git/datasets/ml1m-sun2kgat/kg.txt
    cat ~/git/datasets/ml1m-sun2cao/ml1m/kg/test.dat >> ~/git/datasets/ml1m-sun2kgat/kg.txt
    awk '{print $1,$3,$2}' ~/git/datasets/ml1m-sun2kgat/kg.txt > ~/git/datasets/ml1m-sun2kgat/kg_final.txt
    rm ~/git/datasets/ml1m-sun2kgat/kg.txt
    #sed 's/\t/ /g' ~/git/datasets/ml1m-sun2kgat/kg_final.txt

    ln -s ~/git/datasets/ml1m-sun2kgat/kgat_train.txt ~/git/knowledge_graph_attention_network/Data/ml1m-sun2kgat/train.txt
    ln -s ~/git/datasets/ml1m-sun2kgat/kgat_test.txt ~/git/knowledge_graph_attention_network/Data/ml1m-sun2kgat/test.txt
    ln -s ~/git/datasets/ml1m-sun2kgat/kg_final.txt ~/git/knowledge_graph_attention_network/Data/ml1m-sun2kgat/kg_final.txt
fi

#[activate kgat]
conda deactivate
conda activate kgat

cd ~/git/knowledge_graph_attention_network/Model/
python Main.py --model_type kgat --alg_type bi --dataset ml1m-sun2kgat --regs [1e-5,1e-5] --layer_size [64,32,16] --embed_size 64 --lr 0.0001 --epoch 1000 --verbose 50 --save_flag 1 --pretrain -1 --batch_size 1024 --node_dropout [0.1] --mess_dropout [0.1,0.1,0.1] --use_att True --use_kge True
