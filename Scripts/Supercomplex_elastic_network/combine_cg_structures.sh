#!/bin/bash

cp Structures_CG/molecule_0.pdb Megacomplex_A-cg.pdb
echo "" >> Megacomplex_A-cg.pdb

for i in {1..78}; do
	cat Structures_CG/molecule_$i.pdb >> Megacomplex_A-cg.pdb
	echo "" >> Megacomplex_A-cg.pdb
done

sed -i '/^CONECT/d' Megacomplex_A-cg.pdb
sed -i '/END/d' Megacomplex_A-cg.pdb
sed -i '/^TER/d' Megacomplex_A-cg.pdb

gmx editconf -f Megacomplex_A-cg.pdb -resnr 1 -o Megacomplex_A-cg.pdb