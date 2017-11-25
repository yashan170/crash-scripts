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

# method clusters $outfile name variance inname pca?
run_cluster () {
  #Do we run with PCA or not? 
if [ -z "$7" ]
  then
		$DIR/cluster --cluster-method=$1 --clusters=$2 --outfile=$3 --name=$4 --variance-threshold=$5 $6
	else
		$DIR/cluster --cluster-method=$1 --clusters=$2 --outfile=$3 --name=$4 --variance-threshold=$5 --pca=$7 $6
fi
}

# Run clustering on the extracted vectors. 
echo "Running KMeans clustering(AFL)"
run_cluster "kmeans" 25 $DIR/$NAME'-kmeans.json' "kmeans" "0.9" $DIR/$NAME'-vectors'
echo "Running KMeans clustering(PIN)"
run_cluster "kmeans" 25 $DIR/$NAME'-kmeans-itrace.json' "kmeans-itrace" "0.9" $DIR/$NAME'-itrace-vectors'

echo "Running KMeans(PCA) clustering(AFL)"
run_cluster "kmeans" 25 $DIR/$NAME'-kmeans-pca.json' "kmeans-pca" "0.9" $DIR/$NAME'-vectors' "0.95"

echo "Running KMeans(PCA) clustering(PIN)"
run_cluster "kmeans" 25 $DIR/$NAME'-kmeans-pca-itrace.json' "kmeans-pca-itrace" "0.9" $DIR/$NAME'-itrace-vectors' "0.95"

echo "Running DBSCAN clustering(AFL)"
run_cluster "dbscan" 0 $DIR/$NAME'-dbscan.json' "dbscan" "0.9" $DIR/$NAME'-vectors'

echo "Running DBSCAN clustering(PIN)"
run_cluster "dbscan" 0 $DIR/$NAME'-dbscan-itrace.json' "dbscan-itrace" "0.9" $DIR/$NAME'-itrace-vectors'

echo "Running Aggregate clustering(AFL)"
run_cluster "agg" 25 $DIR/$NAME'-agg.json' "agg" "0.9" $DIR/$NAME'-vectors'

echo "Running Aggregate clustering(PIN)"
run_cluster "agg" 25 $DIR/$NAME'-agg-itrace.json' "agg-itrace" "0.9" $DIR/$NAME'-itrace-vectors'

echo "Running Aggregate(PCA) clustering(AFL)"
run_cluster "agg" 25 $DIR/$NAME'-agg-pca.json' "agg-pca" "0.9" $DIR/$NAME'-vectors' "0.95"

echo "Running Aggregate(PCA) clustering(PIN)"
run_cluster "agg" 25 $DIR/$NAME'-agg-pca-itrace.json' "agg-pca-itrace" "0.9" $DIR/$NAME'-itrace-vectors' "0.95"

echo "Running MeanShift clustering(AFL)"
run_cluster "meanshift" 0 $DIR/$NAME'-meanshift.json' 'meanshift' "0.9" $DIR/$NAME'-vectors'

echo "Running MeanShift clustering(PIN)"
run_cluster "meanshift" 0 $DIR/$NAME'-meanshift-itrace.json' 'meanshift-itrace' "0.9" $DIR/$NAME'-itrace-vectors'

echo "Running MeanShift(PCA) clustering(AFL)"
run_cluster "meanshift" 0 $DIR/$NAME'-meanshift-pca.json' 'meanshift-pca' "0.9" $DIR/$NAME'-vectors' "0.95"

echo "Running MeanShift(PCA) clustering(PIN)"
run_cluster "meanshift" 0 $DIR/$NAME'-meanshift-pca-itrace.json' 'meanshift-pca-itrace' "0.9" $DIR/$NAME'-itrace-vectors' "0.95"

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
