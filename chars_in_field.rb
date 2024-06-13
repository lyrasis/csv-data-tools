#!/usr/bin/env ruby

# For the given column/field name(s) in the given file:
#   - outputs a txt file of the unique characters used in/across the field(s)
require 'csv'
require 'fileutils'
require 'optparse'
require 'pry'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: ruby chars_in_field.rb -i path-to-input-csv '\
    "-c '{col_sep: \";\"}' "\
    '-f field1,field2 '\
    '-o path-to-output-file '

  opts.on('-i', '--input PATH',
          'REQUIRED: Path to input file') do |i|
    options[:input] = File.expand_path(i)
  end

  opts.on('-o', '--output PATH', 'Path to output file. '\
          'If not given written to input path with _chars.txt '\
          'on end') do |o|
    options[:output] = File.expand_path(o)
  end

  opts.on('-f', '--fields [ARRAY]', Array,
          'List of field/heading names to include. Defaults to all') do |f|
    options[:fields] = f
  end

  opts.on('-c', '--csvopts STRING', 'CSV options hash in single quotes') do |c|
    options[:csvopts] = eval(c)
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

unless options[:output]
  base = options[:input].delete_suffix(File.extname(options[:input]))
  options[:output] = "#{base}_chars.txt"
end

options[:opts] = if options[:csvopts]
                   options[:csvopts].merge({ headers: true })
                 else
                   { headers: true }
                 end

data = CSV.parse(File.open(options[:input], 'r'), **options[:opts])

options[:headers] = if options[:fields]
                      options[:fields].intersection(data.headers)
                    else
                      data.headers
                    end

def field_chars(hdr, data)
  data.by_col[hdr]
      .compact
      .reject(&:empty?)
      .map { |val| val.chars.uniq }
      .flatten
      .uniq
end

result = options[:headers].map { |hdr| field_chars(hdr, data) }
                          .flatten
                          .uniq
                          .sort

File.open(options[:output], 'w') do |outfile|
  result.each { |ln| outfile << "#{ln}\n" }
end
