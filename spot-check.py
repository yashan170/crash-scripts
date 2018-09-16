#!/usr/bin/env python2.7
from progressbar import ProgressBar,Bar,Percentage
from runner import run2_asan
import argparse 
import sys 
import csv

def main(args):
  # Get a list of input files to test.
  inputs = []
  with open(args.inputs, 'r') as ir:
    rd = csv.reader(ir)
    rd.next()
    for (filename,a,b) in rd:
      inputs.append(filename)
  # Get a list of programs to test. 
  programs = []
  with open(args.programs, 'r') as ir:
    rd = csv.reader(ir)
    rd.next()
    for (hsh,path,program_args) in rd:
      programs.append((hsh,path))
  # Map the list of programs onto the program commit times, to create an order.
  hash_to_time = {}
  with open(args.commit_times, 'r') as ir:
    rd = csv.reader(ir)
    rd.next()
    for (hsh,ctime,atime,cdate,adate) in rd:
      hash_to_time[hsh] = (int(ctime),cdate)
  # Order the list of programs to run based on hash_to_time. 
  programs.sort(key=lambda x: hash_to_time[x[0]][0])
  # Run and remember the results, in order. 
  work = []
  for i in inputs:
    for (h,prog) in programs:
      work.append((i,prog,h))
 
  work_s = []
  tmp = []
  count_work = len(work)
  for i in work:
    if len(tmp) == 50:
      work_s.append(tmp)
      tmp = [i]
    else:
      tmp.append(i)

  if len(tmp) != 0:
    work_s.append(tmp)

  work = work_s
  results = []
  pbar = ProgressBar(widgets=[Percentage(), Bar()], maxval=count_work).start()
  k = 0
  for worklist in work:
    programs = []
    inputs = []
    stuff = []
    for (i,p,h) in worklist:
      programs.append("file://"+p)
      inputs.append(([],"file://"+i))
      stuff.append({})
    tasks = zip(programs,inputs,stuff)
    rv = run2_asan(tasks)
    for ((i,p,h),r) in zip(worklist,rv):
      res = "NOCRASH"
      if len(r['stack']) > 0:
        res = "CRASH"
      results.append((i,p,h,res))
      k = k + 1
    pbar.update(k)
  pbar.finish()

  # Output in order. 
  results.sort(key=lambda x: hash_to_time[x[2]][0])
  with open(args.output, 'w') as of:
    wt = csv.writer(of)
    wt.writerow(["ctime","hash","inputname","result"])
    for (filename,prog,h,result) in results:
      bn = filename.split("/")[-1]
      r1 = filename.split("/")[-4]
      r2 = filename.split("/")[-5]
      fnm = "{}-{}-{}".format(r2,r1,bn)
      wt.writerow([hash_to_time[h][1], h, fnm, result])
  return 0

if __name__ == '__main__':
  parser = argparse.ArgumentParser('spot-check')
  parser.add_argument('inputs')
  parser.add_argument('programs')
  parser.add_argument('commit_times')
  parser.add_argument('output')
  args = parser.parse_args()
  sys.exit(main(args))
