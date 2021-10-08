# Interpolation to pressure levels

The script `ml2pl.sh` interpolates history files of LMDZ (files named
`hist....nc`) from model levels to pressure levels. Interpolation is
linear in logarithm of pressure. If you want to use this program on the
computers jean-zay at IDRIS, or irene at TGCC, or Ciclad at IPSL, the
program is already installed at the following paths.

On jean-zay:

    /gpfswork/rech/lmd/rdzt899/bin/ml2pl.sh

On irene:

    /ccc/work/cont003/gencmip6/guezl/bin/ml2pl.sh

On Ciclad:

    /data/guez/bin/ml2pl.sh

## Installation

`Ml2pl` is written in Fortran 2003 and Bash. So you need a Fortran 2003
compiler and Bash on your machine. Moreover, you need to have the NetCDF
library installed, with its Fortran interface. The Fortran interface to
the NetCDF library must be installed using the same Fortran compiler
than the one you are going to use for `Ml2pl`.

1.  [Download the archive](ml2pl_with_lib-tar-gz){.internal-link} with
    source files. Extract its content:

        tar xvzf Ml2pl_with_lib-tar-gz

    and change directory:

        cd Ml2pl_with_lib

2.  Decide which Fortran 2003 compiler you want to use. Remember that
    you need the NetCDF library installed with the chosen compiler. If
    you have version 4 of the NetCDF library installed then the program
    `nf-config` should have been installed with the library. (You can
    also try the command `nc-config` instead.) This program will tell
    you the compiler you need to use with your NetCDF library. Just
    type:

        nf-config --fc

    You indicate your choice of Fortran compiler by setting the
    environment variable FC. Here is an example of setting the variable
    `FC` in Bash:

        export FC=the-output-of-nf-config--fc

3.  If the NetCDF library installed with the chosen compiler is not in
    standard locations, you should set the variables `NETCDF_INC_DIR`
    and `LDLIBS`. The directory `$NETCDF_INC_DIR` should contain the
    compiled NetCDF module interfaces (usually `netcdf.mod` and
    `typesizes.mod`). Note that the program does not need `netcdf.inc`.
    If you have the command `nf-config`, type:

        nf-config --includedir

    to find out the value of `NETCDF_INC_DIR`. For example:

        export NETCDF_INC_DIR=the-output-of-nf-config--includedir

    `LDLIBS` should give the path to the compiled NetCDF libraries and
    the name of those libraries, in the form required by your compiler.
    If you have the command `nf-config`, type:

        nf-config --flibs

    and paste the result of the command, between quotes, into `LDLIBS`.
    For example:

        export LDLIBS="the-output-of-nf-config--flibs"

    Here are a few tips to help you define `LDLIBS` if you do not have
    the command `nf-config` nor the command `nc-config`. Usually, the
    path to a library should be given in a `-L` option and the name of a
    library should be given in a `-l` option. So for example the
    adequate definition could be:

        export LDLIBS="-L/usr/lib -lnetcdf"

    which means that `libnetcdf.a` is to be found in `/user/lib`.
    Depending on your NetCDF installation, the Fortran 90 interface of
    NetCDF may be included in `libnetcdf.a` or may be in a separate
    library (usually `libnetcdff.a`, with two \'f\'s). If you have a
    separate library for the Fortran 90 interface, you have to include
    the path to it and its name in the variable `LDLIBS`. For example:

        export LDLIBS="-L/user/lib -L/user/lib/NetCDF_gfortran -lnetcdff -lnetcdf"

    Note that the order of options `-l` is usually important: the
    library for the Fortran 90 interface should be referenced first.
    (The order of options `-L` usually does not matter.)

4.  Optionally, you may choose additional compiler options by setting
    the variable `FFLAGS`. For example:

        export FFLAGS=-O3

5.  The parts of makefiles in the directory `Compiler_options` contain
    the compiler options for free source form and for reference to
    `NETCDF_INC_DIR`. There is one file for each of the following
    compilers : g95, gfortran, ifort, pgfortran, sxf90, xlf95. If you do
    not see the compiler you want in this list, you will have to create
    a similar file for your compiler. **If the above instructions don\'t
    work, please directly edit the makefile corresponding to your netcdf
    compiler, for example `Compiler_options/gfortran.mk`.**
6.  The makefiles are written for GNU make. The command invoking GNU
    make is usually `make` or `gmake`. So, for example, type:

        make

    After compilation, the executable binary file `ml2pl` should be
    created in the directory `Ml2pl_with_lib`. There is also a Bash
    script `ml2pl.sh` in the directory `Ml2pl_with_lib/Ml2pl`.

7.  Decide where you want to keep the executable binary file `ml2pl` and
    move it there. (Or you can just leave it where it is, if you want.)
    We advise not to put it into a directory appearing in your
    environment variable `PATH`. This would not be convenient because
    you will not run `ml2pl` directly. Instead, you will invoke the
    script `ml2pl.sh`.
8.  In the script `ml2pl.sh`, locate the line:

        executable=...

    Replace the ellipsis by the absolute path to the executable binary
    file `ml2pl`. For example:

        executable=~/Ml2pl_with_lib/ml2pl

9.  It may be convenient to move the script `ml2pl.sh` to somewhere in
    your `PATH`.

`ml2pl` and `ml2pl.sh` are the only files you will need. So you can
trash everything else if you want. (Be careful that if you type
`make clean` in the top directory and `ml2pl` is still there then it
will be deleted.)

## Usage

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
