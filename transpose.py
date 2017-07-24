#! /nfs/apps/python/2.7.11/bin/python                                                                                                                                                      
# This trac_transpose_matrix.py transpose matrix                                                                                                                            
# Written by Jiook Cha (cha.jiook@gmail.com)                                                                                                                                

import csv
import sys
#from __future__ import print_function

with open(sys.argv[1], "rt") as f:
  lis = [x.split() for x in f]

for x in zip(*lis):
  for y in x:
    print eval(y+'\t'), 
# (y+'\t','')
  print
