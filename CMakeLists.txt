cmake_minimum_required(VERSION 3.14)
project(Ml2pl LANGUAGES Fortran)
set(CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR})
find_package(NetCDF95 REQUIRED CONFIG)
find_package(NR_util REQUIRED CONFIG)
find_package(Jumble REQUIRED CONFIG)
find_package(Numer_Rec_95 REQUIRED CONFIG)
find_package(NetCDF REQUIRED)
find_package(NetCDF_Fortran REQUIRED)
add_executable(ml2pl ml2pl.f90)

target_link_libraries(ml2pl netcdf95 jumble numer_rec_95
  NetCDF_Fortran::netcdff)
