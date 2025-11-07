#!/usr/bin/env ruby

require 'bundler/inline'
gemfile do
  source 'https://rubygems.org'
  gem 'charlock_holmes'
end

require 'fileutils'
require 'optparse'
require 'charlock_holmes'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: convert_encoding.rb -i path-to-input-dir "\
    "-s file-suffix -o path-to-output-dir"

  opts.on('-i', '--input PATH', 'Path to input directory containing files') do |i|
    options[:input] = File.expand_path(i)
  end

  opts.on('-s', '--suffix STRING', 'File suffix, without dot') do |s|
    options[:suffix] = ".#{s.delete_prefix('.')}"
  end

  opts.on('-o', '--output PATH', 'Path to output directory') do |o|
    options[:output] = File.expand_path(o)
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

class MyFile
  attr_reader :path, :outpath
  def initialize(path, outpath)
    @path = path
    @outpath = outpath
  end

  def detect
    @detected_encoding ||=
      CharlockHolmes::EncodingDetector.detect(content)
    end

  def convert
    str = converted
    return unless str

    File.open(outpath, "w") do |f|
      f.write(str)
    end
  end

  def converted
    str = CharlockHolmes::Converter.convert(content, encoding, 'UTF-8')
    puts "Converted #{path} from #{encoding} to UTF-8"
    str
  rescue ArgumentError=> err
    if err.message == "U_FILE_ACCESS_ERROR"
      puts "\n#{path} too short to detect/convert\n"
    else
      puts "\n#{err}\n"
    end
    nil
  end

  def content
    File.read(path)
  end

  def encoding
    @encoding ||= detect[:encoding]
  end

  def encoding_ok?
    ["UTF-8"].include?(encoding)
  end
end

Dir.children(options[:input])
  .select{ |name| name.downcase.end_with?(options[:suffix]) }
  .each do |filename|
    filepath = Pathname.new(File.join(options[:input], filename))
    outpath = File.join(options[:output], filepath.basename)
    file = MyFile.new(filepath, outpath)
    next if file.encoding_ok?

    file.convert
  end
