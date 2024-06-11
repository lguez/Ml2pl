#!/bin/bash

# Author: Lionel GUEZ

# Set up the necessary environment:
if [[ -f @CMAKE_INSTALL_FULL_LIBEXECDIR@/ml2pl_runtime_env.sh ]]
then
    source @CMAKE_INSTALL_FULL_LIBEXECDIR@/ml2pl_runtime_env.sh
fi

@CMAKE_INSTALL_FULL_LIBEXECDIR@/ml2pl.py $*
