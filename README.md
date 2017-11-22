# Clustering

## Workflow

 * Run `SOME_OTHER_THING3` to generate a ground truth cluster. 
 * Run `mk_command` to make a set of commands for GNU `parallel` to run.
 * Run `parallel` on the generated commands to generate the feature vectors.
 * Run `SOME_OTHER_THING` to reduce all of the feature vectors. 
 * Run `SOME_OTHER_THING2` to cluster the feature vectors into clusters.
 * Run `cluster_compare` on all of the different clusters and the ground truth
   cluster and record the results. 

## Example

There's an experiment script that does all of the above. You invoke it like this:

    ./experiment.sh /media/disk/fuzzing_data/flasm-groundtruth-final.csv flasm-gcc-noopt1 /media/disk/fuzzing_data/flasm-gcc-noopt1/flasm-gcc-noopt1 '/media/disk/fuzzing_data/flasm-gcc-noopt1/src/flasm -d'
