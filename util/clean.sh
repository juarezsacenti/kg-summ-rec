#!/bin/bash
# arg[0]: dataset name, e.g. 'ml1m-summarized_sun'

#[Nohup]
rm ~/git/joint-kg-recommender/nohup.out
rm ~/git/Recurrent-Knowledge-Graph-Embedding/nohup.out

#[Dataset ml1m-sun]
rm ~/git/datasets/ml1m-sun2cao/ml1m/*.*
rm ~/git/datasets/ml1m-sun2cao/ml1m/kg/*.*
rm ~/git/results/ml1m-sun/*.*

#[Dataset ml1m-sun_sum0]
rm ~/git/datasets/ml1m-sun_sum0/ml1m/*.*
rm ~/git/datasets/ml1m-sun_sum0/kg/*.*
rm ~/git/results/ml1m-sun_sum0/*.*
