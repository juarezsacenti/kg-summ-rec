#!/bin/bash
cd ../

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
mkdir datasets/ml1m-sun_sum0
mkdir datasets/ml1m-sun_sum0/ml1m
mkdir datasets/ml1m-sun_sum0/ml1m/kg
mkdir datasets/ml1m-sun_sum1
mkdir datasets/ml1m-sun_sum1/ml1m
mkdir datasets/ml1m-sun_sum1/ml1m/kg

git clone https://github.com/TaoMiner/joint-kg-recommender.git
git clone https://github.com/juarezsacenti/ORBS.git
git clone https://github.com/sunzhuntu/Recurrent-Knowledge-Graph-Embedding.git
cp Recurrent-Knowledge-Graph-Embedding/data/ml/* datasets/ml1m-sun/ml1m/

mkdir results/
mkdir results/ml1m-cao
mkdir results/ml1m-sun
mkdir results/ml1m-sun_sum0
mkdir results/ml1m-sun_sum1
