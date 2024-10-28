import MDAnalysis as mda
import numpy as np
import matplotlib.pyplot as plt
import sys

plt.rcParams.update({'font.size': 50})

def window(size):
    return np.ones(size)/float(size)

# Load the trajectory
universe = mda.Universe('nosol.gro', 'fit_atpase_nosol.xtc')

#here loading in information about the leaflets
clusters = 'clusters.npy'
betafactors = np.load(clusters)[0]
universe.add_TopologyAttr(mda.core.topologyattrs.Tempfactors(betafactors))

# Define the lipid types you want to count
lipid_types = ['POPC', 'SAPE', 'PAPI','POPS','CDL2']  

fig, ax = plt.subplots(3,2,figsize=(20, 30), sharex=True, sharey=True)
areas = { 'inner_ridge' : [0,325,1,2,0], 'inner_edge' : [325,600,1,1,0] , 'inner_flat' : [600,1000,1,0,0],'outer_ridge' : [0,325,2,2,1], 'outer_edge' : [325,600,2,1,1] , 'outer_flat' : [600,1000,2,0,1] }

for region in areas:
    lipid_counts = {lipid: [] for lipid in lipid_types}
    time_points = []
    # Iterate through the trajectory
    for ts in universe.trajectory:
        # Store the current time point
        time_points.append(ts.time)
        
        # Select lipids in the z region 30-60
        #lipids_in_region = universe.select_atoms(f'name {" ".join(lipid_types)} and (prop z >= 30 and prop z <= 60)')
        lipids_in_region = universe.select_atoms(f'resname {" ".join(lipid_types)} and (prop z >= {areas[region][0]} and prop z <= {areas[region][1]}) and (tempfactor {areas[region][2]})')
        #lipids_in_region = universe.select_atoms(f'resname {" ".join(lipid_types)}')# and (prop z <= 250)')
        
        # Count each lipid type
        for lipid in lipid_types:
            #count = len(lipids_in_region.select_atoms(f'resname {lipid}'))
            #lipid_counts[lipid].append(count)
            lipid_residues = lipids_in_region.select_atoms(f'resname {lipid}').residues
            count = len(lipid_residues)
            lipid_counts[lipid].append(count)

    # Convert time_points to a numpy array
    time_points = np.array(time_points)

    time_points = time_points / 1000000

    ## Atempt to convert into percentage, need to take into account sift at beginning

    for lipid in lipid_types:
        start_number = lipid_counts[lipid][2]
        #lipid_counts[lipid] = lipid_counts[lipid] / start_number
        lipid_counts[lipid] = np.array(lipid_counts[lipid])
        lipid_counts[lipid] = ((lipid_counts[lipid] - start_number)/start_number ) *100


    colors = {'POPC' : 'darkturquoise', 'SAPE' : 'limegreen', 'PAPI' : 'lightpink', 'POPS' : 'silver', 'CDL2' : 'darkorange', 'CHOL' : 'mauve', 'PCER' : 'white'}
    # Plot the results

    for lipid, counts in lipid_counts.items():
        ax[areas[region][3],areas[region][4]].plot(time_points, np.convolve(counts,window(10),'same'), label=lipid, color=colors[lipid],linewidth=5)
        ax[areas[region][3],areas[region][4]].plot(time_points, counts, color=colors[lipid],linewidth=3, alpha=0.4)

    #ax[areas[region][3],areas[region][4]].set_xlabel('Time ($\mu$s)')
    #plt.ylabel('Number of lipids')
    #ax[areas[region][3],areas[region][4]].set_ylabel('Percentage change')
    ax[areas[region][3],areas[region][4]].set_ylim(ymin=-60, ymax=60)
    ax[areas[region][3],areas[region][4]].set_xlim(xmin=0, xmax=max(time_points))

#ax[0,0].set_title('Inner',fontdict = {'fontsize' : 30})
#ax[0,0].set_ylabel('Flat',fontdict = {'fontsize' : 30})
#ax[1,0].set_ylabel('Edge',fontdict = {'fontsize' : 30})
#ax[2,0].set_ylabel('Ridge',fontdict = {'fontsize' : 30})
#ax[0,1].set_title('Outer',fontdict = {'fontsize' : 30})
xlim = (0,4)
plt.setp(ax, xlim=xlim)
plt.yticks(np.arange(-50,55,25))
plt.xticks(np.arange(0,5,1))
#ax[1,1].legend()
plt.savefig(f'lipid_count_all.png',dpi=300,format='png')