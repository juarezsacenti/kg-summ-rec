#!/bin/bash

speedup() {
    SEC1=$1
    SEC2=$2
    # Use expr to do the math, let's say TIME1 was the start and TIME2 was the finish
    echo "scale=2 ; $SEC2 / $SEC1 * 100" | bc
}

elipsed_time() {
    SEC1=$1
    SEC2=$2
    # Use expr to do the math, let's say TIME1 was the start and TIME2 was the finish
    DIFFSEC=`expr ${SEC2} - ${SEC1}`
    echo ${DIFFSEC}
}

log_duration() {
    FIN=$1
    LINE=$( head -n1 < $FIN )
    TIME1=$(echo $LINE| cut -d' ' -f 2)
    LINE=$( tail -n1 < $FIN )
    TIME2=$(echo $LINE| cut -d' ' -f 2)

    SEC1=`date +%s -d ${TIME1}`
    SEC2=`date +%s -d ${TIME2}`
    DIFFSEC=$(elipsed_time ${SEC1} ${SEC2})

    #echo Start ${TIME1}
    #echo Finish ${TIME2}
    #echo Took ${DIFFSEC} seconds.
    # And use date to convert the seconds back to something more meaningful
    #echo "$FIN\t" `date +%H:%M:%S -ud @${DIFFSEC}`
    echo ${DIFFSEC}
}

DATASET=$1
KGE=$2
RATE=$3

echo "Dataset & CFKG & CKE & CoFM & KTUP"
CFKG_SEC1=$(log_duration "$HOME/git/results/${DATASET}/ml1m-cfkg-*.log")
CFKG_SEC2=$(log_duration "$HOME/git/results/${DATASET}_${KGE}-${RATE}/ml1m-cfkg-*.log")
CFKG_DIFF=$(speedup ${CFKG_SEC1} ${CFKG_SEC2})

CKE_SEC1=$(log_duration "$HOME/git/results/${DATASET}/ml1m-cke-*.log")
CKE_SEC2=$(log_duration "$HOME/git/results/${DATASET}_${KGE}-${RATE}/ml1m-cke-*.log")
CKE_DIFF=$(speedup ${CKE_SEC1} ${CKE_SEC2})

COFM_SEC1=$(log_duration "$HOME/git/results/${DATASET}/ml1m-cofm-*.log")
COFM_SEC2=$(log_duration "$HOME/git/results/${DATASET}_${KGE}-${RATE}/ml1m-cofm-*.log")
COFM_DIFF=$(speedup ${COFM_SEC1} ${COFM_SEC2})

KTUP_SEC1=$(log_duration "$HOME/git/results/${DATASET}/ml1m-jtransup-*.log")
KTUP_SEC2=$(log_duration "$HOME/git/results/${DATASET}_${KGE}-${RATE}/ml1m-jtransup-*.log")
KTUP_DIFF=$(speedup ${KTUP_SEC1} ${KTUP_SEC2})

echo "${DATASET}_${KGE}-${RATE} " `date +%H:%M:%S -ud @${CFKG_SEC2}` " (" ${CFKG_DIFF} ") & "  `date +%H:%M:%S -ud @${CKE_SEC2}` " (" ${CKE_DIFF} ") & " `date +%H:%M:%S -ud @${COFM_SEC2}` " (" ${COFM_DIFF} ") & " `date +%H:%M:%S -ud @${KTUP_SEC2}` " (" ${KTUP_DIFF} ")"

echo "${DATASET} " `date +%H:%M:%S -ud @${CFKG_SEC1}` " (" $(speedup ${CFKG_SEC1} ${CFKG_SEC1}) ") & "  `date +%H:%M:%S -ud @${CKE_SEC1}` " (" $(speedup ${CKE_SEC1} ${CKE_SEC1}) ") & " `date +%H:%M:%S -ud @${COFM_SEC1}` " (" $(speedup ${COFM_SEC1} ${COFM_SEC1}) ") & " `date +%H:%M:%S -ud @${KTUP_SEC1}` " (" $(speedup ${KTUP_SEC1} ${KTUP_SEC1}) ")"
