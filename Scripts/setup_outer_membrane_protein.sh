#!/bin/bash

# Error function
function error_exit {
  echo -e "\033[38;5;196mOh no, not as easy as you think..... Something is wrong here...\033[0m" >&2
  exit 1
}


# Set default number of threads
nt=1

# Parse optional arguments
while [[ $# -gt 1 ]]
do
key="$2"

case $key in
    -nt|--threads)
    nt="$3"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    echo "Unknown option: $2"
    help
    exit 1
    ;;
esac
done

pdb_code=$1
cg_pdb=${pdb_code}-cg.pdb

# Check if PDB code is provided as an argument
if [ -z "$1" ]
  then
    echo "Please provide a PDB code as an argument"
    exit 1
fi


##Cleaning up the pdb file
grep -v DU ${pdb_code}.pdb  > ${pdb_code}_clean.pdb 
#rm -r *.txt chain*


##This is new to try and get chain breaks and then fix them
python3 ~/Projects/Base_files/mdanalysis_chains.py ${pdb_code}_clean


# Coarse-graining
chain_names="`head -1 chain_names.txt`"
echo "The list for the chains is ${chain_names}"
martinize2 -f ${pdb_code}_clean.pdb -o topol.top -x ${cg_pdb} -ff martini3001 -maxwarn 10000 -elastic -ef 500 -eu 1.0 -el 0.5 -ea 0 -ep 0 -merge $chain_names || error_exit



for i in {1..5}
do
mkdir Simulation_$i
cp molecule* *.pdb topol.top Simulation_$i/
cd Simulation_$i
echo -e "\033[38;5;226mHold on, building system...\033[0m"
insane -u POPC:42.5 -u SAPE:32 -u PAPI:5 -u CHOL:15.5 -u PCER:5 -l POPC:52 -l SAPE:14 -l PAPI:19 -l CHOL:15 -d 10 -o system.gro -f ${cg_pdb} -pbc hexagonal -pr 0.01 -sol W -center -excl -1 2>&1 | tee -a topol.top || error_exit  #-orient -center

# Add other needed include topology statements to topol.top
sed -i 's|#include "martini.itp"|#include "/path_to_itp_files/martini_v3.0.0.itp"\n#include "/path_to_itp_files/martini_v3.0_ffbonded_alpha_v1.itp"\n#include "/path_to_itp_files/martini_v3.0.0_phospholipids_v1.itp"\n#include "/path_to_itp_files/SAPE.itp"\n#include "/path_to_itp_files/PAPI.itp"\n#include "/path_to_itp_files/martini_v3.0_CDLs.itp"\n#include "/path_to_itp_files/martini_v3.0_sterols_v1.0.itp"\n#include "/path_to_itp_files/martini_v3.0_ceramides_alpha_v1.itp"\n#include "/path_to_itp_files/martini_v3.0.0_solvents_v1.itp"\n#include "/path_to_itp_files/martini_v3.0.0_ions_v1.itp"|; s|\bProtein\b|Protein|g' topol.top

# Adding a physiological amount of ions (0.15 M NaCl)
echo -e "\033[38;5;226mHold on, adding ions...\033[0m"
gmx make_ndx -f system.gro -o neutral.ndx <<EOD
del 0-100
rW
q
EOD
gmx grompp -f /path_to_mdp_files/em.mdp -o neutral -c system.gro  -maxwarn 1 
gmx genion -s neutral -p topol.top -neutral -o system.gro -n neutral.ndx -pname NA -nname CL -conc 0.15 <<EOD
0
EOD

# EM
echo -e "\033[38;5;226mEnergy minimizing...\033[0m"
echo "${min_mdp}" > minimization.mdp
gmx grompp -p topol.top -f /path_to_mdp_files/minimization.mdp -c system.gro -o minimization.tpr -maxwarn 1
gmx mdrun -v -deffnm em -s minimization.tpr -nt $nt || error_exit

# Making an index file so groups can be coupled seperately
gmx make_ndx -f em.gro -o sys.ndx << EOD
del 0
del 1-100
rPOP*|rCHO*|rSAP*|rPAP*|rCDL*|rPCER
rW|rION
name 1 LIPID
name 2 SOL_ION
q
EOD

# Production run
echo -e "\033[38;5;226mStarting production run for ${pdb_code}...\033[0m" 
echo "${run_mdp}" > run.mdp
gmx grompp -f /path_to_mdp_files/5us-martini-2021.mdp -c em.gro -p topol.top -o md.tpr -n sys.ndx -maxwarn 1

cd ../
done