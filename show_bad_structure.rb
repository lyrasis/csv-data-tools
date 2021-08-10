#!/usr/bin/env ruby

# Takes path to table, number of columns, delimiter name, and optional row limit
# Prints to screen rows with that number of columns
# Assumes tables have been converted to TAB SEPARATED
require 'csv'
require 'fileutils'
require 'optparse'
require 'pp'
require 'pry'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: clean_convert_report.rb -i path-to-input-dir -s file-suffix -o path-to-output-directory'

  opts.on('-i', '--input PATH', 'Path to input table file') do |i|
    options[:input] = File.expand_path(i)
  end

  opts.on('-d', '--delimiter STRING', 'Delimiter name. Must be: tab, pipe, or comma') do |d|
    case d
    when 'tab'
      options[:delimiter] = '\t'
    when 'pipe'
      options[:delimiter] = '|'
    when 'comma'
      options[:delimiter] = ','
    else
      puts '-d (--delimiter) must be tab, pipe, or comma. Type the string, not the character.'
      exit
    end
  end
  
  opts.on('-c', '--columns INT', Integer, 'Number of columns in rows that will be printed') do |c|
    options[:columns] = c
  end

  opts.on('-l', '--limit [INT]', Integer, 'Number of rows that will be printed') do |l|
    options[:limit] = l || nil
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

structure = {}

File.readlines(options[:input]).each do |row|
  len = row.chomp.split(options[:delimiter]).length
  if structure.key?(len)
    structure[len] << row.chomp
  else
    structure[len] = [row.chomp]
  end
end

rows = structure[options[:columns]]

if rows.empty?
  puts "No rows with #{options[:columns]} columns"
else
  to_print = options[:limit].nil? ? rows.length - 1 : options[:limit] - 1
  rows[0..to_print].each{ |r| puts r }
end

