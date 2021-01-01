#!/bin/bash

#[ampligraph]
source clean_ampligraph.sh

#[datasets]
yes | rm -r ~/git/datasets/ml-sun_ho_*

#[results]
yes | rm -r ~/git/results/ml-sun_ho_*

#[nohup]
yes | rm ~/git/joint-kg-recommender/nohup.out

