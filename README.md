Coherent Sampling-based TRNG with MMCMs
=======================================

Abstract
--------

This repository contains HDL source codes (written in Verilog) and
Ruby scripts to evaluate a true random number generator (TRNG) based
on the following article:

> Naoki Fujieda and Sogo Takashima: Enhanced use of mixed-mode clock
> manager for coherent sampling-based true random number generator,
> 12th International Workshop on Parallel and Distributed Algorithms
> and Applications (PDAA-12) held in conjunction with CANDAR '20,
> pp. 197–203 (11/2020).

The repository is organized by four directories as follows.

- `hdl_source`: HDL source codes written in Verilog
- `scripts`: Ruby scripts to collect and evaluate generated random numbers
- `gen_scripts`: Ruby scripts to synthesize the circuit and collect random
  numbers automatically with various parameter sets
- `reference`: list of frequency pairs (for reference)

The corresponding author confirmed a successful synthesis with Vivado 2020.1.
The target board is Digilent <a href="https://reference.digilentinc.com/reference/programmable-logic/arty/start">Arty</a> (<a href="https://reference.digilentinc.com/reference/programmable-logic/arty-a7/start">Arty A7-35</a>),
which includes an Artix-7 XC7A35T FPGA.

The author ran the Ruby scripts by <a href="https://rubyinstaller.org/">Ruby 2.6.5-1-x64 with MSYS2 (RubyInstaller)</a>
on Windows 10. One of the scripts (serial_read.rb) requires the <a href="https://rubygems.org/gems/serialport/versions/1.3.1">SerialPort gem</a>.
It might not work correctly on some machines. In this case, try an
alternative script written in Python.

-----------------------------------------------------------------------

hdl_source directory
--------------------
The `hdl_source` directory contains the HDL source codes of the TRNG
(and a constraint file).
Their hierarchical relation is as follows.

- *top.v* (TOP)
  - *mmcm.v* (MMCM_AR7): an instantiation of MMCM
  - *counter.v* (COUNTER): coherent sampling module
  - *pack.v* (Pack1b8b): Data Packer
  - *uart.v* (uartsender): UART data sender
    - *fifo.v* (fifo)
- *define.v*: Constant Definition
- *arty.xdc*: Constraint file for Arty (Arty A7-35)

