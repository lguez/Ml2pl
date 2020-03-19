cmake_minimum_required(VERSION 3.14)
project(Ml2pl Fortran)
set(CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR})

find_package(NetCDF95 REQUIRED CONFIG)
find_package(NR_util REQUIRED CONFIG)
find_package(Jumble REQUIRED CONFIG)
find_package(Numer_Rec_95 REQUIRED CONFIG)
find_path(netcdff_INCLUDE_DIR netcdf.mod)
find_package(NetCDF REQUIRED)

add_executable(ml2pl ml2pl.f90)
target_include_directories(ml2pl PRIVATE ${netcdff_INCLUDE_DIR})
target_link_libraries(ml2pl netcdf95 jumble numer_rec_95)

include(ConfigureCompilerFlags)
