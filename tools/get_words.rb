require 'open-uri'
require 'zlib'


CHAR_MIN = 2
CHAR_MAX = 5


output_dir = ARGV.shift || './data'
words = []

puts 'Downloading skk large dictionary...'
packed_dict = open('http://openlab.jp/skk/dic/SKK-JISYO.L.unannotated.gz')

puts 'Unpacking skk dictionary file...'
dict_data = Zlib::GzipReader.wrap(packed_dict).read

dict_data.encode!('UTF-8', 'EUC-JP')

puts 'Extracting words...'
dict_data
  .each_line
  .lazy
  .drop_while {|line| line !~ /;; okuri-nasi entries\./ }
  .reject {|line| line =~ /^;/ }
  .each do |line|
    m = line.match(%r{/.+/})
    next unless m
    words.concat(m[0].split('/').select {|w| w =~ /^\p{Han}{#{CHAR_MIN},#{CHAR_MAX}}$/ })
  end

words.sort!
words.uniq!

puts 'Outputting the word data files...'
Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
IO.write("#{output_dir}/all_words.txt", words.join("\n"))
(CHAR_MIN..CHAR_MAX).each do |n|
  IO.write("data/#{n}words.txt", words.select {|w| w.length == n }.join("\n"))
end

puts 'Done.'
