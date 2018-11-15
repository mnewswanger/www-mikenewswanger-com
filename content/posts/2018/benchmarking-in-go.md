---
title: Benchmarking Results in Go
date: 2018-11-15T09:00:00-05:00
tags: [golang, performance]
description: Diving into go benchmark result data.
---

Benchmarking is a great way to understand how your code is performing, and the go benchmark tools can show both execution times and memory allocation data.  This can be very handy for performance tuning because you have empircal evidence that a change you made is making the difference you expect.

## How does it work?

I'm not going to go into a huge amount of detail here, but I do want to set up some very high-level basics.  For more details, check out [Dave Cheney's blog](https://dave.cheney.net/2013/06/30/how-to-write-benchmarks-in-go).

Let's take a look at the following example.  Benchmarks are added in the same way as tests.  Like tests, benchmarks use function naming convention (`Benchmark...`), and the file containing the functions should be named with `_test.go` suffix.  In this case, I've named the file `benchmark_test.go`.

```
package bechmarkperf

import (
	"testing"
)

func BenchmarkCountParallel(b *testing.B) {
	b.RunParallel(func(pb *testing.PB) {
		for pb.Next() {
			countFunc()
		}
	})
}

func BenchmarkCountSerial(b *testing.B) {
	for i := 0; i < b.N; i++ {
		countFunc()
	}
}

func countFunc() {
	for i := 0; i < 1e6; i++ {
	}
}
```

Tests can be run with the following command: `go test -cpu 1,2,4,8 -benchmem -run=^$ -bench . benchmark_test.go`

The `BenchmarkCountSerial` function runs in serial - that is one process in an execution loop.  It doesn't start the count process until the previous iteration has finished, and everything runs in the main goroutine.  The `BenchmarkCountParallel` function runs in parallel.  The main goroutine fires off multiple goroutines to execute the code inside `b.RunParallel`.  It then waits for all of the goroutines to complete, then continues.  The `-cpu` flag sets the number of threads available to the go runtime.

## Interpreting Results

Running the above command gives us the following results:

```
goos: linux
goarch: amd64
BenchmarkCountParallel     	    5000	    368018 ns/op	       0 B/op	       0 allocs/op
BenchmarkCountParallel-2   	   10000	    163742 ns/op	       0 B/op	       0 allocs/op
BenchmarkCountParallel-4   	   20000	     95246 ns/op	       0 B/op	       0 allocs/op
BenchmarkCountParallel-8   	   20000	     98381 ns/op	       0 B/op	       0 allocs/op
BenchmarkCountSerial       	    5000	    337964 ns/op	       0 B/op	       0 allocs/op
BenchmarkCountSerial-2     	    3000	    386644 ns/op	       0 B/op	       0 allocs/op
BenchmarkCountSerial-4     	    5000	    317093 ns/op	       0 B/op	       0 allocs/op
BenchmarkCountSerial-8     	    5000	    355617 ns/op	       0 B/op	       0 allocs/op
PASS
ok  	command-line-arguments	16.685s
```

We can see here the name of the test followed by the number of allocated procs (via `-cpu` flag) when that is greater than 1.  If it's set to 1, it will have no suffix; otherwise, you will see `-<num procs>`.  Next is the number of iterations run.  This is a fairly light process, so it completes quickly, and many iterations can be run.  This will adjust dynamically based on the test duration specified at execution time.  Then we see the `ns/op` column - this is the average time each function call takes to complete.   After that are the two memory columns (present because of the `-benchmem` flag).  This shows us that in all tests, zero bytes of memory were allocated at an average rate of 0 allocations / operation.

Looking at that result set, everything makes sense except for timing.  Is the function actually getting faster when we add more goroutines?  That function isn't parallelized at all, so all other things held the same, function-level performance should be at best the same as running with fewer threads.  Context switching and CPU exhaustion can lead to significantly slower per-thread performance as well.

To amplify the point, let's tweak the example used above a bit:

```
package bechmarkperf

import (
	"strconv"
	"testing"
	"time"
)

func BenchmarkSleepSerial(b *testing.B) {
	for i := 0; i < b.N; i++ {
		sleepFunc()
	}
}

func BenchmarkSleepParallel(b *testing.B) {
	for i := 1; i <= 8; i *= 2 {
		b.Run(strconv.Itoa(i), func(b *testing.B) {
			b.SetParallelism(i)
			b.RunParallel(func(pb *testing.PB) {
				for pb.Next() {
					sleepFunc()
				}
			})
		})
	}
}

func sleepFunc() {
	time.Sleep(1 * time.Millisecond)
}
```

The test naming structure was set up following the pattern `BenchmarkSleepParallel/<parallelism>-<cpu>`.  Note, if CPU is set to 1, it won't be appended.

Running this code--assuming the sleep implentation is working properly--will never take less than 1ms.

Now let's take a look at the benchmark results by running `go test -cpu 1,2,4,8,16 -benchmem -run=^$ -bench . benchmark_test.go`:

```
goos: linux
goarch: amd64
BenchmarkSleepSerial         	    1000	   1449941 ns/op	       0 B/op	       0 allocs/op
BenchmarkSleepSerial-2       	    1000	   1550830 ns/op	       0 B/op	       0 allocs/op
BenchmarkSleepSerial-4       	    1000	   1468569 ns/op	       0 B/op	       0 allocs/op
BenchmarkSleepSerial-8       	    1000	   1507217 ns/op	       0 B/op	       0 allocs/op
BenchmarkSleepSerial-16      	    1000	   1509757 ns/op	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/1     	    1000	   1498519 ns/op	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/1-2   	    2000	    743778 ns/op	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/1-4   	    5000	    377843 ns/op	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/1-8   	   10000	    198106 ns/op	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/1-16  	   20000	     92807 ns/op	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/2     	    2000	    735995 ns/op	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/2-2   	    5000	    378456 ns/op	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/2-4   	   10000	    186719 ns/op	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/2-8   	   20000	     92417 ns/op	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/2-16  	   30000	     45607 ns/op	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/4     	    5000	    369069 ns/op	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/4-2   	   10000	    190875 ns/op	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/4-4   	   20000	     92051 ns/op	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/4-8   	   30000	     46979 ns/op	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/4-16  	  100000	     22973 ns/op	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/8     	   10000	    186493 ns/op	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/8-2   	   20000	     99457 ns/op	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/8-4   	   30000	     47851 ns/op	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/8-8   	   50000	     25342 ns/op	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/8-16  	  100000	     12024 ns/op	       0 B/op	       0 allocs/op
PASS
ok  	command-line-arguments	48.824s
```

So, on average, each function call is taking well less than the minimum time the function call could take (1ms).  Ruling out code elimination during compilation (which is not happening inside the test), let's take a look at what's going on when the benchmark runs and reports its results.

When a benchmark is run in parallel, it first determines the number of goroutines to run.  This is determined by multiplying `GOMAXPROCS` (set by `--cpu` flag) by the value of `b.parallelism`, which can be set by calling `b.SetParallelism(int)`.  So if we're running on a 4-core machine with defaults, we'll get `4` for GOMAXPROCS multiplied by `1` for parallelism, creating `4` goroutines.  This means that assuming we schedule against 4 CPU cores, we can saturate the CPU without contention (running go processes don't exceed available hardware cores).

As we start to increase parallelism (which in turn increases our multiplier for the goroutine count), we can see the performance get even better.  In fact, even with 128 goroutines running on 4 cores, we can see that doubling the number of goroutines about halves the `ns/op` metric coming from the benchmark.  However, as pointed out above, we're still sleeping for 1ms, so the performance of the function isn't actually getting faster.

So what's actually going on!?

Let's take a look at the benchmark results generation code:

```
func (r BenchmarkResult) String() string {
	mbs := r.mbPerSec()
	mb := ""
	if mbs != 0 {
		mb = fmt.Sprintf("\t%7.2f MB/s", mbs)
	}
	nsop := r.NsPerOp()
	ns := fmt.Sprintf("%10d ns/op", nsop)
	if r.N > 0 && nsop < 100 {
		// The format specifiers here make sure that
		// the ones digits line up for all three possible formats.
		if nsop < 10 {
			ns = fmt.Sprintf("%13.2f ns/op", float64(r.T.Nanoseconds())/float64(r.N))
		} else {
			ns = fmt.Sprintf("%12.1f ns/op", float64(r.T.Nanoseconds())/float64(r.N))
		}
	}
	return fmt.Sprintf("%8d\t%s%s", r.N, ns, mb)
}
```

What we can see here is that the duration of the test run is divided by the iterations run in the test.  This is an incorrect calculation--it's going the wrong direction.  What should be happening here is that the number of iterations run should be calculated over a fixed unit of time instead, giving us a result with the unit `ops/s` based on the data we have.

In the existing scenario, dividing a time duration by completed operations, we get a rate, not a time period per operation.  Switching the numbers around gives a number that's actually relatively useless.  While seeing decreases will show that increasing concurrency increases performance, the number itself can only be used as a relative comparison, because as shown above, a sleep of 1ms is never going to complete in less than that.

By instead providing an operations per second count (anchoring throughput to a fixed time duration), we can have a number that's both useful and accurate.

I'm personally also concerned with timing of the operation.  Because many of the functions that I'm working on are called inline with client requests, I want to know how much elaspsed time they require because this will directly impact their perception of performance.  This can already be accomplished by running tests in serial, but as discussed above, it's a good idea to run tests in parallel, especially if they're already going to run concurrently.

So how do we figure that out?

We need to figure out thread time, which can do fairly accurately by multiplying the duration by the number of running goroutines by the elapsed time.  For even more accuracy, we could track durations within each running goroutine (based on start and completion time of each in case some run noticably longer than others).  The latter shouldn't skew numbers too heavily assuming the duration of the test is reasonably long.

So, I [modified the `go test` tool to do just that](https://github.com/golang/go/pull/28814/files), and here's the results that I got:

```
goos: darwin
goarch: amd64
BenchmarkSleepSerial         	    1000	   1337675 ns/op	       747.57 ops/s	       0 B/op	       0 allocs/op
BenchmarkSleepSerial-2       	    1000	   1387810 ns/op	       720.56 ops/s	       0 B/op	       0 allocs/op
BenchmarkSleepSerial-4       	    1000	   1385465 ns/op	       721.78 ops/s	       0 B/op	       0 allocs/op
BenchmarkSleepSerial-8       	    1000	   1388933 ns/op	       719.98 ops/s	       0 B/op	       0 allocs/op
BenchmarkSleepSerial-16      	    1000	   1401729 ns/op	       713.40 ops/s	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/1     	    1000	   1370312 ns/op	       729.76 ops/s	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/1-2   	    2000	   1410639 ns/op	      1417.79 ops/s	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/1-4   	    3000	   1406812 ns/op	      2843.24 ops/s	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/1-8   	   10000	   1407085 ns/op	      5685.26 ops/s	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/1-16  	   20000	   1378449 ns/op	     11606.96 ops/s	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/2     	    2000	   1395714 ns/op	      1432.94 ops/s	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/2-2   	    3000	   1410110 ns/op	      2836.61 ops/s	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/2-4   	   10000	   1269820 ns/op	      6299.93 ops/s	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/2-8   	   20000	   1289376 ns/op	     12408.16 ops/s	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/2-16  	   30000	   1288648 ns/op	     24820.27 ops/s	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/4     	    3000	   1359702 ns/op	      2941.75 ops/s	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/4-2   	   10000	   1403628 ns/op	      5699.39 ops/s	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/4-4   	   20000	   1404574 ns/op	     11390.93 ops/s	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/4-8   	   30000	   1404647 ns/op	     22765.47 ops/s	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/4-16  	   50000	   1410323 ns/op	     45219.82 ops/s	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/8     	   10000	   1312485 ns/op	      6095.18 ops/s	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/8-2   	   20000	   1295381 ns/op	     12351.18 ops/s	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/8-4   	   30000	   1302094 ns/op	     24562.79 ops/s	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/8-8   	   50000	   1326515 ns/op	     47992.22 ops/s	       0 B/op	       0 allocs/op
BenchmarkSleepParallel/8-16  	  100000	   1303139 ns/op	     97150.85 ops/s	       0 B/op	       0 allocs/op
PASS
ok  	command-line-arguments	64.395s
```

Now, rather than having the `ns/op` dividing by the total elapsed time, the `ns/op` is based off of the processing time running the benchmark.  It also adds the operations per second metric, which shows the throughput doubling when we double the goroutine count as well.

Note that while parallelization increases well beyond available cores, we stil see little overhead in performance.  This is because `time.Sleep` isn't a cpu blocking instruction, which means that while goroutines sleep, others can be run, allowing us to hit higher CPU utilization and have huge amounts of function call throughput.  In reality, you'll probably be benchmarking things that are doing actual work, so you won't be able to oversubscribe the CPU this hard, but asynchronous I/O calls for example can provide similar behavior to a lesser extreme (assuming I/O isn't the bottleneck).
