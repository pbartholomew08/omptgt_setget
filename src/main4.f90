module m_four

  implicit none

  private
  public :: container_t

  type :: container_t
    real, dimension(:), pointer :: b
    real, dimension(:, :), pointer :: bptr
  contains
    final :: destroy_container
  end type

  interface container_t
    procedure init_container
  end interface

contains

  type(container_t) function init_container(n) result(c)
    integer, intent(in) :: n
    integer :: m

    m = int(sqrt(real(n)))
    allocate(c%b(n))
    c%bptr(1:m, 1:m) => c%b(1:m*m)

    !$omp target enter data map(alloc:c%b)
    !$omp target enter data map(to:c%bptr)

  end function

  subroutine destroy_container(self)
    type(container_t) :: self

    if (associated(self%bptr)) then
      !$omp target exit data map(delete:self%bptr)
      nullify(self%bptr)
    end if

    if (allocated(self%b)) then
      !$omp target exit data map(delete:self%b)
      deallocate(self%b)
      nullify(self%b)
    end if

  end subroutine

end module

program main

  use m_four

  implicit none

  real, dimension(:), allocatable :: a
  type(container_t) :: c
  integer, parameter :: n = 1000000000
  integer, parameter :: m = int(sqrt(real(n)))
  integer :: i, j

  allocate(a(n))
  c = container_t(n)

  ! Initialise
  a(:) = 1.0

  ! Set
  !$omp target teams distribute parallel do map(to:a)
  do i = 1, n
    c%b(i) = a(i)
  end do
  !$omp end target teams distribute parallel do

  ! Kernel
  !$omp target teams distribute parallel do collapse(2)
  do i = 1, m
    do j = 1, m
      c%bptr(i, j) = 2 * c%bptr(i, j)
    end do
  end do
  !$omp end target teams distribute parallel do

  ! Get
  !$omp target teams distribute parallel do map(from:a)
  do i = 1, n
    a(i) = c%b(i)
  end do
  !$omp end target teams distribute parallel do

  if (any(a(1:m*m) /= 2.0)) then
    error stop
  else
    print *, "PASS"
  end if

  deallocate(a)

end program
