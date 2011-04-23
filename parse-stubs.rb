require 'ipaddr' ; require 'date' ; require 'digest/md5'
HundredBillion = 100_000_000_000

IO.popen("sort -u > users#{ARGV[0]}.tsv",'w') {|uf| # id, name
  File.open("pages#{ARGV[0]}.tsv",'w') {|pf| # id, title
    File.open("revisions#{ARGV[0]}.tsv",'w') {|rf| # id, user_id, page_id, epochtime
      STDIN.each('</page>') {|page|
        page_title = page[/<title>(M[^<]*)<\/title>/,1]
	next unless page_title
        page_id = page[/<id>(\d+)<\/id>/,1]
	next unless page_id
        pf.print("#{page_id}\t#{page_title}\n")

        page.scan(/<revision>.+?<\/revision>/m) {|rev|
          rev_id = rev[/<id>(\d+)<\/id>/,1]
          rev_time = rev[/<timestamp>(.+)<\/timestamp>/,1]
          rev_epochtime = DateTime.parse(rev_time).strftime('%s')

          user_id = nil
          user_name = nil

          if rev[/<contributor deleted="deleted"/]
	    user_name = "deleted/deleted/vandal"
	    user_id = -1
	  else
	    user = rev[/<contributor>(.+?)<\/contributor>/m,1]
	    username = user[/<username>(.+?)<\/username>/,1]
	    if username
	      user_name = username
	      user_id = user[/<id>(\d+)<\/id>/,1]
	    else
	      user_name = user[/<ip>(.+)<\/ip>/,1] || ''
              user_id = (HundredBillion+IPAddr.new(user_name).to_i) rescue (- Digest::MD5.hexdigest(user_name)[0,16].to_i(16))
            end
          end

          throw "no contributor: #{rev.text}" unless user_id

          uf.print("#{user_id}\t#{user_name}\n")
          rf.print("#{rev_id}\t#{user_id}\t#{page_id}\t#{rev_epochtime}\n")
        }
      }
    }
  }
}