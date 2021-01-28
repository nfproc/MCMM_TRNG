########################################################################
# Auto Build with Various Frequency Pairs 2020.02.20 Naoki F., AIT
# New BSD License is applied. See COPYING file for details.
########################################################################
require_relative 'freqs_test.rb'

########################################################################
require 'FileUtils'
require 'rubygems'
require 'serialport'

VIVADO_DIR   = 'C:\Xilinx\Vivado\2020.1'
PROJ_DIR     = "..\\"
IMPL_DIR     = PROJ_DIR + '\fpga\fpga.runs\impl_1'
GEN_DIR      = PROJ_DIR + '\gen_data'

SOURCE_FILE  = '..\hdl_source\define.v'
BIT_FILE     = IMPL_DIR + '\TOP.bit'
LOG_FILE     = 'vivado.log'

PORT         = "COM8"
SERIAL_BLOCK = 4096
SERIAL_SIZE  = 2000000

newpath = VIVADO_DIR + '\bin;' + VIVADO_DIR + '\lib\win64.o;' + ENV['PATH'];
newenv = {'PATH' => newpath, 'XILINX_VIVADO' => VIVADO_DIR}

########################################################################
# main loop

FREQ_PAIRS.each do |freqs|
  puts "## building frequency pair named #{freqs[0]}"
  puts
  sleep 1

  gen_file = GEN_DIR + "\\" + freqs[0]
  
  # make SOURCE_FILE
  open(SOURCE_FILE, 'w') do |file|
    file.puts "`define MMCMA_M %.3f" % freqs[1]
    file.puts "`define MMCMA_D %d"   % freqs[2]
    file.puts "`define MMCMA_Q %.3f" % freqs[3]
    file.puts "`define MMCMB_M %.3f" % freqs[4]
    file.puts "`define MMCMB_D %d"   % freqs[5]
    file.puts "`define MMCMB_Q %.3f" % freqs[6]
    file.puts "`define PACK_ENABLE 1'b1"
    file.puts "`define CNT_PERIOD 10'd%d" % freqs[7] if freqs[7]
  end
  
  # run Vivado
  IO.popen([newenv, VIVADO_DIR + '\bin\vivado.bat',
           '-mode', 'batch', '-source', 'build_vivado.tcl',
           '-nojournal']) do |io|
    while line = io.gets
      if line =~ /^# [a-z]/ || line =~ /: Time \(s\)/
        puts "%s|%s" % [freqs[0], line.chomp]
      end
    end
  end
  if ! $?.success?
    puts "!! failed to build the core (with status %d). stop." % $?
    exit 1
  end
  
  # copy relavant file
  Dir.mkdir(GEN_DIR) if ! Dir.exist?(GEN_DIR)
  FileUtils.mv LOG_FILE, gen_file + '.log'
  FileUtils.cp BIT_FILE, gen_file + '.bit'

  # save serial output to a file
  puts "## Collecting Counter Values"

  begin
    sp = SerialPort.new(PORT, 3000000, 8, 1, 0)
    sp.read_timeout = 1000
  rescue => e
    STDERR.puts "!! failed to open serial port (%s). stop." % e.message
    exit 1
  end
  begin
    out = open(gen_file + '.bin', "wb:ASCII-8BIT")
  rescue => e
    STDERR.puts "!! failed to open output file (%s). stop." % e.message
    exit 1
  end

  total = 0
  start = nil
  while total < SERIAL_SIZE
    data = sp.read(SERIAL_BLOCK)
    next if ! data
    out.write(data)
    total += data.size
    start = Time.now if !start && total >= SERIAL_SIZE / 2
  end
  elapsed = Time.now - start
  sp.close
  out.close
  puts "## Data Saved Successfully"
  puts "## Transfer Rate (kbit/s): %.3f" % (total / elapsed / 250)
  puts

  open(gen_file + '.txt', 'w') do |file|
    file.puts "Elapsed Time(s): %.3f" % (elapsed * 2)
    file.puts "Transfer Rate (kbit/s): %.3f" % (total / elapsed / 250)
  end
end

########################################################################