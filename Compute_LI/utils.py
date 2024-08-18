import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
from scipy.io import loadmat
import os
import mat73
from scipy.interpolate import interp1d

####################################### 
##        EigenValue Distribution    ##
#######################################

def read_eigenval(file_txt, modes):
    eigenval=np.zeros(modes)
    
    with open(file_txt, 'r') as file:
        for idx,line in enumerate(file):
            eigenval[idx]=(float(line.strip()))
    return eigenval

def read_eigen(directory, subject, modes, txt_file):
    
    eigen_val_lh=np.zeros([len(subject), modes])
    eigen_val_rh=np.zeros([len(subject), modes])
    for idx,subject in enumerate(subject): 

        eigen_val_lh[idx,:]=(read_eigenval(f'{directory}/{subject}/{modes}_modes/white-lh_{txt_file}', modes).flatten())
        eigen_val_rh[idx,:]=(read_eigenval(f'{directory}/{subject}/{modes}_modes/white-rh_{txt_file}', modes).flatten())
    return eigen_val_lh, eigen_val_rh
def plot_eigenval(ylim, xlim, eigen_val_lh,eigen_val_rh, savedname ):
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(7, 3))

    # Common settings
    settings = {
        "xlabel": "Modes",
        "ylabel": "Eigen Values",
        "ylim": (0, ylim),
        "xlim": (0, xlim)
    }

    # Plot data and apply settings
    for ax, title, data in zip([ax1, ax2], ["Left Hemisphere", "Right Hemisphere"], [eigen_val_lh, eigen_val_rh]):
        palette = sns.color_palette("crest", data.shape[1])
        for i, line in enumerate(data.T):
            ax.plot(line, color=palette[i])
        ax.set(**settings)
        ax.set_title(title)

    plt.tight_layout()
    sns.despine()
    plt.savefig(savedname)
    plt.show()
    
####################################### 
##         Accuracy Analysis         ##
#######################################

def merged_hemi_corr(df_right, df_left, left_eigen, right_eigen): 
    df1_copy = df_right.copy()
    df2_copy=df_left.copy()
    
    df1_copy.loc[:, 'Hemisphere'] = 'right'
    df2_copy.loc[:, 'Hemisphere'] = 'left'
    df1_copy.loc[:, 'eigen_value'] = right_eigen
    df2_copy.loc[:, 'eigen_value'] = left_eigen
   
    # Transformation des DataFrames en format long
    df1_long = pd.melt(df1_copy, id_vars=['Hemisphere', 'eigen_value', ], var_name=['Map'], value_name='accuracy')
    df2_long = pd.melt(df2_copy, id_vars=['Hemisphere', 'eigen_value'], var_name=['Map'], value_name='accuracy')

    # Concatenation des deux DataFrames
    df_long = pd.concat([df1_long, df2_long])
    return df_long

def dark_color(rgb_color, factor):

    r, g, b = rgb_color
    darkened_r = float(r *factor)
    darkened_g = float(g * factor)
    darkened_b = float(b * factor)
    return (darkened_r, darkened_g, darkened_b)

def get_corr_df(subjects, directory,modes,indices, hemispheres, mat_dir, name_col,norma_txt,inter) : 
    all_subjects_data=[]
    lambda_inter=[]
    for subject in subjects :
        eigen_value_normalized={}
        correlations={}
        last_cor={}

        for h in hemispheres : 

            correlations[h] = loadmat(f'{directory}/{subject}/{mat_dir}/{h}_corr_step_mode_{modes}_normed.mat')['recon_corr']
            last_cor[h]=  loadmat(f'{directory}/{subject}/{mat_dir}/{h}_corr_all_mode_{modes}_normed.mat')['corr_vextex_all_modes']
            correlations[h]= np.append(correlations[h], last_cor[h], axis=1)
            eigenval=[]

            with open(f'{directory}/{subject}/{modes}_modes/white-{h}_{norma_txt}', 'r') as file:
                for line in file:
                    eigenval.append(float(line.strip()))
            eigen_value_normalized[h] = eigenval

        lambda_inter.append(min(np.array(eigen_value_normalized['rh'])[inter], np.array(eigen_value_normalized['lh'])[inter]))
        left_corr=pd.DataFrame(correlations['rh'].T, columns = name_col)
        right_corr=pd.DataFrame(correlations['lh'].T,columns=name_col)
        right_eigen=np.array(eigen_value_normalized['rh'])[indices]
        left_eigen=np.array(eigen_value_normalized['lh'])[indices]
        df_corr=merged_hemi_corr(right_corr,left_corr,left_eigen, right_eigen)
        df_corr['accuracy']=abs(df_corr['accuracy'])
        df_corr['subject']=[subject]*len(df_corr)
        all_subjects_data.append(df_corr)

    main_df_corr = pd.concat(all_subjects_data, ignore_index=True)
    return main_df_corr,min(lambda_inter)

