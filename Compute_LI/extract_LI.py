from scipy.io import loadmat, savemat
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import os
import argparse
import time
import json
import mat73

def get_grouped_betas (betas, indexes):
    """
    Function to group betas according the defined sub-band.

    Inputs
    -------
        - betas [df] : weights  fron the modal approximations
        - indexes [list] : sub-band indexes

    Outputs
    -------
        - grouped_betas [df] : grouped weights
    """

    betas_abs=betas.abs()
    grouped_betas = np.zeros((len(indexes), np.shape(betas)[1]))
    for idx, index_list in enumerate(indexes):     
        if len(index_list) != 0:
            grouped_betas[idx, :] = betas_abs.loc[index_list].sum(axis=0)  
    return grouped_betas

def get_p_val(permu_mat, observed_vector, seuil):
    """
    Function to compute LI p-values

    Inputs
    -------
        - permu_mat [arr] : matrix with permutated LI (n_sub_band x n_permu)
        - observed_vector [arr] : vector with the observe LI (n_sub_band)
        - seuil [float] : significance threshold

    Outputs
    -------
        - sp [arr] : number of permu_mat > observed_vector
        - sprob [arr] : p-values
        - signif_LI [arr] : index of signficant LI 
    """
    n_perm = permu_mat.shape[1]
    seuil = seuil/permu_mat.shape[0]
    permu_mat=np.hstack((permu_mat, np.transpose([observed_vector])))
    sp = np.sum(np.abs(permu_mat) > np.abs(observed_vector[:, None]), axis=1)
    sprob = sp / (n_perm-1)
    signif_LI=np.where(sprob<seuil)[0]
    return sp, sprob, signif_LI

def get_LI(directory, hemispheres, modes, nperm, permu_dir, map_):
    """
    Function to compute LI and load permuted LI

    Inputs
    -------
        - directory [str] : directory with saved weights from modal modelisation
        - hemispheres [str] : hemipshere of interest ('lh' or 'rh')
        - modes [int] : number of extracted modes
        - nperm [int] : number of permuation
        - permu_dir [str] : directory with permutated data output
        - map_ [list] : spatial map of intest

    Outputs
    -------
        - LI [arr] : compuated LI (1 x n_sub_band)
        - permu_LI [arr] : (nperm xn_sub_band)
    """
    grouped_betas={}
    permu_LI={}
    for h in hemispheres: 
        #Sub-band loading
        indexes= loadmat(f'{directory}/{h}_grouped_values_diff.mat')['Y2'].flatten()
        indexes_list = [list(arr.flatten() - 1) if arr.size > 0 else [] for arr in indexes]

        # if multiple map, only load the intersting ones
        if(len(map_)>1):
            betas_ = mat73.loadmat(f'{directory}/{h}_betas_all_mode_{modes}_normed.mat')['recon_beta_final'][:,map_]
        else :
            betas_ = mat73.loadmat(f'{directory}/{h}_betas_all_mode_{modes}_normed.mat')['recon_beta_final']

        # Get Permuated LI
        grouped_betas[h]=get_grouped_betas(pd.DataFrame(betas_), indexes_list)  
        permu_LI[h]= loadmat(f'{permu_dir}/{h}_beta_permu_{modes}_{nperm}_grouped.mat')['beta_permutation']

    # LI computation
    LI=(grouped_betas['rh']- grouped_betas['lh'])
    return LI , permu_LI

def significant_LIs(LI, permu_LI, color, seuil=0.05, plot_directory=None):
    """
    Function to compute LI and load permuted LI

    Inputs
    -------
        - directory [str] : directory with saved weights from modal modelisation
        - hemispheres [str] : hemipshere of interest ('lh' or 'rh')
        - modes [int] : number of extracted modes
        - nperm [int] : number of permuation
        - permu_dir [str] : directory with permutated data output
        - map_ [list] : spatial map of intest

    Outputs
    -------
        - LI [arr] : compuated LI (1 x n_sub_band)
        - permu_LI [arr] : (nperm xn_sub_band)
    """

    n_map = LI.shape[1]
    significant_LIs = []
    for map_ in range(n_map):
        sub_permu_rh = permu_LI['rh'][:, map_, :]
        sub_permu_lh = permu_LI['lh'][:, map_, :]
        LI_matrix = (sub_permu_rh - sub_permu_lh)
        sp, sprob, signif_LI = get_p_val(LI_matrix, LI[:,map_], seuil)
        if(plot_directory):
            plot_sig(LI[:,map_],color,  light_color(color, 0.7),signif_LI, map_, plot_directory, f"Map_{map_}")
        significant_LIs.append(signif_LI) 
    return significant_LIs

def light_color(rgb_color, factor):

    r, g, b = rgb_color
    darkened_r = float(r *factor)
    darkened_g = float(g * factor)
    darkened_b = float(b * factor)
    return (darkened_r, darkened_g, darkened_b)

