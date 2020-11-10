#!/bin/bash
no_exist() {
for f in $1;
do
    ## Check if the glob gets expanded to existing files.
    ## If not, f here will be exactly the pattern above
    ## and the exists test will evaluate to false.
    if [ -e "$f" ]
    then
         return 1
    else
         return 0
    fi
done
}

################################################################################
###                    Summarize ml1m-sun with kge-cluster                   ###
################################################################################
# Dependencies:
## /datasets/ml1m-sun2cao/ml1m/kg/ [kg.nt]
yes | cp -rf ../../datasets/ml1m-sun2cao/ml1m/kg/kg.nt ../docker/ampligraph-data/
#python kg2rdf.py --mode 'rdf' --kgpath '../../datasets/ml1m-sun2cao/ml1m/kg/' --savepath '../docker/'

cd ../docker
cp ampligraph_Dockerfile Dockerfile
docker build -t ampligraph:1.0 .
docker run --rm -it --gpus all -v "$PWD"/ampligraph-data:/data -w /data ampligraph:1.0 /bin/bash -c "python ampligraph-kge_n_cluster.py"

#[activate jointrec]
conda deactivate
conda activate jointrec

cd ../util
python kg2rdf.py --mode 'cluster' --cluster '../docker/ampligraph-data/cluster25.csv' --input '../docker/ampligraph-data/kg.nt' --output '../docker/ampligraph-data/kg_cluster25.nt'
python kg2rdf.py --mode 'cluster' --cluster '../docker/ampligraph-data/cluster50.csv' --input '../docker/ampligraph-data/kg.nt' --output '../docker/ampligraph-data/kg_cluster50.nt'
python kg2rdf.py --mode 'cluster' --cluster '../docker/ampligraph-data/cluster75.csv' --input '../docker/ampligraph-data/kg.nt' --output '../docker/ampligraph-data/kg_cluster75.nt'

################################################################################
###                          Create Dataset Folders                          ###
################################################################################
mkdir ../../datasets/cluster25/
mkdir ../../datasets/cluster25/ml1m
mkdir ../../datasets/cluster25/ml1m/kg

#mkdir ../../datasets/cluster50/
#mkdir ../../datasets/cluster50/ml1m
#mkdir ../../datasets/cluster50/ml1m/kg

#mkdir ../../datasets/cluster75/
#mkdir ../../datasets/cluster75/ml1m
#mkdir ../../datasets/cluster75/ml1m/kg

################################################################################
###                          Preprocess                                      ###
################################################################################
cd ../preprocess
python sun2cao_step1.py --mode 'nt' --input '../docker/ampligraph-data/kg_cluster25.nt' --mapping '../../datasets/cluster25/'

#[sun2cao/train.dat, valid.dat, test.dat, ... from sun2cao]
ln -s ~/git/datasets/ml1m-sun2cao/ml1m/train.dat ~/git/datasets/cluster25/ml1m/train.dat
ln -s ~/git/datasets/ml1m-sun2cao/ml1m/valid.dat ~/git/datasets/cluster25/ml1m/valid.dat
ln -s ~/git/datasets/ml1m-sun2cao/ml1m/test.dat ~/git/datasets/cluster25/ml1m/test.dat
ln -s ~/git/datasets/ml1m-sun2cao/ml1m/i_map.dat ~/git/datasets/cluster25/ml1m/i_map.dat
ln -s ~/git/datasets/ml1m-sun2cao/ml1m/u_map.dat ~/git/datasets/cluster25/ml1m/u_map.dat
ln -s ~/git/datasets/ml1m-sun2cao/ml1m/sun_training.txt ~/git/datasets/cluster25/ml1m/sun_training.txt
ln -s ~/git/datasets/ml1m-sun2cao/ml1m/sun_test.txt ~/git/datasets/cluster25/ml1m/sun_test.txt
ln -s ~/git/datasets/ml1m-sun2cao/ml1m/kg/predicate_vocab.dat ~/git/datasets/cluster25/ml1m/kg/predicate_vocab.dat
ln -s ~/git/datasets/ml1m-sun2cao/ml1m/kg/relation_filter.dat ~/git/datasets/cluster25/ml1m/kg/relation_filter.dat
ln -s ~/git/datasets/ml1m-sun2cao/ml1m/kg/i2kg_map.tsv ~/git/datasets/cluster25/ml1m/kg/i2kg_map.tsv

#[sun2cao_step2]
if no_exist "../../datasets/cluster25/ml1m/kg/e_map.dat"
then
    python sun2cao_step2.py --data_path '../../datasets/cluster25/' --dataset 'ml1m'
fi

#[activate rkge]
#conda deactivate
#conda activate rkge

#cd ../../Recurrent-Knowledge-Graph-Embedding

#[rkge prepocessing]
#if no_exist "../../datasets/ml1m-summarized_sun/positive-path.txt" || no_exist "../../datasets/ml1m-summarized_sun/negative-path.txt"
#then
#    python auxiliary-mapping-ml.py --auxiliary ../datasets/ml1m-summarized_sun/ml1m/sum_auxiliary.txt --mapping ../datasets/ml1m-summarized_sun/ml1m/auxiliary-mapping.txt
#    python path-extraction-ml.py --training ../datasets/ml1m-summarized_sun/ml1m/sun_training.txt --negtive ../datasets/ml1m-summarized_sun/ml1m/negative.txt --auxiliary ../datasets/ml1m-summarized_sun/ml1m/auxiliary-mapping.txt --positivepath ../datasets/ml1m-summarized_sun/ml1m/positive-path.txt --negativepath ../datasets/ml1m-summarized_sun/ml1m/negative-path.txt --pathlength 3 --samplesize 5
#fi