def interpolations(common_x, df):
    interpolated_data = {'eigen_value': common_x}
    
    for subject in df['subject'].unique():
        subject_df = df[df['subject'] == subject]
        # Interpolate the subject's accuracies to the common x-values
        interp_func = interp1d(subject_df['eigen_value'], subject_df['accuracy'], kind='linear', fill_value="extrapolate")
        interpolated_data[subject] = interp_func(common_x)
        
    return interpolated_data

def plot_all_map_sub_interpo(df, bound, bound_inter, hemisphere, title, color,ax=None, display=True, y_bound=None):
    if ax is None:
        fig, ax = plt.subplots(figsize=(5, 3))
    if y_bound is None : 
        y_bound=bound+1000
        
    
    common_x = np.linspace(0, bound, 11)
    interpolated_data = interpolations(common_x, df)
    
    # Calculate the mean and standard deviation of accuracy across subjects at each common x-value
    interpolated_accuracies = pd.DataFrame(interpolated_data)
    interpolated_accuracies['mean_accuracy'] = interpolated_accuracies.drop(columns='eigen_value').mean(axis=1)
    interpolated_accuracies['std_accuracy'] = interpolated_accuracies.drop(columns='eigen_value').std(axis=1)
    
    # plot
    ax.errorbar(interpolated_accuracies['eigen_value'], 
                interpolated_accuracies['mean_accuracy'], 
                yerr=interpolated_accuracies['std_accuracy'], 
                fmt='-o', 
                color=color, 
                label=hemisphere, 
                linewidth=2, 
                capsize=5)
    
    mean_acc = interpolated_accuracies['mean_accuracy'].values[-1]
    mean_std=interpolated_accuracies['std_accuracy'].values[-1]
    print(f"Mean accuracy (interpolated): {mean_acc}")
    print(f"Std accuracy (interpolated): {mean_std}")
    if(display):
        ax.axhline(y=mean_acc, color='black', linestyle='--', linewidth=1)
        
    ax.axvline(x=bound, color='lightgrey', linestyle='--', linewidth=1)
    ax.axvline(x=bound_inter, color='lightgrey', linestyle='--', linewidth=1)
    
    ax.legend(loc='lower right', bbox_to_anchor=(1, 0), fontsize=16)
    ax.set_ylim(0, 1)
    #ax.set_xticks(np.append(ax.get_xticks(), bound_inter))
    ax.set_xlim(0, y_bound)
    ax.set_xlabel('Eigen Values', fontsize=16)
    ax.set_ylabel('Accuracy', fontsize=16)
    ax.set_title(title)
    ax.tick_params(axis='both', which='major', labelsize=16)
    sns.despine()

####################################### 
## Modal Power and Modes Distribution##
#######################################

def get_grouped_betas_energy (betas, indexes):
    grouped_energy = np.zeros((len(indexes), np.shape(betas)[1]))
    num_mode=[]
    energy_betas=betas.abs() ** 2
    column_sums = energy_betas.sum(axis=0)
    norm_energy=energy_betas.div(column_sums, axis=1)
    
    for idx, index_list in enumerate(indexes):
        num_mode.append(len(index_list))
        if len(index_list) != 0:
            grouped_energy[idx, :] = norm_energy.loc[index_list].sum(axis=0) 
            
    return grouped_energy, num_mode, norm_energy

def get_energy(directory, hemi, modes,map_):

    indexes= loadmat(f'{directory}/{hemi}_grouped_values_diff.mat')['Y2'].flatten()
    indexes_list = [list(arr.flatten() - 1) if arr.size > 0 else [] for arr in indexes]
    if(len(map_)>1):
        betas_ = mat73.loadmat(f'{directory}/{hemi}_betas_all_mode_{modes}_normed.mat')['recon_beta_final'][:,map_]
    else : 
        betas_ = mat73.loadmat(f'{directory}/{hemi}_betas_all_mode_{modes}_normed.mat')['recon_beta_final']
        
    grouped_betas_energy, num_mode, norm_energy=get_grouped_betas_energy(pd.DataFrame(betas_), indexes_list)  

    return grouped_betas_energy, num_mode,norm_energy

