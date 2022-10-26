Mesoscopic Multiscale Simulations
==

###  Description

Simplified Use Case for the [OpenModel](https://open-model.eu/) project.
This workflow aims to create a sample of 512 water molecules (*TIP4P 2005* model). The workflow starts with a coarse-grained force field based on the [**MOLC**](https://doi.org/10.1039/c9cp04120f) model, implemented in a fork of [**LAMMPS**](https://lammps.org), version [2_Jun 2022](https://github.com/sfarr-epcc/lammps_MOLC/).
The sample is first assembled in the desired configuration, annealed, converted to
atomistic coordinates with the program [**BACKMAP**](https://github.com/matteoeghirotta/backmap_legacy/tree/0a096ad26232d5969333cdc9bed59ece392659f5), and
finally annealed with a type-I atomistic force field (*OPLS*).

The whole procedure is based on open-source software and relies on a coarse-grained force field parametrised
consistently with the atomistic force field. Since LAMMPS has limited capabilities to handle complex structures,
the strategy used here is to manipulate molecular samples with a custom-written program, [**dumptools**](./scripts/dumptools.pl), and to combine the structure with the force field using [MOLTEMPLATE](https://github.com/jewettaij/moltemplate).

### Software Dependency

This Use Case depends on the following software. Additional scripts are included in the
[scripts](./scripts/) folder.
1. [MOLTEMPLATE](https://github.com/jewettaij/moltemplate).
2. [LAMMPS_MOLC, patch June 2022](https://github.com/sfarr-epcc/lammps_MOLC), including the USER-MOLC package.
3. [BACKMAP](https://github.com/matteoeghirotta/backmap_legacy/tree/0a096ad26232d5969333cdc9bed59ece392659f5).
4. [VMD](http://www.ks.uiuc.edu/Research/vmd/).

### Workflow

Go to the [multiscale](./multiscale/) folder and execute the following steps.

1. Create a cubic box of coarse-grained TIP4P-2005 water molecules. Anneal and equilibrate the structure with LAMMPS.
   ```sh
   bash 01_step.sh
   ```
2. Post-process the output:
  
  * Wrap the last frame of the CG trajectory.
  * Convert the CG snapshot to atomic coordinates.
  * Render the backmapped structure and the force field with MOLTEMPLATE.
  * Run the atomistic MD simulation with LAMMPS.
 ```sh
   bash 02_step.sh
   ```
3. EXTRA: create a PSF topology file to visualize the binary trajectory:
   ```sh
   data2psf 02_water_aa.data 02_water_bm.pdb
   vmd -psf 02_water_aa.psf -dcd 02_water_aa.dcd
   ```

### Notes

LAMMPS 2Jun22 has been compiled with the following packages enabled:
```sh
make yes-asphere yes-kspace yes-mc yes-misc yes-molecule yes-rigid yes-asphere yes-molc yes-extra-dump yes-class2
make -j4 g++_openmpi
```
