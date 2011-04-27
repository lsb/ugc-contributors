# intended usage: ls /1/1???? | xargs -P 8 -n 1 consume.sh
(/opt/ruby-enterprise-1.8.7-2011.03/bin/ruby mh-consumer.rb < $1 > $1.csv) && rm $1