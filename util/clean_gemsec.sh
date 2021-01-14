#!/bin/bash

#[gemsec_data]
clean_gemsec() {
    #yes | rm ~/git/kg-summ-rec/docker/gemsec_data/application.log
    yes | rm -r ~/git/kg-summ-rec/docker/gemsec_data/temp/*.*
}
