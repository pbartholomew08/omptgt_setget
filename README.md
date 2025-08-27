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

All performance tests were ran on EPCC's Grace-Hopper node using nvfortran v25.1.
Unless stated otherwise programs are built with
```
FFLAGS=-g -O3 -mp=gpu -Minfo=mp
```
as detailed in the `Makefile`.

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

The addition of timers around the host-device, kernel, and device-host regions
reveals that the time is dominated by data movement costs:
```
$ OMP_TARGET_OFFLOAD=MANDATORY time ./bin/main1
 PASS
 TIMES (s):
 - Host-Device:     54.18061709403992     
 - Kernel:    0.1184039115905762     
 - Device-Host:     50.47920107841492     
101.83user 4.13system 1:46.94elapsed 99%CPU (0avgtext+0avgdata 7925760maxresident)k
0inputs+0outputs (0major+159427minor)pagefaults 0swaps
```

### Adding map clauses

In `main2` `map` clauses are used to control the movement of data to and from the GPU.
As the timings show this reduces the runtime to ~40s, and it can be seen that
the `nvomp` runtime reports smaller data movements as only the required data is
up/downloaded.
```
$ NVCOMPILER_ACC_NOTIFY=3 OMP_TARGET_OFFLOAD=MANDATORY time ./main2
upload CUDA data  file=.../main2.f90 function=main line=16 device=0 threadid=1 variable=a$sd1(:) bytes=128
upload CUDA data  file=.../main2.f90 function=main line=16 device=0 threadid=1 variable=b$sd2(:) bytes=128
upload CUDA data  file=.../main2.f90 function=main line=16 device=0 threadid=1 variable=descriptor bytes=128
upload CUDA data  file=.../main2.f90 function=main line=16 device=0 threadid=1 variable=a(:) bytes=4000000000
upload CUDA data  file=.../main2.f90 function=main line=16 device=0 threadid=1 variable=descriptor bytes=128
launch CUDA kernel file=.../main2.f90 function=main line=16 device=0 host-threadid=0 num_teams=0 thread_limit=0 kernelname=nvkernel_MAIN__F1L16_2_ grid=<<<7812500,1,1>>> block=<<<128,1,1>>> shmem=0b
download CUDA data  file=.../main2.f90 function=main line=20 device=0 threadid=1 variable=b(:) bytes=4000000000
upload CUDA data  file=.../main2.f90 function=main line=23 device=0 threadid=1 variable=b$sd2(:) bytes=128
upload CUDA data  file=.../main2.f90 function=main line=23 device=0 threadid=1 variable=descriptor bytes=128
upload CUDA data  file=.../main2.f90 function=main line=23 device=0 threadid=1 variable=b(:) bytes=4000000000
launch CUDA kernel file=.../main2.f90 function=main line=23 device=0 host-threadid=0 num_teams=0 thread_limit=0 kernelname=nvkernel_MAIN__F1L23_4_ grid=<<<7812500,1,1>>> block=<<<128,1,1>>> shmem=0b
download CUDA data  file=.../main2.f90 function=main line=27 device=0 threadid=1 variable=b(:) bytes=4000000000
upload CUDA data  file=.../main2.f90 function=main line=30 device=0 threadid=1 variable=a$sd1(:) bytes=128
upload CUDA data  file=.../main2.f90 function=main line=30 device=0 threadid=1 variable=b$sd2(:) bytes=128
upload CUDA data  file=.../main2.f90 function=main line=30 device=0 threadid=1 variable=descriptor bytes=128
upload CUDA data  file=.../main2.f90 function=main line=30 device=0 threadid=1 variable=b(:) bytes=4000000000
upload CUDA data  file=.../main2.f90 function=main line=30 device=0 threadid=1 variable=descriptor bytes=128
launch CUDA kernel file=.../main2.f90 function=main line=30 device=0 host-threadid=0 num_teams=0 thread_limit=0 kernelname=nvkernel_MAIN__F1L30_6_ grid=<<<7812500,1,1>>> block=<<<128,1,1>>> shmem=0b
download CUDA data  file=.../main2.f90 function=main line=34 device=0 threadid=1 variable=a(:) bytes=4000000000
 PASS
44.21user 4.76system 0:49.96elapsed 98%CPU (0avgtext+0avgdata 7925760maxresident)k
0inputs+0outputs (0major+200171minor)pagefaults 0swaps
```

