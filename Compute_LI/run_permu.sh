#!/bin/bash
#####100307 100408 101107 101309 101915 103111 103414 103818 105014 105115 106016 108828 110411 111312 111716 113619 113922 114419 115320 116524 117122 118528 118730 118932 120111 122317 122620 123117 123925 124422 125525 126325 127630 127933 128127 128632 129028 130013 130316 131217 131722 133019 133928 135225 135932 136833 138534 139637 140925 144832 146432 147737 148335 148840 149337 149539 149741 151223 151526 151627 153025 154734 156637 159340 160123 161731 162733 163129 176542 178950 189450 190031 192540 196750 198451 199655 201111 208226 211417 212318 214423 221319 239944 245333 280739 298051 366446 397760 414229 499566

subjects=(100307)  
hemispheres='lh rh'
num_modes=2000
output="/media/miplab-nas2/Data3/Hamid_Alicia"
n_permu=2
log_dir="../logs"
matlab_dir='../functions_matlab'

# Ensure the log directory exists
mkdir -p "${log_dir}"

# Function to log messages with timestamps
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "${log_dir}/permu.txt"
}

log "Script started."

# Record start time
start_time=$(date +%s)

# Loop through subjects and hemispheres
for subject in "${subjects[@]}"; do
    for hemisphere in ${hemispheres}; do
        log "Processing ${hemisphere}"
        
        permu_dir="${output}/${subject}/permu/"
        mkdir -p "$permu_dir"

        data_to_recon="${output}/${subject}/${num_modes}_modes/${hemisphere}_data_${num_modes}_normed.mat"
        eigen_file="${output}/${subject}/${num_modes}_modes/${hemisphere}_eigen_wo_nan_${num_modes}.mat"
        bins_file="${output}/${subject}/${num_modes}_modes/${hemisphere}_grouped_values_diff.mat"
        nohup bash -c "
            start_time=\$(date +%s)
            matlab -nodisplay -nosplash -nodesktop -r \"data_to_recon='${data_to_recon}'; eigen_file='${eigen_file}';  bins_file='${bins_file}'; hemisphere='${hemisphere}';  output='${permu_dir}'; num_modes=${num_modes}; n_permu=${n_permu}; matlab_dir='$matlab_dir'; demo_permu(data_to_recon, eigen_file,bins_file, n_permu, num_modes, hemisphere, output, matlab_dir);\" > ${log_dir}/${subject}_${hemisphere}_permu.out 2>&1
            end_time=\$(date +%s)
            execution_time=\$((end_time - start_time))
            echo \"Total execution time: \${execution_time} seconds\" >> ${log_dir}/${subject}_${hemisphere}_permu.out
        " > /dev/null 2>&1 &
        
    done
done

log "Script finished."
