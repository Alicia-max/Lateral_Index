function demo_permu(data_to_recon, eigen_file, bins_file, n_permu, num_modes, hemisphere, output, matlab_dir)
  
    disp("Begin");
    addpath(genpath(matlab_dir));
   
    % Load activity map - loaded.mat file (normalized one)
    data_to_reconstruct_struct = load(data_to_recon);
    data_to_reconstruct=data_to_reconstruct_struct.data_to_reconstruct;
    %only the right hemisphere
    data_to_reconstruct=data_to_reconstruct(:,201:400);
   
    % Load eigenmodes
    eigenmodes_load = load(eigen_file);
    eigenmodes = eigenmodes_load.eigenmodes;

    %Load bins
    bins_data=load(bins_file);
    bins=bins_data.Y2;
   
    % Initialize cell array to store permutation results
    beta_permutation = zeros(length(bins), size(data_to_reconstruct, 2), n_permu);
  
    disp("Permu");

    % Perform permutations
    for i = 1:n_permu 
        shuffled_indices = randperm(size(data_to_reconstruct, 1));
        permuted_matrix = data_to_reconstruct(shuffled_indices, :);
        betas_ = calc_eigendecomposition(permuted_matrix, eigenmodes, 'matrix');
        beta_permutation(:,:,i) = get_grouped(betas_,bins);
        
        
    end

    disp("Save");
    matFilePath = sprintf('%s/%s_beta_permu_%i_%i_grouped_testos.mat', output, hemisphere, num_modes,n_permu);
    save(matFilePath, 'beta_permutation');
end

%TODO MOVE TO HELP FUNC

function grouped_permu = get_grouped(betas, bins)

    grouped_permu = zeros(length(bins), size(betas, 2));
        for i=1:length(bins)
            indexes = bins{i};
            grouped_permu(i, :) =sum(abs(betas(indexes, :)), 1);
        end
end 



