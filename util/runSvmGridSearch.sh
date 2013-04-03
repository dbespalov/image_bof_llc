#!/bin/bash

## names of binaries for Liblinear's train and predict programs
SVML_TRAIN=svml-train
SVML_PREDICT=svml-predict

# assumes the train-validate-test splits are located in files:
#    $FN".train."$IN_EXT
#    $FN".validate."$IN_EXT
#    $FN".test."$IN_EXT
FN=$1; 
IN_EXT=$2;

PRINT_CL_AVG=0; # when PRINT_CL_AVG is set to 1, the script will also print macro-average errors 

echo "Will run svm test for "$FN".train."$IN_EXT;

# extracting labels from libsvm files
for fsel in train test validate 
do
    cut -d ' ' -f 1 $FN"."$fsel"."$IN_EXT > $FN"."$fsel"."$IN_EXT".labels";
done

MIN_ERR=1;
MIN_CVAL=1;

CL_MIN_ERR=1;
CL_MIN_CVAL=1;

CVALS_STR="";
ERRS_STR="";
CL_ERRS_STR="";

C_VAL=8192;
for ((ii=1; ii < 20; ii++))
do 
    ## training SVM model for each penalty value (C_VAL)
    #echo train -q  -c $C_VAL  $FN".train."$IN_EXT $FN".train."$IN_EXT".model";
    $SVML_TRAIN -q  -c $C_VAL  $FN".train."$IN_EXT $FN".train."$IN_EXT".model";
    
    ## testing each SVM model using validating set 
    fsel=validate;
    #echo predict $FN"."$fsel"."$IN_EXT  $FN".train."$IN_EXT".model" $FN"."$fsel"."$IN_EXT".preds";
    $SVML_PREDICT $FN"."$fsel"."$IN_EXT  $FN".train."$IN_EXT".model" $FN"."$fsel"."$IN_EXT".preds";
    
    ## computing macro-average classification error (average of per-class prediction errors)
    CL_PRED_ERR=(`pr -tm        $FN"."$fsel"."$IN_EXT".labels"                 $FN"."$fsel"."$IN_EXT".preds"     |  awk '{ if (! ($1 in err_array) ) { err_array[$1]=0; cnt_array[$1]=0; }   if ($1 == $2) { cnt_array[$1]++; } else { err_array[$1]++; cnt_array[$1]++; } } END { cats_cnt=0; avg_err=0; for (one_cat in err_array) { avg_err+=(err_array[one_cat]/cnt_array[one_cat]); cats_cnt++; } avg_err = avg_err/cats_cnt; print avg_err," ",cats_cnt; } '  `);
    
    ## computing micro-average classification error 
    ## (average prediction error for all samples, regardless of their class labels)
    PRED_ERR=(`pr -tm        $FN"."$fsel"."$IN_EXT".labels"                 $FN"."$fsel"."$IN_EXT".preds"     |  awk 'BEGIN { err=0; cnt=0; }  { if ($1 == $2) { cnt++; } else { err++; cnt++; } } END { avg_err = err/cnt; print avg_err," ",cnt; } '  `);
    
    #    echo "CL-AVG ERR for $fsel over ${CL_PRED_ERR[1]} labels: ${CL_PRED_ERR[0]}";
    #    echo "AVG ERR for $fsel over ${PRED_ERR[1]} labels: ${PRED_ERR[0]}";
    
    CVALS_STR=$CVALS_STR" "$C_VAL;
    ERRS_STR=$ERRS_STR" "${PRED_ERR[0]};
    CL_ERRS_STR=$CL_ERRS_STR" "${CL_PRED_ERR[0]};
    
    ## maintain C value that results in the smallest micro-average classification error for validating set
    TMPV=${PRED_ERR[0]};
    MINS=(`echo "$TMPV $MIN_ERR $MIN_CVAL $C_VAL" | awk '{if ($1 < $2) print $1," ",$4; else print $2," ",$3}'`);
    MIN_ERR=${MINS[0]};
    MIN_CVAL=${MINS[1]};
    
    ## maintain C value that results in the smallest macro-average classification error for validating set
    CL_TMPV=${CL_PRED_ERR[0]};
    CL_MINS=(`echo "$CL_TMPV $CL_MIN_ERR $CL_MIN_CVAL $C_VAL" | awk '{if ($1 < $2) print $1," ",$4; else print $2," ",$3}'`);
    
    CL_MIN_ERR=${CL_MINS[0]};
    CL_MIN_CVAL=${CL_MINS[1]};
    
    C_VAL=`echo "$C_VAL/2" | bc -l | xargs printf '%.4f'`;
    
