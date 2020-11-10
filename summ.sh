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


# Input dataset: ml-sun, ml-cao
DATASET=$1
# Translation model: complex, distmult,
KGE=$2
# Low Frequence Filtering
LOW_FREQUENCE=$3

################################################################################
###                          Create Dataset Folders - {25,50,75}             ###
################################################################################
if [ ! -d "$HOME/git/datasets/${DATASET}_${KGE}-25" ]
then
    echo "[kg-summ-rs] Creating ~/git/datasets/${DATASET}_${KGE}-25"
    mkdir ~/git/datasets/${DATASET}_${KGE}-25/
    mkdir ~/git/datasets/${DATASET}_${KGE}-25/cao-format
    mkdir ~/git/datasets/${DATASET}_${KGE}-25/cao-format/ml1m
    mkdir ~/git/datasets/${DATASET}_${KGE}-25/cao-format/ml1m/kg
    mkdir ~/git/results/${DATASET}_${KGE}-25/
fi

if [ ! -d "$HOME/git/datasets/${DATASET}_${KGE}-50" ]
then
    echo "[kg-summ-rs] Creating ~/git/datasets/${DATASET}_${KGE}-50"
    mkdir ~/git/datasets/${DATASET}_${KGE}-50/
    mkdir ~/git/datasets/${DATASET}_${KGE}-50/cao-format
    mkdir ~/git/datasets/${DATASET}_${KGE}-50/cao-format/ml1m
    mkdir ~/git/datasets/${DATASET}_${KGE}-50/cao-format/ml1m/kg
    mkdir ~/git/results/${DATASET}_${KGE}-50/
fi

if [ ! -d "$HOME/git/datasets/${DATASET}_${KGE}-75" ]
then
    echo "[kg-summ-rs] Creating ~/git/datasets/${DATASET}_${KGE}-75"
    mkdir ~/git/datasets/${DATASET}_${KGE}-75/
    mkdir ~/git/datasets/${DATASET}_${KGE}-75/cao-format
    mkdir ~/git/datasets/${DATASET}_${KGE}-75/cao-format/ml1m
    mkdir ~/git/datasets/${DATASET}_${KGE}-75/cao-format/ml1m/kg
    mkdir ~/git/results/${DATASET}_${KGE}-75/
fi

################################################################################
###                    Clusterize $DATASET with $KGE - {25,50,75}             ###
################################################################################
# Dependencies:
#[~/git/datasets/$DATASET/kg.nt]

if no_exist "$HOME/git/know-rec/docker/ampligraph-data/temp/kg.nt"
then 
    echo '[kg-summ-rs] Creating ~/git/know-rec/docker/ampligraph-data/temp/kg.nt'
    yes | cp -L ~/git/datasets/${DATASET}/kg.nt docker/ampligraph-data/temp/
fi

if no_exist "$HOME/git/know-rec/docker/ampligraph-data/temp/i2kg_map.tsv"
then 
    echo '[kg-summ-rs] Creating ~/git/know-rec/docker/ampligraph-data/temp/i2kg_map.tsv'
    yes | cp -L ~/git/datasets/$DATASET/cao-format/ml1m/i2kg_map.tsv docker/ampligraph-data/temp/
fi

if no_exist "$HOME/git/datasets/${DATASET}_${KGE}-25/cluster25.tsv"
then 
    echo "[kg-summ-rs] Creating ~/git/datasets/${DATASET}_${KGE}-25/cluster25.tsv"
    cd docker
    cp ampligraph_Dockerfile Dockerfile
    docker build -t ampligraph:1.0 .
    docker run --rm -it --gpus all -v "$PWD"/ampligraph-data:/data -w /data ampligraph:1.0 /bin/bash -c "python ampligraph-kge_n_cluster.py --model $KGE"
    cp "$HOME/git/know-rec/docker/ampligraph-data/temp/cluster25.tsv" "$HOME/git/datasets/${DATASET}_${KGE}-25/cluster25.tsv"
    cp "$HOME/git/know-rec/docker/ampligraph-data/temp/cluster50.tsv" "$HOME/git/datasets/${DATASET}_${KGE}-50/cluster50.tsv"
    cp "$HOME/git/know-rec/docker/ampligraph-data/temp/cluster75.tsv" "$HOME/git/datasets/${DATASET}_${KGE}-75/cluster75.tsv"
    cd ..
