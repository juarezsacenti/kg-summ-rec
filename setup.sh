#!/bin/bash
# root_folder: ~/git/kg-summ-rec
cd ../

################################################################################
###                                 Datasets                                 ###
################################################################################
mkdir datasets
mkdir datasets/ml-cao
mkdir datasets/ml-cao/cao-format
mkdir datasets/ml-cao/cao-format/ml1m
mkdir datasets/ml-cao/cao-format/ml1m/kg
mkdir datasets/ml-sun
mkdir datasets/ml-sun/sun-format

################################################################################
###                                 Projects                                 ###
################################################################################
### Cao's dataset
cd datasets/ml-cao/
wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=1FIbaWzP6AWUNG2-8q6SKQ3b9yTiiLvGW' -O datasets.zip
unzip datasets.zip
mv datasets的副本/ml1m/kg/*.* cao-format/ml1m/kg/
mv datasets的副本/ml1m/*.* cao-format/ml1m/
rm -rf datasets的副本/
rm -rf __MACOSX/
cd ../../
### Cao's project
git clone https://github.com/TaoMiner/joint-kg-recommender.git
### Adapting Cao to CaseRecommender
mv joint-kg-recommender/jTransUP/models/item_recommendation.py joint-kg-recommender/jTransUP/models/item_recommendation.py_ORIG
cp kg-summ-rec/adapt/item_recommendation.py joint-kg-recommender/jTransUP/models/item_recommendation.py
mv joint-kg-recommender/jTransUP/models/knowledgable_recommendation.py joint-kg-recommender/jTransUP/models/knowledgable_recommendation.py_ORIG
cp kg-summ-rec/adapt/knowledgable_recommendation.py joint-kg-recommender/jTransUP/models/knowledgable_recommendation.py

### Sun's project
git clone https://github.com/sunzhuntu/Recurrent-Knowledge-Graph-Embedding.git
### Sun's dataset
cp Recurrent-Knowledge-Graph-Embedding/data/ml/* datasets/ml-sun/sun_format/
### Adapting Sun to CaseRecommender
mv Recurrent-Knowledge-Graph-Embedding/recurrent-neural-network.py Recurrent-Knowledge-Graph-Embedding/recurrent-neural-network.py_ORIG
cp kg-summ-rec/adapt/recurrent-neural-network.py Recurrent-Knowledge-Graph-Embedding/recurrent-neural-network.py

### KGAT's project
#git clone https://github.com/xiangwang1223/knowledge_graph_attention_network.git
#mkdir knowledge_graph_attention_network/Data/ml1m-sun2kgat

### RippleNet's project
#git clone https://github.com/hwwang55/RippleNet.git

################################################################################
###                                 Results                                  ###
################################################################################
mkdir results/
mkdir results/ml-cao
mkdir results/ml-sun
