#!/usr/bin/env ruby

# Print to screen the results of `file` command for all
require 'optparse'
require 'pathname'
require 'pp'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: file_info.rb -i path-to-input-dir -s file-suffix -m min-file-size'

  opts.on('-i', '--input PATH', 'Path to input directory containing files') do |i|
    options[:input] = File.expand_path(i)
  end

  opts.on('-s', '--suffix STRING', 'File suffix, without dot') do |s|
    options[:suffix] = ".#{s.delete_prefix('.')}"
  end

  opts.on('-m', '--min-file-size INTEGER', 'Minimum file size to report on, in bytes') do |m|
    options[:min_file_size] = m
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

options[:min_file_size] = 1 if options[:min_file_size].nil?

files = Dir.children(options[:input])
  .select{ |name| name.downcase.end_with?(options[:suffix]) }
  .map{ |name| "#{options[:input]}/#{name}" }

results = {}

FileData = Struct.new(:size, :file)

def get_file_info(file)
  info = `file #{file}`
rescue StandardError => e
  e
else
  info.delete_prefix("#{file}: ")
end

files.each do |file|
  size = File.size(file)
  next unless size >= options[:min_file_size]

  results[Pathname.new(file).basename] = FileData.new(size, get_file_info(file))
end

results.keys.sort.each do |file|
  filedata = results[file]
  msg = <<~MSG
  #{file}:
    size: #{filedata.size}
    info: #{filedata.file}

  MSG
  puts msg
end

