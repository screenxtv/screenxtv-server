#! /bin/sh
export NODE_PORT=8800
export NODE_UPORT=8000
export RAILS_PORT=8008
export CONSUMER_KEY=pJ2F7coxlc5jlKcmSPrLqQ
export CONSUMER_SECRET=n0qURhYbR8ugJfET12fhb1ko4vJD18e8Kmuxlk3M884

cd NodeXServer
curl localhost:$NODE_PORT/ ||nohup node app.js&
cd ../RailsXServer
unicorn_rails -E production -p $RAILS_PORT -D


