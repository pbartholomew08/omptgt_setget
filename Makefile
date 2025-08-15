FC=nvfortran
FFLAGS=-g -O0 -mp=gpu
FFLAGS+=-Minfo=mp

#FC=gfortran
#FFLAGS=-g -O3 -fopenmp

all: main1 main1.usm main2 main3 main4

main1: src/main1.f90
	$(FC) $(FFLAGS) $^ -o bin/$@

main1.usm: src/main1.f90
	$(FC) $(FFLAGS) -gpu=mem:unified $^ -o bin/$@

main2: src/main2.f90
	$(FC) $(FFLAGS) $^ -o bin/$@

main3: src/main3.f90
	$(FC) $(FFLAGS) $^ -o bin/$@

main4: src/four.f90 src/main4.f90
	$(FC) $(FFLAGS) -c src/four.f90 -o bin/four.o
	$(FC) $(FFLAGS) src/main4.f90 -o bin/$@ bin/four.o
