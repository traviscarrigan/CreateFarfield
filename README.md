# CreateFarfield
A Pointwise Glyph script to generate either hemispherical or spherical farfields for a given selection of domains.

## Usage
Open *createFarfield.glf* in your favorite text editor and specify the farfield radius, farfield grid spacing, and the freestream direction. Currently, the plan is for the radius and spacing parameters to be a function of the grid extents. The freestream axis simply gives the script a preferential direction for the symmetry test. Ultimately, the script should be able to compute whether a grid is symmetric or not and build the appropriate farfield. 

	 

