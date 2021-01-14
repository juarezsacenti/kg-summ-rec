#!/bin/bash

#[kge-k-means_data]
clean_kge-k-means() {
    yes | rm ~/git/kg-summ-rec/docker/kge-k-means_data/application.log
    yes | rm -r ~/git/kg-summ-rec/docker/kge-k-means_data/temp/*.*
}
