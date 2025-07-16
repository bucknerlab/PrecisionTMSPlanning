#!/usr/bin/env python
import simnibs as sm
import numpy as np
import math
import os
from scipy.io import savemat
import argparse

# Read in from command line
parser = argparse.ArgumentParser(description="Import coordinates to localite markers")
parser.add_argument('-b', '--base', action='store',type=str,required=True,help="Give Base Directory")
parser.add_argument('-e', '--efolder', action='store',type=str,required=True,help="Give Efield Folder")
parser.add_argument('-s', '--subject', action='store',type=str,required=True,help="Give Subject ID")
parser.add_argument('-d','--distance',action='store',type=int,required=True,help="Give Distance")
parser.add_argument('-a','--avoid',action='store',type=str,required=True,help="Give Avoid")
parser.add_argument('-o','--outdir',action='store',type=str,required=True,help="Give Target TANS Outdir")
parser.add_argument('-t','--target',action='store',type=str,required=True,help="Give Target Code")
args = parser.parse_args()


basedir=args.base
SUB=args.subject

Outdir=args.outdir
Avoid=args.avoid
distance=args.distance
exptarg_name=args.target
efield_folder=args.efolder
root=os.path.join(basedir, f"{SUB}/{efield_folder}/tans/HeadModel/m2m_{SUB}")

meshes=os.listdir(root)
mesh = [m for m in meshes if m.endswith(".msh")]

meshfile = os.path.join(root, mesh[0])
print(meshfile)
msh=sm.read_msh(meshfile)

coordroot=os.path.join(basedir, f"{SUB}/{efield_folder}/tans/{Outdir}/A{Avoid}/Optimize")
# Define the path to the file
orientpath = coordroot + '/CoilOrientationCoordinates.txt'

# Read the data from the file
pos_ydir = np.loadtxt(orientpath)


centerpath = coordroot + '/CoilCenterCoordinates.txt'

# Read the data from the file
center = np.loadtxt(centerpath)

print(center)
print(pos_ydir)


print(f"Calculating 4x4 from center: {center}; pos_ydir: {pos_ydir}; distance: {distance}")
np.set_printoptions(suppress=True, precision=6)

mat = msh.calc_matsimnibs(center, pos_ydir, distance)
mat[:, 1] *= -1

print(mat)


### export from POSITION

pos = sm.sim_struct.POSITION()
pos.matsimnibs = mat
fn=os.path.join(coordroot, f"{SUB}_{Outdir}_dist{distance}.xml")
sm.localite().write(pos, fn, names=exptarg_name, overwrite=True) # out_coord_space default is 'RAS'


# Path to your XML file
file_path = fn
output_path = fn

old_head = '<InstrumentMarker alwaysVisible="false" index="0" selected="false">'
new_head = '<Element index="0" selected="true" type="InstrumentMarker">'

old_subhead = f'<Marker additionalInformation="" color="#ff0000" description="{exptarg_name}" set="true">'
new_subhead  = f'<InstrumentMarker additionalInformation="" alwaysVisible="true" color="#ff0000" description="{exptarg_name}" locked="false" set="true" uid="2">'

# Read the original XML file
with open(file_path, 'r') as file:
    file_data = file.read()

# Replace all occurrences of 'InstrumentMarkerList' with 'GUMMarkerList'
file_data = file_data.replace('InstrumentMarkerList', 'GUMMarkerList')
file_data = file_data.replace(old_head, new_head)
file_data = file_data.replace(old_subhead, new_subhead)
file_data = file_data.replace('</InstrumentMarker>', '</Element>')
file_data = file_data.replace('</Marker>', '</InstrumentMarker>')
# Write the modified data back to a new file
with open(output_path, 'w') as file:
    file.write(file_data)

print("File has been modified and saved as", output_path)


out=os.path.join(coordroot,f"{SUB}_{Outdir}_4x4.mat")
mat = msh.calc_matsimnibs(center, pos_ydir, distance)
savemat(out, {'matsimnibs': mat, 'average_distance': distance, 'average_didt': 1*(10**6)})
print(f"Saving...{out}")
