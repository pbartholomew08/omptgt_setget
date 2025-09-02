program main

  use m_four

  implicit none

  real, dimension(:), allocatable :: a
  type(container_t) :: c
  integer, parameter :: n = 1000000000
  integer :: i, j

  allocate(a(n))
  c = container_t(n)

  ! Initialise
  a(:) = 1.0

  ! Set
  call c%set(a)

  ! ! Kernel
  call c%kernel()

  ! ! Get
  call c%get(a)

  if (any(a(1:c%m*c%m) /= 2.0)) then
    error stop
  else
    print *, "PASS"
  end if

  deallocate(a)

end program
