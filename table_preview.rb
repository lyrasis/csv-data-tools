#!/usr/bin/env ruby

# this script goes through all tables in a directory with the given suffix, and,
#  for each, prints the headers and first 25 rows, nicely formatted, all in one
#  text file for scrolling through/searching.

require 'csv'
require 'fileutils'
require 'optparse'
require 'ostruct'
require 'pp'
require 'pry'

# -d / -t are handled by the option you use to run the script
# other options from https://csvkit.readthedocs.io/en/1.0.6/scripts/csvlook.html and
#   https://csvkit.readthedocs.io/en/1.0.6/common_arguments.html can be set as a string here

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: table_preview.rb -i path-to-input-dir -s file-suffix -o path-to-output-directory -d comma'

  opts.on('-i', '--input PATH', 'Path to input directory containing files') do |i|
    options[:input] = File.expand_path(i)
  end

  opts.on('-o', '--output PATH', 'Path to output file') do |o|
    options[:output] = File.expand_path(o)
  end

  opts.on('-s', '--suffix STRING', 'File suffix, without dot') do |s|
    options[:suffix] = ".#{s.delete_prefix('.')}"
  end

  opts.on('-d', '--delimiter STRING', 'comma, pipe, tab, or literal string') do |d|
    options[:delimiter] = d
  end

  opts.on('-m', '--max_rows INTEGER', 'maximum number of rows to output') do |m|
    options[:max_rows] = m
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

CustomCsvlookOptions = '-u 1 -y 0 -I'

def get_delim_opt(delim)
  lookup = {
    'comma' => '-d ,',
    'pipe' => '-d |',
    'tab' => '-t'
  }

  common_value = lookup[delim]
  return common_value if common_value

  "-d #{delim}"
end

delim_opt = get_delim_opt(options[:delimiter])


files = Dir.children(options[:input])
  .select{ |name| name.downcase.end_with?(options[:suffix]) }
  .map{ |name| "#{options[:input]}/#{name}" }

File.open(options[:output], 'w') do |f|
  files.each do |table|
    puts "  #{table}"
    f.puts "-=-=-=-=-=-=-=-=-=-=-=-=-"
    f.puts table
    f.puts "-=-=-=-=-=-=-=-=-=-=-=-=-"
    cmd = "csvlook #{delim_opt} #{CustomCsvlookOptions} --max-rows #{options[:max_rows]} #{table}"
    look = `#{cmd}`
    f.puts look
    f.puts "\n\n"
  end
end
