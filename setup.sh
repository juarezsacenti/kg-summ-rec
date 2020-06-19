#!/bin/bash
cd ../

################################################################################
###                                 Datasets                                 ###
################################################################################
mkdir datasets
mkdir datasets/ml1m-cao
mkdir datasets/ml1m-cao/ml1m
mkdir datasets/ml1m-cao/ml1m/kg
mkdir datasets/ml1m-cao2sun
mkdir datasets/ml1m-cao2sun/ml1m
mkdir datasets/ml1m-sun
mkdir datasets/ml1m-sun/ml1m
mkdir datasets/ml1m-sun2cao
mkdir datasets/ml1m-sun2cao/ml1m
mkdir datasets/ml1m-sun2cao/ml1m/kg
mkdir datasets/ml1m-sun2kgat
mkdir datasets/ml1m-sun_sum0
mkdir datasets/ml1m-sun_sum0/ml1m
mkdir datasets/ml1m-sun_sum0/ml1m/kg
mkdir datasets/ml1m-sun_sum1
mkdir datasets/ml1m-sun_sum1/ml1m
mkdir datasets/ml1m-sun_sum1/ml1m/kg
mkdir datasets/ml1m-sun_sum5
mkdir datasets/ml1m-sun_sum5/ml1m
mkdir datasets/ml1m-sun_sum5/ml1m/kg
mkdir datasets/ml1m-sun_sum4
mkdir datasets/ml1m-sun_sum4/ml1m
mkdir datasets/ml1m-sun_sum4/ml1m/kg

################################################################################
###                                 Projects                                 ###
################################################################################
### Cao's project
git clone https://github.com/TaoMiner/joint-kg-recommender.git
### Cao's dataset
cd datasets/ml1m-cao/
wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=1FIbaWzP6AWUNG2-8q6SKQ3b9yTiiLvGW' -O datasets.zip
unzip datasets.zip
mv datasets的副本/ml1m/kg/*.* ml1m/kg/
mv datasets的副本/ml1m/*.* ml1m/
cd ../../
### Adapting Cao to CaseRecommender
mv joint-kg-recommender/jTransUP/models/item_recommendation.py joint-kg-recommender/jTransUP/models/item_recommendation.py_ORIG
cp know-rec/adapt/item_recommendation.py joint-kg-recommender/jTransUP/models/item_recommendation.py
mv joint-kg-recommender/jTransUP/models/knowledgable_recommendation.py joint-kg-recommender/jTransUP/models/knowledgable_recommendation.py_ORIG
cp know-rec/adapt/knowledgable_recommendation.py joint-kg-recommender/jTransUP/models/knowledgable_recommendation.py

### Sun's project
git clone https://github.com/sunzhuntu/Recurrent-Knowledge-Graph-Embedding.git
### Sun's dataset
cp Recurrent-Knowledge-Graph-Embedding/data/ml/* datasets/ml1m-sun/ml1m/
### Adapting Sun to CaseRecommender
mv Recurrent-Knowledge-Graph-Embedding/recurrent-neural-network.py Recurrent-Knowledge-Graph-Embedding/recurrent-neural-network.py_ORIG
cp know-rec/adapt/recurrent-neural-network.py Recurrent-Knowledge-Graph-Embedding/recurrent-neural-network.py

### KGAT's project
git clone https://github.com/xiangwang1223/knowledge_graph_attention_network.git
mkdir knowledge_graph_attention_network/Data/ml1m-sun2kgat

### RippleNet's project
git clone https://github.com/hwwang55/RippleNet.git

################################################################################
###                                 Results                                  ###
################################################################################
mkdir results/
mkdir results/ml1m-cao
mkdir results/ml1m-sun
mkdir results/ml1m-sun_sum0
mkdir results/ml1m-sun_sum1
mkdir results/ml1m-sun_sum5
mkdir results/ml1m-sun_sum4
