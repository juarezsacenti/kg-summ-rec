#!/bin/bash
cd ../

mkdir datasets/
mkdir datasets/ml1m-cao
mkdir datasets/ml1m-sun
mkdir datasets/ml1m-sun2cao
mkdir datasets/ml1m-cao2sun

git clone https://github.com/TaoMiner/joint-kg-recommender.git

git clone https://github.com/sunzhuntu/Recurrent-Knowledge-Graph-Embedding.git

cp Recurrent-Knowledge-Graph-Embedding/data/ml/* datasets/ml1m-sun/

mkdir results/
mkdir results/ml1m-cao
mkdir results/ml1m-sun
