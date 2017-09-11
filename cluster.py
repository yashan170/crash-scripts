#!/usr/bin/env python2
from sklearn.cluster import KMeans
import numpy as np
import argparse
import sys

def tovec(filename):
  contents = open(filename, 'r').read()
  return [ ord(i) for i in contents ] 

def main(args):
  vecs = []
  for f in args.files:
    vecs.append(tovec(f))
  # Pad out everything. 
  high = 0 
  for i in vecs:
    if len(i) > high:
      high = len(i)
  vecs = [ i + ([0] * (high-len(i))) for i in vecs ]
  # Do the clustering. 
  na = np.array(vecs)
  kmeans = KMeans(n_clusters=args.clusters, random_state=0).fit(na)
  for i,c in enumerate(kmeans.labels_):
    print "%s|%s" % (args.files[i], c)
  return 0

if __name__ == '__main__':
  parser = argparse.ArgumentParser("cluster")
  parser.add_argument('files', nargs='+')
  parser.add_argument('--clusters', type=int, default=8)
  args = parser.parse_args()
  sys.exit(main(args))

