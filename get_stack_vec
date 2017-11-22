#!/usr/bin/env python2.7
from sklearn.cluster import KMeans
from sklearn.decomposition import PCA
from multiprocessing import Pool
import tempfile
import numpy as np
import subprocess
import argparse
import json
import sys
import os

COMMAND = 'bash -c "cat %s | ASAN_OPTIONS=symbolize=false,log_path=stdout gdb -batch -ex "run" -ex "bt" %s"'
LLDB_COMMAND = "./debugger %s %s"
#AFL_COMMAND = 'bash -c "cat %s | afl-showmap -q -o %s -- %s"'
AFL_COMMAND = 'afl-showmap -q -o %s -- %s -d %s'

class GetStack(object):
  def __init__(self, p):
    self.p = p
  def __call__(self, x):
    return (x,subprocess.check_output(LLDB_COMMAND % (x, self.p), shell=True))

class GetMap(object):
  def __init__(self, p):
    self.p = p
  def __call__(self, x):
    f = tempfile.NamedTemporaryFile(delete=False)
    nm = f.name
    f.close()
    subprocess.call(AFL_COMMAND % (nm, self.p, x), shell=True)
    u = open(nm, 'r')
    buf = u.read()
    u.close()
    os.remove(nm)
    return (x,buf)

def main(args):
  files = []
  injs = json.load(open(args.files, 'r'))
  for i in injs["labels"]:
    files.append(i[0])
  p = Pool(16)
  if args.get_stacks:
    stacks = p.map(GetStack(args.program), files)
    prunedstacks = []
    for (infile,s) in stacks:
      newstack = []
      b = s.split("\n")
      start1 = False
      start = False
      for i in b[2:]:
        iu = i.strip().rstrip()
        ij = iu.find("thread backtrace all")
        if ij != -1:
          start1 = True
          continue
        if start1 == True:
          if iu.find("thread #") != -1:
            start = True
            continue
        if len(iu) > 0 and (iu[0] == '#' or iu[0] == '*') and start == True:
          a = iu.find("#")
          newstack.append(iu[a+1:])
      prunedstacks.append((infile,newstack))
    for (i,s) in prunedstacks:
      print i
      for u in s:
        print u
      print ""
    return 0
  maps = p.map(GetMap(args.program), files)
  maps_as_dicts = []
  for (infile,m) in maps:
    dmap = {}
    for l in m.split("\n"):
      lu = l.strip().rstrip()
      if len(lu) > 0:
        a,b = lu.split(":")
        dmap[a] = int(b)
    maps_as_dicts.append((infile,dmap))
  # Align all of the dicts, i.e. give them all the same key set. 
  all_keys = set()
  for (a,m) in maps_as_dicts:
    all_keys = all_keys.union(set(m.keys()))
  for (a,m) in maps_as_dicts:
    for k in all_keys:
      if m.has_key(k) == False:
        m[k] = 0
  vecs = [ [ m[i] for i in m.keys() ] for (a,m) in maps_as_dicts ]
  """
  # Make them into vectors. 
  na = np.array(vecs)
  # Run PCA?
  if args.pca == True:
    u = PCA(n_components=300).fit(na)
    na = u.transform(na)
  # Do the clustering.
  kmeans = KMeans(n_clusters=args.clusters, random_state=0).fit(na)
  for i,c in enumerate(kmeans.labels_):
    print "%s|%s" % (maps_as_dicts[i][0], c)
  """

  return 0

if __name__ == '__main__':
  parser = argparse.ArgumentParser("getstacks")
  parser.add_argument('--clusters', type=int, default=8)
  parser.add_argument('--pca', type=bool, default=False)
  parser.add_argument('--get-stacks', type=bool, default=False)
  parser.add_argument('--pca_components', type=int, default=100)
  parser.add_argument("program", type=str)
  parser.add_argument("files", type=str, help="JSON file specifying input files")
  args = parser.parse_args()
  sys.exit(main(args))
