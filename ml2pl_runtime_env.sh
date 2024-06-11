# This is just a template for the run-time environment that could be
# needed by ml2pl.sh. Customize a copy for each machine into
# LIBEXECDIR.

module purge --silent
module load intel/... --silent
module load netcdf-fortran/... --silent
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:...NetCDF...
