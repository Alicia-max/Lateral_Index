function plot_brains_tau(vtk_file, data_to_recon,eigen_file, reconstruction_file, medial_wall_file, data_output, hemisphere, num_modes, map_int, mode_interest, dir_func)
  
    % Function to visualize surface eigenmodes and reconstruction
    %
    % Parameters:
    % subject - Subject ID (numeric)
    % hemisphere - Hemisphere ('lh' or 'rh') (string)
    % num_modes - Number of modes (numeric)
    % mesh_interest - Mesh of interest ('white', etc.) (string)
    % map_int - Map integer (numeric)
      

   
    addpath(genpath(dir_func));

    % Display start message
    disp("begin");

    % =========================================================================
    % Load surface, eigenmodes and reconstruction                 
    % =========================================================================

    % Load surface file
    [vertices, faces] = read_vtk(vtk_file);
    surface.vertices = vertices';
    surface.faces = faces';
  
    % Load activity map - loaded.mat file (normalized one)
    %activity_map_normed_struct = load(data_to_recon);
    %activity_map_normed=activity_map_normed_struct.data_to_reconstruct;
    
    % Load eigenmodes
    %eigenmodes_load = load(eigen_file);
    %eigenmodes = eigenmodes_load.eigenmodes;

    medial_wall_struct=load(medial_wall_file);
    medial_wall=medial_wall_struct.medial_wall;
    
    % Load Reconstruction
    reconstruction_struct = load(reconstruction_file);
    reconstruction=reconstruction_struct.reconstructions;

    
    

    % =========================================================================
    % Visualize the signal to reconstruct                
    % =========================================================================

    surface_to_plot = surface;
    with_medial = 1; 
    %data_to_plot = activity_map_normed(:, map_int);
    %new_vec=get_new_vec(medial_wall, data_to_plot);  
    %fig = draw_surface_bluewhitered_gallery_dull(surface_to_plot, new_vec, hemisphere, medial_wall, with_medial);
    %fig.Name = 'Signal to reconstruct';
    %saveas(fig, sprintf('%s/Tau_PET_%s.png',data_output, hemisphere));
    %disp("Original Map plot done");

    % =========================================================================
    % Visualize multiple eigenmodes                       
    % =========================================================================

     %data_to_plot = eigenmodes(:, mode_interest);
     %new_matrix = get_new_mat(medial_wall, data_to_plot);
     %fig = draw_surface_bluewhitered_gallery_dull(surface_to_plot, new_matrix, hemisphere, medial_wall, with_medial);
     %fig.Name = 'Multiple surface eigenmodes without medial wall view';
     %saveas(fig, sprintf('%s/%s_Eigenmode_multiple_modes_end_%i.png',data_output ,hemisphere, num_modes));
     %disp("Eigenmode plot done");
     
    % =========================================================================
    % Reconstruct data                
    % =========================================================================
    
     data_to_plot = reconstruction(:,map_int);
     new_vec=get_new_vec(medial_wall, data_to_plot); 
     fig = draw_surface_bluewhitered_gallery_dull(surface_to_plot, new_vec, hemisphere, medial_wall, with_medial);
     fig.Name = 'Reconstruction';
     saveas(fig, sprintf('%s/%s_Reconstruction_%i_modes.png',data_output ,hemisphere, num_modes));
     disp("Reconstruction plot done");
   
end

function [new_vec]=get_new_vec(medial_wall, data_to_plot)
     N = length(data_to_plot);
     numNaNs = length(medial_wall);
     new_vec = zeros(N + numNaNs, 1);
     logical_idx = true(N + numNaNs, 1);
     logical_idx(medial_wall) = false;
     new_vec(logical_idx) = data_to_plot;
end 

function [new_matrix]=get_new_mat(medial_wall, data_to_plot)
     N=size(data_to_plot,1);
     numNaNs = length(medial_wall);
     new_matrix=zeros(N + numNaNs, size(data_to_plot,2));
     logical_idx=true(N + numNaNs, size(data_to_plot,2));
     logical_idx(medial_wall,:) = false;
     new_matrix(logical_idx) = data_to_plot;
     
end 

function [outputArray] = convertCellArray(input)
    if iscell(input)
       
        outputArray = cell2mat(input);
    else
        
        outputArray = input;
    end
end