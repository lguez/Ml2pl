PROGRAM ml2pl

  ! This is a program in Fortran 2003.
  ! Author: Lionel GUEZ
  ! See general description in the wrapper script.

  use netcdf95, only: nf95_close, nf95_copy_att, nf95_create, nf95_def_dim, &
       nf95_def_var, nf95_enddef, nf95_get_att, nf95_get_var, nf95_gw_var, &
       nf95_inq_dimid, nf95_inq_varid, nf95_inquire_dimension, nf95_open, &
       nf95_put_att, nf95_put_var, nf95_find_coord, nf95_inquire_variable, &
       nf95_clobber, nf95_double, nf95_float, nf95_global, nf95_max_name, &
       nf95_nowrite, nf95_unlimited, NF95_FILL_REAL
  use jumble, only: read_column, assert
  use numer_rec_95, only: regr1_lint, hunt, sort

  IMPLICIT NONE

  INTEGER  iim, n_lat, llm ! dimensions des données avant interpolation
  INTEGER ntim ! nombre de dates

  INTEGER n_plev ! nombre de niveaux de pression en sortie

  REAL, allocatable:: pres(:, :, :) ! (iim, n_lat, llm)
  ! input pressure field, in hPa 

  REAL, allocatable:: ap(:) ! (llm)
  REAL, allocatable:: b(:) ! (llm)
  REAL, allocatable:: ps(:, :) ! (iim, n_lat) surface pressure field, in hPa

  character(len=10) units

  logical hybrid ! pressure is given through ap, b and ps 

  REAL, allocatable:: rlon(:) ! (iim)
  REAL, allocatable:: rlat(:) ! (n_lat)
  double precision, allocatable:: time(:) ! (ntim)

  integer i, j, k, l, n
  integer n_var ! number of variables to interpolate

  ! For NetCDF:
  INTEGER dim_x, dim_y, dim_z, dim_t
  integer, allocatable:: dimids(:)
  INTEGER ncid_in, ncid_out, ncerr
  integer varid_x, varid_y, varid_z, varid_t, varid_t_in, varid, varid_p

  integer, allocatable:: varid_in(:) ! (n_var)
  ! IDs in the input NetCDF file of the variables to interpolate

  integer, allocatable:: varid_out(:) ! (n_var)
  ! IDs in the output NetCDF file of the interpolated variables

  CHARACTER(len=nf95_max_name), allocatable:: varpossib(:) ! (n_var)
  ! names of the NetCDF variables we want to interpolate

  integer nv, nw
  ! Number of variables to extrapolate and to set to 0 below
  ! surface. Other variables are set to missing below
  ! surface. Variable are in the order: extrapolated, set to 0, set to
  ! missing, in "varpossib".

  CHARACTER(len=nf95_max_name) pressure_var

  REAL, allocatable:: var_ml(:, :, :, :) ! (iim, n_lat, llm, n_var)
  ! variables at model levels

  REAL, allocatable:: var_pl(:, :, :, :) ! (iim, n_lat, n_plev, n_var)
  ! variables at pressure levels

  integer surf_loc ! location of surface in target pressure levels

  REAL, allocatable:: plev(:) ! (n_plev)
  ! target pressure levels, in hPa, in descending order

  !---------------------------------------------------------------------

  ! Read the names of the variables:
  call read_column(varpossib, "variable_list_ml2pl")
  n_var =size(varpossib)

  ! Read target pressure levels:
  call read_column(plev, "press_levels.txt", first=2)
  n_plev = size(plev)
  call sort(plev)
  plev = plev(n_plev:1:- 1) ! sort in descending order

  read *, nv, nw, pressure_var

  call nf95_open("input_file_ml2pl.nc", nf95_nowrite, ncid_in)

  ! Read horizontal coordinates:

  call nf95_find_coord(ncid_in, varid=varid, std_name="longitude")
  call nf95_gw_var(ncid_in, varid, rlon)
  iim = size(rlon)

  call nf95_find_coord(ncid_in, varid=varid, std_name="latitude")
  call nf95_gw_var(ncid_in, varid, rlat)
  n_lat = size(rlat)

  ! Read IDs of variables to interpolate:
  allocate(varid_in(n_var))
  do n = 1, n_var
     call nf95_inq_varid(ncid_in, trim(varpossib(n)), varid_in(n))
  end do

  ! Get the number of model levels:
  call nf95_inquire_variable(ncid_in, varid_in(1), dimids=dimids)
  call nf95_inquire_dimension(ncid_in, dimids(3), nclen=llm)

  hybrid = len_trim(pressure_var) == 0

  if (hybrid) then
     print *, 'Using "ap", "b" and "ps" for the input pressure field...'
     allocate(ap(llm), b(llm), ps(iim, n_lat))

     call nf95_inq_varid(ncid_in, 'ps', varid_p)
     call nf95_get_att(ncid_in, varid_p, "units", units)
     call assert(units == "Pa", "ps should be in Pa")

     call nf95_inq_varid(ncid_in, 'ap', varid)
     call nf95_get_var(ncid_in, varid, ap)
     ap = ap / 100. ! convert from Pa to hPa

     call nf95_inq_varid(ncid_in, 'b', varid)
     call nf95_get_var(ncid_in, varid, b)

  else
     print *, 'Using "' // trim(pressure_var) // &
          '" for the input pressure field...'
     call nf95_inq_varid(ncid_in, trim(pressure_var), varid_p)

     call nf95_get_att(ncid_in, varid_p, "units", units)
     call assert(units == "Pa", trim(pressure_var) // " should be in Pa")
  end if

  ! Read time coordinate:
  call nf95_find_coord(ncid_in, varid=varid_t_in, std_name="time")
  if (varid_t_in == 0) then
     print *, "ml2pl: could not find a time coordinate"
     stop 1
  end if
  call nf95_gw_var(ncid_in, varid_t_in, time)
  ntim = size(time)

  call nf95_create("output_file_ml2pl.nc", nf95_clobber, ncid_out)

  call nf95_put_att(ncid_out, nf95_global, 'comment', &
       'interpolated to pressure levels')
  call nf95_def_dim(ncid_out, 'longitude', iim, dim_x)
  call nf95_def_dim(ncid_out, 'latitude', n_lat, dim_y)
  call nf95_def_dim(ncid_out, 'plev', n_plev, dim_z)
  call nf95_def_dim(ncid_out, 'time', nf95_unlimited, dim_t)

  call nf95_def_var(ncid_out, 'longitude', nf95_float, dim_x, varid_x)
  call nf95_put_att(ncid_out, varid_x, 'standard_name', 'longitude')
  call nf95_put_att(ncid_out, varid_x, 'units', 'degrees_east')

  call nf95_def_var(ncid_out, 'latitude', nf95_float, dim_y, varid_y)
  call nf95_put_att(ncid_out, varid_y, 'standard_name', 'latitude')
  call nf95_put_att(ncid_out, varid_y, 'units', 'degrees_north')

  call nf95_def_var(ncid_out, 'plev', nf95_float, dim_z, varid_z)
  call nf95_put_att(ncid_out, varid_z, 'standard_name', 'air_pressure')
  call nf95_put_att(ncid_out, varid_z, 'units', 'hPa')

  call nf95_def_var(ncid_out, 'time', nf95_double, dim_t, varid_t)
  call nf95_put_att(ncid_out, varid_t, 'standard_name', 'time')
  call nf95_copy_att(ncid_in, varid_t_in, 'units', ncid_out, varid_t)
  call nf95_copy_att(ncid_in, varid_t_in, 'calendar', ncid_out, varid_t)

  ! Create interpolated variables:
  allocate(varid_out(n_var))
  do n = 1, n_var
     call nf95_def_var(ncid_out, trim(varpossib(n)), nf95_float, &
          (/dim_x, dim_y, dim_z, dim_t/), varid_out(n))
     call nf95_copy_att(ncid_in, varid_in(n), 'units', ncid_out, &
          varid_out(n), ncerr)
     call nf95_put_att(ncid_out, varid_out(n), "_FillValue", NF95_FILL_REAL)
  end do

  call nf95_enddef(ncid_out)

  ! Horizontal and time coordinates are the same in the input and output files:
  call nf95_put_var(ncid_out, varid_x, rlon)
  call nf95_put_var(ncid_out, varid_y, rlat)
  call nf95_put_var(ncid_out, varid_t, time)

  call nf95_put_var(ncid_out, varid_z, plev)

  allocate(var_ml(iim, n_lat, llm, n_var), var_pl(iim, n_lat, n_plev, n_var))
  allocate(pres(iim, n_lat, llm))

  ! For each date, read the pressure field and all the variables to
  ! interpolate, then interpolate at each horizontal position:
  DO l = 1, ntim
     if (hybrid) then
        call nf95_get_var(ncid_in, varid_p, ps, start=(/1, 1, l/))
        ps = ps / 100. ! convert from Pa to hPa

        forall (k = 1:llm) pres(:, :, k) = ap(k) + b(k) * ps
     else
        call nf95_get_var(ncid_in, varid_p, pres, start=(/1, 1, 1, l/))
        pres = pres / 100. ! convert from Pa to hPa
     end if

     ! Quick check:
     call assert(pres(1, 1, 1) > pres(1, 1, 2), &
          "Input pressure field should decrease with increasing level index")

     do n = 1, n_var
        call nf95_get_var(ncid_in, varid_in(n), var_ml(:, :, :, n), &
             start=(/1, 1, 1, l/))
     end do

     if (nv >= 1) then
        ! Variables extrapolated below surface
        do j = 1, n_lat
           do i = 1, iim
              var_pl(i, j, :, :nv) = regr1_lint(var_ml(i, j, :, :nv), &
                   xs = log(pres(i, j, :)), xt = log(plev))
           end do
        end do
     end if

     if (nv < n_var) then
        ! Variables set to 0 or missing below surface
        surf_loc = 1 ! first guess

        do j = 1, n_lat
           do i = 1, iim
              call hunt(plev, pres(i, j, 1), surf_loc)
              ! {plev(surf_loc + 1) <= pres(i, j, 1) <=  plev(surf_loc)}

              var_pl(i, j, :surf_loc, nv + 1: nv + nw) = 0.
              var_pl(i, j, :surf_loc, nv + nw + 1:) = NF95_FILL_REAL

              var_pl(i, j, surf_loc + 1:, nv + 1:) &
                   = regr1_lint(var_ml(i, j, :, nv + 1:), &
                   xs = log(pres(i, j, :)), xt = log(plev(surf_loc + 1:)))
           end do
        end do
     end if

     do n = 1, n_var
        call nf95_put_var(ncid_out, varid_out(n), var_pl(:, :, :, n), &
             start=(/1, 1, 1, l/))
     end DO
  end do

  call nf95_close(ncid_out)
  call nf95_close(ncid_in)

END PROGRAM ml2pl
