cmake_minimum_required(VERSION 3.16...3.27)
set(CMAKE_BUILD_TYPE Release CACHE STRING
  "Choose the type of build: Debug,Release...")
project(Ml2pl VERSION 0.7 LANGUAGES Fortran)
include(FetchContent)
FetchContent_Declare(LG_cmake_utils GIT_REPOSITORY
  https://gitlab.in2p3.fr/guez/cmake.git GIT_TAG 517d97c3)
FetchContent_MakeAvailable(LG_cmake_utils)
list(APPEND CMAKE_MODULE_PATH "${lg_cmake_utils_SOURCE_DIR}")
option(FETCH "Download")

if(FETCH)
  FetchContent_Declare(Jumble GIT_REPOSITORY
    https://github.com/lguez/Jumble.git GIT_TAG e4c47ce3)
  FetchContent_Declare(NetCDF95 GIT_REPOSITORY
    https://github.com/lguez/NetCDF95.git GIT_TAG 48b5834)
  FetchContent_Declare(Numer_Rec_95 GIT_REPOSITORY
    https://gitlab.in2p3.fr/guez/Numer_Rec_95.git GIT_TAG 2dce7325)
  FetchContent_MakeAvailable(Jumble NetCDF95 Numer_Rec_95)
else()
  foreach(my_package IN ITEMS NetCDF95 Jumble Numer_Rec_95)
    find_package(${my_package} CONFIG)
    
    if (NOT ${my_package}_FOUND)
      message(FATAL_ERROR
	"${my_package} not found, consider the option of cmake:-DFETCH=ON")
    endif()
  endforeach()
endif()

add_executable(ml2pl ml2pl.f90)
target_link_libraries(ml2pl PRIVATE NetCDF95::netcdf95 Jumble::jumble
  Numer_Rec_95::numer_rec_95)
include(GNUInstallDirs)
install(TARGETS ml2pl DESTINATION ${CMAKE_INSTALL_LIBEXECDIR})
configure_file(ml2pl_in.py ml2pl.py @ONLY)
install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/ml2pl.py TYPE BIN)
