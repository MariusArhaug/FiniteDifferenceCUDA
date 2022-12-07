# TDT4200 Problem set 5: Graded CUDA

## Finite difference approximation of the 2D shallow water equations using CUDA
In this assignment you will work on an implementation of the Finite Difference Method (FDM) for solving the 2D shallow water equations using the CUDA API for NVIDIA GPUs. Information on parallelization with CUDA is described in the lecture slides.

The serial solution can be found in `shallow_water_serial.c` and should be kept as a reference. A skeleton for your parallel implementation can be found in `shallow_water_parallel.cu`, in which you should write your parallel implementation. You should complete the parallel implementation as described by the problem set description.

## Run
### Setup
`make setup`

Creates folders `data`, `plots` and `video`.
- `data`: contains output from the simulation
- `plots`: contains output from plotting
- `video`: contains output from video generation

Compiles the code for comparing solutions.

### Serial solution
**Compile**

`make serial`

**Run**

`./serial -n [grid_size] -i [max_iteration] -s [snapshot_frequency]`

**Example**

```
make serial
./serial -n 256 -i 5000 -s 40
```

**Compile and run**

You can also execute both of the above commands together with default values with `make run_serial`

### Parallel solution
**Compile**

`make parallel`

**Run**

`./parallel -n [grid_size] -i [max_iteration] -s [snapshot_frequency]`

**Example**

```
make parallel
./parallel -n 256 -i 5000 -s 40
```

**Compile and Run**

You can also execute both of the above commands together with default values with `make run`.

## Visualize
### Plots
`./plot_solution.sh -n [grid_size]`

Plots the program output using [gnuplot](http://gnuplot.sourceforge.net).

Alternatively, you can compile, run, and plot the solution with default values with `make plot` .

You can plot the serial solution with `make plot_serial`.

**Example**

`./plot_solution.sh -n 256`

### Video
`make show`

Compiles, runs, and plots the parallel solution with default values and creates a video using [ffmpeg](https://ffmpeg.org).

You can create a video from the serial solution with `make show_serial`.

## Check
`make check`

Compiles and runs the parallel solution with default values and compares the output data to reference data.

You can check the serial solution with `make check_serial`.

## Options
Option | Description | Restrictions | Default value
:------------ | :------------ | :------------ | :------------
**-n** | Number of grid points in one spatial dimension | > 0 | 256
**-i** | Number of iterations | > 0 | 5000
**-s** | Number of iterations between each time the grid state is saved to file | > 0 | 40

## Installing dependencies
**CUDA**

Linux/Ubuntu:

An in-depth overview of how to install CUDA on Linux can be found [here](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html)

MacOSX:

NVIDIA no longer supports development on macOS. Please opt for using
the Snotra cluster or another operating system. The TDT4200 staff will not
be able to offer support for compiling and running CUDA applications on MacOSX.

**gnuplot**

Linux/Ubuntu:

```
sudo apt update
sudo apt install gnuplot
```

MacOSX:

```
brew update
brew install gnuplot
```

**ffmpeg**

Linux/Ubuntu:

```
sudo apt update
sudo apt install ffmpeg
```

MacOSX:

```
brew update
brew install ffmpeg
```
