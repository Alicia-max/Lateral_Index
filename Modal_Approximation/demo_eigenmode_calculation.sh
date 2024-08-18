#!/bin/bash

# Define variables
structure='white'
hemispheres='lh rh'
num_modes=2000
directory_path='/media/miplab-nas2/Data3/Hamid/HCP100_miplabgolgi/'
data_output='/media/miplab-nas2/Data3/Hamid_Alicia'
log_file='../logs/execution_log.txt'

# Function to log messages with timestamps
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$log_file"
}

# Set up FreeSurfer environment
export FREESURFER_HOME=/usr/local/freesurfer/7.2.0/
export SUBJECTS_DIR=$FREESURFER_HOME/subjects
source $FREESURFER_HOME/SetUpFreeSurfer.sh  

log "Script started."

# Record start time
start_time=$(date +%s)

# Find directories containing only numbers at the beginning
folders=$(find "${directory_path}" -maxdepth 1 -type d | grep -E '/[0-9]+' | sed 's#.*/##')

# Iterate over subject directories
for folder in ${folders}; do 
    log "Processing folder: $folder"
    
    # Iterate over each hemisphere
    for hemisphere in ${hemispheres}; do
        log "Processing ${hemisphere}"

        # Create directories if they don't exist
        mkdir -p "${data_output}/${folder}/"
        mkdir -p "${data_output}/${folder}/${num_modes}_modes/"
        gii_file_path="${directory_path}/${folder}/T1w/${folder}/surf/${hemisphere}.${structure}.surf.gii"
        vtk_file_path="${data_output}/${folder}/${structure}-${hemisphere}.vtk"

        if [ ! -f "$vtk_file_path" ]; then
            log "Converting surface to VTK format: $vtk_file_path"
            mris_convert "${gii_file_path}" "${vtk_file_path}"
        fi
                     
        surface_input_filename="${data_output}/${folder}/${structure}-${hemisphere}.vtk"
        output_emode_filename="${data_output}/${folder}/${num_modes}_modes/${structure}-${hemisphere}_emode_${num_modes}.txt"
        output_evaln_filename="${data_output}/${folder}/${num_modes}_modes/${structure}-${hemisphere}_norma_eval_${num_modes}.txt"

        # Check if any of the output files exist
        if [ ! -f "$output_eval_filename" ] || [ ! -f "$output_emode_filename" ]  || [ ! -f "$output_evaln_filename" ]; then
            log "Running Python script for surface eigenmodes computation."
            python surface_eigenmodes.py "${surface_input_filename}" \
                                         "${output_emode_filename}" \
                                         "${output_evaln_filename}"  \
                                          -N "${num_modes}" 
        else
            log "Output files already exist. Skipping computation for ${hemisphere}."
        fi
    done
done

# Record end time
end_time=$(date +%s)

# Calculate elapsed time
elapsed_time=$((end_time - start_time))
log "Script completed. Elapsed time: $elapsed_time seconds."