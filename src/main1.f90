program main

  implicit none

  real, dimension(:), allocatable :: a, b
  integer, parameter :: n = 1000000000
  integer :: i

  allocate(a(n))
  allocate(b(n))

  ! Initialise
  a(:) = 1.0

  ! Set
  !$omp target teams distribute parallel do
  do i = 1, n
    b(i) = a(i)
  end do
  !$omp end target teams distribute parallel do

  ! Kernel
  !$omp target teams distribute parallel do
  do i = 1, n
    b(i) = 2 * b(i)
  end do
  !$omp end target teams distribute parallel do

  ! Get
  !$omp target teams distribute parallel do
  do i = 1, n
    a(i) = b(i)
  end do
  !$omp end target teams distribute parallel do

  if (any(a /= 2.0)) then
    error stop
  else
    print *, "PASS"
  end if

  deallocate(a)
  deallocate(b)

end program