fi

################################################################################
###                    Summarize $DATASET with clusters                      ###
################################################################################
#[activate jointrec]
conda deactivate
conda activate jointrec

if no_exist "$HOME/git/datasets/${DATASET}_${KGE}-25/kg.nt"
then
    echo "[kg-summ-rs] Creating ~/git/datasets/${DATASET}_${KGE}-25/kg.nt"
    cd util
    python kg2rdf.py --mode 'cluster' --input2 "$HOME/git/datasets/${DATASET}_${KGE}-25/cluster25.tsv" --input "$HOME/git/datasets/${DATASET}/kg.nt" --output "$HOME/git/datasets/${DATASET}_${KGE}-25/kg.nt"
    cd ..
fi

if no_exist "$HOME/git/datasets/${DATASET}_${KGE}-50/kg.nt"
then
    echo "[kg-summ-rs] Creating ~/git/datasets/${DATASET}_${KGE}-50/kg.nt"
    cd util
    python kg2rdf.py --mode 'cluster' --input2 "$HOME/git/datasets/${DATASET}_${KGE}-50/cluster50.tsv" --input "$HOME/git/datasets/${DATASET}/kg.nt"  --output "$HOME/git/datasets/${DATASET}_${KGE}-50/kg.nt"
    cd ..
fi
if no_exist "$HOME/git/datasets/${DATASET}_${KGE}-75/kg.nt"
then
    echo "[kg-summ-rs] Creating ~/git/datasets/${DATASET}_${KGE}-75/kg.nt"
    cd util
    python kg2rdf.py --mode 'cluster' --input2 "$HOME/git/datasets/${DATASET}_${KGE}-75/cluster75.tsv" --input "$HOME/git/datasets/${DATASET}/kg.nt"  --output "$HOME/git/datasets/${DATASET}_${KGE}-75/kg.nt"
    cd ..
fi

################################################################################
###                       Preprocess ${DATASET}_${KGE}-25                    ###
################################################################################
cd preprocess
source cao-format_summ.sh ${DATASET} ${KGE} 25 ${LOW_FREQUENCE}

################################################################################
###                       Preprocess ${DATASET}_${KGE}-50                    ###
################################################################################
source cao-format_summ.sh ${DATASET} ${KGE} 50 ${LOW_FREQUENCE}

################################################################################
###                       Preprocess ${DATASET}_${KGE}-75                    ###
################################################################################
source cao-format_summ.sh ${DATASET} ${KGE} 75 ${LOW_FREQUENCE}
cd ..

################################################################################
###                       Summarization impact                               ###
################################################################################
if no_exist "$HOME/git/results/${DATASET}_${KGE}-25/kg_stats.tsv"
then
    echo "[kg-summ-rs] Creating ~/git/results/${DATASET}_${KGE}-25/kg_stats.tsv"
    cd util
    python kg2rdf.py --mode 'statistics' --kgpath "$HOME/git/datasets/${DATASET}_${KGE}-25"  --output "$HOME/git/results/${DATASET}_${KGE}-25/kg_stats.tsv"
    cd ..
fi
if no_exist "$HOME/git/results/${DATASET}_${KGE}-50/kg_stats.tsv"
then
    echo "[kg-summ-rs] Creating ~/git/results/${DATASET}_${KGE}-50/kg_stats.tsv"
    cd util
    python kg2rdf.py --mode 'statistics' --kgpath "$HOME/git/datasets/${DATASET}_${KGE}-50" --output "$HOME/git/results/${DATASET}_${KGE}-50/kg_stats.tsv"
    cd ..
fi
if no_exist "$HOME/git/results/${DATASET}_${KGE}-75/kg_stats.tsv"
then
    echo "[kg-summ-rs] Creating ~/git/results/${DATASET}_${KGE}-75/kg_stats.tsv"
    cd util
    python kg2rdf.py --mode 'statistics' --kgpath "$HOME/git/datasets/${DATASET}_${KGE}-75" --output "$HOME/git/results/${DATASET}_${KGE}-75/kg_stats.tsv"
    cd ..
fi
