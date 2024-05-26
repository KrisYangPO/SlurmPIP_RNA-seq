#!/bin/bash

path=/staging/biology/ls807terra/0_script/pipeline_test

cd ${path}

file=sampleFormula_test.xlsx
outputname=sampleFormula_test.csv

<<<<<<< HEAD
/staging/biology/ls807terra/0_Programs/xlsx2csv-master/xlsx2csv.py \
 --delimiter 'tab' \
=======
xlsx2csv.py --delimiter 'tab' \
>>>>>>> 818eacc (Develop Sample Table input pipeline)
 ${file} \
 ${outputname}

