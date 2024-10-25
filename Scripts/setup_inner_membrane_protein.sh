#!/bin/bash

# Help function 
function help {
  echo "" 
#  echo -e "\033[38;5;226mAutomated Workflow for Outer Mitochondrial Membrane Simulation Modeling\033[0m"   
#  echo -e "\033[38;5;208mTitle: mainone.sh (for 'MArtinize-INsanify Outer-membraNE...'\033[0m"
#  echo -e "\033[38;5;34mAuthor: Delinyah C. Koning (last edited on March 16th, 2023)\033[0m"
#  echo -e "\033[38;5;34mAuthor: Delinyah C. Koning (last edited on March 16th, 2023)\033[0m"
#  echo -e "\033[38;5;34mUniversity of Groningen, FSE Faculty, GBB Institute, Molecular Dynamics Group (2023)\033[0m" 
#  echo ""
  echo "Usage: ./mainone.sh <pdb_code> [-nt <number_of_threads>]"
  echo "Don't forget to give permission to execute this file (chmod +x mainone.sh)."
  echo ""
  echo -e "\033[38;5;226mWithout editing the parameter files, the run is executed as follows:\033[0m"
  echo "Martinize coarse-grains protein"
  echo "Insane builds a charge-neutralized (NaCl) coarse-grained system with -excl set to -1 so that water can be placed everywhere (e.g. also inside barrel proteins)."
  echo "1000-step EM"
  echo "1500ps NVT (dt 0.03, nstxout 20, v-rescale coupling system)"
  echo "1500ps NPT (dt 0.03, nstxout 20, parrinello-rahman pressure coupling, semiisotropic)"
  echo "by default a 100ns production run (dt 0.03, nstep 3333333, nstxout 1000 >>> 3333 frames total, 30ps per frame)" 
  echo ""
  echo "Notes:"  
  echo "The pdb-code must be specified without .pdb extension (just the 4-letter code)."
  echo "The pdb-file is the only file that should be present in the working directory (+ this .sh script). Fetching structures from PDB or OPM will be available in the future."
  echo "During running, the pdb-input in the initial working directory will be moved (not copied) to a folder that is named after the pdb-code."
  echo "During the script, the new directory will become the new working directory; this makes sure that all output is collected."
  echo "The topol.top file after coarse-graining is adapted by appending it with the stderr output after execution of the insane command. Do NOT change."
  echo ""
  echo "Flag options:"
  echo "  -h, --help: Show this help message and exit."
  echo "  -nt: Number of threads to use in GROMACS simulations (default is 1)."
  echo ""
  echo "Prerequisites:"
  echo "  - .mdp files are located in the home directory (specify path as needed)."
  echo "  - The PDB files to be used MUST be downloaded in the working directory."
  echo "  - The DSSP library is assumed to be located in /usr/bin/dssp. If not, adapt script."
  echo "  - Insane executable, Martinate.py, and all required .itp files are in the home directory. They will not be copied to the working directory."
  echo ""
}

# Error function
function error_exit {
  echo -e "\033[38;5;196mOh no, not as easy as you think..... Something is wrong here...\033[0m" >&2
  exit 1
}

# Parse command line arguments
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
  help
  exit 0
fi

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
#cg_top=${pdb_code}-cg.top

# Check if PDB code is provided as an argument
if [ -z "$1" ]
  then
    echo "Please provide a PDB code as an argument"
    exit 1
fi

#cp ${pdb_code}-orignal.pdb ${pdb_code}.pdb

##Cleaning up the pdb file
grep -v DU ${pdb_code}.pdb  > ${pdb_code}_clean.pdb
#rm -r *.txt chain*


##This is new to try and get chain breaks and then fix them
python3 ~/Projects/Base_files/mdanalysis_chains.py ${pdb_code}
# Extract chain names into a list
#chain_list=($(grep -oP 'Chain\s+\K\S+' "chain_breaks.txt"))
# Print the list of chain names
#echo "Fixing the following chains:"
#for chain in "${chain_list[@]}"; do
#    echo "$chain"
#    bash /home/chelsea/Projects/Base_files/fix_protein_loops_complex.sh $chain $pdb_code
#done


##Fixing any missing atoms in the file
#python3 ~/Projects/Base_files/Pras-Server_fix_protein.py ${pdb_code}_clean.pdb 
#mv out.pdb ${pdb_code}_fixed.pdb 

# Coarse-graining
#echo -e "\033[38;5;226mCoarse graining your system...\033[0m"
chain_names="`head -1 chain_names.txt`"
echo "The list for the chains is ${chain_names}"

