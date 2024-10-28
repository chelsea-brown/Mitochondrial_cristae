import sys,os,re
import MDAnalysis as mda
import subprocess
from subprocess import run
import warnings 


warnings.filterwarnings("ignore")

###INPUT####
## Need to remember to activate the bentopy_v virtual environment to run this in
cutoff = 0.03

###Functions###
def get_residue_number(bentopy_output_line):
    #numbers = re.findall(r'\d+\. \d+|\d+', bentopy_output_line)
    clean_text = re.sub(r'[()]', '', bentopy_output_line)
    numbers=[]
    for word in clean_text.split():
        if word.isdigit():
            numbers.append(int(word))
    residue_to_remove = numbers[2]
    print(f'Removing {residue_to_remove}')
    return residue_to_remove

def run_bentopy(structure):
    overlap = run(f"bentopy-check -e --cutoff {cutoff} {structure}", capture_output=True, shell=True, text=True)
    return overlap.stdout.splitlines()[-1]

def remove_residue(structure, residue_number):
    u = mda.Universe(structure)
    new_structure = u.select_atoms(f'not (resid {residue_number})')
    residue_name = u.select_atoms(f'(resid {residue_number})')
    for i, res in enumerate(new_structure.residues, start=1):
        res.resid = i
    print(residue_name.residues.resnames[0])
    open('Residues_removed.txt','a+').write(f'{residue_number}\t{residue_name.residues.resnames[0]}\n')
    new_structure.atoms.write('system_new.pdb')
    return new_structure



def main():
    try:
        os.remove('Residues_removed.txt')
    except FileNotFoundError:
        pass
    first_residue = run_bentopy(sys.argv[1])
    residue_to_remove = get_residue_number(first_residue)
    new_structure = remove_residue(sys.argv[1],residue_to_remove)
    while True:
        try:
            residue = run_bentopy('system_new.pdb')
            residue_to_remove = get_residue_number(residue)
            new_structure = remove_residue('system_new.pdb',residue_to_remove)
        except IndexError:
            print('Could have finished?')
            break

if __name__ == "__main__":
    main()