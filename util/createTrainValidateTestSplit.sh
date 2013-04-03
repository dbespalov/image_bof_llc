#!/bin/bash

DATASET_FILENAME=$1;

OUT_PREFIX=$2;    #  will create the following output files: 
                  #  $OUT_PREFIX".train.libsvm"
                  #  $OUT_PREFIX".validate.libsvm"
                  #  $OUT_PREFIX".test.libsvm"

TRAIN_SIZE=$3;
VALIDATE_SIZE=$4;

if [[ -z $DATASET_FILENAME ]]; then
    echo "Dataset $DATASET_FILENAME does not exist!";
    exit;
fi


for SPLIT_NAME in train validate test; do

    if [[ -f $OUT_PREFIX"."$SPLIT_NAME".libsvm" ]]; then
	echo "File "$OUT_PREFIX"."$SPLIT_NAME".libsvm already exists!";
	exit;
    fi
    
    touch $OUT_PREFIX"."$SPLIT_NAME".libsvm";
done

echo "Dataset file: "$DATASET_FILENAME;

TOTAL_LABELS=`cut -d ' ' -f 1 $DATASET_FILENAME | sort | uniq`;

for ii in $TOTAL_LABELS; do

    awk -F " " '$1 == '$ii' { print $0 }' $DATASET_FILENAME > $OUT_PREFIX".class"$ii;
    
    CLASS_NSAMPLES=(`wc -l $OUT_PREFIX".class"$ii`); 
    CLASS_NSAMPLES=${CLASS_NSAMPLES[0]};

    echo "Processing label $ii with $CLASS_NSAMPLES samples...";
    
    ((( VLDTST_SIZE=$CLASS_NSAMPLES-$TRAIN_SIZE )));
    ((( TEST_SIZE=$VLDTST_SIZE-$VALIDATE_SIZE )));

    
    if [[ $VLDTST_SIZE -le 0 ]]; then
    	echo "### WARNING: only $CLASS_NSAMPLES samples for class $ii -- no samples left for validation and testing";
    	VALIDATE_SIZE=0;
    fi
    
    if [[ $TEST_SIZE -le 0 ]]; then
    	echo "### WARNING: only $CLASS_NSAMPLES samples for class $ii -- no samples left for testing";
    	TEST_SIZE=0;
    fi
    
    head -$TRAIN_SIZE $OUT_PREFIX".class"$ii >> $OUT_PREFIX".train.libsvm";
    tail -$VLDTST_SIZE $OUT_PREFIX".class"$ii | head -$VALIDATE_SIZE >> $OUT_PREFIX".validate.libsvm";
    tail -$VLDTST_SIZE $OUT_PREFIX".class"$ii | tail -$TEST_SIZE >> $OUT_PREFIX".test.libsvm";
    
    rm $OUT_PREFIX".class"$ii;

done

