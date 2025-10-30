#!/usr/bin/env ruby

# outputs two CSV files for use in putting together the data review Excel sheet
require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "caxlsx"
  gem "csv"
  gem "ostruct"
end

require "fileutils"
require "optparse"

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: tables_and_columns.rb -i path-to-input-dir "\
    "-s file-suffix -d comma -o path-to-output-file.xlsx"

  opts.on("-i", "--input PATH", "Path to input directory containing files") do |i|
    options[:input] = File.expand_path(i)
  end

  opts.on("-o", "--output PATH", "Path to output file (xlsx extension)") do |o|
    unless o.end_with?(".xlsx")
      puts "Output file name must have .xlsx extension"
      exit
    end

    options[:output] = File.expand_path(o)
  end

  opts.on("-s", "--suffix STRING", "File suffix, without dot") do |s|
    options[:suffix] = ".#{s.delete_prefix(".")}"
  end

  opts.on("-d", "--delimiter STRING", "Field delimiter: tab, comma, pipe, unitsep ") do |d|
    lookup = {
      "comma" => ",",
      "pipe" => "|",
      "tab" => "\t",
      "unitsep" => "␟"
    }
    delim = lookup[d]
    unless delim
      puts "Delimiter must be one of: #{lookup.keys.join(",")}"
      exit
    end

    options[:delimiter] = delim
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

unless options[:output]
  options[:output] = File.join(options[:input], "tables_and_columns.xlsx")
end

# create hash to hold openstruct objects with data about each file, with file path as keys
filedata = {}

# get list of files
files = Dir.children(options[:input])
  .select{ |name| name.downcase.end_with?(options[:suffix]) }
  .map{ |name| "#{options[:input]}/#{name}" }

# create key value pairs in filedata, populating keys with file paths and values with empty OpenStructs
files.each do |file|
  filedata[file] = OpenStruct.new(
    filename: File.basename(file, options[:suffix]).sub(/_l$/, ""),
    row_ct: nil,
    column_ct: nil,
    columns: []
    )
end

# populate rest of openstruct for each file
files.each do |file|
  rowct = %x{sed -n "=" #{file} | wc -l}.to_i
  puts "Processing #{file} (#{rowct} rows)"
  if rowct == 0
    filedata[file].row_ct = rowct
    filedata[file].column_ct = 0
    filedata[file].columns = []
    next
  end

  filedata[file].row_ct = rowct - 1
  headers = File.open(file, &:gets).chomp.split(options[:delimiter])
  filedata[file].column_ct = headers.size
  filedata[file].columns = headers
end

def write(outfile, filedata)
  p = Axlsx::Package.new
  wb = p.workbook
  prepare_tables_sheet(wb, filedata)
  prepare_columns_sheet(wb, filedata)
  p.serialize(outfile)
end

def prepare_tables_sheet(wb, filedata)
  wb.add_worksheet(name: "tables") do |sheet|
    headers = %w[table column_ct row_ct]
    sheet.add_row(headers)
    filedata.values.each { |v| sheet.add_row([v.filename, v.column_ct, v.row_ct]) }
  end
end

def prepare_columns_sheet(wb, filedata)
  wb.add_worksheet(name: "columns") do |sheet|
    headers = %w[table column column_position]
    sheet.add_row(headers)
    filedata.values
      .each do |v|
      v.columns.each_with_index do |c, i|
        sheet.add_row([
          v.filename,
          c.delete_prefix('"').delete_suffix('"'),
          i + 1
        ])
      end
    end
  end
end

write(options[:output], filedata)
