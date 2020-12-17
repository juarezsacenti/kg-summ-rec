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

# Dependencies:
## /datasets/ml1m-sun2cao/ml1m/kg/ [train.dat, valid.dat, test.dat, e_map.dat, r_map.dat]

cd ../util

#[activate jointrec]
conda deactivate
conda activate jointrec

yes | cp -rf ../../datasets/ml1m-sun2cao/ml1m/kg/kg.ttl ../docker/ampligraph-data/
#python kg2rdf.py --mode 'rdf' --kgpath '../../datasets/ml1m-sun2cao/ml1m/kg/' --savepath '../docker/'

cd ../docker
cp ampligraph_Dockerfile Dockerfile
docker build -t ampligraph:1.0 .
docker run -p 8888:8888 --rm -it --gpus all -v "$PWD"/ampligraph-data:/data -w /data/notebooks ampligraph:1.0 $CMD
