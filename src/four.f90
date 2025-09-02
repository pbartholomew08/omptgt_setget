module m_four

  use iso_c_binding, only: c_ptr, c_size_t, c_f_pointer, c_sizeof
  use omp_lib, only: omp_target_alloc, omp_target_free, omp_get_default_device

  implicit none

  private
  public :: container_t

  type :: container_t
    integer :: n
    integer :: m
    real, dimension(:), pointer :: b
    real, dimension(:, :), pointer :: bptr
    type(c_ptr), private :: devptr
    integer, private :: devid
  contains
    procedure :: set, get
    procedure :: kernel
    !!! final :: destroy_container ! XXX: This seems to be triggered at inopportune times
  end type

  interface container_t
    procedure init_container
  end interface

contains

  type(container_t) function init_container(n) result(c)
    integer, intent(in) :: n
    integer(kind=c_size_t) :: nbytes

    c%n = n
    c%m = int(sqrt(real(n)))
    nbytes = int(n, kind=c_size_t) * c_sizeof(0.0)

    c%devid = omp_get_default_device()
    c%devptr = omp_target_alloc(nbytes, c%devid)

    call c_f_pointer(c%devptr, c%b, [n])
    call c_f_pointer(c%devptr, c%bptr, [c%m, c%m])

  end function

  subroutine destroy_container(self)
    type(container_t) :: self

    call omp_target_free(self%devptr, self%devid)
    nullify(self%bptr)
    nullify(self%b)

  end subroutine

  subroutine set(self, a)
    class(container_t) :: self
    real, dimension(:), intent(in) :: a

    integer :: i

    call set_(self%b, a, min(self%n, size(a)))
  end subroutine

  subroutine set_(b, a, n)
    real, dimension(:), intent(inout) :: b
    real, dimension(:), intent(in) :: a
    integer, intent(in) :: n

    integer :: i

    !$omp target teams distribute parallel do map(to:a) has_device_addr(b)
    do i = 1, n
      b(i) = a(i)
    end do
    !$omp end target teams distribute parallel do

  end subroutine

  subroutine get(self, a)
    real, dimension(:), intent(out) :: a
    class(container_t), intent(in) :: self

    integer :: i

    call get_(a, self%b, self%n)
  end subroutine

  subroutine get_(a, b, n)
    real, dimension(:), intent(out) :: a
    real, dimension(:), intent(in) :: b
    integer, intent(in) :: n

    integer :: i

    !$omp target teams distribute parallel do map(from:a) has_device_addr(b)
    do i = 1, n
      a(i) = b(i)
    end do
    !$omp end target teams distribute parallel do
  end subroutine

  subroutine kernel(self)
    class(container_t) :: self
    integer :: i, j

    call kernel_(self%m, self%bptr)
  end subroutine

  subroutine kernel_(m, ptr)
    integer, intent(in) :: m
    real, dimension(m, m) :: ptr

    integer :: i, j

    !$omp target teams distribute parallel do collapse(2) has_device_addr(ptr)
    do i = 1, m
      do j = 1, m
        ptr(i, j) = 2 * ptr(i, j)
      end do
    end do
    !$omp end target teams distribute parallel do
  end subroutine

end module
