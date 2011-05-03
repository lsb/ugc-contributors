require 'rubygems'
require 'zlib'
require 'nokogiri'
require 'lzma'
require 'digest/md5'
require 'date'

class String
  def inflate ; Zlib::Inflate.inflate self ; end
  def deflate ; Zlib::Deflate.deflate self ; end
  def sha2 ; Digest::SHA2.hexdigest self ; end
end

Revision = Struct.new(:id, :time, :ztext, :hash, :reverted)

$, = "|"  # output field separator
$\ = "\n" # output record separator

worth_processing = false
$all_revisions = []

def flush_page
  handle_reversions
  window = [Revision.new(0,0,"".deflate,"",0)] * 7
  $all_revisions.each {|r|
    rtext = r['ztext'].inflate
    window_text = window.map {|wrev| wrev['ztext'].inflate }.join
    size_difference = LZMA.compress(window_text + rtext).size - LZMA.compress(window_text).size
    STDOUT.print(r['id'], window.last['id'], size_difference, rtext.size, r['hash'], r['reverted'])
    window = window[1..-1] + [r] if r['reverted'].zero?
  }
  $all_revisions = []
end

def handle_reversions
  hashes = Hash.new([])
  $all_revisions.each_with_index {|r,i| hashes[r['hash']] += [i] }
  $all_revisions.reverse.each {|r|
    next unless r['reverted'].zero?
    reversion_window = hashes[r['hash']]
    next if reversion_window.size == 1
    (reversion_window.first+1 ... reversion_window.last).each {|j| $all_revisions[j]['reverted'] = 1 }
    hashes[r['hash']] = [reversion_window.first]
  }
end

STDIN.each('</revision>') {|r|
  maybe_new_title = r[%r%<title>(.+)</title>%,1]  # cheap trick: a pages' title always comes before its revisions
  if maybe_new_title
    flush_page if worth_processing
    worth_processing = maybe_new_title =~ /^M/ && !maybe_new_title.include?(':')
  end
  next unless worth_processing
  revision = Nokogiri::HTML(r)
  rtext = revision.at('revision > text')
  next unless rtext
  rid = revision.at('revision > id')
  rtime = revision.at('revision > timestamp')
  epochtime = DateTime.parse(rtime.text).strftime("%s")
  $all_revisions.push(Revision.new(rid.text, epochtime, rtext.text.deflate, rtext.text.sha2, 0))
}
