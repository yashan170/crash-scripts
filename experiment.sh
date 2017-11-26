#!/bin/bash
set -e 
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CSV=$1
NAME=$2
DATAPATH=$3
PROGRAM=$4

pushd .
cd $DIR
./experiment $CSV $NAME $DATAPATH "$PROGRAM"
popd