A breakdown of the timings shows that there is still a significant data
transfer cost associated with running the kernel as `b` must be copied on and
off the device
```
$ OMP_TARGET_OFFLOAD=MANDATORY time ./bin/main2
 PASS
 TIMES (s):
 - Host-Device:     15.90019917488098     
 - Kernel:     24.75345897674561     
 - Device-Host:     25.95578479766846     
62.93user 4.82system 1:08.79elapsed 98%CPU (0avgtext+0avgdata 7925760maxresident)k
0inputs+0outputs (0major+176800minor)pagefaults 0swaps
```

### Device resident data

Operations on the working array `b` occur on device, by using `target
enter/exit data map(alloc/delete:b)` it can be created on device and no
transfers involving `b` are necessary.
By applying this optimisation the significant host-device data movement is
reduced to only up/downloading `a` and the runtime is now <1s.
```
$ NVCOMPILER_ACC_NOTIFY=3 OMP_TARGET_OFFLOAD=MANDATORY time ./main3
upload CUDA data  file=.../main3.f90 function=main line=17 device=0 threadid=1 variable=descriptor bytes=128
upload CUDA data  file=.../main3.f90 function=main line=17 device=0 threadid=1 variable=a$sd1(:) bytes=128
upload CUDA data  file=.../main3.f90 function=main line=17 device=0 threadid=1 variable=descriptor bytes=128
upload CUDA data  file=.../main3.f90 function=main line=17 device=0 threadid=1 variable=a(:) bytes=4000000000
launch CUDA kernel file=.../main3.f90 function=main line=17 device=0 host-threadid=0 num_teams=0 thread_limit=0 kernelname=nvkernel_MAIN__F1L17_2_ grid=<<<7812500,1,1>>> block=<<<128,1,1>>> shmem=0b
upload CUDA data  file=.../main3.f90 function=main line=24 device=0 threadid=1 variable=descriptor bytes=128
launch CUDA kernel file=.../main3.f90 function=main line=24 device=0 host-threadid=0 num_teams=0 thread_limit=0 kernelname=nvkernel_MAIN__F1L24_4_ grid=<<<7812500,1,1>>> block=<<<128,1,1>>> shmem=0b
upload CUDA data  file=.../main3.f90 function=main line=31 device=0 threadid=1 variable=descriptor bytes=128
upload CUDA data  file=.../main3.f90 function=main line=31 device=0 threadid=1 variable=a$sd1(:) bytes=128
upload CUDA data  file=.../main3.f90 function=main line=31 device=0 threadid=1 variable=descriptor bytes=128
launch CUDA kernel file=.../main3.f90 function=main line=31 device=0 host-threadid=0 num_teams=0 thread_limit=0 kernelname=nvkernel_MAIN__F1L31_6_ grid=<<<7812500,1,1>>> block=<<<128,1,1>>> shmem=0b
download CUDA data  file=.../main3.f90 function=main line=35 device=0 threadid=1 variable=a(:) bytes=4000000000
 PASS
0.52user 3.86system 0:05.37elapsed 81%CPU (0avgtext+0avgdata 4027392maxresident)k
0inputs+0outputs (0major+62607minor)pagefaults 0swaps
```

Now that we are controlling the device memory we can see that the time is
dominated by allocating the device memory with some overhead for data
transfers, the kernel itself takes minimal time
```
$ OMP_TARGET_OFFLOAD=MANDATORY time ./bin/main3
 PASS
 TIMES (s):
 - Alloc:     2.973485946655273     
 - Host-Device:    0.2939069271087646     
 - Kernel:    4.7280788421630859E-003
 - Device-Host:    1.8191099166870117E-002
 - Delete:    1.0013580322265625E-005
0.53user 3.84system 0:05.30elapsed 82%CPU (0avgtext+0avgdata 4027392maxresident)k
0inputs+0outputs (0major+62582minor)pagefaults 0swaps
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

The breakdown of timers reveals that the data movement costs are significantly
reduced relative to the non-unified memory version, the upfront cost of moving
the shared memory to the device is comparable to the allocation costs in
`main3`, the kernel runtime itself is almost identical.
```
$ OMP_TARGET_OFFLOAD=MANDATORY time ./bin/main1.usm 
 PASS
 TIMES (s):
 - Host-Device:     1.017045974731445     
 - Kernel:    4.7500133514404297E-003
 - Device-Host:    4.7299861907958984E-003
1.61user 3.34system 0:05.92elapsed 83%CPU (0avgtext+0avgdata 4027392maxresident)k
0inputs+0outputs (0major+14939minor)pagefaults 0swaps
```
