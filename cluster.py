#!/usr/bin/env python2
from sklearn.cluster import KMeans
import numpy as np
import argparse
import json
import sys

def main(args):
  # Read in all the vector files as dictionaries. 
  
  map_dicts = []
  for f in args.files:
    map_dicts.append(json.load(open(f, 'r')))
  # Pad out all the dicts in map.dicts to have the same key set.
  total_key_set = set()
  for m in map_dicts:
    total_key_set = total_key_set.union(m.keys())
  for m in map_dicts:
    for k in total_key_set:
      if k not in m.keys():
        m[k] = 0

  # Now, turn these into actual vectors, with an order controlled by
  # the set of all keys. 
  vecs = []
  for m in map_dicts:
    vec = []
    for k in total_key_set:
      vec.append(m[k])
    vecs.append(vec)
  # Now we can actually do some clustering. 
  na = np.array(vecs)
  kmeans = KMeans(n_clusters=args.clusters, random_state=0).fit(na)
  # Write the results of this clustering out to a file. 
  for i,c in enumerate(kmeans.labels_):
    print "%s|%s" % (args.files[i], c)
  return 0

if __name__ == '__main__':
  parser = argparse.ArgumentParser("cluster")
  parser.add_argument('files', nargs='+')
  parser.add_argument('--clusters', type=int, default=8)
  args = parser.parse_args()
  sys.exit(main(args))

