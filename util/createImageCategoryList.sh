#!/bin/bash

DATASET_DIR=$1;
OUT_FILENAME=$2;

if [[ -f $OUT_FILENAME ]]; then
    echo "File already exists: $OUT_FILENAME";
    exit;
fi


DATASET_DIR="$(readlink -m $1)";


echo "Dataset directory: "$DATASET_DIR;

CAT_ID=1;

touch $OUT_FILENAME;

for ii in $(ls $DATASET_DIR); do
    
    echo "Processing category $ii, CAT_ID = $CAT_ID";
    
    for jj in $(ls $DATASET_DIR/$ii); do
	if [[ $jj == *.jpg || $jj == *.JPG ]]; then
	    echo "$DATASET_DIR/$ii/$jj   $CAT_ID" >> $OUT_FILENAME;
	fi
    done
    
    (((CAT_ID=$CAT_ID+1)))
done


