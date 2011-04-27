# Regexps, the Krav Maga of XML parsing.  There's 3TB of XML in the pages-meta-history, so DOM parsing is out, and all of the interesting data is in text nodes, not attributes,
# so for a SAX parser to discern whether an <id>12345</id> is a page/revision/contributor id requires a state machine, and that's an enormous amount of complexity.  So regexps.

# There's a consistent XML node ordering, <page><title>abc</title><revision>...</revision><revision>...</revision></page>, with consecutive revisions,
# so split by </revision>, process each one in turn, and a <title> signals a new page, and you can run with only one rev (plus a sliding text window) in memory.
# Note that we lose all of the interesting metadata this way, which we'll read from the stub-meta-history (pages-meta-history minus the text), small enough to afford DOM parsing.

# JSON makes a convenient way to serialize data from producers to consumers with encoding of characters like linebreaks, so split can easily churn through it.

require 'rubygems'
require 'json'
require 'digest/md5'

worth_processing = false

empty_revision = {:id => 0, :text => ""}
sliding_window = []
window_size = 7

STDIN.each('</revision>') {|r|
  maybe_new_title = r[%r%<title>(.+)</title>%,1]
  worth_processing = (maybe_new_title =~ /^M/ && !maybe_new_title.include?(':')) if maybe_new_title
  next unless worth_processing

  revision = r[%r%<revision[^>]*>(.+)</revision>%m,1]
  next unless revision

  sliding_window = [empty_revision] * window_size if maybe_new_title
  rid = revision[%r%<id>(\d+)</id>%,1]
  rtext = revision[%r%<text[^>]*>(.+)</text>%m,1]
  next unless rtext

  digest = Digest::MD5.hexdigest(rtext)

  window_text = sliding_window.map {|window_revision| window_revision[:text] }.join

  old_id = sliding_window.last[:id]
  sliding_window.push({:id => rid, :text => rtext})
  sliding_window.shift
  
  STDOUT.puts(JSON.dump({:new_id => rid, :old_id => old_id, :window => window_text, :text => rtext, :digest => digest}))
}
