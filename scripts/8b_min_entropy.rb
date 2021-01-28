# min-entropy calculation
# 2020-02-21 Naoki F., AIT
# New BSD License is applied. See COPYING file for details.

BLOCK_SIZE = 1000

['J', 'JJ', 'JC'].each do |mode|
  1.upto(23) do |id|
    filename = "../gen_data/%s%02d.bin" % [mode, id]
    next if ! File.exist?(filename)

    dist = Array.new 256, 0
    open(filename, "rb:ASCII-8BIT") do |file|
      while block = file.read(BLOCK_SIZE) do
        block.each_byte{|b| dist[b] += 1 }
      end
    end
    odd_count   = [[0, 1] * 128, dist].transpose.reduce(0){|s, x| s + x[0] * x[1] }
    even_count  = [[1, 0] * 128, dist].transpose.reduce(0){|s, x| s + x[0] * x[1] }
    dist = dist.join(', ')
    total_count = odd_count + even_count
    min_entropy  = -Math.log2(1.0 * [even_count, odd_count].max / total_count)
    puts "%s%02d, %.6f, %d, %d, %s" %
      [mode, id, min_entropy, even_count, odd_count, dist]
  end
end