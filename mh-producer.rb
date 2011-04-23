require 'rubygems'
require 'json'
require 'digest/md5'

worth_processing = false

empty_revision = {:id => 0, :text => ""}
sliding_window = []
window_size = 7

STDIN.each('</revision>') {|r|
  maybe_new_title = r[%r%<title>(.+)</title>%,1]
  worth_processing = (maybe_new_title[/^M/] && !maybe_new_title.include?(':')) if maybe_new_title
  next unless worth_processing

  revision = r[%r%<revision[^>]*>(.+)</revision>%m,1]
  next unless revision

  (sliding_window = [empty_revision] * window_size) if maybe_new_title
  rid = revision[%r%<id>(\d+)</id>%,1]
  rtext = revision[%r%<text[^>]*>(.+)</text>%m,1].tr("\n"," ") rescue nil
  next unless rtext

  digest = Digest::MD5.hexdigest(rtext)

  window_text = sliding_window.map {|window_revision| window_revision[:text] }.join

  old_id = sliding_window.last[:id]
  sliding_window.push({:id => rid, :text => rtext})
  sliding_window.shift
  
  STDOUT.puts(JSON.dump({:new_id => rid, :old_id => old_id, :window => window_text, :text => rtext, :digest => digest}))
}
