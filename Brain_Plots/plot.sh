#!/bin/bash

# Define variables
subjects=(676) # Add your list of subjects
hemispheres='lh rh' # List of hemispheres
num_modes=500
mesh_interest='white'
map_int=1
output="/media/miplab-nas2/Data3/Hamid_Alicia/results/676"
mode_interest=(1 2)
arr_in_matlab=$(IFS=,; echo "[${mode_interest[*]}]")
dir_func='../functions_matlab'
log_dir="../logs"

if [ ! -d "$log_dir" ]; then
    mkdir "$log_dir"
fi

# Loop through each subject
for subject in "${subjects[@]}"; do
    for hemisphere in ${hemispheres}; do
        echo "Processing ${subject}, the ${hemisphere}"
        #data_output="${output}/${subject}"
        log_file="${log_dir}/log_${num_modes}_${hemisphere}_${subject}_plot.out"
        if [ ! -f "$log_file" ]; then
            touch "$log_file"
            echo "log_out created"
        fi

        output_dir_plots="${output}/plots"
        if [ ! -d "$output_dir_plots" ]; then
            mkdir "$output_dir_plots"
        fi
        
        data_to_recon="${output}/${num_modes}_modes/${hemisphere}_data_${num_modes}_normed.mat"
        eigen_file="${output}/${num_modes}_modes/${hemisphere}_eigen_wo_nan_${num_modes}.mat"
        reconstruction_file="${output}/${num_modes}_modes/${hemisphere}_data_${num_modes}_reconstructions.mat"
        medial_wall_file="${output}/${num_modes}_modes/${hemisphere}_medial_wall_${num_modes}.mat"
        vtk_file="${output}/${num_modes}_modes/${mesh_interest}-${hemisphere}.vtk"
        
    
        nohup matlab -nodisplay -nosplash -nodesktop -r "vtk_file='${vtk_file}'; data_to_recon='${data_to_recon}'; eigen_file='${eigen_file}';reconstruction_file='$reconstruction_file'; data_output='$output_dir_plots';hemisphere ='$hemisphere'; num_modes=$num_modes; map_int=$map_int;medial_wall_file='$medial_wall_file'; mode_interest=${arr_in_matlab};dir_func='${dir_func}'; plot_brains(vtk_file, data_to_recon,eigen_file, reconstruction_file, medial_wall_file, data_output, hemisphere, num_modes, map_int,mode_interest, dir_func);" > "${log_file}" 2>&1  &
    
    done
    
done
