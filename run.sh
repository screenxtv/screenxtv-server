#! /bin/sh
export NODE_PORT=8800
export NODE_UPORT=8000
export RAILS_PORT=8008
export CONSUMER_KEY=pJ2F7coxlc5jlKcmSPrLqQ
export CONSUMER_SECRET=n0qURhYbR8ugJfET12fhb1ko4vJD18e8Kmuxlk3M884
export NEWS_ACCESS_TOKEN=56388372-TPTVPxfguCqK3bIcSwHhOfYNQXvcWOlQqw1192iuM
export NEWS_TOKEN_SECRET=5rMb4YX190QXNfLwTI1jHi9JetpXTOBTAXUltgUu9z4

cd NodeXServer
#curl localhost:$NODE_PORT/ ||nohup node app.js&
cd ../RailsXServer
#unicorn_rails -E production -p $RAILS_PORT -D
RAILS_ENV=production rails s -p $RAILS_PORT



