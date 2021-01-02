#!/bin/bash
#arg[0]: dataset name, e.g. 'ml1m-summarized_sun'

################################################################################
###                                   Logs                                   ###
################################################################################
#[Nohup]
rm ~/git/joint-kg-recommender/nohup.out
rm ~/git/Recurrent-Knowledge-Graph-Embedding/nohup.out
rm ~/git/kg-summ-rec/nohup.out

################################################################################
###                                 Datasets                                 ###
################################################################################
#[ml-sun]
#rm -rf ~/git/datasets/ml-sun/cao-format

#[ml-cao]
#rm -rf ~/git/datasets/ml-cao/sun-format

################################################################################
###                                 Docker                                   ###
################################################################################
#[ampligraph-data]
rm ~/git/kg-summ-rec/docker/ampligraph-data/application.log
rm -r ~/git/kg-summ-rec/docker/ampligraph-data/temp/*.*

#[gemsec-data]
rm ~/git/kg-summ-rec/docker/ampligraph-data/application.log
rm -r ~/git/kg-summ-rec/docker/gemsec-data/temp/*.*

################################################################################
###                                 Results                                  ###
################################################################################
#[ml-sun]
#rm ~/git/results/ml-sun/*.*

#[ml-cao]
# rm ~/git/results/ml-cao/*.*

#[ml-sun_complex-25]
rm -rf ~/git/results/ml-sun_complex-25

#[ml-sun_complex-50]
#rm -rf ~/git/results/ml-sun_complex-50

#[ml-sun_complex-75]
#rm -rf ~/git/results/ml-sun_complex-75
