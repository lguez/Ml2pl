PROGRAM ml2pl

  ! This is a program in Fortran 2003.
  ! Author: Lionel GUEZ
  ! See general description in the wrapper script.

  ! pres, ap, ps and plev are in the same unit.

  use, intrinsic:: ISO_FORTRAN_ENV

  ! Libraries:
  use jumble, only: read_column, assert, get_command_arg_dyn
  use netcdf95, only: nf95_close, nf95_copy_att, nf95_create, nf95_def_dim, &
       nf95_def_var, nf95_enddef, nf95_get_att, nf95_get_var, nf95_gw_var, &
       nf95_inq_dimid, nf95_inq_varid, nf95_inquire_dimension, nf95_open, &
       nf95_put_att, nf95_put_var, nf95_find_coord, nf95_inquire_variable, &
       nf95_clobber, nf95_double, nf95_float, nf95_global, nf95_max_name, &
       nf95_nowrite, nf95_unlimited, NF95_FILL_REAL, nf95_inq_varnatts, &
       nf95_inq_attname, nf95_noerr, nf95_get_missing
  use numer_rec_95, only: regr1_lint, hunt, sort

  IMPLICIT NONE

  INTEGER  n_lon, n_lat, llm ! dimensions des données avant interpolation
  INTEGER ntim ! nombre de dates
  INTEGER n_plev ! nombre de niveaux de pression en sortie

  REAL, allocatable:: pres(:, :, :) ! (n_lon, n_lat, llm) Input
  ! pressure field at model levels. Should decrease with increasing
  ! level index.

  REAL, allocatable:: ap(:) ! (llm)
  REAL, allocatable:: b(:) ! (llm)
  REAL, allocatable:: ps(:, :) ! (n_lon, n_lat) surface pressure field
  logical hybrid ! pressure is given through ap, b and ps
  REAL, allocatable:: rlon(:) ! (n_lon)
  REAL, allocatable:: rlat(:) ! (n_lat)
  double precision, allocatable:: time(:) ! (ntim)
  integer i, j, k, l, n, attnum
  integer n_var ! number of variables to interpolate

  ! For NetCDF:
  INTEGER dim_x, dim_y, dim_z, dim_t
  integer, allocatable:: dimids(:)
  INTEGER ncid_in, ncid_out, ncerr, ncid_pres_in
  integer varid_x, varid_y, varid_z, varid_t, varid_t_in, varid, varid_p, nvatts

  integer, allocatable:: varid_in(:) ! (n_var)
  ! IDs in the input NetCDF file of the variables to interpolate

  integer, allocatable:: varid_out(:) ! (n_var)
  ! IDs in the output NetCDF file of the interpolated variables

  CHARACTER(len = nf95_max_name), allocatable:: varpossib(:) ! (n_var)
  ! names of the NetCDF variables we want to interpolate

  integer nv, nw
  ! Number of variables to extrapolate and to set to 0 below
  ! surface. Other variables are set to missing below
  ! surface. Variable are in the order: extrapolated, set to 0, set to
  ! missing, in "varpossib".

  CHARACTER(len = nf95_max_name) pressure_var, lon_name, lat_name, time_name
  character(len = :), allocatable:: name, input_file, pressure_file

  REAL, allocatable:: var_ml(:, :, :, :) ! (n_lon, n_lat, llm, n_var)
  ! variables at model levels

  REAL, allocatable:: var_pl(:, :, :, :) ! (n_lon, n_lat, n_plev, n_var)
  ! variables at pressure levels

  integer surf_loc ! location of surface in target pressure levels

  REAL, allocatable:: plev(:) ! (n_plev)
  ! target pressure levels, in descending order

  real p0 ! reference_air_pressure_for_atmosphere_vertical_coordinate
  logical, allocatable:: mask(:, :), descending_pressure(:, :)
  real missing ! missing value for NetCDF variable ps or pressure_var

  !---------------------------------------------------------------------

  call get_command_arg_dyn(1, input_file)
  ! Read the names of the variables:
  call read_column(varpossib, "variable_list_ml2pl.txt")
  n_var = size(varpossib)

  ! Read target pressure levels:
  call read_column(plev, "press_levels.txt", first = 2)
  n_plev = size(plev)
  call assert(n_plev >= 1, "ml2pl: no value found in press_levels.txt")
  call sort(plev)
  plev = plev(n_plev:1:- 1) ! sort in descending order
  call assert(all(plev(:n_plev - 1) /= plev(2:)), &
       "Pressure levels should be distinct")

  read *, nv, nw, pressure_var
  call nf95_open(input_file, nf95_nowrite, ncid_in)

  ! Read horizontal coordinates:

  ! Longitude:
  call nf95_find_coord(ncid_in, varid = varid, std_name = "longitude", &
       name = lon_name)
  call nf95_gw_var(ncid_in, varid, rlon)
  n_lon = size(rlon)

  ! Latitude:
  call nf95_find_coord(ncid_in, varid = varid, std_name = "latitude", &
       name = lat_name)
  call nf95_gw_var(ncid_in, varid, rlat)
  n_lat = size(rlat)

  ! Read IDs of variables to interpolate:
  allocate(varid_in(n_var))
  do n = 1, n_var
     call nf95_inq_varid(ncid_in, trim(varpossib(n)), varid_in(n))
  end do

  ! Get the number of model levels:
  call nf95_inquire_variable(ncid_in, varid_in(1), dimids = dimids)
  call nf95_inquire_dimension(ncid_in, dimids(3), nclen = llm)

  if (command_argument_count() == 1) then
     ncid_pres_in = ncid_in
  else
     ! {command_argument_count() == 2}
     call get_command_arg_dyn(2, pressure_file)
     call nf95_open(pressure_file, nf95_nowrite, ncid_pres_in)
  end if

  hybrid = len_trim(pressure_var) == 0

  if (hybrid) then
     print *, 'Using "ap", "b" and "ps" for the input pressure field...'
     allocate(ps(n_lon, n_lat))
     call nf95_inq_varid(ncid_pres_in, 'ps', varid_p)
     call nf95_inq_varid(ncid_pres_in, 'ap', varid, ncerr)

     if (ncerr == nf95_noerr) then
        call nf95_gw_var(ncid_pres_in, varid, ap)
     else
        print *, "ap not found, computing it from `a` and p0..."
        call nf95_inq_varid(ncid_pres_in, 'a', varid)
        call nf95_gw_var(ncid_pres_in, varid, ap)
        call nf95_inq_varid(ncid_pres_in, 'p0', varid)
        call nf95_get_var(ncid_pres_in, varid, p0)
        ap = ap * p0
     end if

     call nf95_inq_varid(ncid_pres_in, 'b', varid)
     call nf95_gw_var(ncid_pres_in, varid, b)

     if (size(ap) == llm + 1) then
        print *, "ap has one more element than the number of model levels."
        print *, "We will use mid-values of ap and b..."
        ap = (ap(:llm) + ap(2:)) / 2.
        b = (b(:llm) + b(2:)) / 2.
     else if (size(ap) /= llm) then
        write(error_unit, fmt = *) "ml2pl error: different sizes"
        write(error_unit, fmt = *) "size(ap) = ", size(ap)
        write(error_unit, fmt = *) "size(", trim(varpossib(1)), ", 3) = ", llm
        stop 1
     end if
  else
     print *, 'Using "' // trim(pressure_var) // &
          '" for the input pressure field...'
     call nf95_inq_varid(ncid_pres_in, trim(pressure_var), varid_p)
  end if

  call nf95_get_missing(ncid_pres_in, varid_p, missing)

  ! Read time coordinate:

  call nf95_find_coord(ncid_in, varid = varid_t_in, std_name = "time", &
       name = time_name)

  if (varid_t_in == 0) then
     print *, "ml2pl: could not find a time coordinate"
     stop 1
  end if

  call nf95_gw_var(ncid_in, varid_t_in, time)
  ntim = size(time)

  call nf95_create("output_file_ml2pl.nc", nf95_clobber, ncid_out)
  call nf95_put_att(ncid_out, nf95_global, 'comment', &
       'interpolated to pressure levels by ml2pl')
  call nf95_def_dim(ncid_out, lon_name, n_lon, dim_x)
  call nf95_def_dim(ncid_out, lat_name, n_lat, dim_y)
  call nf95_def_dim(ncid_out, 'plev', n_plev, dim_z)
  call nf95_def_dim(ncid_out, time_name, nf95_unlimited, dim_t)

  ! Longitude:
  call nf95_def_var(ncid_out, lon_name, nf95_float, dim_x, varid_x)
  call nf95_put_att(ncid_out, varid_x, 'standard_name', 'longitude')
  call nf95_put_att(ncid_out, varid_x, 'units', 'degrees_east')

  ! Latitude:
  call nf95_def_var(ncid_out, lat_name, nf95_float, dim_y, varid_y)
  call nf95_put_att(ncid_out, varid_y, 'standard_name', 'latitude')
  call nf95_put_att(ncid_out, varid_y, 'units', 'degrees_north')

  ! Pressure level:
  call nf95_def_var(ncid_out, 'plev', nf95_float, dim_z, varid_z)
  call nf95_put_att(ncid_out, varid_z, 'standard_name', 'air_pressure')
  call nf95_copy_att(ncid_pres_in, varid_p, 'units', ncid_out, varid_z)

  ! Time:
  call nf95_def_var(ncid_out, time_name, nf95_double, dim_t, varid_t)
  call nf95_put_att(ncid_out, varid_t, 'standard_name', 'time')
  call nf95_copy_att(ncid_in, varid_t_in, 'units', ncid_out, varid_t)
  call nf95_copy_att(ncid_in, varid_t_in, 'calendar', ncid_out, varid_t)

  ! Create interpolated variables:

  allocate(varid_out(n_var))

  do n = 1, n_var
     call nf95_def_var(ncid_out, trim(varpossib(n)), nf95_float, &
          [dim_x, dim_y, dim_z, dim_t], varid_out(n))
     call nf95_copy_att(ncid_in, varid_in(n), 'units', ncid_out, &
          varid_out(n), ncerr)
     call nf95_put_att(ncid_out, varid_out(n), "_FillValue", NF95_FILL_REAL)
  end do

  ! Copy all global attributes:

  call nf95_inq_varnatts(ncid_in, NF95_GLOBAL, nvatts)

  do attnum = 1, nvatts
     call nf95_inq_attname(ncid_in, NF95_GLOBAL, attnum, name)
     call nf95_copy_att(ncid_in, NF95_GLOBAL, name, ncid_out, NF95_GLOBAL)
  end do

  call nf95_enddef(ncid_out)

  ! Horizontal and time coordinates are the same in the input and output files:
  call nf95_put_var(ncid_out, varid_x, rlon)
  call nf95_put_var(ncid_out, varid_y, rlat)
  call nf95_put_var(ncid_out, varid_t, time)

  call nf95_put_var(ncid_out, varid_z, plev)
  allocate(var_ml(n_lon, n_lat, llm, n_var), mask(n_lon, n_lat), &
       var_pl(n_lon, n_lat, n_plev, n_var), pres(n_lon, n_lat, llm), &
       descending_pressure(n_lon, n_lat))

  ! For each date, read the pressure field and all the variables to
  ! interpolate, then interpolate at each horizontal position:
  loop_time: DO l = 1, ntim
     if (hybrid) then
        call nf95_get_var(ncid_pres_in, varid_p, ps, start = [1, 1, l])
        mask = ps /= missing

        forall (k = 1:llm)
           where(mask) pres(:, :, k) = ap(k) + b(k) * ps
        end forall
     else
        call nf95_get_var(ncid_pres_in, varid_p, pres, start = [1, 1, 1, l])
        mask = pres(:, :, 1) /= missing
     end if

     ! Quick check:

     where(mask)
        descending_pressure = pres(:, :, 1) > pres(:, :, 2)
     elsewhere
        descending_pressure = .true.
     end where

     call assert(all(descending_pressure), &
          "Input pressure field should decrease with increasing level index")

     do n = 1, n_var
        call nf95_get_var(ncid_in, varid_in(n), var_ml(:, :, :, n), &
             start = [1, 1, 1, l])
     end do

     if (nv >= 1) then
        ! Variables extrapolated below surface
        do j = 1, n_lat
           do i = 1, n_lon
              if (mask(i, j)) then
                 var_pl(i, j, :, :nv) = regr1_lint(var_ml(i, j, :, :nv), &
                      xs = log(pres(i, j, :)), xt = log(plev))
              else
                 var_pl(i, j, :, :nv) = NF95_FILL_REAL
              end if
           end do
        end do
     end if

     if (nv < n_var) then
        ! Variables set to 0 or missing below surface
        surf_loc = 1 ! first guess

        do j = 1, n_lat
           do i = 1, n_lon
              if (mask(i, j)) then
                 if (n_plev >= 2) then
                    call hunt(plev, pres(i, j, 1), surf_loc)
                    ! {plev(surf_loc + 1) <= pres(i, j, 1) <=  plev(surf_loc)}
                 else
                    ! n_plev == 1
                    surf_loc = merge(0, 1, plev(1) <= pres(i, j, 1))
                 end if

                 var_pl(i, j, :surf_loc, nv + 1: nv + nw) = 0.
                 var_pl(i, j, :surf_loc, nv + nw + 1:) = NF95_FILL_REAL

                 var_pl(i, j, surf_loc + 1:, nv + 1:) &
                      = regr1_lint(var_ml(i, j, :, nv + 1:), &
                      xs = log(pres(i, j, :)), xt = log(plev(surf_loc + 1:)))
              else
                 var_pl(i, j, :, nv + 1:) = NF95_FILL_REAL
              end if
           end do
        end do
     end if

     do n = 1, n_var
        call nf95_put_var(ncid_out, varid_out(n), var_pl(:, :, :, n), &
             start = [1, 1, 1, l])
     end DO
  end do loop_time

  call nf95_close(ncid_out)
  if (ncid_pres_in /= ncid_in) call nf95_close(ncid_pres_in)
  call nf95_close(ncid_in)

END PROGRAM ml2pl
