#!/bin/bash

path=/staging/biology/ls807terra/0_script/pipeline_test

cd ${path}

file=sampleFormula_test.xlsx
outputname=sampleFormula_test.csv

xlsx2csv.py --delimiter 'tab' \
 ${file} \
 ${outputname}

