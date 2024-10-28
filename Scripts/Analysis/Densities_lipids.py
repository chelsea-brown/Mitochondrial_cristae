#!/usr/bin/env python
import glob
import os,sys, numpy as np
from matplotlib import pyplot as plt
from matplotlib.lines import Line2D
import seaborn as sns
import random
import string
import pandas as pd

plt.rcParams.update({'font.size': 50})

x,y = np.loadtxt('protein-density.xvg', comments=["@","#"],unpack=True)
x2,y2 = np.loadtxt('phosphate-density.xvg', comments=["@","#"],unpack=True)
x1,y1 = np.loadtxt('popc-density.xvg', comments=["@","#"],unpack=True)
x3,y3 = np.loadtxt('cdl2-density.xvg', comments=["@","#"],unpack=True)
x4,y4 = np.loadtxt('sape-density.xvg', comments=["@","#"],unpack=True)
x5,y5 = np.loadtxt('papi-density.xvg', comments=["@","#"],unpack=True)
x6,y6 = np.loadtxt('pops-density.xvg', comments=["@","#"],unpack=True)
x7,y7 = np.loadtxt('chol-density.xvg', comments=["@","#"],unpack=True)
x8,y8 = np.loadtxt('pcer-density.xvg', comments=["@","#"],unpack=True)

fig, ax = plt.subplots(figsize=(20, 30))

#ax.plot(y,x,color='darkblue', label ="Protein", linewidth=5)
#ax.plot(y2,x2,color='black', label ="Phosphates", linewidth=5)
ax.plot(y1,x1,color='darkturquoise', label ="POPC", linewidth=5)
ax.plot(y3,x3,color='darkorange', label ="CDL2", linewidth=5)
ax.plot(y4,x4,color='green', label ="SAPE", linewidth=5)
ax.plot(y5,x5,color='lightpink', label ="PAPI", linewidth=5)
ax.plot(y6,x6,color='silver', label ="POPS", linewidth=5)
ax.plot(y7,x7,color='palevioletred', label ="CHOL", linewidth=5)
ax.plot(y8,x8,color='whitesmoke', label ="PCER", linewidth=5)
#plt.fill_between(y, x, interpolate=True, alpha=0.2, color='darkblue')
#plt.fill_between(y2, x2, alpha=0.2, color='black')
ax.fill_between(y1,x1,color='darkturquoise', alpha=0.2,)
ax.fill_between(y3,x3,color='darkorange', alpha=0.2,)
ax.fill_between(y4,x4,color='green', alpha=0.2,)
ax.fill_between(y5,x5,color='lightpink', alpha=0.2,)
ax.fill_between(y6,x6,color='silver', alpha=0.2,)
ax.fill_between(y7,x7,color='palevioletred', alpha=0.2,)
ax.fill_between(y8,x8,color='whitesmoke', alpha=0.2,)

ax.legend()


#plt.autoscale(enable=True, tight=True)
#plt.autoscale(tight=True)

#plt.title("Average positions and densities in the membrane")
#plt.xlabel("Density (kg $\mathregular{m^3}$)")
#plt.ylabel("Average relative position (nm)")
plt.xlim(0,18)
plt.ylim(10,100)
#plt.show()
#fig.savefig("Density.pdf", format='pdf')
fig.savefig("Density.png", format='png', dpi=300)
