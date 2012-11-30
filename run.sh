#! /bin/sh
export NODE_PORT=8080
export NODE_UPORT=8000
export RAILS_PORT=80
export CONSUMER_KEY='pJ2F7coxlc5jlKcmSPrLqQ';
export CONSUMER_SECRET='n0qURhYbR8ugJfET12fhb1ko4vJD18e8Kmuxlk3M884'


cd NodeXServer
rm nohup.out
nohup node app.js&
cd ../RailsXServer
rails s -d -p $RAILS_PORT

