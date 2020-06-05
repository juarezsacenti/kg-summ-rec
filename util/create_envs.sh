#!/bin/bash
cd ~/git/know-rec

# TaoMiner/joint-kg-recommender environment:
conda create -n jointrec python=3.6
conda activate jointrec

wget -O downloaded_file https://download.pytorch.org/whl/cu75/torch-0.3.0.post4-cp36-cp36m-linux_x86_64.whl
pip install downloaded_file
conda install python-gflags
pip install visdom
conda install -c conda-forge tqdm
conda install pandas
pip install -U git+git://github.com/caserec/CaseRecommender.git

conda deactivate

# sunzhuntu/Recurrent-Knowledge-Graph-Embedding environment:
conda create -n rkge python=3.6.9
conda activate rkge

conda install pytorch=0.4.1 cuda75 -c pytorch
conda install networkx
pip install -U git+git://github.com/caserec/CaseRecommender.git

conda deactivate

# juarezsacenti/orbs environment:
#conda create -n orbs python=3.6
#conda activate orbs

#sudo apt-get update
#sudo apt-get install gcc
#pip install numpy cython
#cd ~/git/ORBS
#python setup.py install

#conda deactivate
