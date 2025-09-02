# FC=nvfortran
# FFLAGS=-g -O3 -mp=gpu
# FFLAGS+=-Minfo=mp
# LDFLAGS=

FC=amdflang
GPUARCH=gfx942 # MI300A
FFLAGS = -g -O3 -fopenmp --offload-arch=$(GPUARCH)
LDFLAGS = -fopenmp -lstdc++ -lamdhip64
LDFLAGS += -lflang_rt.hostdevice -lrocprofiler-sdk-roctx -lrocprofiler-sdk 

#FC=gfortran
#FFLAGS=-g -O3 -fopenmp

all: main1 main1.usm main2 main3 main4

main1: src/main1.f90
	$(FC) $(FFLAGS) $^ -o bin/$@ $(LDFLAGS)

main1.usm: src/main1.f90
	$(FC) $(FFLAGS) -gpu=mem:unified $^ -o bin/$@ $(LDFLAGS)

main2: src/main2.f90
	$(FC) $(FFLAGS) $^ -o bin/$@ $(LDFLAGS)

main3: src/main3.f90
	$(FC) $(FFLAGS) $^ -o bin/$@ $(LDFLAGS)

main4: src/four.f90 src/main4.f90
	$(FC) $(FFLAGS) -c src/four.f90 -o bin/four.o
	$(FC) $(FFLAGS) src/main4.f90 -o bin/$@ bin/four.o
