#!/usr/bin/env python3

"""Interpolates NetCDF variables from model levels to pressure levels.

The target pressure levels should be in a file called
"press_levels.txt", in the same unit as input pressure field. For
further information, see https://github.com/lguez/Ml2pl.

Author: Lionel GUEZ

Do not run several instances of this script in parallel in the same
directory. File names are not made different for different instances.

"""

# This script is a wrapper for a Fortran program. For an explanation
# of programming choices, see notes.

import argparse
import sys
import os
import subprocess

# Absolute path to Fortran executable:
executable = "@CMAKE_INSTALL_FULL_LIBEXECDIR@/ml2pl"

parser = argparse.ArgumentParser(
    prog="ml2pl.sh",
    description=__doc__,
    formatter_class=argparse.RawDescriptionHelpFormatter,
)
parser.add_argument("input_file")
parser.add_argument("output_file")
parser.add_argument("pressure_file", nargs="?")
parser.add_argument(
    "-p",
    "--pressure_var",
    metavar="VARIABLE",
    help="name of 4-dimensional variable in the input file or in the pressure "
    "file containing the pressure field at model levels",
    default="",
)
parser.add_argument(
    "-v",
    metavar="VARIABLE",
    action="append",
    help="name of variable you want to interpolate, or extrapolate if "
    "target pressure level is below surface",
)
parser.add_argument(
    "-w",
    metavar="VARIABLE",
    action="append",
    help="name of variable you want to interpolate, or set to 0 if target "
    "pressure level is below surface",
)
parser.add_argument(
    "-m",
    metavar="VARIABLE",
    action="append",
    help="name of variable you want to interpolate, or set to missing if "
    "target pressure level is below surface",
)
args = parser.parse_args()

if not (args.v or args.w or args.m):
    sys.exit(
        "Specify at least one variable, following -v, -w or -m.\n"
        "Use option -h for help"
    )

if not os.access(executable, os.X_OK):
    sys.exit(f"{executable} not found or not executable")

if not os.access(args.input_file, os.R_OK):
    sys.exit(f"ml2pl.sh: {args.input_file} not found")

if not os.access("press_levels.txt", os.R_OK):
    sys.exit("ml2pl.sh: press_levels.txt not found\nUse option -h for help")

if args.pressure_file and not os.access(args.pressure_file, os.R_OK):
    sys.exit(f"ml2pl.sh: {args.pressure_file} not found")

if not args.v:
    args.v = []

if not args.w:
    args.w = []

if not args.m:
    args.m = []

nv = len(args.v)
nw = len(args.w)

# Create the list of variables:
with open("variable_list_ml2pl.txt", "w") as f_obj:
    for my_var in args.v + args.w + args.m:
        print(my_var, file=f_obj)

# Run the Fortran program:

subp_args = [executable, args.input_file]

if args.pressure_file:
    subp_args.append(args.pressure_file)

subprocess.run(
    subp_args,
    text=True,
    input=f'{nv}\n{nw}\n"{args.pressure_var}"\n',
    check=True,
)
# (Quotes around $pressure_var are necessary for the case when
# pressure_var is not defined.)

os.rename("output_file_ml2pl.nc", args.output_file)

# Clean up:
os.remove("variable_list_ml2pl.txt")
