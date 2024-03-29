#!/usr/bin/env ruby
require 'csv'
require 'json'

if ARGV.size != 2
  puts 'Usage: csv_to_json input_file.csv output_file.json'
  puts 'This script uses the first line of the csv file as the keys for the JSON properties of the objects'
  exit(1)
end

lines = CSV.open(ARGV[0], headers: true)
File.open(ARGV[1], 'w') do |f|
  data = lines.map(&:to_h)
  f.puts JSON.pretty_generate(data)
end

