cmake_minimum_required(VERSION 3.14)
project(Ml2pl Fortran)

find_path(netcdf95_INCLUDE_DIR netcdf95.mod)
find_library(netcdf95_LIBRARY netcdf95)

find_path(netcdff_INCLUDE_DIR netcdf.mod)
find_library(netcdff_LIBRARY netcdff)

find_path(numer_rec_95_INCLUDE_DIR numer_rec_95.mod)
find_library(numer_rec_95_LIBRARY numer_rec_95)

find_path(jumble_INCLUDE_DIR jumble.mod)
find_library(jumble_LIBRARY jumble)

find_path(nr_util_INCLUDE_DIR nr_util.mod)
find_library(nr_util_LIBRARY nr_util)

find_package(NetCDF REQUIRED)

add_executable(ml2pl ml2pl.f90)

target_include_directories(ml2pl PRIVATE ${netcdf95_INCLUDE_DIR}
  ${netcdff_INCLUDE_DIR})

target_link_libraries(ml2pl ${netcdf95_LIBRARY} ${netcdff_LIBRARY}
  ${NetCDF_LIBRARY} ${numer_rec_95_LIBRARY} ${jumble_LIBRARY}
  ${nr_util_LIBRARY})

include(ConfigureCompilerFlags)
