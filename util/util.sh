#!/bin/bash
# This file is part of this program.
#
# Copyright 2020 Juarez Sacenti
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#######################################
# Summarize using KGE-K-Means
# GLOBALS:
#   None
# ARGUMENTS:
#   path_to_file: Input path to file
# OUTPUTS:
#   None
# RETURN:
#   0 if print succeeds, non-zero on error.
#######################################
no_exist() {
    local path_to_file=$1

    for f in ${path_to_file};
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

#######################################
# Summarize using KGE-K-Means
# GLOBALS:
#   None
# ARGUMENTS:
#   path_to_file: Input path to file
# OUTPUTS:
#   None
# RETURN:
#   0 if print succeeds, non-zero on error.
#######################################
no_exist_dir() {
    local dir_path=$1

    if [! -d "$f" ]
    then
        return 1
    else
        return 0
    fi
}

#######################################
# Copy ml-sun dataset
# GLOBALS:
#   None
# ARGUMENTS:
#   path_to_dataset: path to dataset that will be copied
#   path_to_new_dataset: path to the new dataset
# OUTPUTS:
#   None
# RETURN:
#   0 if print succeeds, non-zero on error.
#######################################
copy_ml_sun() {
    local path_to_dataset=$1
    local path_to_new_dataset=$2

    mkdir "${path_to_new_dataset}"
    mkdir "${path_to_new_dataset}/sun-format"
    ln -s "${path_to_dataset}/sun-format/auxiliary.txt" "${path_to_new_dataset}/sun-format/auxiliary.txt"
    ln -s "${path_to_dataset}/sun-format/auxiliary-mapping.txt" "${path_to_new_dataset}/sun-format/auxiliary-mapping.txt"
    ln -s "${path_to_dataset}/sun-format/negative-path.txt" "${path_to_new_dataset}/sun-format/negative-path.txt"
    ln -s "${path_to_dataset}/sun_format/negative.txt" "${path_to_new_dataset}/sun-format/negative.txt"
    ln -s "${path_to_dataset}/sun-format/positive-path.txt" "${path_to_new_dataset}/sun-format/positive-path.txt"
    ln -s "${path_to_dataset}/sun_format/pre-train-item-embedding.txt" "${path_to_new_dataset}/sun-format/pre-train-item-embedding.txt"
    ln -s "${path_to_dataset}/sun-format/pre-train-user-embedding.txt" "${path_to_new_dataset}/sun-format/pre-train-user-embedding.txt"
    ln -s "${path_to_dataset}/sun-format/rating-delete-missing-itemid.txt" "${path_to_new_dataset}/sun-format/rating-delete-missing-itemid.txt"
    ln -s "${path_to_dataset}/sun-format/test.txt" "${path_to_new_dataset}/sun-format/test.txt"
    ln -s "${path_to_dataset}/sun-format/training.txt" "${path_to_new_dataset}/sun-format/training.txt"
}

#######################################
# Copy ml-cao dataset
# GLOBALS:
#   None
# ARGUMENTS:
#   path_to_dataset: path to dataset that will be copied
#   path_to_new_dataset: path to the new dataset
# OUTPUTS:
#   None
# RETURN:
#   0 if print succeeds, non-zero on error.
#######################################
copy_ml_cao() {
    local path_to_dataset=$1
    local path_to_new_dataset=$2

    mkdir "${path_to_new_dataset}"
    mkdir "${path_to_new_dataset}/cao-format"
    mkdir "${path_to_new_dataset}/cao-format/ml1m"
    mkdir "${path_to_new_dataset}/cao-format/ml1m/kg"
    ln -s "${path_to_dataset}/cao-format/ml1m/i2kg_map.tsv" "${path_to_new_dataset}/cao-format/i2kg_map.tsv"
    ln -s "${path_to_dataset}/cao-format/ml1m/train.dat" "${path_to_new_dataset}/cao-format/train.dat"
    ln -s "${path_to_dataset}/cao-format/ml1m/valid.dat" "${path_to_new_dataset}/cao-format/valid.dat"
    ln -s "${path_to_dataset}/cao-format/ml1m/i_map.dat" "${path_to_new_dataset}/cao-format/i_map.dat"
    ln -s "${path_to_dataset}/cao-format/ml1m/test.dat" "${path_to_new_dataset}/cao-format/test.dat"
    ln -s "${path_to_dataset}/cao-format/ml1m/u_map.dat" "${path_to_new_dataset}/cao-format/u_map.dat"
    ln -s "${path_to_dataset}/cao-format/ml1m/kg/e_map.dat" "${path_to_new_dataset}/cao-format/kg/e_map.dat"
    ln -s "${path_to_dataset}/cao-format/ml1m/kg/r_map.dat" "${path_to_new_dataset}/cao-format/kg/r_map.dat"
    ln -s "${path_to_dataset}/cao-format/ml1m/kg/test.dat" "${path_to_new_dataset}/cao-format/kg/test.dat"
    ln -s "${path_to_dataset}/cao-format/ml1m/kg/train.dat" "${path_to_new_dataset}/cao-format/kg/train.dat"
    ln -s "${path_to_dataset}/cao-format/ml1m/kg/valid.dat" "${path_to_new_dataset}/cao-format/kg/valid.dat"

}
