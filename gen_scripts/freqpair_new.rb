# Frequency Pair Finder
# 2020-12-17 Naoki F., AIT
# New BSD License is applied. See COPYING file for details.

if ARGV.size != 2
  STDERR.puts 'usage: ruby freqpair_new.rb lower_limit upper_limit'
  exit 1
end
lower = ARGV[0].to_i
upper = ARGV[1].to_i

puts "ma\tqa\tda\tfa\tmb\tqb\tdb\tfb\tcnt"
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
        puts "%.3f\t%d\t%d\t%.3f\t%.3f\t%.3f\t%d\t%.3f\t%.1f" %
        [ma, qa, da, fa, mb, qb, db, fb, 0.5 * freq_n]
      end
    end
  end
end
      