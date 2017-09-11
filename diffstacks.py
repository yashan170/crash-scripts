#!/usr/bin/env python2
import argparse
import sys

def getstacks(filename):
  r = {}
  buf = open(filename, 'r').read()
  m = None
  l = []
  for i in buf.split("\n"):
    iu = i.strip().rstrip()
    if len(iu) == 0 and m != None:
      r[m] = l
      m = None
      l = []
    else:
      if m == None:
        m = iu
      else:
        l.append(iu)

  return r

def lcs(a, b):
  tbl = [[0 for _ in range(len(b) + 1)] for _ in range(len(a) + 1)]
  for i, x in enumerate(a):
    for j, y in enumerate(b):
      tbl[i + 1][j + 1] = tbl[i][j] + 1 if x == y else max(tbl[i + 1][j], tbl[i][j + 1])
  res = []
  i, j = len(a), len(b)
  while i and j:
    if tbl[i][j] == tbl[i - 1][j]:
      i -= 1
    elif tbl[i][j] == tbl[i][j - 1]:
      j -= 1
    else:
      res.append(a[i - 1])
      i -= 1
      j -= 1
  return res[::-1]

def printstack(s):
  for i in s:
    print i

def main(args):
  A = getstacks(args.A)
  B = getstacks(args.B)
  allmembers = set(A.keys()).union(B.keys())
  results = {}
  for m in allmembers:
    Astack = A[m]
    Bstack = B[m]
    subseq = lcs(Astack, Bstack)
    if subseq != Astack:
      if subseq != Astack[1:] or subseq != Bstack[1:]:
        if subseq != Astack[2:] or subseq != Bstack[2:]:
          print "%s diffs!" % m
          printstack(Astack)
          printstack(Bstack)

  return 0

if __name__ == '__main__':
  parser = argparse.ArgumentParser("diffstacks")
  parser.add_argument("A", type=str)
  parser.add_argument("B", type=str)
  args = parser.parse_args()
  sys.exit(main(args))
