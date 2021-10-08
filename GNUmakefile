# This is a makefile for GNU make.

# 1. Compiler-dependent part

FC = gfortran
FFLAGS = -O3 -I${HOME}/.local/include -I/usr/include

LDLIBS = -L${HOME}/.local/lib -lnumer_rec_95 -ljumble -lnetcdf95 -lnr_util -lnetcdff

# 2. Rules

%: %.f90
	$(LINK.f) $^ $(LOADLIBES) $(LDLIBS) -o $@

ml2pl:
.PHONY: clean

clean:
	-rm ml2pl
