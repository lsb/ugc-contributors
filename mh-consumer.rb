require 'rubygems'
require 'lzma'
require 'json'
require 'digest/md5'
require 'english'

$OFS = "|"

STDIN.each {|revision_json|
  r = JSON.parse(revision_json)
  throw 'corrupted' unless r['digest'] == Digest::MD5.hexdigest(r['text'])

  size_difference = LZMA.compress(r['window'] + r['text']).size - LZMA.compress(r['window']).size

  STDOUT.print(r['new_id'], r['old_id'], size_difference, r['digest'] << "\n")
}

