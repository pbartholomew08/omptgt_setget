module m_four

  implicit none

  private
  public :: container_t

  type :: container_t
    integer :: n
    integer :: m
    real, dimension(:), pointer :: b
    real, dimension(:, :), pointer :: bptr
  contains
    procedure :: set, get
    procedure :: kernel
    final :: destroy_container
  end type

  interface container_t
    procedure init_container
  end interface

contains

  type(container_t) function init_container(n) result(c)
    integer, intent(in) :: n

    c%n = n
    c%m = int(sqrt(real(n)))
    allocate(c%b(n))
    c%bptr(1:c%m, 1:c%m) => c%b(1:c%m*c%m)
    !$omp target enter data map(alloc:c%b)
    !$omp target enter data map(to:c%bptr)

  end function

  subroutine destroy_container(self)
    type(container_t) :: self

    print *, "Destruction!"
    if (associated(self%bptr)) then
      !$omp target exit data map(delete:self%bptr)
      nullify(self%bptr)
    end if

    if (associated(self%b)) then
      print *, "Delete B"
      !$omp target exit data map(delete:self%b)
      deallocate(self%b)
      nullify(self%b)
    end if

  end subroutine

  subroutine set(self, a)
    class(container_t) :: self
    real, dimension(:), intent(in) :: a

    call set_(self%b, a, min(self%n, size(a)))

  end subroutine

  subroutine set_(b, a, n)
    real, dimension(:), intent(inout) :: b
    real, dimension(:), intent(in) :: a
    integer, intent(in) :: n

    integer :: i

    !$omp target teams distribute parallel do map(to:a)
    do i = 1, n
      b(i) = a(i)
    end do
    !$omp end target teams distribute parallel do

  end subroutine

  subroutine get(self, a)
    real, dimension(:), intent(out) :: a
    class(container_t), intent(in) :: self

    call get_(a, self%b, self%n)
  end subroutine

  subroutine get_(a, b, n)
    real, dimension(:), intent(out) :: a
    real, dimension(:), intent(in) :: b
    integer, intent(in) :: n

    integer :: i

    !$omp target teams distribute parallel do map(from:a)
    do i = 1, n
      a(i) = b(i)
    end do
    !$omp end target teams distribute parallel do
  end subroutine

  subroutine kernel(self)
    class(container_t) :: self

    call kernel_(self%m, self%bptr)

  end subroutine

  subroutine kernel_(m, ptr)
    integer, intent(in) :: m
    real, dimension(m, m) :: ptr

    integer :: i, j

    !$omp target teams distribute parallel do collapse(2)
    do i = 1, m
      do j = 1, m
        ptr(i, j) = 2 * ptr(i, j)
      end do
    end do
    !$omp end target teams distribute parallel do
  end subroutine

end module
