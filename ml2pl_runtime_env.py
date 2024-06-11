# This is just a template for the run-time environment that could be
# needed by ml2pl.py. Customize a copy for each machine into
# LIBEXECDIR.

exec(open("/usr/share/modules/init/python.py").read(), globals())
module("purge")
module(
    "load",
    "intel/...",
    "netcdf-c/...",
    "netcdf-fortran/..."
)
import os
os.environ["LD_LIBRARY_PATH"] += ":...NetCDF..."
