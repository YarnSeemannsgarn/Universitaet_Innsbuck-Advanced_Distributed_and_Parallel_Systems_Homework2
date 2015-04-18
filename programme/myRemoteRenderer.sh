#!/bin/bash

PWD="$PWD"
BIN_DIR=${PWD}/bin
INPUT_DIR=${PWD}/inputdata
JOB_DIR=${PWD}/jobs
DEST=lab623/files_for_rendering
HEADLINE="****************************************************************************************************"

usage() { echo "Usage: $0 <user@host> <processor-number> [clean]" 1>&2; exit 1; }

if [[ $# != 2 && $# != 3 ]] ;
then
    usage
fi

# SSH preperations
ssh_private_file=~/.ssh/id_rsa
ssh_public_file=~/.ssh/id_rsa.pub
if [[ -f "$ssh_private_file" && -f "$ssh_public_file" ]] ;
then
    echo "SSH keypair exists!"
    while true; do
	read -p "Do you want to copy the ssh public file to the remote host to avoid password entering multiple times? If the key is already on the remote host you should enter \"no\". (yn)" yn
	case $yn in
	    [Yy]* ) ssh-agent -s; ssh-add $ssh_private_file; ssh-copy-id $1; break;;
	    [Nn]* ) break;;
	    * ) echo "Please answer yes or no.";;
	esac
    done
else
    echo "SSH keypair does not exists!"
    while true; do
	read -p "Do you want to generate a ssh keypair and copy the ssh public file to the remote host to avoid password entering multiple times? (yn)" yn
	case $yn in
	    [Yy]* ) ssh-agent -s; ssh-keygen; ssh-add $ssh_private_file; ssh-copy-id $1; break;;
	    [Nn]* ) break;;
	    * ) echo "Please answer yes or no.";;
	esac
    done
fi

# Task 1: Copy files to cluster
echo
echo "${HEADLINE}"
echo "TASK 1: COPY FILES TO REMOTE HOST TO ~/${DEST}"
echo "${HEADLINE}"
echo
ssh $1 "mkdir -p ${DEST}"
rsync -avcPe ssh ${BIN_DIR} ${INPUT_DIR} ${JOB_DIR} ${PWD}/render.sh $1:~/${DEST}
echo
echo "${HEADLINE}"
echo "FINISHED COPYING"
echo "${HEADLINE}"

# Task 2: Render on cluster (script includes task 3)
echo
echo "${HEADLINE}"
echo "TASK 2 & 3: START REMOTE RENDERING - USE SOLUTION OF HOMEWORK 1"
echo "${HEADLINE}"
ssh $1 "cd ${DEST}; ./render.sh $2"
echo
echo "${HEADLINE}"
echo "FINISHED REMOTE RENDERING"
echo "${HEADLINE}"

# Task 4: Get gif from remote host
echo
echo "${HEADLINE}"
echo "TASK 4: COPY GIF FROM REMOTE HOST TO ${PWD}"
echo "${HEADLINE}"
echo
PAR_DIR=${DEST}/results/parallel
rsync -avcPe ssh $1:~/${PAR_DIR}/*gif ./
echo
echo "${HEADLINE}"
echo "GOT GIF"
echo "${HEADLINE}"

# Task 5: Clean up
if [[ $# == 3 ]] ;
then
    if [[ $3 == "clean" ]] ;
    then
	echo
	echo "${HEADLINE}"
	echo "TASK 5: CLEAN UP GENERATED DATA (${DEST}/results) ON REMOTE HOST"
	echo "${HEADLINE}"
	echo
	ssh $1 "rm -rf ${DEST}/results"
	echo
	echo "${HEADLINE}"
	echo "FINISHED CLEAN UP"
	echo "${HEADLINE}"
	echo
    else
	echo "Wrong third argument!"
	usage
    fi
fi