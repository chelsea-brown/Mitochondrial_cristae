#!/bin/bash

n=0
echo 'All subunits' > martinize_log.txt
for structure in Structures_AT/*.pdb; do
	echo 'Working on molecule '$n 'which is for' $structure
	echo 'molecule_'$n >> martinize_log.txt
	martinize2 -f $structure -o itps/molecule_$n.top -x Structures_CG/molecule_$n.pdb -ff martini3001 -maxwarn 10000 -elastic -ef 500 -eu 1.0 -el 0.5 -ea 0 -ep 0 &>> martinize_log.txt
	mv molecule_0.itp itps/molecule_$n.itp
	n=$((n+1))
done	