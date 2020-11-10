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
###                    Low Frequency at 0                                    ###
################################################################################
#Low Frequence Filtering (0, 10)
LOW_FREQUENCE=0

###############################################################################
###                    Create Sun's original KG Folders                      ###
################################################################################
if no_exist "$HOME/git/datasets/ml-sun_fil-${LOW_FREQUENCE}"
then
    echo "[kg-summ-rs] Creating ~/git/datasets/ml-sun_fil-${LOW_FREQUENCE}"
    mkdir "$HOME/git/datasets/ml-sun_fil-${LOW_FREQUENCE}"
    mkdir "$HOME/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/sun-format"
    ln -s "$HOME/git/datasets/ml-sun/sun-format/auxiliary.txt" "$HOME/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/sun-format/auxiliary.txt"
    ln -s "$HOME/git/datasets/ml-sun/sun-format/auxiliary-mapping.txt" "$HOME/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/sun-format/auxiliary-mapping.txt"
    ln -s "$HOME/git/datasets/ml-sun/sun-format/negative-path.txt" "$HOME/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/sun-format/negative-path.txt"
    ln -s "$HOME/git/datasets/ml-sun/sun-format/negative.txt" "$HOME/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/sun-format/negative.txt"
    ln -s "$HOME/git/datasets/ml-sun/sun-format/positive-path.txt" "$HOME/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/sun-format/positive-path.txt"
    ln -s "$HOME/git/datasets/ml-sun/sun-format/pre-train-item-embedding.txt" "$HOME/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/sun-format/pre-train-item-embedding.txt"
    ln -s "$HOME/git/datasets/ml-sun/sun-format/pre-train-user-embedding.txt" "$HOME/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/sun-format/pre-train-user-embedding.txt"
    ln -s "$HOME/git/datasets/ml-sun/sun-format/rating-delete-missing-itemid.txt" "$HOME/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/sun-format/rating-delete-missing-itemid.txt"
    ln -s "$HOME/git/datasets/ml-sun/sun-format/test.txt" "$HOME/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/sun-format/test.txt"
    ln -s "$HOME/git/datasets/ml-sun/sun-format/training.txt" "$HOME/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/sun-format/training.txt"
fi

################################################################################
###                    Preprocessing Sun's original KG                       ###
################################################################################
# Creating dependencies:
#[~/git/datasets/ml-sun/cao_format/ml1m/kg/kg.nt]
cd preprocess
source cao-format_ml-sun.sh "ml-sun_fil-${LOW_FREQUENCE}" ${LOW_FREQUENCE}
cd ..

################################################################################
###                       Sun's original KG stats                            ###
################################################################################
#[activate jointrec]
conda deactivate
conda activate jointrec

if no_exist "$HOME/git/results/ml-sun_fil-${LOW_FREQUENCE}/kg_stats.tsv"
then
    echo "[kg-summ-rs] Creating ~/git/results/ml-sun_fil-${LOW_FREQUENCE}/kg_stats.tsv"    
    cd util
    python kg2rdf.py --mode 'statistics' --kgpath "~/git/datasets/ml-sun_fil-${LOW_FREQUENCE}" --output "~/git/results/ml-sun_fil-${LOW_FREQUENCE}/kg_stats.tsv"
    cd ..
fi

################################################################################
###                       Summ. ml-sun with complex                          ###
################################################################################
source summ.sh "ml-sun_fil-${LOW_FREQUENCE}" 'complex' ${LOW_FREQUENCE}

################################################################################
###                    Low Frequency at 10                                    ###
################################################################################
#Low Frequence Filtering (0, 10)
LOW_FREQUENCE=10

################################################################################
###                    Create Sun's original KG Folders                      ###
################################################################################
if no_exist "$HOME/git/datasets/ml-sun_fil-${LOW_FREQUENCE}"
then
    echo "[kg-summ-rs] Creating ~/git/datasets/ml-sun_fil-${LOW_FREQUENCE}"
    mkdir "$HOME/git/datasets/ml-sun_fil-${LOW_FREQUENCE}"
    mkdir "$HOME/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/sun-format"
    ln -s "$HOME/git/datasets/ml-sun/sun-format/auxiliary.txt" "$HOME/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/sun-format/auxiliary.txt"
    ln -s "$HOME/git/datasets/ml-sun/sun-format/auxiliary-mapping.txt" "$HOME/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/sun-format/auxiliary-mapping.txt"
    ln -s "$HOME/git/datasets/ml-sun/sun-format/negative-path.txt" "$HOME/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/sun-format/negative-path.txt"
    ln -s "$HOME/git/datasets/ml-sun/sun-format/negative.txt" "$HOME/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/sun-format/negative.txt"
    ln -s "$HOME/git/datasets/ml-sun/sun-format/positive-path.txt" "$HOME/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/sun-format/positive-path.txt"
    ln -s "$HOME/git/datasets/ml-sun/sun-format/pre-train-item-embedding.txt" "$HOME/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/sun-format/pre-train-item-embedding.txt"
    ln -s "$HOME/git/datasets/ml-sun/sun-format/pre-train-user-embedding.txt" "$HOME/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/sun-format/pre-train-user-embedding.txt"
    ln -s "$HOME/git/datasets/ml-sun/sun-format/rating-delete-missing-itemid.txt" "$HOME/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/sun-format/rating-delete-missing-itemid.txt"
    ln -s "$HOME/git/datasets/ml-sun/sun-format/test.txt" "$HOME/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/sun-format/test.txt"
    ln -s "$HOME/git/datasets/ml-sun/sun-format/training.txt" "$HOME/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/sun-format/training.txt"
