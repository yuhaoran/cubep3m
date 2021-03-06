!! add mass to fine mesh density within tile using nearest gridpoint scheme

#ifdef NEUTRINOS
subroutine fine_ngp_mass(pp,tile,thread,ONLYPID)
#else
subroutine fine_ngp_mass(pp,tile,thread)
#endif
    implicit none

    include 'cubepm.fh'

    integer(4)               :: pp,thread
    integer(4), dimension(3) :: tile,i1
    real(4),    dimension(3) :: x, offset
#ifdef NEUTRINOS
    integer(1), optional :: ONLYPID
    real(4) :: fpp
    logical :: DO_ONLYPID = .false.
    if (present(ONLYPID)) DO_ONLYPID = .true.
#endif

    offset(:)= - tile(:) * nf_physical_tile_dim + nf_buf 
! removed the half-cell offset so that fine mesh cells will line up with coarse mesh cells
!    offset(:)= - tile(:) * nf_physical_tile_dim + nf_buf - 0.5

#ifndef NEUTRINOS

    do
      if (pp == 0) exit
      x(:) = xv(1:3,pp) + offset(:)
      i1(:) = floor(x(:)) + 1
      rho_f(i1(1),i1(2),i1(3),thread) = rho_f(i1(1),i1(2),i1(3),thread)+mass_p
      pp = ll(pp)
    enddo

#else

      if (.not. DO_ONLYPID) then

      do
        if (pp == 0) exit
        x(:) = xv(1:3,pp) + offset(:)
        i1(:) = floor(x(:)) + 1
        rho_f(i1(1),i1(2),i1(3),thread) = rho_f(i1(1),i1(2),i1(3),thread) + mass_p*mass_p_nudm_fac(PID(pp))
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
        if (PID(pp) == ONLYPID) then !! This is the particle we want 
          rho_f(i1(1),i1(2),i1(3),thread) = rho_f(i1(1),i1(2),i1(3),thread)+mass_p*fpp
        endif
        pp = ll(pp)
      enddo

    endif

#endif

end subroutine fine_ngp_mass
