#!/bin/bash

#[ampligraph]
source clean_ampligraph.sh

#[datasets]

yes | rm -r ~/git/datasets/hs_*

#[results]
yes | rm -r ~/git/results/hs_*

#[nohup]
yes | rm ~/git/joint-kg-recommender/nohup.out

#[.out]
yes | rm ~/git/know-rec/run_hyperparameter_selection.out

