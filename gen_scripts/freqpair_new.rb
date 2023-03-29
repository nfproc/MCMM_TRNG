# Frequency Pair Finder
# 2020-12-17 -> 2021-04-12 Naoki F., AIT
# New BSD License is applied. See COPYING file for details.

if ARGV.size != 3
  STDERR.puts 'usage: ruby freqpair_new.rb prefix lower_limit upper_limit'
  exit 1
end
prefix = ARGV[0]
lower = ARGV[1].to_i
upper = ARGV[2].to_i
freqs = Array.new
found = 0

6.upto(32) do |qa|
  48.upto(64) do |mac|
    qac = qa * 8
    ma = mac * 0.125
    fa = 100.0 * ma / qa
    da = (64.0 / ma).floor
    next if fa > 100 || fa < 50
    48.upto(256) do |qbc|
      qb = qbc * 0.125
      48.upto(64) do |mbc|
        mb = mbc * 0.125
        fb = 100.0 * mb / qb
        db = (64.0 / mb).floor
        freq_m = mac * qbc / (mac * qbc).gcd(qac * mbc)
        freq_n = qac * mbc / (mac * qbc).gcd(qac * mbc)
        next if freq_m - freq_n != 1 || freq_n < lower || freq_n > upper || freq_n % qa != 0
        found += 1
        freqpair = ["%s%02d" % [prefix, found], ma, da, qa, mb, db, qb, freq_n]
        freqs << freqpair
      end
    end
  end
end

puts "[[NORMAL]]"
puts "ID\tA_M\tA_D\tA_Q\tB_M\tB_D\tB_Q\tCNT_PERIOD"
freqs.each do |x|
  puts "%s\t%.3f\t%d\t%.3f\t%.3f\t%d\t%.3f\t%d" %
    [x[0], x[1], 1, x[3], x[4], 1, x[6], x[7]]
end
puts
puts "[[JITTERY]]"
puts "ID\tA_M\tA_D\tA_Q\tB_M\tB_D\tB_Q\tCNT_PERIOD"
freqs.each do |x|
  puts "%s\t%.3f\t%d\t%.3f\t%.3f\t%d\t%.3f\t%d" %
    [x[0], x[1] * x[2], x[2], x[3], x[4] * x[5], x[5], x[6], x[7]]
end
puts
puts "[[COMBINED]]"
puts "ID\tA_M\tA_D\tA_Q\tB_M\tB_D\tB_Q\tCNT_PERIOD"
freqs.each do |x|
  puts "%s\t%.3f\t%d\t%.3f\t%.3f\t%d\t%.3f\t%d" %
    [x[0], x[1] * x[2], x[2], 1, x[4] * x[5], x[5], x[6], x[7] / x[3]]
end