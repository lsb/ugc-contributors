# Rip the XML apart at the seams of pages, ensure the title's prefix is good, and then use Nokogiri's DOM parsing to have something more intelligible than regexps.
# Ideally, we'd pull out the metadata as we run the producer, but stripping all this out with regexps would be heinous, and the full pages are too big for DOM parsing.

require 'rubygems'
require 'nokogiri'
require 'ipaddr'
require 'date'
require 'digest/md5'
require 'english'

Billion = 1_000_000_000
$OFS = '|'

IO.popen('sort -u > users.tsv','w') {|uf| # id, name
  File.open('pages.tsv','w') {|pf| # id, title
    File.open('revisions.tsv','w') {|rf| # id, user_id, page_id, epochtime
      STDIN.each('</page>') {|page|
        next unless page =~ /<title>M/

        nokopage = Nokogiri::XML(page)

        page_id = nokopage.at('page > id').text
        page_title = nokopage.at('page > title').text
        pf.print(page_id, page_title << "\n")

        nokopage.css('revision').each {|rev|
          rev_id = rev.at('id').text
          rev_time = rev.at('timestamp').text
          rev_epochtime = DateTime.parse(rev_time).strftime('%s')

          user = rev.at('contributor')
          user_name = nil
          user_id = nil

          if rev.at('contributor')['deleted']
            user_name = "vandalism/deleted/deleted"
            user_id = -1
          else
            maybe_username = user.at('username')
            if maybe_username
              user_id = user.at('id').text
              user_name = maybe_username.text
            else
              user_name = user.at('ip').text
              user_id = (Billion + IPAddr.new(user_name).to_i) rescue (-Billion - Digest::MD5.hexdigest(user_name)[0,15].to_i(16))
            end
          end
          uf.print(user_id, user_name << "\n")
          rf.print(rev_id, user_id, page_id, rev_epochtime << "\n")
        }
      }
    }
  }
}