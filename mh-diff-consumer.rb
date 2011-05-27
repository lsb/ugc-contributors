require 'rubygems'
require 'zlib'
require 'lzma'
require 'json'

class String
  def inflate() Zlib::Inflate.inflate(self) end
  def deflate() Zlib::Deflate.deflate(self, Zlib::BEST_SPEED) end
  def sha2() Digest::SHA2.hexdigest(self) end
end

$, = "|"  # output field separator
$\ = "\n" # output record separator

STDIN.each {|j|
  h = JSON.parse(j)
  window = h['window'].map {|t| t.inflate }.join
  text = h['text'].inflate
  size_difference = LZMA.compress(window + text).size - LZMA.compress(window).size
  STDOUT.print(h['id'], h['last_id'], size_difference, text.size, h['hash'], h['reverted'])
}
