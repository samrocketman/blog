#!/bin/ruby
#Created by Sam Gleske
#https://github.com/samrocketman/blog
#Updates the date for post history

require 'yaml'

#get timezone (in date format) from _config.yml
timezone = YAML::load_file('_config.yml')['timezone']
if timezone then
  timezone = "TZ=\"#{timezone}\" "
else
  timezone = ''
end

file = '_data/updated.yml'
if File.exist?(file) then
  updated = YAML::load_file(file)
else
  updated = Hash.new
end

Dir.glob('_posts/*.md') do |md_file|
  updated_date = `git log -1 --format=format:%at #{md_file} | #{timezone}xargs -I '{}' -- date -d '@{}' '+%b %d, %Y'`.strip
  updated[md_file.to_s] = updated_date.to_s
end

#sort hashmap
updated = Hash[updated.sort]

File.write(file, updated.to_yaml(options = {:line_width => -1}))
