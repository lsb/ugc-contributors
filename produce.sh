7z e -so enwiki-20110317-pages-meta-history$1.xml.7z | /opt/ruby-enterprise-1.8.7-2011.03/bin/ruby mh-diff-producer.rb | split -l 10000 -a 4 - /$1/$1-diffs-