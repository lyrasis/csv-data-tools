#!/usr/bin/env ruby

# NOT FINISHED - DO NOT USE

# require 'bundler/inline'
# gemfile do
#   source 'https://rubygems.org'
#   gem 'charlock_holmes'
#   gem 'pry'
# end

# require 'fileutils'
# require 'optparse'
# require 'pry'
# require 'charlock_holmes'

# options = {}
# OptionParser.new do |opts|
#   opts.banner = 'Usage: convert_encoding.rb -i path-to-input-dir -s file-suffix'

#   opts.on('-i', '--input PATH', 'Path to input directory containing files') do |i|
#     options[:input] = File.expand_path(i)
#   end

#   opts.on('-s', '--suffix STRING', 'File suffix, without dot') do |s|
#     options[:suffix] = ".#{s.delete_prefix('.')}"
#   end

#   opts.on('-h', '--help', 'Prints this help') do
#     puts opts
#     exit
#   end
# end.parse!

# Detector = CharlockHolmes::EncodingDetector.new
# Converter = CharlockHolmes::Converter.new

# class MyFile
#   attr_reader :path
#   def initialize(path)
#     @path = path
#   end

#   def convert_to_utf8
#     puts "Converting #{path}"
#     `iconv -f #{encoding} -t UTF-8 #{path} > #{path}.conv`
#   end
  
#   def content
#     File.read(path)
#   end

#   def encoding
#     @encoding ||= Detector.detect(content)
#   end

#   def utf8?
#     encoding == 'UTF-8'
#   end

#   private


# end

# files = Dir.children(options[:input])
#   .select{ |name| name.downcase.end_with?(options[:suffix]) }
#   .map{ |name| "#{options[:input]}/#{name}" }
#   .map{ |path| MyFile.new(path) }


# files.each do |file|
#   binding.pry
# end

# # to_convert = files.reject{ |file| file.utf8? }

# # to_convert.each{ |file| file.convert_to_utf8 }
