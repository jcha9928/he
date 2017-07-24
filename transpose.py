#! /usr/bin/env python                                                                                                                                                      
# This trac_transpose_matrix.py transpose matrix                                                                                                                            
# Written by Jiook Cha (cha.jiook@gmail.com)                                                                                                                                




import sys                                                                                                                                                                 
from numpy import genfromtxt, savetxt                                                                                                                                      
data = genfromtxt(sys.argv[1])                                                                                                                                             
savetxt(sys.argv[1])   
