#!/bin/bash
#100307 103111 105115  100408 113922 126325 101107 101309 101915  103414 103818 105014 106016 108828 110411 111312 111716 113619 114419 115320 116524 117122 118528 118730 118932 120111 122317 122620 123117 123925 124422 125525 127630 127933 128127 128632 129028 130013 130316 131217 131722 133019 133928 135225 135932 136833 138534 139637 140925 144832 146432 147737 148335 148840 149337 149539 149741 151223 151526 151627 153025 154734 156637 159340 160123 161731 162733 163129 176542 178950 188347 189450 190031 192540 196750 198451 199655 201111 208226 211417 212318 214423 221319 239944 280739 298051 366446 397760 414229 499566 654754 672756 751348 756055 792564 856766 857263 899885 245333

# Define variables 
subjects=(100307)
hemispheres='rh lh'
num_modes=20
data_dir='/media/miplab-nas2/Data3/Hamid_Alicia/'
log_file='../logs/reconstruction_log.txt'
mesh_interest='white'
input_spatial_pat='/media/miplab-nas2/Data3/Hamid/HCP100_miplabgolgi'
tmp='rfMRI_REST1_LR.res1250.spaceT1w.detrend1_regMov1_zscore1.SSBCAPs_schaefer400yeo7_res1250_spaceT1w'
stepwise=true
matlab_dir='../functions_matlab'
step_=1 
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$log_file"
}

log "Script started."

#Iterate through subject dir
for subject in "${subjects[@]}"; do
    
    subject_folder="${data_dir}/${subject}"
    dir_mat="${subject_folder}/${num_modes}_modes"
    mkdir -p "$dir_mat"    
    
    for hemisphere in ${hemispheres}; do
        log "Processing ${subject}, the ${hemisphere}"
        
        file_gii="${input_spatial_pat}/${subject}/T1w/Results/rfMRI_REST1_LR/${hemisphere}.${tmp}.gii"
        file_eigen="${data_dir}/${subject}/${num_modes}_modes/${mesh_interest}-${hemisphere}_emode_${num_modes}.txt"
        
        # Log file paths
        log "file_gii: $file_gii"
        log "file_eigen: $file_eigen"
        
        # Check if files exist
        if [[ ! -f "$file_gii" ]]; then
            log "File not found: $file_gii"
            continue
        fi
        
        if [[ ! -f "$file_eigen" ]]; then
            log "File not found: $file_eigen"
            continue
        fi
        

        matlab_cmd="file_gii='$file_gii'; file_eigen='$file_eigen'; dir_mat='$dir_mat'; hemisphere='$hemisphere'; num_modes=$num_modes; stepwise=$stepwise; matlab_dir='$matlab_dir'; step_=$step_; run_recon(file_gii,file_eigen, dir_mat, hemisphere, num_modes, stepwise, matlab_dir, step_);"
     
        nohup bash -c "
            start_time=\$(date +%s)
            matlab -nodisplay -nosplash -nodesktop -r \"$matlab_cmd\" > \"../logs/log_${num_modes}_${hemisphere}_${subject}.out\" 2>&1
            end_time=\$(date +%s)
            execution_time=\$((end_time - start_time))
            echo \"Total execution time: \$execution_time seconds\" >> \"../logs/log_${num_modes}_${hemisphere}_${subject}.out\"
        " > /dev/null 2>&1 &
    
    done
done
