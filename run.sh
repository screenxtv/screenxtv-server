#! /bin/sh
export NODE_PORT=8800
export NODE_UPORT=8000
export RAILS_PORT=8008
export CONSUMER_KEY=pJ2F7coxlc5jlKcmSPrLqQ
export CONSUMER_SECRET=n0qURhYbR8ugJfET12fhb1ko4vJD18e8Kmuxlk3M884
export NEWS_CONSUMER_KEY=Ve2c9FEbmgBxTD3Tcg5mWw
export NEWS_CONSUMER_SECRET=jFqj9ARRLFHvHnEoqm95BIWXEboIh1qOLb5KPv2WCg
export NEWS_ACCESS_TOKEN=1003487647-27gvEUidncxAJJ506TOu5CbpmtCwPziqtbf17B3
export NEWS_TOKEN_SECRET=lZvuckd6MRTcNvySGZmCHZjkhkIhdMDJIbtB7js4aak

cd NodeXServer
curl localhost:$NODE_PORT/ ||nohup node app.js&
cd ../RailsXServer
unicorn_rails -E production -p $RAILS_PORT -D -c config/unicorn.rb
#RAILS_ENV=production rails s -p 4000