def modify_color(c, index, col ) : 
    for i in index : 
        c[i] = col
        
def plot_sig(array_AI, color1, color2, selected_indexes, map_, out_directory, name):
    c = [color1] * len(array_AI)
    modify_color(c, selected_indexes, color2)
    
    plt.figure(figsize=(10, 6))
    plt.bar(range(len(array_AI)), array_AI, color=c)
    plt.title(f'Bar Plot for SSBCAPS {map_+1} (sig)')
    plt.xlabel('Sub-Bands', fontsize=16)
    plt.ylabel('Laterality Index', fontsize=16)
    plt.ylim([-0.09, 0.09])
    ticks = np.arange(0, len(array_AI), step=1)
    labels = (ticks + 1).tolist()
    plt.xticks(ticks=ticks, labels=labels, rotation=45)
    plt.tight_layout()
    sns.despine()
    plt.savefig(f"{out_directory}/{name}.png")
    plt.close()

def get_final_dataset_Tau(LI,significant_LIs,subject): 

    sub_vec = np.zeros((np.shape(significant_LIs)[1], 3), dtype=object)
    sig_LI = LI[significant_LIs, 0]
    sub_vec[:, 0] = [subject] * len(sig_LI)
    sub_vec[:, 1] = sig_LI
    sub_vec[:, 2] = significant_LIs[0]+1 #Because we want 1-20 and not 0-19
   
    return sub_vec

    
    
def get_final_dataset_SSBCAP(names_nw, map_names, LI,significant_LIs,subject):
    all_sub_vecs = []

    for idx, map_name in enumerate(map_names):
        sub_vec = np.zeros((len(significant_LIs[idx]), 5), dtype=object)
        nw = names_nw[map_name].values[0]
        sig_LI = LI[significant_LIs[idx], idx]
        # Populate sub_vec with values
        sub_vec[:, 0] = [subject] * len(sig_LI)
        sub_vec[:, 1] = [nw] * len(sig_LI)
        sub_vec[:, 2] = [map_name] * len(sig_LI)  
        sub_vec[:, 3] = sig_LI
        sub_vec[:, 4] = significant_LIs[idx]+1 #Because we want 1-20 and not 0-19
        all_sub_vecs.append(sub_vec)
        
    final_array = np.concatenate(all_sub_vecs)
    return  final_array

def main(config_path):
    
    with open(config_path, 'r') as config_file:
        config = json.load(config_file)
    
    subjects = config['subjects']
    modes = config['modes']
    n_perm = config['n_perm']
    permu_dir= config['permu_dir']
    hemipsheres=config['hemispheres']
    names_nw_file=config['names_nw_file']
    data_dir=config['data_dir']
    output_file=config['output_file']  
    seuil=config['seuil']
    map_=config['map']
  
    tmp=[]
    if(names_nw_file != "None"):
        names_nw = pd.read_csv(names_nw_file,sep= ",", header=None)
        #only tight hemipshere 
        names_nw = names_nw.iloc[:, 200:400]
        names_nw.columns =[f'SSBCAP_{int(col) + 1}' for col in names_nw.columns] 
        map_names = [f"SSBCAP_{index+1}" for index in range(200, 400)]
        columns=['Subject', 'NW', 'Map_Name', 'LI_Amplitude', 'Significant_LI']
    else : 
        columns=['Subject',  'LI_Amplitude', 'Significant_LI']
        
    for subject in subjects : 
        directory = f"{data_dir}/{subject}/{modes}_modes"
        permu_dir_ = f"{data_dir}/{subject}/{permu_dir}"
        plot_dir=f"{data_dir}/{subject}/plots/LI"
        os.makedirs(plot_dir, exist_ok=True)
        
        LI, permu_LI=get_LI(directory,hemipsheres, modes, n_perm, permu_dir_, map_ )
    
        sig=significant_LIs(permu_dir_, LI,permu_LI, (0.86, 0.3712, 0.33999999999999997), seuil, plot_dir)
    
        
        if(names_nw_file != "None"):
            dataset=get_final_dataset_SSBCAP(names_nw, map_names, LI,sig,subject)
            
        else : 
            dataset=get_final_dataset_Tau(LI,sig,subject)
            
        tmp.append(dataset)

    final_array = np.concatenate(tmp, axis=0)   
    df = pd.DataFrame(final_array, columns=columns)
    df.to_pickle(output_file)
    
    
if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Run Asymmetric Index Calculation.')
    parser.add_argument('--config', type=str, required=True, help='Path to the configuration file.')
    args = parser.parse_args()
    start_time = time.time()
    main(args.config)
    end_time = time.time()
    execution_time = end_time - start_time
    print(f"Execution time: {execution_time} seconds")
