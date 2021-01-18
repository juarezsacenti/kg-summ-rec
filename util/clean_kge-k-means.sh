#!/bin/bash

#[kge-k-means_data]
clean_kge-k-means() {
    if [ -f "$HOME/git/kg-summ-rec/docker/kge-k-means_data/application.log" ]
    then 
        yes | rm ~/git/kg-summ-rec/docker/kge-k-means_data/application.log
    fi

    if ls "$HOME/git/kg-summ-rec/docker/kge-k-means_data/temp/*.*" 1> /dev/null 2>&1
    then
        yes | rm -r ~/git/kg-summ-rec/docker/kge-k-means_data/temp/*.*
    fi
}
