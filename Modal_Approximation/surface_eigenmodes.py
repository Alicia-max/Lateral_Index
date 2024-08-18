#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Calculate the eigenmodes of a cortical surface
Adapted from https://github.com/NSBLab/BrainEigenmodes/blob/main/surface_eigenmodes.py
"""

# Import all the libraries
from lapy import TriaMesh,shapedna
import numpy as np
import nibabel as nib
import brainspace.mesh as mesh
import os
from argparse import ArgumentParser
import scipy.sparse as sp
from scipy.io import savemat
import time



def calc_eig(tria, num_modes):
    """
    Calculate the eigenvalues and eigenmodes of a surface.

    Inputs
    ------
    tria : lapy compatible object
        Loaded vtk object corresponding to a surface triangular mesh
    num_modes : int
        Number of eigenmodes to be calculated

    Output
    ------
    evals [arr] : contains eigenvalues (n_modes x 1)
        
    emodes [arr] : contains eigenvector (number of surface points x num_modes)
      
    normalized_evals : volume corrected eigenvalues (n_modes x 1)
    """
    ev = shapedna.compute_shapedna(tria, k=num_modes)
    evals=ev['Eigenvalues']
    emodes=ev['Eigenvectors']
    normalized_evals=shapedna.normalize_ev(tria, evals, method="geometry")
    return emodes, normalized_evals

    
def calc_surface_eigenmodes_nomask(surface_input_filename, output_emode_filename,  output_evaln_filename,num_modes):
    """
    Main function to calculate the eigenmodes of a cortical surface.
    
    Inputs
    ------
    surface_input_filename [str] : filename of input surface
    output_emode_filename [str]: filename of of the output to store eigenmodes 
    output_evaln_filename [str] :filename of of the output to store volume corrected eigenvalues
    num_modes [int]: number of eigenmodes to be derived          
    
    """
   
    # load surface (as a lapy object)
    tria = TriaMesh.read_vtk(surface_input_filename)
    # calculate eigenmodes, volumes corrected eigenvalues
    emodes, normalized_evals = calc_eig(tria, num_modes)
    # save  results 
    np.savetxt(output_emode_filename, emodes)
    np.savetxt(output_evaln_filename, normalized_evals)  
    
def main(raw_args=None):    
    parser = ArgumentParser(epilog="surface_eigenmodes.py -- A function to calculate the eigenmodes of a cortical surface.")
    parser.add_argument("surface_input_filename", help="An input surface in vtk format", metavar="surface_input.vtk")
    parser.add_argument("output_emode_filename", help="An output text file where the eigenmodes will be stored", metavar="emodes.txt")
    parser.add_argument("output_evaln_filename", help="An output text file where the normalized eval  will be stored", metavar="normalized_evals.txt")
    parser.add_argument("-N", dest="num_modes", default=20, help="Number of eigenmodes to be calculated, default=20", metavar="20")
    
    #--------------------    Parsing the inputs from terminal:   -------------------
    args = parser.parse_args()
    surface_input_filename   = args.surface_input_filename
    output_emode_filename    = args.output_emode_filename
    output_evaln_filename    = args.output_evaln_filename
    num_modes                = int(args.num_modes)
    #-------------------------------------------------------------------------------
    calc_surface_eigenmodes_nomask(surface_input_filename, output_emode_filename,  output_evaln_filename, num_modes)
if __name__ == '__main__':
    start_time = time.time()
    main()
    end_time = time.time()
    execution_time = end_time - start_time
    print(f"Execution time: {execution_time} seconds")