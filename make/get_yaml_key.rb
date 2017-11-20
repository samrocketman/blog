#!/bin/ruby
#Created by Sam Gleske
#https://github.com/samrocketman/blog
#Reads a yaml key from _config.yml

require 'yaml'

if ARGV.size > 0 then
  config = YAML::load_file('_config.yml')
  result = config[ARGV[0].to_s]
  if result then
    puts result
  end
end
