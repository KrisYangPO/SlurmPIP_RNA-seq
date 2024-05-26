#!/bin/bash

path=/staging/biology/ls807terra/0_script/pipeline_test

cd ${path}

file=sampleFormula_test.xlsx
outputname=sampleFormula_test.csv

/staging/biology/ls807terra/0_Programs/xlsx2csv-master/xlsx2csv.py \
 --delimiter 'tab' \
 ${file} \
 ${outputname}

