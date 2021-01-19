#!/bin/bash

#[kge-k-means_data]
clean_kge-k-means() {
    if [ -f "$HOME/git/kg-summ-rec/docker/kge-k-means_data/application.log" ]
    then
        yes | rm ~/git/kg-summ-rec/docker/kge-k-means_data/application.log
    fi
    yes | rm -r ~/git/kg-summ-rec/docker/kge-k-means_data/temp/*.*
}
