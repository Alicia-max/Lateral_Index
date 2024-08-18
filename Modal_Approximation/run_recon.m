function run_recon(file_gii,file_eigen, dir_mat, hemisphere, num_modes, stepwise, matlab_dir, step_)
    % Function to compute reconstruct a spatial map using geoemtric eigenmode
    %
    % Input:
    % _______
    % file_gii [str]- spatial pattern to reconstruct (.gii)
    % file_eigen [str]- extracted eigenmodes(.txt)
    % dir_mat [str] - directory to save the results
    % hemisphere [str] - hemipshere to plot ('rh' or 'lh')
    % num_modes [int] - number of extracted mode
    % stepwise [bool] - indicates if stepwise reconstruction or not
    % matlab_dir [str] - directory with help functions
    % step_ [int] - number of step
    disp("START");
    
    % TODO : Default value
    addpath(genpath(matlab_dir));
    
    % Spatial brain pattern loading (to reconstruct)
    activity_map = gifti(file_gii).cdata;
    % Remove Nan and Normalized
    non_nan_indices = (find(~isnan(activity_map(:,1))));
    medial_wall = find(isnan(activity_map(:,1)));
    data_to_reconstruct = activity_map(non_nan_indices,:);
    data_to_reconstruct=data_to_reconstruct./vecnorm(data_to_reconstruct);
    
    % Eigenmodes loading 
     eigenmodes =  dlmread(file_eigen);
     eigenmodes = eigenmodes(non_nan_indices,:);

     disp("DATA LOADED AND PRE-PRO"); 
     disp("RECONSTRUCTION");
    
    %Reconstruction (with all modes)
     [recon_beta_final,reconstructions,corr_vextex_all_modes] = all_reconstruction(data_to_reconstruct, eigenmodes);
     
    %Reconstruction (step by step)
     if(stepwise)
      disp("STEPWISE RECONSTRUCTION");
        
         [recon_beta_step, recon_corr] = step_reconstruction(data_to_reconstruct,eigenmodes, num_modes, step_); 
         save(sprintf("%s/%s_corr_step_mode_%i_normed.mat",dir_mat, hemisphere, num_modes),"recon_corr" );
     end 
     
     disp("SAVING");

     save(sprintf("%s/%s_betas_all_mode_%i_normed.mat",dir_mat,hemisphere,num_modes), "recon_beta_final", "-v7.3"); 
     save(sprintf("%s/%s_corr_all_mode_%i_normed.mat",dir_mat, hemisphere, num_modes), "corr_vextex_all_modes");
     
     % for Permutation
     save(sprintf("%s/%s_data_%i_normed.mat",dir_mat, hemisphere, num_modes), "data_to_reconstruct");
     save(sprintf("%s/%s_eigen_wo_nan_%i.mat",dir_mat, hemisphere, num_modes), "eigenmodes", "-v7.3");
     
     % Only for plot
     save(sprintf("%s/%s_medial_wall_%i.mat",dir_mat, hemisphere, num_modes), "medial_wall");
     save(sprintf("%s/%s_data_%i_reconstructions.mat",dir_mat, hemisphere, num_modes), "reconstructions")
     
         
end

function[recon_beta_final,reconstructions,corr_vextex_all_modes] = all_reconstruction(data_to_reconstruct,eigenmodes)
    recon_beta_final= calc_eigendecomposition(data_to_reconstruct, eigenmodes, 'matrix');
    reconstructions = eigenmodes*recon_beta_final; 
    corr_vextex_all_modes = diag(corr(data_to_reconstruct, reconstructions, "rows", "pairwise"));
end

function [recon_beta_step, recon_corr] = step_reconstruction(data_to_reconstruct, eigenmodes, num_modes, step_)
    
    % Perform reconstruction process
    T = size(data_to_reconstruct, 2);
    recon_beta_step = zeros(num_modes, T, num_modes/step_);
    recon_corr= zeros(T, num_modes/step_);
    
    % Compute reconstruction and acc using steps_ more modes at the time
    start_value=1;
    indices = start_value:step_:num_modes; 
    num_iterations = length(indices); 

    for i = 1:num_iterations
        mode = indices(i); 
        basis = eigenmodes(:,1:mode);
        recon_beta_step(1:mode,:,i) = calc_eigendecomposition(data_to_reconstruct, basis, 'matrix');
        reconstructions = basis*recon_beta_step(1:mode,:,i); 
        recon_corr(:,i) = diag(corr(data_to_reconstruct, reconstructions, "rows", "pairwise"));
    end
end