#!/usr/bin/env bash

# Author: Otello M Roscioni
# email om.roscioni@materialx.co.uk
#
# Unauthorized copying of this file, via any medium is strictly prohibited.
# Proprietary and confidential.
# 
# Copyright (C) MaterialX LTD - All Rights Reserved.

# Create a small sample of CG water placing them on a cubic grid.

# Input variables.
dumptools="perl ../scripts/dumptools.pl"
backmap="/usr/local/bin/backmap_legacy"
input="01_water_cg"
output="02_water"
atom_type1="../molc/tip4p.xyz"
# Settings for AA MD simulation.
ff_aa="../molc/tip4p2005_aa_01.lt" # Force field describing the solvent.
solvent_aa="../molc/solvent_aa_equilibration.lt " # Template for an isotropic liquid.
temp=298.15                        # Temperature 
ts=2                               # timestep
p=1000                             # correlation length
s=5                                # sample interval
equi=50000                         # Equilibration steps

# 1. Postprocess:

# 1.1 Wrap the CG structure.
$dumptools -o $output -f last -w $input.dump
mv ${output}_f*.dump ${output}_cg.dump

# 1.2 Convert the structure to atomic coordinates.
$backmap -t $atom_type1 ${output}_cg.dump
mv ${output}_cg.dump.0* ${output}_bm.pdb

# 2. Preprocess: create the input deck for an atomistic AA simulation (equilibration).

# 2.1 parse the PDB for number of molecules in the sample.
seq=$(tail -2 ${output}_bm.pdb | grep -v END | tail -1 | awk '{seq=substr($0,23,4); printf "%i",seq}')

# 2.2 parse the force field for molecule name.
mol=$(grep \{ $ff_aa | grep -v -e write -e @ | awk '{print $1}')

# 2.3 Write the header of the simulation.
function header_aa(){
cat << EOF

# Import the force field.
import $ff_aa

# Place the molecules on a cubic grid.
sol = new $mol[$seq]

write("In Init"){
# Input variables.
variable run string  ${output}_aa
variable temp  equal $temp  
variable ts    equal $ts      # timestep
variable p     equal $p    # correlation length
variable s     equal $s       # sample interval
variable equi  equal $equi    # Equilibration steps
}

EOF
}

header_aa > ${output}_aa.header

# 2.4 Write the input file for MOLTEMPLATE.
echo "# Import the definition of the solvent:
# * Molecular species.
# * number of molecules.
# * input variables. 
import ${output}_aa.header
# Import the template for equilibrating a liquid.
import $solvent_aa" > ${output}_aa.lt

# 2.5 Render the input script with MOLTEMPLATE.
moltemplate.sh -overlay-bonds -overlay-angles -overlay-dihedrals -overlay-impropers -pdb ${output}_bm.pdb ${output}_aa.lt
rm -fr output_ttree

# 2. Execute the simulation.
mpirun -np 4 lmp_2Jun22 -in ${output}_aa.in
