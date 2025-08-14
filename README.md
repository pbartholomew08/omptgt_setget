# OpenMP Target Offload Set/Get example

This example code demonstrates setting and getting an array on a device using
the OpenMP target offload API.

The program creates two 1-D arrays, `a` and `b`, initialises `a` on the host
then uses the device to copy `a` into `b`, execute a kernel to double `b`'s
contents and finally copy `b` into `a` and confirm the values have been
doubled.
Several versions of the program are used to explore the optimising the
performance by controlling data movement using the openMP API.

## Performance

All performance tests were ran on EPCC's Grace-Hopper node using nvfortran v25.1

### Naive implementation

A naive implementation (main1.f90) without considering data movement shows that
on each kernel the data is copied in and out each time
```
NVCOMPILER_ACC_NOTIFY=3 OMP_TARGET_OFFLOAD=MANDATORY time ./main1
upload CUDA data  file=.../main.f90 function=main line=16 device=0 threadid=1 variable=b(:) bytes=4000000000
upload CUDA data  file=.../main.f90 function=main line=16 device=0 threadid=1 variable=a(:) bytes=4000000000
launch CUDA kernel file=.../main.f90 function=main line=16 device=0 host-threadid=0 num_teams=0 thread_limit=0 kernelname=nvkernel_MAIN__F1L16_2_ grid=<<<7812500,1,1>>> block=<<<128,1,1>>> shmem=0b
download CUDA data  file=.../main.f90 function=main line=20 device=0 threadid=1 variable=a(:) bytes=4000000000
download CUDA data  file=.../main.f90 function=main line=20 device=0 threadid=1 variable=b(:) bytes=4000000000
upload CUDA data  file=.../main.f90 function=main line=23 device=0 threadid=1 variable=b(:) bytes=4000000000
launch CUDA kernel file=.../main.f90 function=main line=23 device=0 host-threadid=0 num_teams=0 thread_limit=0 kernelname=nvkernel_MAIN__F1L23_4_ grid=<<<7812500,1,1>>> block=<<<128,1,1>>> shmem=0b
download CUDA data  file=.../main.f90 function=main line=27 device=0 threadid=1 variable=b(:) bytes=4000000000
upload CUDA data  file=.../main.f90 function=main line=30 device=0 threadid=1 variable=a(:) bytes=4000000000
upload CUDA data  file=.../main.f90 function=main line=30 device=0 threadid=1 variable=b(:) bytes=4000000000
launch CUDA kernel file=.../main.f90 function=main line=30 device=0 host-threadid=0 num_teams=0 thread_limit=0 kernelname=nvkernel_MAIN__F1L30_6_ grid=<<<7812500,1,1>>> block=<<<128,1,1>>> shmem=0b
download CUDA data  file=.../main.f90 function=main line=34 device=0 threadid=1 variable=b(:) bytes=4000000000
download CUDA data  file=.../main.f90 function=main line=34 device=0 threadid=1 variable=a(:) bytes=4000000000
 PASS
93.92user 4.44system 1:39.31elapsed 99%CPU (0avgtext+0avgdata 7925760maxresident)k
0inputs+0outputs (0major+162431minor)pagefaults 0swaps
```

### Unified shared memory

Returning to the naive implementation and enabling unified shared memory
(`-gpu=unified`) the transfers are replaced by unified memory accesses and the
performance is significantly improved from ~90s to ~2s run time
```
$ NVCOMPILER_ACC_NOTIFY=3 OMP_TARGET_OFFLOAD=MANDATORY time ./main1.usm 
launch CUDA kernel file=.../main1.f90 function=main line=16 device=0 host-threadid=0 num_teams=0 thread_limit=0 kernelname=nvkernel_MAIN__F1L16_2_ grid=<<<7812500,1,1>>> block=<<<128,1,1>>> shmem=0b
launch CUDA kernel file=.../main1.f90 function=main line=23 device=0 host-threadid=0 num_teams=0 thread_limit=0 kernelname=nvkernel_MAIN__F1L23_4_ grid=<<<7812500,1,1>>> block=<<<128,1,1>>> shmem=0b
launch CUDA kernel file=.../main1.f90 function=main line=30 device=0 host-threadid=0 num_teams=0 thread_limit=0 kernelname=nvkernel_MAIN__F1L30_6_ grid=<<<7812500,1,1>>> block=<<<128,1,1>>> shmem=0b
 PASS
1.65user 3.34system 0:06.01elapsed 83%CPU (0avgtext+0avgdata 4027392maxresident)k
0inputs+0outputs (1major+14943minor)pagefaults 0swaps
```
