!! add mass to fine mesh density within tile
#ifdef NEUTRINOS
subroutine fine_cic_mass(pp,tile,thread,ONLYPID)
#else
subroutine fine_cic_mass(pp,tile,thread)
#endif
    implicit none

    include 'cubepm.fh'

    integer(4) :: pp,thread
    integer(4), dimension(3) :: tile
    integer(4), dimension(3) :: i1, i2
    real(4), dimension(3) :: x, offset, dx1, dx2
#ifdef NEUTRINOS
    integer(1), optional :: ONLYPID
    real(4) :: fpp
    logical :: DO_ONLYPID = .false.
    if (present(ONLYPID)) DO_ONLYPID = .true.
#endif

    offset(:)= - tile(:) * nf_physical_tile_dim + nf_buf !- 0.5 

#ifndef NEUTRINOS

    do
      if (pp == 0) exit
      x(:) = xv(1:3,pp) + offset(:)
      i1(:) = floor(x(:)) + 1
      i2(:) = i1(:) + 1
      dx1(:) = i1(:) - x(:)
      dx2(:) = 1 - dx1(:)

      dx1(1) = mass_p * dx1(1)
      dx2(1) = mass_p * dx2(1)

      rho_f(i1(1),i1(2),i1(3),thread) = rho_f(i1(1),i1(2),i1(3),thread) &
                                       + dx1(1) * dx1(2) * dx1(3)
      rho_f(i2(1),i1(2),i1(3),thread) = rho_f(i2(1),i1(2),i1(3),thread) &
                                       + dx2(1) * dx1(2) * dx1(3)
      rho_f(i1(1),i2(2),i1(3),thread) = rho_f(i1(1),i2(2),i1(3),thread) &
                                       + dx1(1) * dx2(2) * dx1(3)
      rho_f(i2(1),i2(2),i1(3),thread) = rho_f(i2(1),i2(2),i1(3),thread) &
                                       + dx2(1) * dx2(2) * dx1(3)
      rho_f(i1(1),i1(2),i2(3),thread) = rho_f(i1(1),i1(2),i2(3),thread) &
                                       + dx1(1) * dx1(2) * dx2(3)
      rho_f(i2(1),i1(2),i2(3),thread) = rho_f(i2(1),i1(2),i2(3),thread) &
                                       + dx2(1) * dx1(2) * dx2(3)
      rho_f(i1(1),i2(2),i2(3),thread) = rho_f(i1(1),i2(2),i2(3),thread) &
                                       + dx1(1) * dx2(2) * dx2(3)
      rho_f(i2(1),i2(2),i2(3),thread) = rho_f(i2(1),i2(2),i2(3),thread) &
                                       + dx2(1) * dx2(2) * dx2(3)
      pp = ll(pp)
    enddo

#else

  if (.not. DO_ONLYPID) then

    do
      if (pp == 0) exit
      x(:) = xv(1:3,pp) + offset(:)
      i1(:) = floor(x(:)) + 1
      i2(:) = i1(:) + 1
      dx1(:) = i1(:) - x(:)
      dx2(:) = 1 - dx1(:)

      dx1(1) = mass_p * dx1(1) * mass_p_nudm_fac(PID(pp)) 
      dx2(1) = mass_p * dx2(1) * mass_p_nudm_fac(PID(pp))

      rho_f(i1(1),i1(2),i1(3),thread) = rho_f(i1(1),i1(2),i1(3),thread) &
                                       + dx1(1) * dx1(2) * dx1(3)
      rho_f(i2(1),i1(2),i1(3),thread) = rho_f(i2(1),i1(2),i1(3),thread) &
                                       + dx2(1) * dx1(2) * dx1(3)
      rho_f(i1(1),i2(2),i1(3),thread) = rho_f(i1(1),i2(2),i1(3),thread) &
                                       + dx1(1) * dx2(2) * dx1(3)
      rho_f(i2(1),i2(2),i1(3),thread) = rho_f(i2(1),i2(2),i1(3),thread) &
                                       + dx2(1) * dx2(2) * dx1(3)
      rho_f(i1(1),i1(2),i2(3),thread) = rho_f(i1(1),i1(2),i2(3),thread) &
                                       + dx1(1) * dx1(2) * dx2(3)
      rho_f(i2(1),i1(2),i2(3),thread) = rho_f(i2(1),i1(2),i2(3),thread) &
                                       + dx2(1) * dx1(2) * dx2(3)
      rho_f(i1(1),i2(2),i2(3),thread) = rho_f(i1(1),i2(2),i2(3),thread) &
                                       + dx1(1) * dx2(2) * dx2(3)
      rho_f(i2(1),i2(2),i2(3),thread) = rho_f(i2(1),i2(2),i2(3),thread) &
                                       + dx2(1) * dx2(2) * dx2(3)
      pp = ll(pp)
    enddo

  else !! When doing halofind and projections want to include only one type of particle 

    if (ONLYPID == 1) then
        fpp = 1.
    else
        fpp = 1./real(ratio_nudm_dim)**3
    endif

    do
      if (pp == 0) exit
      x(:) = xv(1:3,pp) + offset(:)
      i1(:) = floor(x(:)) + 1
      i2(:) = i1(:) + 1
      dx1(:) = i1(:) - x(:)
      dx2(:) = 1 - dx1(:)

      if (PID(pp) == ONLYPID) then !! This is the particle we want 

          dx1(1) = mass_p * dx1(1) * fpp
          dx2(1) = mass_p * dx2(1) * fpp

          rho_f(i1(1),i1(2),i1(3),thread) = rho_f(i1(1),i1(2),i1(3),thread) &
                                       + dx1(1) * dx1(2) * dx1(3)
          rho_f(i2(1),i1(2),i1(3),thread) = rho_f(i2(1),i1(2),i1(3),thread) &
                                       + dx2(1) * dx1(2) * dx1(3)
          rho_f(i1(1),i2(2),i1(3),thread) = rho_f(i1(1),i2(2),i1(3),thread) &
                                       + dx1(1) * dx2(2) * dx1(3)
          rho_f(i2(1),i2(2),i1(3),thread) = rho_f(i2(1),i2(2),i1(3),thread) &
                                       + dx2(1) * dx2(2) * dx1(3)
          rho_f(i1(1),i1(2),i2(3),thread) = rho_f(i1(1),i1(2),i2(3),thread) &
                                       + dx1(1) * dx1(2) * dx2(3)
          rho_f(i2(1),i1(2),i2(3),thread) = rho_f(i2(1),i1(2),i2(3),thread) &
                                       + dx2(1) * dx1(2) * dx2(3)
          rho_f(i1(1),i2(2),i2(3),thread) = rho_f(i1(1),i2(2),i2(3),thread) &
                                       + dx1(1) * dx2(2) * dx2(3)
          rho_f(i2(1),i2(2),i2(3),thread) = rho_f(i2(1),i2(2),i2(3),thread) &
                                       + dx2(1) * dx2(2) * dx2(3)

      endif

      pp = ll(pp)
    enddo

  endif

#endif

end subroutine fine_cic_mass
