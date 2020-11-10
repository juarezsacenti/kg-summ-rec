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
if [ ! -d "$HOME/git/datasets/${DATASET}_${KGE}-25_mv" ]
then
    echo "[kg-summ-rs] Creating ~/git/datasets/${DATASET}_${KGE}-25_mv"
    mkdir ~/git/datasets/${DATASET}_${KGE}-25_mv/
    mkdir ~/git/datasets/${DATASET}_${KGE}-25_mv/cao-format
    mkdir ~/git/datasets/${DATASET}_${KGE}-25_mv/cao-format/ml1m
    mkdir ~/git/datasets/${DATASET}_${KGE}-25_mv/cao-format/ml1m/kg
    mkdir ~/git/results/${DATASET}_${KGE}-25_mv/
fi

if [ ! -d "$HOME/git/datasets/${DATASET}_${KGE}-50_mv" ]
then
    echo "[kg-summ-rs] Creating ~/git/datasets/${DATASET}_${KGE}-50_mv"
    mkdir ~/git/datasets/${DATASET}_${KGE}-50_mv/
    mkdir ~/git/datasets/${DATASET}_${KGE}-50_mv/cao-format
    mkdir ~/git/datasets/${DATASET}_${KGE}-50_mv/cao-format/ml1m
    mkdir ~/git/datasets/${DATASET}_${KGE}-50_mv/cao-format/ml1m/kg
    mkdir ~/git/results/${DATASET}_${KGE}-50_mv/
fi

if [ ! -d "$HOME/git/datasets/${DATASET}_${KGE}-75_mv" ]
then
    echo "[kg-summ-rs] Creating ~/git/datasets/${DATASET}_${KGE}-75_mv"
    mkdir ~/git/datasets/${DATASET}_${KGE}-75_mv/
    mkdir ~/git/datasets/${DATASET}_${KGE}-75_mv/cao-format
    mkdir ~/git/datasets/${DATASET}_${KGE}-75_mv/cao-format/ml1m
    mkdir ~/git/datasets/${DATASET}_${KGE}-75_mv/cao-format/ml1m/kg
    mkdir ~/git/results/${DATASET}_${KGE}-75_mv/
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

if no_exist "$HOME/git/datasets/${DATASET}_${KGE}-25_mv/cluster25.tsv"
then 
    echo "[kg-summ-rs] Creating ~/git/datasets/${DATASET}_${KGE}-25_mv/cluster25.tsv"
    cd docker
    cp ampligraph_Dockerfile Dockerfile
    docker build -t ampligraph:1.0 .
    docker run --rm -it --gpus all -v "$PWD"/ampligraph-data:/data -w /data ampligraph:1.0 /bin/bash -c "python mv_ampligraph-kge_n_cluster.py --mode multiview --verbose"
    cp "$HOME/git/know-rec/docker/ampligraph-data/temp/cluster25.tsv" "$HOME/git/datasets/${DATASET}_${KGE}-25_mv/cluster25.tsv"
    cp "$HOME/git/know-rec/docker/ampligraph-data/temp/cluster50.tsv" "$HOME/git/datasets/${DATASET}_${KGE}-50_mv/cluster50.tsv"
    cp "$HOME/git/know-rec/docker/ampligraph-data/temp/cluster75.tsv" "$HOME/git/datasets/${DATASET}_${KGE}-75_mv/cluster75.tsv"
    cd ..
fi

################################################################################
###                    Summarize $DATASET with clusters                      ###
################################################################################
#[activate jointrec]
conda deactivate
conda activate jointrec

if no_exist "$HOME/git/datasets/${DATASET}_${KGE}-25_mv/kg.nt"
then
    echo "[kg-summ-rs] Creating ~/git/datasets/${DATASET}_${KGE}-25_mv/kg.nt"
    cd util
    python kg2rdf.py --mode 'mv_cluster' --input2 "$HOME/git/datasets/${DATASET}_${KGE}-25_mv/cluster25.tsv" --input "$HOME/git/datasets/${DATASET}/kg.nt" --output "$HOME/git/datasets/${DATASET}_${KGE}-25_mv/kg.nt"
    cd ..
fi

if no_exist "$HOME/git/datasets/${DATASET}_${KGE}-50_mv/kg.nt"
then
    echo "[kg-summ-rs] Creating ~/git/datasets/${DATASET}_${KGE}-50_mv/kg.nt"
    cd util
    python kg2rdf.py --mode 'mv_cluster' --input2 "$HOME/git/datasets/${DATASET}_${KGE}-50_mv/cluster50.tsv" --input "$HOME/git/datasets/${DATASET}/kg.nt"  --output "$HOME/git/datasets/${DATASET}_${KGE}-50_mv/kg.nt"
    cd ..
fi
if no_exist "$HOME/git/datasets/${DATASET}_${KGE}-75_mv/kg.nt"
then
    echo "[kg-summ-rs] Creating ~/git/datasets/${DATASET}_${KGE}-75_mv/kg.nt"
    cd util
    python kg2rdf.py --mode 'mv_cluster' --input2 "$HOME/git/datasets/${DATASET}_${KGE}-75_mv/cluster75.tsv" --input "$HOME/git/datasets/${DATASET}/kg.nt"  --output "$HOME/git/datasets/${DATASET}_${KGE}-75_mv/kg.nt"
    cd ..
fi

################################################################################
###                       Preprocess ${DATASET}_${KGE}-25                    ###
################################################################################
cd preprocess
source cao-format_summ.sh ${DATASET} ${KGE} 25_mv ${LOW_FREQUENCE}

################################################################################
###                       Preprocess ${DATASET}_${KGE}-50                    ###
################################################################################
source cao-format_summ.sh ${DATASET} ${KGE} 50_mv ${LOW_FREQUENCE}

################################################################################
###                       Preprocess ${DATASET}_${KGE}-75                    ###
################################################################################
source cao-format_summ.sh ${DATASET} ${KGE} 75_mv ${LOW_FREQUENCE}
cd ..

################################################################################
###                       Summarization impact                               ###
################################################################################
if no_exist "$HOME/git/results/${DATASET}_${KGE}-25_mv/kg_stats.tsv"
then
    echo "[kg-summ-rs] Creating ~/git/results/${DATASET}_${KGE}-25_mv/kg_stats.tsv"
    cd util
    python kg2rdf.py --mode 'statistics' --kgpath "$HOME/git/datasets/${DATASET}_${KGE}-25_mv"  --output "$HOME/git/results/${DATASET}_${KGE}-25_mv/kg_stats.tsv"
    cd ..
fi
if no_exist "$HOME/git/results/${DATASET}_${KGE}-50_mv/kg_stats.tsv"
then
    echo "[kg-summ-rs] Creating ~/git/results/${DATASET}_${KGE}-50_mv/kg_stats.tsv"
    cd util
    python kg2rdf.py --mode 'statistics' --kgpath "$HOME/git/datasets/${DATASET}_${KGE}-50_mv" --output "$HOME/git/results/${DATASET}_${KGE}-50_mv/kg_stats.tsv"
    cd ..
fi
if no_exist "$HOME/git/results/${DATASET}_${KGE}-75_mv/kg_stats.tsv"
then
    echo "[kg-summ-rs] Creating ~/git/results/${DATASET}_${KGE}-75_mv/kg_stats.tsv"
    cd util
    python kg2rdf.py --mode 'statistics' --kgpath "$HOME/git/datasets/${DATASET}_${KGE}-75_mv" --output "$HOME/git/results/${DATASET}_${KGE}-75_mv/kg_stats.tsv"
    cd ..
fi
