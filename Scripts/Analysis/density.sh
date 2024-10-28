#!/bin/bash

source ~/.bashrc

gmx make_ndx -f ../nosol.gro -o index.ndx << EOD
del 0-100
a P*
name 0 Phosphates
a BB
name 1 Backbone
a P* & r POPC
a P* & r SAPE
a P* & r CDL2
a P* & r PAPI
a P* & r POPS
a ROH & r CHOL
a OH1 & r PCER
q
EOD

gmx density -f ../fit_atpase_nosol.xtc -s ../md.tpr -b 2000000 -n index.ndx -relative -sl 600 -o phosphate-density.xvg << EOD
0
EOD

gmx density -f ../fit_atpase_nosol.xtc -s ../md.tpr -b 2000000 -n index.ndx -relative -sl 600 -o protein-density.xvg << EOD
1
EOD

gmx density -f ../fit_atpase_nosol.xtc -s ../md.tpr -b 2000000 -n index.ndx -relative -sl 600 -o popc-density.xvg << EOD
2
EOD

gmx density -f ../fit_atpase_nosol.xtc -s ../md.tpr -b 2000000 -n index.ndx -relative -sl 600 -o sape-density.xvg << EOD
3
EOD

gmx density -f ../fit_atpase_nosol.xtc -s ../md.tpr -b 2000000 -n index.ndx -relative -sl 600 -o cdl2-density.xvg << EOD
4
EOD

gmx density -f ../fit_atpase_nosol.xtc -s ../md.tpr -b 2000000 -n index.ndx -relative -sl 600 -o papi-density.xvg << EOD
5
EOD

gmx density -f ../fit_atpase_nosol.xtc -s ../md.tpr -b 2000000 -n index.ndx -relative -sl 600 -o pops-density.xvg << EOD
6
EOD

gmx density -f ../fit_atpase_nosol.xtc -s ../md.tpr -b 2000000 -n index.ndx -relative -sl 600 -o chol-density.xvg << EOD
7
EOD

gmx density -f ../fit_atpase_nosol.xtc -s ../md.tpr -b 2000000 -n index.ndx -relative -sl 600 -o pcer-density.xvg << EOD
8
EOD

python3 Densities_lipids.py

rm \#*