To synthesize the circuit, make an `fpga` Vivado project targeting
Arty in the directory of repository (make sure the "create project
subdirectory" option is ticked), add *.v as design sources, add
arty.xdc as a constraint, and follow an ordinary logic synthesis flow.

If the data packer is disabled (set PACK_ENABLE to 1'b0 in *define.v*),
the output will be the values of the 8-bit counter in the coherent
sampling module. It counts the number of ones in N samples.
Note that the MSB of the counter saturates: that is, the value next
to 0xff is 0x80 (rather than 0x00).

If the data packer is enabled (set PACK_ENABLE to 1'b1), the output
will be random bit sequences, where the LSB of the counter values
are concatenated.

scripts directory
-----------------
The `scripts` directory is a collection of Ruby scripts for
evaluation of TRNGs.

### serial_read.rb
It reads a fixed amount of data from a serial port and save them to a file.
- Argument 1: Name of output file
- Argument 2: the number of bytes to be read

> ruby serial_read.rb out.dat 1000000

-> read 1 MB of data from a serial port and write them to out.dat

Before using this script, the PORT constant must be modified according to
the environment. The constant will be COM?? in Windows and /dev/ttyS?? in
Unix-like OS (?? is the port number).

Approximately 2 MB of data are required to conduct the test procedure B
of AIS-31.

### 8b_graph.rb
It graphically displays the distribution of the number of times the bytes
0x00 - 0xff appear in a file.

- Argument 1: A data file collected with the counter mode

### 8b_distribution.rb
It outputs the distribution of the number of times the bytes 0x00 - 0xff
appear in a file to a CSV file.

- Argument 1: A data file collected with the counter mode
- Argument 2: An output CSV file

> ruby 8b_distribution.rb out.dat out.csv

### 8b_min_entropy.rb
It calculates the min-entropy of the collected random bitstrings.
It was used to generate the data shown in Table VI of the paper.

This script is supposed to be executed after the all data were collected
by autobuild.rb and stored in the `gen_data` directory.

### ais_test.rb
It examines a data file as a random bit sequence with statistical tests
defined in AIS-31. It finally outputs whether the data statistically
unbiased (PASS) or not (FAIL).

- Argument 1: Type of test (usually A or B)
- Argument 2: A data file collected with the TRNG mode

> ruby ais_test.rb B out.dat

gen_scripts directory
---------------------
The `gen_scripts` directory includes an automation script for synthesizing
the circuit and collecting random numbers.
It has two main scripts, while the other scripts are included from them.

### autobuild.rb
This is the automation script. Before execution, the VIVADO_DIR and
PORT constants must be modified according to the environment.
The script is written specially for a 64-bit Windows environment.


### freqpair_new.rb
This script finds appropriate sets of parameters according to the
strategy proposed in the paper. Although the lower and upper limits
of N (the number of samples per count) is fixed to 400 and 1000
(respectively) in the paper, the script can take them as arguments.

- Argument 1: Lower Limit of N 
- Argument 2: Upper Limit of N

The found parameter sets will be output to the standard output.

reference directory
-------------------

The `reference` directory contains Excel worksheets that include lists
of frequency pairs with IDs.

The files are named as Frequency_*I*_*J*.xlsx.
The numbers *I* and *J* corresponds to the lower and upper limits of
the number of samples per count (N), respectively.

-----------------------------------------------------------------------

How to evaluate TRNG
--------------------

The steps to start a reproducive experiment are as follows.

1. Make an `fpga` Vivado project in the repository directory and
   synthesize the circuit in this project (refer to the "hdl_source
   directory" section).
2. Program the FPGA in your Arty with the generated bitstream.
3. Check the serial port number of Arty and modify the PORT constant
   in serial_read.rb.
4. By default, the circuit continuously outputs the sequence of counter
   values. Execute the serial_read.rb script to collect some of them.

>     > cd scripts
>     > ruby serial_read.rb hoge 1000000

5. Execute a visualization script. You can see the distribution of
   the collected counter values.

>     >ruby 8b_graph.rb hoge
>     even =     497197 (49.545%)
>     odd  =     506323 (50.455%)
>     avg. = 29.52
>     s.d. = 1.85
>     med. = 30
>     
>     [[Graph]]
>     00
>     ...
>     18
>     19 **
>     1a *******
>     1b **********************
>     1c ***********************************
>     1d ********************************************
>     1e **************************************************
>     1f ****************************************
>     20 ********************
>     21 ********
>     22 **
>     23
>     ...

6. As the Vivado project has been successfully configured, you are ready
   to execute the automation script (autobuild.rb). Make sure the
   VIVADO_DIR and PORT constants are modified properly.
7. Execute the automation script. By default, it will work for only one
   parameter set (N001), defined in freqs_test.rb, to test the operation
   of the script.

>     > cd ..\gen_scripts
>     > ruby autobuild.rb
>     ## building frequency pair named N001
>     
>     N001|# open_project ../fpga/FPGA.xpr
>     N001|# reset_run synth_1
>     ...

8. If the script finishes with no errors, it says "Data Saved
   Successfully." Now you can see the `gen_data` directory is created
   in the repository directory and find the following files:

- N001.bin: collected random bitstring
- N001.bit: bitstream generated by Vivado
- N001.log: synthesis log of Vivado
- N001.txt: measured bit rate of generation

-----------------------------------------------------------------------

Copyright
---------

<a href="https://aitech.ac.jp/~dslab/">Digital Systems Laboratory</a> in <a href="https://www.ait.ac.jp/en/">Aichi Institute of Technology</a>
(managed by <a href="https://aitech.ac.jp/~dslab/nf/index.en.html">Naoki FUJIEDA</a>) holds copyright of this repository.
It is licensed under the New BSD license.
See the COPYING file for more information.

Copyright (C) 2020-2021 Digital Systems Lab., Aichi Institute of Technology.
All rights reserved.