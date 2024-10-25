import MDAnalysis as mda
import sys

def extract_and_write_chain_names(pdb_file, output_file):
    # Load the PDB file using MDAnalysis
    u = mda.Universe(pdb_file)
    # Get the list of unique authentication codes (chain IDs)
    auth_codes = set(atom.segment.segid for atom in u.atoms)
    #return list(auth_codes)
    # Write the results to a text file
    with open(output_file, 'w') as file:
        file.write(",".join(auth_codes))

def find_and_write_chain_breaks(pdb_file, output_file):
    # Load the PDB file using MDAnalysis
    u = mda.Universe(pdb_file)
    # Initialize variables
    prev_residue_number = None
    prev_chain_id = None
    missing_residues = {}  # Dictionary to store missing residues for each chain
    # Iterate through atoms
    for atom in u.atoms:
        residue_number = atom.resnum
        chain_id = atom.segment.segid
        # Check for missing residues and chain breaks
        if prev_chain_id is not None:
            if residue_number != prev_residue_number + 1 or chain_id != prev_chain_id:
                # Chain break detected
                if chain_id not in missing_residues:
                    missing_residues[chain_id] = []
                missing_residues[chain_id].extend(
                    range(prev_residue_number + 1, residue_number)
                )
        # Update previous values
        prev_residue_number = residue_number
        prev_chain_id = chain_id
    # Write the results to a text file
    with open(output_file, 'w') as file:
        for chain_id, missing_residue_list in missing_residues.items():
            if missing_residue_list:
                file.write(f"Chain {chain_id} {missing_residue_list}\n")

pdb_file_path = sys.argv[1]+'.pdb'
extract_and_write_chain_names(pdb_file_path, 'chain_names.txt')
find_and_write_chain_breaks(pdb_file_path, 'chain_breaks.txt')

