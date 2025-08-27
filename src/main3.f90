program main

  use omp_lib, only: omp_get_wtime

  implicit none

  real, dimension(:), allocatable :: a, b
  integer, parameter :: n = 1000000000
  integer :: i

  double precision :: t0, t1
  double precision :: t_hd, t_kernel, t_dh
  double precision :: t_alloc, t_delete

  allocate(a(n))
  allocate(b(n))

  ! Initialise
  a(:) = 1.0
  t0 = omp_get_wtime()
  !$omp target enter data map(alloc:b)
  t1 = omp_get_wtime()
  t_alloc = t1 - t0

  ! Set
  t0 = omp_get_wtime()
  !$omp target teams distribute parallel do map(to:a)
  do i = 1, n
    b(i) = a(i)
  end do
  !$omp end target teams distribute parallel do
  t1 = omp_get_wtime()
  t_hd = t1 - t0

  ! Kernel
  t0 = omp_get_wtime()
  !$omp target teams distribute parallel do
  do i = 1, n
    b(i) = 2 * b(i)
  end do
  !$omp end target teams distribute parallel do
  t1 = omp_get_wtime()
  t_kernel = t1 - t0

  ! Get
  t0 = omp_get_wtime()
  !$omp target teams distribute parallel do map(from:a)
  do i = 1, n
    a(i) = b(i)
  end do
  !$omp end target teams distribute parallel do
  t1 = omp_get_wtime()
  t_dh = t1 - t0

  if (any(a /= 2.0)) then
    error stop
  else
    print *, "PASS"
  end if

  t0 = omp_get_wtime()
  !$omp target exit data map(delete:b)
  t1 = omp_get_wtime()
  t_delete = t1 - t0
  deallocate(a)
  deallocate(b)

  print *, "TIMES (s):"
  print *, "- Alloc: ", t_alloc
  print *, "- Host-Device: ", t_hd
  print *, "- Kernel: ", t_kernel
  print *, "- Device-Host: ", t_dh
  print *, "- Delete: ", t_delete

end program