martinize2 -f ${pdb_code}_clean.pdb -o topol.top -x ${cg_pdb} -ff martini3001 -maxwarn 10000 -elastic -ef 500 -eu 1.0 -el 0.5 -ea 0 -ep 0  -merge $chain_names || error_exit

# Make sure that when the following command edits topol.top no new stuff is added to existing lines
#echo ';' >> topol.top

#This is to clean up itp files so errors won't occur
#for i in molecule*.itp; do
#	grep '^;' "$i" > "$i"information.txt
#	sed -i '/;/d' "$i"
#done


for i in {1..5}
do
mkdir Simulation_$i
cp molecule* *.pdb topol.top Simulation_$i/
cd Simulation_$i
# Building initial configuration + writing text file with stderr output
echo -e "\033[38;5;226mHold on, building system...\033[0m"
insane -u POPC:29 -u SAPE:36 -u PAPI:6 -u POPS:3 -u CDL2:26 -l POPC:58 -l SAPE:37 -l PAPI:5 -l POPS:3 -l CDL2:11 -au 0.83 -a 0.83 -d 10 -o system.gro -f ${cg_pdb}  -pbc hexagonal  -sol W -excl -1 2>&1 | tee -a topol.top || error_exit  #-orient -center

# Add other needed include topology statements to topol.top
sed -i 's|#include "martini.itp"|#include "/home/chelsea/Projects/Base_files/martini_v3.0.0.itp"\n#include "/home/chelsea/Projects/Base_files/martini_v3.0_ffbonded_alpha_v1.itp"\n#include "/home/chelsea/Projects/Base_files/martini_v3.0.0_phospholipids_v1.itp"\n#include "/home/chelsea/Projects/Base_files/SAPE.itp"\n#include "/home/chelsea/Projects/Base_files/PAPI.itp"\n#include "/home/chelsea/Projects/Base_files/martini_v3.0_CDLs.itp"\n#include "/home/chelsea/Projects/Base_files/martini_v3.0.0_solvents_v1.itp"\n#include "/home/chelsea/Projects/Base_files/martini_v3.0.0_ions_v1.itp"|; s|\bProtein\b|Protein|g' topol.top

# Adding a physiological amount of ions (0.15 M NaCl)
echo -e "\033[38;5;226mHold on, adding ions...\033[0m"
gmx make_ndx -f system.gro -o neutral.ndx <<EOD
del 0-100
rW
q
EOD
gmx grompp -f /home/chelsea/Projects/Base_files/mdp_files/em.mdp -o neutral -c system.gro  -maxwarn 1 
gmx genion -s neutral -p topol.top -neutral -o system.gro -n neutral.ndx -pname NA -nname CL -conc 0.15 <<EOD
0
EOD

# EM
echo -e "\033[38;5;226mEnergy minimizing...\033[0m"
echo "${min_mdp}" > minimization.mdp
gmx grompp -p topol.top -f /home/chelsea/Projects/Base_files/mdp_files/minimization.mdp -c system.gro -o minimization.tpr -maxwarn 1
gmx mdrun -v -deffnm em -s minimization.tpr -nt $nt || error_exit

# Making an index file so groups can be coupled seperately
gmx make_ndx -f em.gro -o sys.ndx << EOD
del 0
del 1-100
rPOP*|rCHO*|rSAP*|rPAP*|rCDL*
rW|rION
name 1 LIPID
name 2 SOL_ION
q
EOD

# # NVT
# echo -e "\033[38;5;226mNVT equilibration...\033[0m"
# echo "${nvt_mdp}" > nvt.mdp
# gmx grompp -p topol.top -f /home/chelsea/Projects/Base_files/mdp_files/nvt.mdp -c em.gro -o nvt.tpr -n sys.ndx -maxwarn 1
# gmx mdrun -v -deffnm nvt -s nvt.tpr -nt $nt || error_exit

# # NPT
# echo -e "\033[38;5;226mNPT equilibration...\033[0m"
# echo "${npt_mdp}" > npt.mdp
# gmx grompp -f /home/chelsea/Projects/Base_files/mdp_files/npt.mdp -c nvt.gro -p topol.top -o npt.tpr -n sys.ndx -maxwarn 1
# gmx mdrun -v -deffnm npt -s npt.tpr -nt $nt || error_exit

# Production run
echo -e "\033[38;5;226mStarting production run for ${pdb_code}...\033[0m" 
echo "${run_mdp}" > run.mdp
gmx grompp -f /home/chelsea/Projects/Base_files/mdp_files/1us-martini-2021.mdp -c em.gro -p topol.top -o md.tpr -n sys.ndx -maxwarn 1
#gmx mdrun -v -deffnm md -s md.tpr -nt $nt || error_exit

cd ../
done
