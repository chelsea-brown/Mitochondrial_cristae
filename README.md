# An integrative modelling approach to the mitochondrial cristae

The link to the pre-print can be found [here](https://www.biorxiv.org/content/10.1101/2024.09.23.613389v1) 

![A model of a mitochondrial cristae](Images/Starting_frame.png "Mitochondrial cristae model")

The repository here should contain the information to set up the same systems, with details on how to perform each step. In order to do this some other programmes are needed alongside gromacs and other more standard tools. 

## Required programmes
- [vermouth-martinize](https://github.com/marrink-lab/vermouth-martinize)
- [bentopy](https://zenodo.org/records/13818758)
- [TS2CG](https://github.com/marrink-lab/TS2CG)
- [insane](https://github.com/Tsjerk/Insane)

and for analysis
- [MDVoxelSegmentation](https://github.com/marrink-lab/MDVoxelSegmentation)


Below is a summary of the steps taken to assemble the system.

### Assembling the structures
Brief explination here

### High-throughput simulations 
High-throughput simulations should start from an orientated protein, with dummy atoms as the membrane to ensure correct placement. Then, either the `setup_inner_membrane_proteins.sh` or `setup_outer_membrane_proteins.sh` should be used to assemble small scale simulations for each membrane protein. While each step is found within these bash scripts, the key commands will be shown here.
> `martinize2 -f ${pdb_code}_clean.pdb -o topol.top -x ${cg_pdb} -ff martini3001 -maxwarn 10000 -elastic -ef 500 -eu 1.0 -el 0.5 -ea 0 -ep 0 -merge $chain_names || error_exit`

martinize converts atomistic (AT) protein structures to coarse-grained (CG) strucutres, and in this case the Martini 3 forcefield (`-ff martini3001`) using an elastic network between all chains present in the protein with a force-constant of 500 kJ/mol/nm<sup>2</sup>. When the protein is in a CG representation, this can then be embedded in a membrane.
For inner membrane proteins:
> `insane -u POPC:29 -u SAPE:36 -u PAPI:6 -u POPS:3 -u CDL2:26 -l POPC:58 -l SAPE:37 -l PAPI:5 -l POPS:3 -l CDL2:11 -au 0.83 -a 0.83 -d 10 -o system.gro -f ${cg_pdb} -pbc hexagonal -sol W -excl -1 2>&1 | tee -a topol.top`

And for outer membrane proteins
> `insane -u POPC:42.5 -u SAPE:32 -u PAPI:5 -u CHOL:15.5 -u PCER:5 -l POPC:52 -l SAPE:14 -l PAPI:19 -l CHOL:15 -d 10 -o system.gro -f ${cg_pdb} -pbc hexagonal -pr 0.01 -sol W -center -excl -1 2>&1 | tee -a topol.top`