fi

################################################################################
###                    Preprocessing Sun's original KG                       ###
################################################################################
if [ ! -d "$HOME/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/cao-format" ]
then
    echo "[kg-summ-rs] Creating ~/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/cao-format/ml1m/kg"
    mkdir ~/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/cao-format
    mkdir ~/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/cao-format/ml1m
    mkdir ~/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/cao-format/ml1m/kg
fi

if no_exist "$HOME/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/cao-format/ml1m/train.dat"
then
    #[train.dat, valid.dat, test.dat symbolic links]
    echo "Copying ~/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/cao-format/ml1m/train.dat"
    ln -s ~/git/datasets/ml-sun_fil-0/cao-format/ml1m/train.dat ~/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/cao-format/ml1m/train.dat
    ln -s ~/git/datasets/ml-sun_fil-0/cao-format/ml1m/valid.dat ~/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/cao-format/ml1m/valid.dat
    ln -s ~/git/datasets/ml-sun_fil-0/cao-format/ml1m/test.dat ~/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/cao-format/ml1m/test.dat
    ln -s ~/git/datasets/ml-sun_fil-0/cao-format/ml1m/i_map.dat ~/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/cao-format/ml1m/i_map.dat
    ln -s ~/git/datasets/ml-sun_fil-0/cao-format/ml1m/u_map.dat ~/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/cao-format/ml1m/u_map.dat
    ln -s ~/git/datasets/ml-sun_fil-0/cao-format/ml1m/clean_auxiliary.txt ~/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/cao-format/ml1m/clean_auxiliary.txt
    ln -s ~/git/datasets/ml-sun_fil-0/cao-format/ml1m/kg/kg_hop0.dat ~/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/cao-format/ml1m/kg/kg_hop0.dat
    ln -s ~/git/datasets/ml-sun_fil-0/cao-format/ml1m/kg/predicate_vocab.dat ~/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/cao-format/ml1m/kg/predicate_vocab.dat
    ln -s ~/git/datasets/ml-sun_fil-0/cao-format/ml1m/kg/relation_filter.dat ~/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/cao-format/ml1m/kg/relation_filter.dat
    ln -s ~/git/datasets/ml-sun_fil-0/cao-format/ml1m/kg/entity_vocab.dat ~/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/cao-format/ml1m/kg/entity_vocab.dat
    ln -s ~/git/datasets/ml-sun_fil-0/cao-format/ml1m/i2kg_map.tsv ~/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/cao-format/ml1m/i2kg_map.tsv
    ln -s ~/git/datasets/ml-sun_fil-0/cao-format/ml1m/kg_map.dat ~/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/cao-format/ml1m/kg_map.dat
    ln -s ~/git/datasets/ml-sun_fil-0/kg.nt ~/git/datasets/ml-sun_fil-${LOW_FREQUENCE}/kg.nt
fi

cd preprocess
source cao-format_ml-sun.sh "ml-sun_fil-${LOW_FREQUENCE}" ${LOW_FREQUENCE}
cd ..

################################################################################
###                       Sun's original KG stats                            ###
################################################################################
if no_exist "$HOME/git/results/ml-sun_fil-${LOW_FREQUENCE}/kg_stats.tsv"
then
    echo "[kg-summ-rs] Creating ~/git/results/ml-sun_fil-${LOW_FREQUENCE}/kg_stats.tsv"
    cd util
    python kg2rdf.py --mode 'statistics' --kgpath "~/git/datasets/ml-sun_fil-${LOW_FREQUENCE}" --output "~/git/results/ml-sun_fil-${LOW_FREQUENCE}/kg_stats.tsv"
    cd ..
fi

################################################################################
###                       Summ. ml-sun with complex                          ###
################################################################################
source clean_ampligraph.sh
source summ.sh "ml-sun_fil-${LOW_FREQUENCE}" 'complex' ${LOW_FREQUENCE}




################################################################################
###                    Low Frequency at chosen value                         ###
################################################################################
#Low Frequence Filtering (0, 10)
LOW_FREQUENCE=0

################################################################################
###                     Preprocessing Cao's original KG                      ###
################################################################################
#source clean_ampligraph.sh
#cd util
#python kg2rdf.py --mode 'splitkg' --kgpath "~/git/datasets/ml-cao/cao-format/ml1m/kg/" --output "~/git/datasets/ml-cao/kg.nt"
#cd ..

################################################################################
###                       Cao's original KG stats                            ###
################################################################################
if no_exist "$HOME/git/results/ml-cao/kg_stats.tsv"
then
    echo "[kg-summ-rs] Creating ~/git/results/ml-cao/kg_stats.tsv"
    cd util
    python kg2rdf.py --mode 'statistics' --kgpath "~/git/datasets/ml-cao" --output "~/git/results/ml-cao/kg_stats.tsv"
    cd ..
fi

################################################################################
###                       Summ. ml-cao with complex                          ###
################################################################################
source clean_ampligraph.sh
source summ.sh	"ml-cao" 'complex' ${LOW_FREQUENCE}

################################################################################
###                   Multiview summ. ml-sun with complex                    ###
################################################################################
#source clean_ampligraph.sh
#source mv_summ.sh "ml-sun" 'complex' ${LOW_FREQUENCE}

################################################################################
###                   Multiview summ. ml-cao with complex                    ###
################################################################################
#source clean_ampligraph.sh
#source mv_summ.sh "ml-cao" 'complex' ${LOW_FREQUENCE}

