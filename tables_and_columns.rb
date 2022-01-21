#!/usr/bin/env ruby

# outputs two CSV files for use in putting together the data review Excel sheet
require 'csv'
require 'fileutils'
require 'optparse'
require 'ostruct'
require 'pp'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: tables_and_columns.rb -i path-to-input-dir -s file-suffix -o path-to-output-directory -d comma'

  opts.on('-i', '--input PATH', 'Path to input directory containing files') do |i|
    options[:input] = File.expand_path(i)
  end

  opts.on('-o', '--output PATH', 'Path to output directory') do |o|
    options[:output] = File.expand_path(o)
  end

  opts.on('-s', '--suffix STRING', 'File suffix, without dot') do |s|
    options[:suffix] = ".#{s.delete_prefix('.')}"
  end

  opts.on('-d', '--delimiter STRING', 'Field delimiter: tab, comma, pipe, unitsep ') do |d|
    lookup = {
      'comma' => ',',
      'pipe' => '|',
      'tab' => "\t",
      'unitsep' => '␟'
    }
    delim = lookup[d]
    unless delim
      puts "Delimiter must be one of: #{lookup.keys.join(',')}"
      exit
    end
    
    options[:delimiter] = delim
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

# makes dir if it doesn't exist; does nothing otherwise
FileUtils.mkdir_p(options[:output])

# create hash to hold openstruct objects with data about each file, with file path as keys
filedata = {}

# get list of files
files = Dir.children(options[:input])
  .select{ |name| name.downcase.end_with?(options[:suffix]) }
  .map{ |name| "#{options[:input]}/#{name}" }

# create key value pairs in filedata, populating keys with file paths and values with empty OpenStructs
files.each do |file|
  filedata[file] = OpenStruct.new(
    filename: File.basename(file, options[:suffix]).sub(/_l$/, ''),
    row_ct: nil,
    column_ct: nil,
    columns: []
    )
end

# populate rest of openstruct for each file
files.each do |file|
  # get row count
  rowct = %x{sed -n '=' #{file} | wc -l}.to_i
  filedata[file].row_ct = rowct - 1

  headers = File.open(file, &:gets).chomp.split(options[:delimiter])
  filedata[file].column_ct = headers.size
  filedata[file].columns = headers 
end

CSV.open("#{options[:output]}/tables.csv", 'w') do |csv|
  csv << %w[table column_ct row_ct]
  filedata.each{ |k, v| csv << [v.filename, v.column_ct, v.row_ct] }
end

CSV.open("#{options[:output]}/columns.csv", 'w') do |csv|
  csv << %w[table column]
  filedata.each do |k, v|
    v.columns.each{ |c| csv << [v.filename, c.delete_prefix('"').delete_suffix('"')] }
  end
end


