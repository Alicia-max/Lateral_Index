#!/bin/bash

IDs=(100307 100408 101107 101309 101915 103111 103414 103818 105014 105115 106016 108828 110411 111312 111716 113619 113922 114419 115320 116524 117122 118528 118730 118932 120111 122317 122620 123117 123925 124422 125525 126325 127630 127933 128127 128632 129028 130013 130316 131217 131722 133019 133928 135225 135932 136833 138534 139637 140925 144832 146432 147737 148335 148840 149337 149539 149741 151223 151526 151627 153025 154734 156637 159340 160123 161731 162733 163129 176542 178950 189450 190031 192540 196750 198451 199655 201111 208226 211417 212318 214423 221319 239944 245333 280739 298051 366446 397760 414229 499566 654754 672756 751348 756055 792564 856766 857263 899885)  
d_out='/media/miplab-nas2/Data3/Hamid_Alicia/'
N_sa=20
N_modes=2000
WhichSignals='rh'
log_dir="../logs"
dir_save='/media/miplab-nas2/Data3/Hamid_Alicia/splitting'
modes_dir='2000_modes'
d_utils='../functions_matlab/utils_saSOKS'

# Ensure the log directory exists
mkdir -p "${log_dir}"
mkdir -p "${dir_save}"

# Function to log messages with timestamps
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "${log_dir}/subband.txt"
}

log "Script started."

# Define MATLAB command to run run_subband.m
MATLAB_COMMAND="matlab -nodisplay -nosplash -r \"IDs=[${IDs[*]}]; N_sa=${N_sa}; d_out='${d_out}'; WhichSignals='${WhichSignals}'; N_modes=${N_modes};dir_save='${dir_save}';  modes_dir='${modes_dir}'; d_utils='${d_utils}'; run_subband(IDs, N_sa, N_modes, '${d_out}', '${WhichSignals}', '${dir_save}','${modes_dir}', '$d_utils'); exit;\""


nohup bash -c "$MATLAB_COMMAND" > "${log_dir}/run_subband.log" 2>&1 &