def reshape(array):
    n, m, p = array.shape
    merged_array = array.transpose(1, 0, 2).reshape(m, n * p)
    return merged_array

def modal_pw_mode_dist(subjects, modes, hemi, data_dir, num_group, map_):

    grouped_energy_all=np.zeros([len(subjects), num_group, len(map_)])
    modes_number=np.zeros([len(subjects), num_group])
    norm_energy=np.zeros([len(subjects),modes,len(map_)])
    for idx,subject in enumerate(subjects): 
        directory = f"{data_dir}/{subject}/{modes}_modes"
        x, y, z = get_energy(directory,hemi, modes, map_)
        grouped_energy_all[idx,:]=x
        modes_number[idx,:]=y
        norm_energy[idx,:]=z

    return reshape(grouped_energy_all), modes_number.T, reshape(norm_energy)

def get_averaged_plot(df, hemisphere): 
    means = df.mean(axis=1)
    stds = df.std(axis=1)

 
    data = pd.DataFrame({
        'Row': range(len(means)),
        'Mean': means,
        'STD': stds,
        'Hemisphere': hemisphere
    })
    
    return data

def plot_avg_dist_dual_y_axes(df_energy_l, df_energy_r, df_modes_l, df_modes_r,
                              ylabel1, ylabel2, title, dir_saved,
                              ylim1=None , ylim2=None):

    bar_width = 0.2
    indices = range(len(df_energy_l))
    fig, ax1 = plt.subplots(figsize=(14, 6))

    data_energy_l = get_averaged_plot(df_energy_l, 'left')
    ax1.bar([i - 1.5 * bar_width for i in indices], data_energy_l['Mean'], 
            width=bar_width, color='silver', yerr=data_energy_l['STD'], capsize=5, label='Normalized Power - Left Hemisphere', alpha=0.7)

    data_energy_r = get_averaged_plot(df_energy_r, 'right')
    ax1.bar([i - 0.5 * bar_width for i in indices], data_energy_r['Mean'], 
            width=bar_width, color='slategrey', yerr=data_energy_r['STD'], capsize=5, label='Normalized Power - Right Hemisphere', alpha=0.7)

    # Set labels and limits for the first y-axis (Normalized Energy)
    
    ax1.set_ylabel(ylabel1, fontsize=16)
    ax1.tick_params(axis='both', which='major', labelsize=16)
    ax1.tick_params(axis='y')
    if ylim1:
        ax1.set_ylim(ylim1)

    # Create a secondary y-axis for the number of modes
    ax2 = ax1.twinx()

    # Plot bars for the number of modes (left hemisphere) on the second y-axis
    data_modes_l = get_averaged_plot(df_modes_l, 'left')
    ax2.bar([i + 0.5 * bar_width for i in indices], data_modes_l['Mean'], 
            width=bar_width, color='cornflowerblue', yerr=data_modes_l['STD'], capsize=5, label='Number of Modes - Left Hemisphere', alpha=0.7)

    # Plot bars for the number of modes (right hemisphere) on the second y-axis
    data_modes_r = get_averaged_plot(df_modes_r, 'right')
    ax2.bar([i + 1.5 * bar_width for i in indices], data_modes_r['Mean'], 
            width=bar_width, color='royalblue', yerr=data_modes_r['STD'], capsize=5, label='Number of Modes - Right Hemisphere', alpha=0.7)
    ax2.set_ylabel(ylabel2, fontsize=16)
    
    ax2.tick_params(axis='both', which='major', labelsize=16)
    ax2.tick_params(axis='y')

    if ylim2:
        ax2.set_ylim(ylim2)

    plt.title(title, fontsize=18)
    plt.tight_layout()
    ax1.set_xticks(indices)
    ax1.set_xticklabels([f'Sub-band {i+1}' for i in indices], rotation=90, fontsize=16)
    ax1.legend(loc='upper left', bbox_to_anchor=(1.1, 1), fontsize=16)
    ax2.legend(loc='upper left', bbox_to_anchor=(1.1, 0.8), fontsize=16)



    # Save and show plot
    plt.savefig(dir_saved, bbox_inches='tight')
    plt.show()