#!/usr/bin/env ruby

# this script goes through all tables in a directory with the given suffix, and,
#  for each, prints the headers and first 25 rows, nicely formatted, all in one
#  text file for scrolling through/searching.

require 'csv'
require 'fileutils'
require 'optparse'
require 'ostruct'
require 'pp'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: table_preview.rb -i path-to-input-dir -s file-suffix -o path-to-output-directory'

  opts.on('-i', '--input PATH', 'Path to input directory containing files') do |i|
    options[:input] = File.expand_path(i)
  end

  opts.on('-o', '--output PATH', 'Path to output directory') do |o|
    options[:output] = File.expand_path(o)
  end

  opts.on('-s', '--suffix STRING', 'File suffix, without dot') do |s|
    options[:suffix] = ".#{s.delete_prefix('.')}"
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

files = Dir.children(options[:input])
  .select{ |name| name.downcase.end_with?(options[:suffix]) }
  .map{ |name| "#{options[:input]}/#{name}" }

# makes output dir if it doesn't exist; does nothing otherwise
FileUtils.mkdir_p(options[:output])

File.open("#{options[:output]}/table_preview.txt", 'w') do |f|
  files.each do |table|
    puts "  #{table}"
    f.puts "-=-=-=-=-=-=-=-=-=-=-=-=-"
    f.puts table
    f.puts "-=-=-=-=-=-=-=-=-=-=-=-=-"
    look = `csvlook -t --max-rows 27 #{table}`
    f.puts look
    f.puts "\n\n"
  end
end
