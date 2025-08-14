FC=nvfortran
FFLAGS=-g -O3 -mp=gpu
FFLAGS+=-Minfo=mp

all: main1 main1.usm main2 main3

main1: src/main1.f90
	$(FC) $(FFLAGS) $^ -o bin/$@

main1.usm: src/main1.f90
	$(FC) $(FFLAGS) -gpu=mem:unified $^ -o bin/$@

main2: src/main2.f90
	$(FC) $(FFLAGS) $^ -o bin/$@

main3: src/main3.f90
	$(FC) $(FFLAGS) $^ -o bin/$@
