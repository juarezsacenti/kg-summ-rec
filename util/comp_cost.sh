#!/bin/bash

elipsed_time() {
    local SEC1=$1
    local SEC2=$2
    # Use expr to do the math, let's say TIME1 was the start and TIME2 was the finish
    local DIFFSEC=`expr ${SEC2} - ${SEC1}`
    echo ${DIFFSEC}
}

log_duration() {
    local FIN=$1
    local LINE=$( head -n1 < $FIN )
    local TIME1=$(echo $LINE| cut -d' ' -f 2)
    LINE=$( tail -n1 < $FIN )
    local TIME2=$(echo $LINE| cut -d' ' -f 2)

    local SEC1=`date +%s -d ${TIME1}`
    local SEC2=`date +%s -d ${TIME2}`
    local DIFFSEC=$(elipsed_time ${SEC1} ${SEC2})

    #echo Start ${TIME1}
    #echo Finish ${TIME2}
    #echo Took ${DIFFSEC} seconds.
    # And use date to convert the seconds back to something more meaningful
    #echo "$FIN\t" `date +%H:%M:%S -ud @${DIFFSEC}`
    echo ${DIFFSEC}
}


comp_cost() {
    local experiment=$1
    local dataset_in=$2

    local CFKG_SEC=$(log_duration "$HOME/git/results/${experiment}/${dataset_in}/ml1m-cfkg-*.log")
    local CKE_SEC=$(log_duration "$HOME/git/results/${experiment}/${dataset_in}/ml1m-cke-*.log")
    local COFM_SEC=$(log_duration "$HOME/git/results/${experiment}/${dataset_in}/ml1m-cofm-*.log")
    local KTUP_SEC=$(log_duration "$HOME/git/results/${experiment}/${dataset_in}/ml1m-jtransup-*.log")

    # echo "KG-based RS \t Seconds \t Training Duration"
    echo "CFKG \t $CFKG_SEC \t "`date +%H:%M:%S -ud @${CFKG_SEC}`
    echo "CKE \t $CKE_SEC \t "`date +%H:%M:%S -ud @${CKE_SEC}`
    echo "CoFM \t $COFM_SEC \t "`date +%H:%M:%S -ud @${COFM_SEC}`
    echo "KTUP \t $KTUP_SEC \t "`date +%H:%M:%S -ud @${KTUP_SEC}`
}

comp_cost $1 $2
