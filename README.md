# What is it?

Ml2pl interpolates atmospheric data at model levels to pressure
levels. Input and output are in
[NetCDF](https://www.unidata.ucar.edu/software/netcdf) format.

Ml2pl was first written to process history files of
[LMDZ](https://lmdz.lmd.jussieu.fr/) (files named `hist....nc`). It
also works with atmospheric data from other sources. It is used in
[Climaf](https://climaf.readthedocs.io/en/latest/index.html).

# Installation

## Note for the users of French supercomputing centers

If you want to use this program on the computers jean-zay at IDRIS, or
irene at TGCC, or spirit at IPSL, the program is already installed at
the following paths.

On jean-zay:

    /gpfswork/rech/lmd/rdzt899/bin/ml2pl.sh

On irene:

    /ccc/work/cont003/gencmip6/guezl/bin/ml2pl.sh

On spirit:

    /data/guez/bin/ml2pl.sh

## Dependencies

- [CMake](https://cmake.org/download) (version &ge; 3.16)[^1].

- The [NetCDF-C
  library](https://docs.unidata.ucar.edu/nug/current/getting_and_building_netcdf.html)
  (version &ge; 4.6).

- The [NetCDF-Fortran
  library](https://www.unidata.ucar.edu/downloads/netcdf/index.jsp)
  (version &ge; 4.5).

- The Fortran compiler that was used to compile your installed
  NetCDF-Fortran library.

- [NCO](https://nco.sourceforge.net).
- Git (optional, the easiest way to download Ml2pl).

Under Ubuntu &ge; 20.04 or Linux Mint &ge; 20, you can install all these
dependencies with the following command:

	sudo apt install libnetcdff-dev gfortran cmake nco git

## Instructions

1.  Get [Ml2pl from Github](https://github.com/lguez/Ml2pl). As the
    Git repository contains a submodule, the easiest way is to type:

		git clone --recurse-submodules https://github.com/lguez/Ml2pl.git

	If you prefer to download a ZIP file then you will also have to
    download the [cmake subdirectory](https://github.com/lguez/cmake).

2.  Create a build subdirectory in the Ml2pl directory you have just
    downloaded:

        cd Ml2pl
        mkdir build
        cd build

3.  Decide in which directory you want to install Ml2pl after
    compilation and type the command below with your choice after
    `-DCMAKE_INSTALL_PREFIX=` (enter an absolute path). The
    installation process will install a shell script, `ml2pl.sh`, in
    `$CMAKE_INSTALL_PREFIX/bin`. It is convenient for
    `$CMAKE_INSTALL_PREFIX/bin` to be in your `PATH` environment
    variable. For example:

        cmake .. -DFETCH=ON -DCMAKE_INSTALL_PREFIX=~/.local

4.  Type:

        make install

You do not need to keep the downloaded directory Ml2pl (nor the build
directory) after installation. Note that the installation process also
installs a Fortran executable file, `ml2pl`, in
`$CMAKE_INSTALL_PREFIX/libexec`. Do not remove this file.

## Advanced instructions

Most users should not need these advanded instructions.

- You can choose any name and any location for the build
  directory. You have to refer to the source directory when you run
  cmake from the build directory:

		mkdir /wherever/any/name
		cd /wherever/any/name
		cmake /where/I/downloaded/Ml2pl -DFETCH=ON -DCMAKE_INSTALL_PREFIX=~/.local

- The option `-DFETCH=ON` instructs CMake to download, compile and
  install the libraries [Jumble](https://lguez.github.io/Jumble),
  [NetCDF95](https://lguez.github.io/NetCDF95) and
  [`Numer_Rec_95`](https://gitlab.in2p3.fr/guez/Numer_Rec_95). If you
  have already installed these libraries, you can omit the FETCH
  option.

## Troubleshooting

- If your installation of NetCDF or NetCDF-Fortran is in a
  non-standard location, and CMake does not find it, then re-run cmake
  setting the variable `CMAKE_PREFIX_PATH` to the directory containing
  it. CMake will then search `${CMAKE_PREFIX_PATH}/lib`,
  `${CMAKE_PREFIX_PATH}/include`, etc. For example:

		cmake . -DCMAKE_PREFIX_PATH:PATH=/path/to/my/favorite/installation

- If you have several Fortran or C compilers on your machine, it is
  possible that CMake does not choose the ones you want. Note that when
  you run cmake, it prints lines telling which compilers it is going
  to use. For example :

		-- The Fortran compiler identification is GNU 11.3.0
		-- The C compiler identification is GNU 11.3.0

	So if you want other compilers, remove everything in the build
	directory and run cmake again setting the variables FC and CC to the
	compilers you want. For example:

		rm -r * # in the build directory!
		FC=ifort CC=icc cmake .. -DCMAKE_INSTALL_PREFIX=~/.local

[^1]: On Mac OS, after downloading the application from the CMake web
    site, run it, then click on "How to Install For Command Line Use"
    in the Tools menu.


# Usage

Running the command with argument `-h` will produce a help message:

    $ ml2pl.sh -h
    usage: ml2pl.sh [OPTION]... input-file output-file [pressure-file]

    Interpolates NetCDF variables from model levels to pressure
    levels.

    Options:
       -h                       : this help message
       -p variable              : name of 4-dimensional variable in the input file
                                  or the pressure file containing the
                                  pressure field at model levels
       -v variable[,variable...]: names of variables you want to interpolate,
                                  or extrapolate if target pressure level is below
                                  surface
       -w variable[,variable...]: names of variables you want to interpolate,
                                  or set to 0 if target pressure level is below
                                  surface
       -m variable[,variable...]: names of variables you want to interpolate,
                                  or set to missing if target pressure level is
                                  below surface

The interpolation is linear in logarithm of pressure. The input
variables depend on longitude, latitude, vertical level and
time. There is no constraint on the dimensions.

All computations are done with single-precision real numbers.

input-file, output-file and pressure-file are NetCDF files.

You must list the variables you want to interpolate, each variable
listed after either `-v`, `-w` or `-m`. There must be at least one variable
listed, following either `-v`, `-w` or `-m`. In the same command, you
can have several options `-v`, `-w` or `-m` with associated variables.

The pressure field at model levels can be specified in input-file or
pressure-file either through hybrid coefficients and surface pressure
or directly from 4-dimensional pressure. In both cases, pressure must
be given in Pa and decrease when the index of model level
increases. This is checked quickly in the program. If option `-p` is
not used then the program will look for `ap`, `b` (hybrid
coefficients) and `ps` (surface pressure) in the input file or the
pressure file.

The target pressure levels should be in a text file called
`press_levels.txt` in the current directory at run-time. The first
line of the file is skipped, assuming it is a title line. Pressure
levels should be in hPa, in any order, one value per line. There
should be at least one target pressure level. There is no other
constraint on these values nor on the number of values.

There is [an example for file `press_levels.txt`](press_levels.txt).

## Main memory

The program loops on time index and does not use four-dimensional
(space plus time) variables. So the main memory used depends on
spatial resolution of the fields but not on the number of dates.

If $n_\mathrm{lon}$ is the number of longitudes, $n_\mathrm{lat}$ the
number of latitudes, $n_\mathrm{mod}$ the number of model levels,
$n_\mathrm{var}$ the number of variables to interpolate and
$n_\mathrm{plev}$ the number of target pressure levels, the amount of
main memory used should be approximately :

```math
n_\mathrm{lon} n_\mathrm{lat} [n_\mathrm{mod} (n_\mathrm{var} + 1)
+ n_\mathrm{plev} n_\mathrm{var}] \times 4 B
```

(B is for bytes).