done


echo "                  C vals: $CVALS_STR";
echo "micro-average errors on validation set: $ERRS_STR";
echo "macro-average errors on validation set: $CL_ERRS_STR";


echo " %%%%%%%%%%%%%%%%% micro-AVG %%%%%%%%%%%%%%%%%% "

echo $SVML_TRAIN -q -c $MIN_CVAL    $FN".train."$IN_EXT      $FN".train."$IN_EXT".model";
     $SVML_TRAIN -q -c $MIN_CVAL    $FN".train."$IN_EXT      $FN".train."$IN_EXT".model";

for fsel in test validate
do
    echo $SVML_PREDICT       $FN"."$fsel"."$IN_EXT      $FN".train."$IN_EXT".model"        $FN"."$fsel"."$IN_EXT".preds";
    $SVML_PREDICT            $FN"."$fsel"."$IN_EXT      $FN".train."$IN_EXT".model"        $FN"."$fsel"."$IN_EXT".preds";

    PRED_ERR=(`pr -tm        $FN"."$fsel"."$IN_EXT".labels"                 $FN"."$fsel"."$IN_EXT".preds"     |  awk 'BEGIN { err=0; cnt=0; }  { if ($1 == $2) { cnt++; } else { err++; cnt++; } } END { avg_err = err/cnt; print avg_err," ",cnt; } '  `);
    
    echo "####   micro-AVG ERR MIN_CVAL=$MIN_CVAL  "$FN"."$fsel"."$IN_EXT" over ${PRED_ERR[1]} labels: ${PRED_ERR[0]}";
    
done

if [[ $PRINT_CL_AVG -gt 0 ]]; then

    echo " %%%%%%%%%%%%%%%%% MACRO-AVG %%%%%%%%%%%%%%%%%% "

    echo $SVML_TRAIN -q -c $CL_MIN_CVAL      $FN".train."$IN_EXT      $FN".train."$IN_EXT".cl_model";
         $SVML_TRAIN -q -c $CL_MIN_CVAL      $FN".train."$IN_EXT      $FN".train."$IN_EXT".cl_model";
    
    for fsel in test validate
    do
	echo $SVML_PREDICT       $FN"."$fsel"."$IN_EXT      $FN".train."$IN_EXT".cl_model"        $FN"."$fsel"."$IN_EXT".cl_preds";
             $SVML_PREDICT       $FN"."$fsel"."$IN_EXT      $FN".train."$IN_EXT".cl_model"        $FN"."$fsel"."$IN_EXT".cl_preds";
	
	PRED_CLERR=(`pr -tm        $FN"."$fsel"."$IN_EXT".labels"                 $FN"."$fsel"."$IN_EXT".cl_preds"     |  awk '{ if (! ($1 in err_array) ) { err_array[$1]=0; cnt_array[$1]=0; }   if ($1 == $2) { cnt_array[$1]++; } else { err_array[$1]++; cnt_array[$1]++; } } END { cats_cnt=0; avg_err=0; for (one_cat in err_array) { avg_err+=(err_array[one_cat]/cnt_array[one_cat]); cats_cnt++; } avg_err = avg_err/cats_cnt; print avg_err," ",cats_cnt; } '  `);
	
	echo "####   MACRO-AVG ERR, MIN_CVAL=$CL_MIN_CVAL "$FN"."$fsel"."$IN_EXT" over ${PRED_CLERR[1]} labels: ${PRED_CLERR[0]}";
	
    done
fi

