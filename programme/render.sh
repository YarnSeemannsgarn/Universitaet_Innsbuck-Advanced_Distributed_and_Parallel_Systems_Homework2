#!/bin/bash

# Mainly taken from homework 1
PWD="$PWD"
BIN_DIR=${PWD}/bin
INPUT_DIR=${PWD}/inputdata
JOB_DIR=${PWD}/jobs
PAR_DIR=${PWD}/results/parallel
mkdir -p $PAR_DIR
HEADLINE="***************"

usage() { echo "Usage: $0 <processor-number>" 1>&2; exit 1; }

if [[ $# != 1 ]] ;
then
    usage
fi

# Read .ini file to get frame numbers
while read line
do
    if [[ $line == Initial_Frame* ]] || [[ $line == Final_Frame* ]] ;
    then
	equal_pos=`expr index $line =`
	length=`expr length $line`
	frame_number=${line:equal_pos:length}
	
	if [[ $line == Initial_Frame* ]] ;
	then
	    INITIAL_FRAME=$frame_number
	else
	    FINAL_FRAME=$frame_number
	fi
    fi
done < ${INPUT_DIR}/scherk.ini

# M = number of frames
M=$((FINAL_FRAME - INITIAL_FRAME + 1))
echo
echo "$M frames will be rendered in parallel"

# Get processors as argument
N=$1

# Split frames to processors
if [[ $N -gt $M ]] ;
then
    echo "There are more processors than frames, so only $M processors will be used"
    USED_PROCESSORS=$M
else
    USED_PROCESSORS=$N
fi

subset_start_frame=1
subsets_per_processor=$(( M/N ))
modulo=`expr $M % $N`
parallel_job_names=""
job_ids=""
echo "Execute job_hw1_task5 on $USED_PROCESSORS processors to generate all png files"
for (( i=1; i<=$USED_PROCESSORS; i++ ))
do
    subset_end_frame=$((subset_start_frame + subsets_per_processor - 1))
    if [[ $i -le $modulo ]]
    then
	subset_end_frame=$((subset_end_frame + 1))
    fi

    job_name=job_hw1_task5_part$i

    # Get job id to extract job running time later
    job_id=`qsub -N $job_name -cwd -e ${PAR_DIR}/ -o ${PAR_DIR}/ -v BIN_DIR=${BIN_DIR},INPUT_DIR=${INPUT_DIR},SF=${subset_start_frame},EF=${subset_end_frame} ${JOB_DIR}/job_hw1_task5.sge | cut -d ' ' -f 3`
    job_ids="${job_ids},${job_id}"
    subset_start_frame=$((subset_end_frame + 1))
    parallel_job_names="${parallel_job_names},${job_name}"
done

# Use job_hw1_task2 to merge files
echo "Merge all png files, when all pngs are generated"
job_id=`qsub -N job_hw1_task5_merge -cwd -sync y -hold_jid ${parallel_job_names} -e ${PAR_DIR}/ -o ${PAR_DIR}/ -v BIN_DIR=${BIN_DIR} ${JOB_DIR}/job_hw1_task2.sge | cut -d ' ' -f 3`
job_ids="${job_ids},${job_id}"

# Move files to PAR_DIR
echo "Move pngs and gif to $PAR_DIR"
echo
mv ${PWD}/*.png ${PWD}/*.gif ${PAR_DIR}/

# Task 3: Extract job times
IFS=', ' read -a array <<< "$job_ids"
first_loop=true
echo "${HEADLINE} TASK 3 - JOB EXECUTION TIMES ${HEADLINE}"
echo
for job_id in "${array[@]}"
do
    # Skip first encounter, because job_ids format is: ",job_id1,job_id2 ..."
    if [[ "$first_loop" = true ]] ;
    then 
	first_loop=false
    else
	echo "${HEADLINE} JOB ${job_id} ${HEADLINE}"
	
	until qacct -j $job_id > /dev/null 2>&1; do
 	    sleep 1
        done
	qacct -j $job_id | grep hostname
	qacct -j $job_id | grep ru_utime
	qacct -j $job_id | grep start_time
	qacct -j $job_id | grep end_time
	echo
    fi
done