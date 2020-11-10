#!/bin/bash
cd ~/git/know-rec

# TaoMiner/joint-kg-recommender environment:
conda create -n jointrec python=3.6
conda activate jointrec

wget -O torch-0.3.0.post4-cp36-cp36m-linux_x86_64.whl https://download.pytorch.org/whl/cu75/torch-0.3.0.post4-cp36-cp36m-linux_x86_64.whl
pip install torch-0.3.0.post4-cp36-cp36m-linux_x86_64.whl
rm torch-0.3.0.post4-cp36-cp36m-linux_x86_64.whl

conda install python-gflags
pip install visdom
conda install -c conda-forge tqdm
conda install pandas
pip install -U git+git://github.com/caserec/CaseRecommender.git
pip install rdflib

conda deactivate

# sunzhuntu/Recurrent-Knowledge-Graph-Embedding environment:
conda create -n rkge python=3.6.9
conda activate rkge

conda install pytorch=0.4.1 cuda75 -c pytorch
conda install networkx
pip install -U git+git://github.com/caserec/CaseRecommender.git

conda deactivate

# xiangwang1223/knowledge_graph_attention_network
conda create -n kgat python=3.6.5
conda activate kgat

conda install numpy=1.15.4
conda install scipy=1.1.0
conda install scikit-learn=0.20.0
conda install tensorflow-gpu=1.12.0

# hwwang55/RippleNet
conda create -n ripplenet python=3.6.5
conda activate ripplenet

wget -O cuda_8.0_linux.run https://developer.nvidia.com/compute/cuda/8.0/Prod2/local_installers/cuda_8.0.61_375.26_linux-run
chmod +x cuda_8.0_linux.run
sudo sh cuda_8.0_linux.run --silent --toolkit --toolkitpath=/usr/local/cuda-8.0
rm cuda_8.0_linux.run

cd $CONDA_PREFIX
mkdir -p ./etc/conda/activate.d
mkdir -p ./etc/conda/deactivate.d
touch ./etc/conda/activate.d/env_vars.sh
touch ./etc/conda/deactivate.d/env_vars.sh

echo '#!/bin/sh' >> ./etc/conda/activate.d/env_vars.sh
echo 'export ORIG_PATH=$PATH' >> ./etc/conda/activate.d/env_vars.sh
echo 'export ORIG_LD_LIBRARY_PATH=$LD_LIBRARY_PATH' >> ./etc/conda/activate.d/env_vars.sh
echo 'export PATH=/usr/local/cuda-8.0/bin:$PATH' >> ./etc/conda/activate.d/env_vars.sh
echo 'export LD_LIBRARY_PATH=/usr/local/cuda-8.0/lib64:/usr/local/cuda-8.0/extras/CUPTI/lib64:/lib/nccl/cuda-8:$LD_LIBRARY_PATH' >> ./etc/conda/activate.d/env_vars.sh

echo '#!/bin/sh' >> ./etc/conda/deactivate.d/env_vars.sh
echo 'export PATH=$ORIG_PATH' >> ./etc/conda/deactivate.d/env_vars.sh
echo 'export LD_LIBRARY_PATH=$ORIG_LD_LIBRARY_PATH' >> ./etc/conda/deactivate.d/env_vars.sh
echo 'unset ORIG_PATH' >> ./etc/conda/deactivate.d/env_vars.sh
echo 'unset ORIG_LD_LIBRARY_PATH' >> ./etc/conda/deactivate.d/env_vars.sh

conda install numpy=1.14.5
conda install scikit-learn=0.19.1
pip install tensorflow-gpu==1.4.0

# juarezsacenti/orbs environment:
#conda create -n orbs python=3.6
#conda activate orbs

#sudo apt-get update
#sudo apt-get install gcc
#pip install numpy cython
#cd ~/git/ORBS
#python setup.py install

#conda deactivate
