# What is it?

The script `ml2pl.sh` interpolates history files of LMDZ (files named
`hist....nc`) from model levels to pressure levels. Interpolation is
linear in logarithm of pressure.

# Note for the users of French supercomputing centers

If you want to use this program on the
computers jean-zay at IDRIS, or irene at TGCC, or Ciclad at IPSL, the
program is already installed at the following paths.

On jean-zay:

    /gpfswork/rech/lmd/rdzt899/bin/ml2pl.sh

On irene:

    /ccc/work/cont003/gencmip6/guezl/bin/ml2pl.sh

On Ciclad:

    /data/guez/bin/ml2pl.sh

# Installation

Dependencies: `Ml2pl` is written in Fortran 2003 and Bash. So you need
a Fortran 2003 compiler and Bash on your machine. You must first
install the libraries
[NetCDF-C](https://www.unidata.ucar.edu/downloads/netcdf/index.jsp)
and
[NetCDF-Fortran](https://www.unidata.ucar.edu/downloads/netcdf/index.jsp).
Note that NetCDF-Fortran must be installed using the same Fortran
compiler than the one you are going to use for `Ml2pl`.

## Installation with CMake

This is the recommended way.

Additional dependency: you must first install
[CMake](https://cmake.org/download) (version ≥ 3.16).

2.  Type:

        cd the-Ml2pl-directory-you-downloaded
        mkdir build
        cd build

3.  Choose the installation directory `CMAKE_INSTALL_PREFIX` and type
    the command below with your choice after `-DCMAKE_INSTALL_PREFIX=`
    (enter an absolute path). For example, you could choose
    `-DCMAKE_INSTALL_PREFIX=~/.local`. The installation process will
    install a shell script, `ml2pl.sh`, in
    `$CMAKE_INSTALL_PREFIX/bin`. It is convenient for
    `$CMAKE_INSTALL_PREFIX/bin` to be in your `PATH` environment
    variable.

        cmake .. -DCMAKE_BUILD_TYPE=Release -DFETCH=True -DCMAKE_INSTALL_PREFIX=/wherever

4.  Type:

        make install

Note that the installation process also installs a Fortran executable
file, `ml2pl`, in `$CMAKE_INSTALL_PREFIX/libexec`. Do not remove this
file.

## Installation directly with make

This is the (old) less automated way, not recommended.

Additional dependencies: you must first install the libraries
[NetCDF95](https://www.lmd.jussieu.fr/~lguez/NetCDF95_site/index.html),
[NR\_util](https://www.lmd.jussieu.fr/~lguez/NR_util_site/index.html),
[Numer\_Rec\_95](https://gitlab.in2p3.fr/ipsl/lmd/dpao/numer_rec_95)
and
[Jumble](https://www.lmd.jussieu.fr/~lguez/Jumble_site/index.html).
The five Fortran libraries, NetCDF-Fortran, NetCDF95, NR\_util,
Numer\_Rec\_95 and Jumble, must be compiled with the same compiler.

2. Indicate your Fortran compiler by setting the variable FC in
   GNUmakefile.
	
2. If necessary, add or modify options `-I` in the variable FFLAGS in
   GNUmakefile. The options `-I` should give the path to the `.mod` files
   of the five Fortran libraries, NetCDF-Fortran, NetCDF95, NR\_util,
   Numer\_Rec\_95 and Jumble.
   
3. If necessary, add or modify options `-L` in the variable LDLIBS in
   GNUmakefile. The options `-L` should give the path to the library
   files of the five Fortran libraries: `libnetcdff.a`,
   `libnetcdf95.a`, `libnr_util.a`, `libnumer_rec_95.a` and
   `libjumble.a` (or the dynamic libraries with a `.so` suffix).
	
6.  The makefile is written for GNU make. The command invoking GNU
    make is usually `make` or `gmake`. So, for example, type:

        cd the-Ml2pl-directory-you-downloaded
        make

    After compilation, the executable binary file `ml2pl` should be
    created.

7.  Decide where you want to keep the executable binary file `ml2pl` and
    move it there. (Or you can just leave it where it is, if you want.)
    We advise not to put it into a directory appearing in your
    environment variable `PATH`. This would not be convenient because
    you will not run `ml2pl` directly.
	
7. There is also a Bash script `ml2pl_in.sh` in the directory of
   Ml2pl. In the script `ml2pl_in.sh`, locate the line:

        executable=@CMAKE_INSTALL_FULL_LIBEXECDIR@/ml2pl

    Replace `@CMAKE_INSTALL_FULL_LIBEXECDIR@` by the absolute path to
    the executable binary file `ml2pl`. For example:

        executable=~/.local/bin/ml2pl

9.  Rename `ml2pl_in.sh` to `ml2pl.sh`. It may be convenient to move
    the script `ml2pl.sh` to somewhere in your `PATH`.

`ml2pl` and `ml2pl.sh` are the only files you will need. So you can
trash everything else if you want. (Be careful that if you type `make
clean` and `ml2pl` is still there then it will be deleted.)

### Troubleshooting

For installation directly with make, here are a few tips to help you
define `FFLAGS` and `LDLIBS`, especially with regard to the NetCDF and
NetCDF-Fortran libraries.

1. If you have version 4 of the NetCDF-Fortran library installed then
   the program `nf-config` should have been installed with the
   library. (You can also try the command `nc-config` instead.) This
   program will tell you the compiler used to compile your
   NetCDF-Fortran library:

		nf-config --fc

3. It will give you the directory containing the compiled
   NetCDF-Fortran module interfaces (usually `netcdf.mod` and
   `typesizes.mod`):

        nf-config --includedir
		
3. It will give you what you need to copy to `LDLIBS`:

        nf-config --flibs

3. After `-l`, in `LDLIBS`, you write the name of the library without
   prefix lib and without suffix `.a` or `.so`. For example `-lnetcdf`
   for `libnetcdf.a`. The NetCDF-Fortran library should be in the file
   `libnetcdff.a` or `libnetcdff.so`, with two 'f's.

3. Note that the order of options `-l` is usually important: the
   NetCDF-Fortran library should be referenced first.
   
3. The order of options `-L` usually does not matter.

# Usage

Running the command with argument `-h` will produce a help message:

    $ ml2pl.sh -h
    usage: ml2pl.sh [OPTION]... input-file output-file [pressure-file]

    Interpolates NetCDF variables from model levels to pressure
    levels. The interpolation is linear in logarithm of pressure. The
    input variables depend on longitude, latitude, vertical level and
    time. There is no constraint on the dimensions.

    Options:
       -h                       : this help message
       -p variable              : name of 4-dimensional variable in the input file
                                  or the pressure file containing the
                                  pressure field at model levels
       -v variable[,variable...]: names of variables you want to interpolate, 
                                  and possibly extrapolate if target pressure 
                                  level is below surface
       -w variable[,variable...]: names of variables you want to interpolate, 
                                  or set to 0 if target pressure level is below
                                  surface
       -m variable[,variable...]: names of variables you want to interpolate, 
                                  or set to missing if target pressure level is 
                                  below surface

    input-file, output-file and pressure-file are NetCDF files.

    You must list the variables you want to interpolate, each variable
    listed after either -v, -w or -m. There must be at least one variable
    listed, following either -v, -w or -m.

    The pressure field at model levels can be specified in input-file or
    pressure-file either through hybrid coefficients and surface pressure
    or directly from 4-dimensional pressure. In both cases, pressure must
    be given in Pa and decrease when the index of model level
    increases. This is checked quickly in the program. If option -p is not
    used then the program will look for "ap", "bp" (hybrid
    coefficients) and "ps" (surface pressure) in the input file or the
    pressure file.

    The target pressure levels should be in a text file called
    "press_levels.txt" in the current directory at run-time. The first
    line of the file is skipped, assuming it is a title line. Pressure
    levels should be in hPa, in descending order, one value per
    line. There is no constraint on these values nor on the number of
    values.

There is [an example for file
`press_levels.txt`](Tests/press_levels.txt) in directory Tests.
