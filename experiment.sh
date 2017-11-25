#!/bin/bash
set -e 
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CSV=$1
NAME=$2
DATAPATH=$3
PROGRAM=$4

# Check that we have afl-showmap and pin in $PATH.
hash afl-showmap 2>/dev/null || { echo >&2 "I require afl-showmap but it's not installed.  Aborting."; exit 1; }
hash "pin -t itrace -- /bin/ls /" > /dev/null || { echo >&2 "I require pin but it's not installed. Aborting."; exit 1; }

echo "Generating ground truth data"
# Start from some CSV input and make a JSON ground truth.
$DIR/analyze_groundtruth $NAME $CSV $DIR/$NAME'-groundtruth.json' $DATAPATH

echo "Generating vector extraction commands for AFL"
# Generate vector extract commands from the JSON.
mkdir -p $DIR/$NAME'-vectors'
$DIR/mk_command "$DIR/get_afl_vec \"$PROGRAM\"" $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-vectors' > $DIR/$NAME'-commands'

echo "Generating vector extraction commands for PIN"
mkdir -p $DIR/$NAME'-itrace-vectors'
$DIR/mk_command "$DIR/get_itrace_vec \"$PROGRAM\"" $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-itrace-vectors' > $DIR/$NAME'-itrace-commands'

echo "Extracting vectors for AFL"
# Run the vector extract commands through GNU parallel. 
parallel --bar < $DIR/$NAME'-commands'

echo "Extracting vectors for PIN"
parallel --bar < $DIR/$NAME'-itrace-commands'

# Run clustering on the extracted vectors. 
echo "Running KMeans clustering(AFL)"
$DIR/cluster --cluster-method=kmeans --clusters=25 --outfile=$DIR/$NAME'-kmeans.json' --name=kmeans --variance-threshold=0.9 $DIR/$NAME'-vectors'
echo "Running KMeans clustering(PIN)"
$DIR/cluster --cluster-method=kmeans --clusters=25 --outfile=$DIR/$NAME'-kmeans-itrace.json' --name=kmeans-itrace --variance-threshold=0.9 $DIR/$NAME'-itrace-vectors'

echo "Running KMeans(PCA) clustering(AFL)"
$DIR/cluster --pca=0.95 --cluster-method=kmeans --clusters=25 --outfile=$DIR/$NAME'-kmeans-pca.json' --name=kmeans-pca --variance-threshold=0.9 $DIR/$NAME'-vectors'

echo "Running KMeans(PCA) clustering(PIN)"
$DIR/cluster --pca=0.95 --cluster-method=kmeans --clusters=25 --outfile=$DIR/$NAME'-kmeans-pca-itrace.json' --name=kmeans-pca-itrace --variance-threshold=0.9 $DIR/$NAME'-itrace-vectors'

echo "Running DBSCAN clustering(AFL)"
$DIR/cluster --cluster-method=dbscan --outfile=$DIR/$NAME'-dbscan.json' --name=dbscan --variance-threshold=0.9 $DIR/$NAME'-vectors'

echo "Running DBSCAN clustering(PIN)"
$DIR/cluster --cluster-method=dbscan --outfile=$DIR/$NAME'-dbscan-itrace.json' --name=dbscan-itrace --variance-threshold=0.9 $DIR/$NAME'-itrace-vectors'

echo "Running Aggregate clustering(AFL)"
$DIR/cluster --cluster-method=agg --clusters=25 --outfile=$DIR/$NAME'-agg.json' --name=agg --variance-threshold=0.9 $DIR/$NAME'-vectors'

echo "Running Aggregate clustering(PIN)"
$DIR/cluster --cluster-method=agg --clusters=25 --outfile=$DIR/$NAME'-agg-itrace.json' --name=agg-itrace --variance-threshold=0.9 $DIR/$NAME'-itrace-vectors'

echo "Running Aggregate(PCA) clustering(AFL)"
$DIR/cluster --pca=0.95 --cluster-method=agg --clusters=25 --outfile=$DIR/$NAME'-agg-pca.json' --name=agg-pca --variance-threshold=0.9 $DIR/$NAME'-vectors'

echo "Running Aggregate(PCA) clustering(PIN)"
$DIR/cluster --pca=0.95 --cluster-method=agg --clusters=25 --outfile=$DIR/$NAME'-agg-pca-itrace.json' --name=agg-pca-itrace --variance-threshold=0.9 $DIR/$NAME'-itrace-vectors'

echo "Running MeanShift clustering(AFL)"
$DIR/cluster --cluster-method=meanshift --outfile=$DIR/$NAME'-meanshift.json' --name=meanshift --variance-threshold=0.9 $DIR/$NAME'-vectors'

echo "Running MeanShift clustering(PIN)"
$DIR/cluster --cluster-method=meanshift --outfile=$DIR/$NAME'-meanshift-itrace.json' --name=meanshift-itrace --variance-threshold=0.9 $DIR/$NAME'-itrace-vectors'

echo "Running MeanShift(PCA) clustering(AFL)"
$DIR/cluster --pca=0.95 --cluster-method=meanshift --outfile=$DIR/$NAME'-meanshift-pca.json' --name=meanshift-pca --variance-threshold=0.9 $DIR/$NAME'-vectors'

echo "Running MeanShift(PCA) clustering(PIN)"
$DIR/cluster --pca=0.95 --cluster-method=meanshift --outfile=$DIR/$NAME'-meanshift-pca-itrace.json' --name=meanshift-pca-itrace --variance-threshold=0.9 $DIR/$NAME'-itrace-vectors'

compare_results () {
  $DIR/analyze_clusters --method=$1 $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-kmeans.json'
  $DIR/analyze_clusters --method=$1 $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-kmeans-itrace.json'
  $DIR/analyze_clusters --method=$1 $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-kmeans-pca.json'
  $DIR/analyze_clusters --method=$1 $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-kmeans-pca-itrace.json'
  $DIR/analyze_clusters --method=$1 $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-dbscan.json'
  $DIR/analyze_clusters --method=$1 $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-dbscan-itrace.json'
  $DIR/analyze_clusters --method=$1 $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-agg.json'
  $DIR/analyze_clusters --method=$1 $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-agg-itrace.json'
  $DIR/analyze_clusters --method=$1 $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-agg-pca.json'
  $DIR/analyze_clusters --method=$1 $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-agg-pca-itrace.json'
  $DIR/analyze_clusters --method=$1 $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-meanshift.json'
  $DIR/analyze_clusters --method=$1 $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-meanshift-itrace.json'
  $DIR/analyze_clusters --method=$1 $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-meanshift-pca.json'
  $DIR/analyze_clusters --method=$1 $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-meanshift-pca-itrace.json'
}

# Compare the produced cluster(s) with ground truth and report. 
echo "Comparing clusters using FMI"
compare_results fmi
echo "Comparing clusters using F"
compare_results f
echo "Comparing clusters using ARI"
compare_results ari
echo "Comparing clusters using AMI"
compare_results ami
