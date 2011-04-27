# mount /1 through /15 to as many disks as you like.
7z e -so /minnie/enwiki-20110317-pages-meta-history$1.xml.7z | /opt/ruby-enterprise-1.8.7-2011.03/bin/ruby mh-producer.rb | split -a 4 - /$1/$1
