!*******************************************************
! fft_fine.f90 - subroutines 
! for fft on the fine mesh. 
! Written by Joachim Harnois-Deraps, 2013/02
!*******************************************************

subroutine cubepm_fftw2(c, thread)
   use omp_lib
   use, intrinsic :: iso_c_binding
   implicit none
   include 'cubepm.fh'
#ifdef MKL
   include 'fftw3.f'
   include 'fftw3_mkl.f'
#else
   include 'fftw3.f03'
#endif

   character c
   integer(4) :: thread
#ifdef NESTED_OMP
   integer(4) :: fft_threads = nested_threads
#else
   integer(4) :: fft_threads = 1
#endif   

   if (firstfftw_nest) then

        call sfftw_init_threads(ierr)
        if (ierr /= 0) then
            write(*,*) "sfftw_init_threads worked with threads: ", fft_threads
        else
            write(*,*) "ERROR returned in sfftw_init_threads: ", rank, ierr
        endif
        firstfftw_nest = .false.

   endif

   if (firstfftw2(thread)) then

      call sfftw_plan_with_nthreads(fft_threads)
      call sfftw_plan_dft_r2c_3d(fftw2_plan(thread),nf_tile,nf_tile,nf_tile,rho_f(:,:,:,thread),rho_f(:,:,:,thread),FFTW_MEASURE)
      call sfftw_plan_dft_c2r_3d(fftw2_iplan(thread),nf_tile,nf_tile,nf_tile,rho_f(:,:,:,thread),rho_f(:,:,:,thread),FFTW_MEASURE)
      call sfftw_plan_with_nthreads(1) !! Call this again to avoid accidentally creating threaded coarse fftw plans

     firstfftw2(thread)=.false.

   endif

   if (c .eq. 'f') then
     call sfftw_execute(fftw2_plan(thread))
   elseif (c .eq. 'b') then
     call sfftw_execute(fftw2_iplan(thread))
     rho_f(:,:,:,thread) = rho_f(:,:,:,thread) / real(nf_tile)**3
   elseif (c .eq. 'q') then
     call sfftw_destroy_plan(fftw2_plan(thread))
     call sfftw_destroy_plan(fftw2_iplan(thread))
   else 
     write(*,*) 'FFT direction error'
   endif

   return
 end subroutine cubepm_fftw2

