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
output="01_water_cg"               # Output filename.
ff_cg="../molc/tip4p2005_cg_01.lt" # Force field describing the solvent.
solvent_cg="../molc/solvent_cg_creation.lt " # Template for creating an isotropic liquid.
grid_size=4                        # Molecules on a $grid_size*$grid_size*$grid_size cubic grid.
grid_spacing=6.4                   # Separation between grid points.
temp=298.15                        # Temperature 
ts=10                              # timestep
p=1000                             # correlation length
s=5                                # sample interval
steps=50                           # Steps for equilibration.
equi=100                           # Equilibration steps
prod=50000                         # Production steps


# 1. Create the initial guess of a liquid by placing molecules on a cubic grid.

# 1.1 parse the force field for molecule name.
mol=$(grep \{ $ff_cg | grep -v -e write -e @ | awk '{print $1}')

# 1.2 Compute the box size based on the grid and spacing.
box=$(bc -l<<<$grid_spacing*$grid_size/2 | awk '{printf "%.3f",$1}')

# 1.3 Write the header of the simulation.
function header_cg(){
cat << EOF

# Import the force field.
import $ff_cg

# Place the molecules on a cubic grid.
sol = new $mol[$grid_size].move(0,0,$grid_spacing)
              [$grid_size].move(0,$grid_spacing,0)
              [$grid_size].move($grid_spacing,0,0)

# shift all the molecules to the centre of the box
sol[*][*][*].move(-$box,-$box,-$box)

# Simulation box.
write_once("Data Boundary") {
-$box $box xlo xhi
-$box $box ylo yhi
-$box $box zlo zhi
}

write("In Init"){
# Input variables.
variable run string $output
variable temp  equal $temp  
variable ts    equal $ts      # timestep
variable p     equal $p    # correlation length
variable s     equal $s       # sample interval
variable steps equal $steps      # Steps for equilibration.
variable equi  equal $equi    # Equilibration steps
variable prod  equal $prod  # Production steps
}

EOF
}
header_cg > ${output}.header

# 1.4 Write the input file for MOLTEMPLATE.
echo "# Import the definition of the solvent:
# * Molecular species.
# * number of molecules.
# * simulation box.
# * input variables. 
import ${output}.header
# Import the template for annealing an isotropic liquid.
import $solvent_cg" > $output.lt

# 1.5 Render the input script with MOLTEMPLATE.
moltemplate.sh -atomstyle "hybrid molecular ellipsoid" -overlay-bonds $output.lt
rm -fr output_ttree

# 2. Execute the simulation.
mpirun -np 4 lmp_2Jun22 -in $output.in
