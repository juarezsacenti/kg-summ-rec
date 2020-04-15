#!/bin/bash
# arg[0]: dataset name, e.g. 'ml1m-summarized_sun'

rm ~/git/results/$1/*.*
rm ~/git/datasets/$1/ml1m/*.*
rm ~/git/datasets/$1/ml1m/kg/*.*
rm ~/git/joint-kg-recommender/nohup.out
rm ~/git/Recurrent-Knowledge-Graph-Embedding/nohup.out
