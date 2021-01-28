# AIS-31 Test suite
# 2019-10-16 Naoki F., AIT
# New BSD License is applied. See COPYING file for details.

class Ais31
  # All test functions input a bitstring and output an array A
  # A[0] is array of "PASS" or "FAIL", A[1] is the number of used input bits
  BIT_PROC_A  = 8285728
  BIT_TEST_T0 = 3145728
  BIT_TEST_A  = 20000
  BIT_TEST_B  = 100000
  RUN_MIN = [2267, 1079, 502, 223,  90,  90]
  RUN_MAX = [2733, 1421, 748, 402, 223, 223]
  Q_T8 = 2560
  K_T8 = 256000

  def self.procedure_a (bits)
    if bits.length < BIT_PROC_A
      STDERR.puts "!! The input bitstring is too short. Stop."
      exit 1
    end
    puts "[[ AIS-31 Test Procedure A ]]"
    failure = nil
    2.times do |trial|
      results = Array.new
      results += self.test_t0(bits)[0]
      bits = bits[BIT_TEST_T0..-1]
      257.times do |i|
        puts "[Iteration %3d]" % (i + 1)
        [:test_t1, :test_t2, :test_t3, :test_t4, :test_t5].each do |t|
          results += self.method(t).call(bits)[0]
        end
        bits = bits[BIT_TEST_A..-1]
      end
      failure = results.reduce(0){|s, x| s + ((x == "FAIL") ? 1 : 0) }
      puts
      puts "## Number of FAILed Tests (out of 1286): %d" % failure
      break if failure != 1 || trial != 0 || bits.length < BIT_PROC_A
      puts "## Exactly one test has failed. Retrying..."
    end
    if failure == 0
      puts "## Test Procedure A is PASSED!!!"
      puts
      return [["PASS"], BIT_PROC_A]
    else
      puts "## Test Procedure A is FAILED..."
      puts
      return [["FAIL"], BIT_PROC_A]
    end
  end

  def self.procedure_b (bits)
    puts "[[ AIS-31 Test Procedure B ]]"
    failure = nil
    total = bits.length
    2.times do |trial|
      results = Array.new
      [:test_t6, :test_t7a, :test_t7b, :test_t7c, :test_t8].each do |t|
        result = self.method(t).call(bits)
        results += result[0]
        bits = bits[result[1]..-1]
      end
      failure = results.reduce(0){|s, x| s + ((x == "FAIL") ? 1 : 0) }
      puts
      puts "## Number of bits used: %d" % (total - bits.length)
      puts "## Number of FAILed Tests (out of 9): %d" % failure
      break if failure != 1 || trial != 0
      puts "## Exactly one test has failed. Retrying..."
    end
    if failure == 0
      puts "## Test Procedure B is PASSED!!!"
      puts
      return [["PASS"], total - bits.length]
    else
      puts "## Test Procedure B is FAILED..."
      puts
      return [["FAIL"], total - bits.length]
    end
  end

  def self.test_t0 (bits)
    bits = bits[0..BIT_TEST_T0-1]
    num_unique = bits.scan(/.{48}/).uniq.size
    result = (num_unique == 65536) ? "PASS" : "FAIL"
    puts "T0 : %s => # of unique bitstrings = %d (65536)" % [result, num_unique]
    return [[result], BIT_TEST_T0]
  end

  def self.test_t1 (bits)
    bits = bits[0..BIT_TEST_A-1]
    ones = bits.bytes.reduce(0){|s, x| s + (x & 1) }
    result = (ones >= 9655 && ones <= 10345) ? "PASS" : "FAIL"
    puts "T1 : %s => # of ones = %d (9655-10345)" % [result, ones]
    return [[result], BIT_TEST_A]
  end

  def self.test_t2 (bits)
    bits = bits[0..BIT_TEST_A-1]
    freq = Array.new(16, 0)
    bits.scan(/..../).each{|x| freq[x.to_i(2)] += 1 }
    t2 = 16.0 / 5000 * freq.reduce(0){|s, x| s + x * x } - 5000
    result = (t2 > 1.03 && t2 < 57.4) ? "PASS" : "FAIL"
    puts "T2 : %s => Test value = %.3f (1.03-57.4)" % [result, t2]
    return [[result], BIT_TEST_A]
  end

  def self.test_t3 (bits)
    bits = bits[0..BIT_TEST_A-1].bytes.map{|x| x & 1 }
    runs = Array.new
    runs[0] = Array.new 6, 0
    runs[1] = Array.new 6, 0
    cur = bits[0]
    len = 0
    1.upto(19999) do |i|
      if cur != bits[i]
        runs[cur][len] += 1
        cur = bits[i]
        len = 0
      else
        len = (len < 5) ? len + 1 : 5
      end
    end
    runs[cur][len] += 1
    result = "PASS"
    runs.each do |run|
      run.each_index {|i| result = "FAIL" if run[i] < RUN_MIN[i] || run[i] > RUN_MAX[i] }
    end
    print "T3 : %s => Run |" % result
    runs[0].each_index{|i| print " %d(%4d-%4d) |" % [i + 1, RUN_MIN[i], RUN_MAX[i]] }
    puts
    runs.each_index do |i|
      print "             %ds  |" % i
      runs[i].each{|x| print " %11d  |" % x }
      puts
    end
    return [[result], BIT_TEST_A]
  end

  def self.test_t4 (bits)
    bits = bits[0..BIT_TEST_A-1].bytes.map{|x| x & 1 }
    cur = bits[0]
    len = 1
    longest = 1
    1.upto(19999) do |i|
      if cur != bits[i]
        cur = bits[i]
        len = 1
      else
        len = len + 1
        longest = len if longest < len
      end
    end
    result = (longest <= 33) ? "PASS" : "FAIL"
    puts "T4 : %s => Longest run = %d (1-33)" % [result, longest]
    return [[result], BIT_TEST_A]
  end

  def self.test_t5 (bits)
    bits = bits[0..BIT_TEST_A-1].bytes.map{|x| x & 1 }
    tau = 0
    max_dif = -1
    1.upto(5000) do |i|
      t5 = (0..4999).to_a.reduce(0){|s, x| s + (bits[x] ^ bits[x + i]) }
      dif = (t5 - 2500).abs
      if dif > max_dif
        tau = i
        max_dif = dif
      end
    end
    t5 = (10000..14999).to_a.reduce(0){|s, x| s + (bits[x] ^ bits[x + tau]) }
    result = (t5 >= 2327 && t5 <= 2673) ? "PASS" : "FAIL"
    puts "T5 : %s => value of T5(%d) = %d (2327-2673)" % [result, tau, t5]
    return [[result], BIT_TEST_A]
  end
  
  def self.test_t6 (bits)
    bits = bits[0..BIT_TEST_B-1]
    ones = bits.bytes.reduce(0){|s, x| s + (x & 1) }
    result = (ones >= 47500 && ones <= 52500) ? "PASS" : "FAIL"
    puts "T6 : %s => # of ones = %d (47500-52500)" % [result, ones]
    return [[result], BIT_TEST_B]
  end

  def self.collect_tuples (bits, len)
    num_tf = 2 ** (len - 1)
    total  = 0
    rest   = BIT_TEST_B * num_tf;
    occs   = Array.new(num_tf, 0)
    ones   = Array.new(num_tf, 0)
    while rest > 0
      if total + len > bits.length
        STDERR.puts "!! The input bitstring ran out. Stop."
        exit 1
      end
      tuple = bits[total..total+len-1]
      tf = tuple[0..-2].to_i(2)
      if occs[tf] < BIT_TEST_B
        occs[tf] += 1
        ones[tf] += 1 if tuple[-1] == '1'
        rest -= 1
      end
      total += len
    end
    return [ones, total]
  end

  def self.test_t7a (bits)
    ones, total = collect_tuples(bits, 2)
    vemp01 = ones[0].fdiv(BIT_TEST_B)
    vemp10 = 1.0 - ones[1].fdiv(BIT_TEST_B)
    result = ((vemp01 + vemp10 - 1).abs < 0.02) ? "PASS" : "FAIL"
    puts "T7a: %s => vemp0(1) = %.5f, vemp1(0) = %.5f, sum = %.5f (0.98-1.02)" %
      [result, vemp01, vemp10, vemp01 + vemp10]
    return [[result], total]
  end

  def self.test_t7 (bits, postfix, len)
    ones, total = collect_tuples(bits, len)
    num_cp = ones.size / 2
    results = Array.new
    num_cp.times do |i|      
      f01  = ones[i]
      f00  = BIT_TEST_B - f01
      f11  = ones[i + num_cp]
      f10  = BIT_TEST_B - f11
      np1  = (f01 + f11) / 2.0
      np0  = (f00 + f10) / 2.0
      chi2 = ((f00 - np0) ** 2 + (f10 - np0) ** 2) / np0 +
             ((f01 - np1) ** 2 + (f11 - np1) ** 2) / np1
      result = (chi2 <= 15.136) ? "PASS" : "FAIL"
      puts "T7%s: %s => vemp%%0%db(1) = %.5f, vemp%%0%db(1) = %.5f, chi-sq = %.3f (0-15.136)" %
        [postfix, result, len - 1, f01.fdiv(BIT_TEST_B), len - 1, f11.fdiv(BIT_TEST_B), chi2] %
        [i, i + num_cp]
      results << result
    end
    return [results, total]
  end
  
  def self.test_t7b (bits) self.test_t7(bits, 'b', 3) end
  def self.test_t7c (bits) self.test_t7(bits, 'c', 4) end

  def self.test_t8 (bits, k = K_T8)
    bit_test_q8 = (Q_T8 + k) * 8
    if bits.length < bit_test_q8
      STDERR.puts "!! The input bitstring is too short. Stop."
      exit 1
    end
    bits = bits[0..bit_test_q8-1].scan(/.{8}/).map{|x| x.to_i(2) }
    last = Array.new(256, -1)
    dists = Array.new
    (Q_T8 + k).times do |i|
      if i >= Q_T8
        dist = i - last[bits[i]]
        dists[dist] = (dists[dist] || 0) + 1
      end
      last[bits[i]] = i
    end
    gi = 0.0
    g_sum = 0.0
    dists.each_index do |i|
      gi += 1.0 / (i - 1) if i >= 2
      next if ! dists[i]
      g_sum += gi * dists[i]
    end
    entropy = g_sum / k / Math.log(2) / 8
    result = (entropy > 0.997) ? "PASS" : "FAIL"
    puts "T8 : %s => estimated entropy per bit = %.6f (0.997-)" % [result, entropy]
    return [[result], bit_test_q8]
  end
end