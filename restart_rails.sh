#! /bin/sh
#restart rails
cd RailsXServer
kill -INT `pgrep -f 'unicorn_rails master'`
unicorn_rails -E production -p 8008 -D -c config/unicorn.rb
