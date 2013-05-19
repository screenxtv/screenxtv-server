#! /bin/sh
cd RailsXServer
bundle install &&
rake db:migrate RAILS_ENV=production &&
rake assets:precompile RAILS_ENV=production
