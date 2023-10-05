#!/usr/bin/env ruby

# For each given file:
#   - outputs a txt file for each column, listing unique values (with occurrence
#   count for each)
#   - outputs to STDOUT column name, number of rows, and number of unique values
require "csv"
require "fileutils"
require "optparse"
require "pathname"
require "pry"

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby reformat_tables.rb -i path-to-input-dir "\
    "-s file-suffix -o path-to-output-directory"

  opts.on("-i", "--input PATH",
    "Path to input directory containing files") do |i|
    options[:input] = File.expand_path(i)
  end

  opts.on("-o", "--output PATH", "Path to output directory") do |o|
    options[:output] = File.expand_path(o)
  end

  opts.on("-s", "--suffix STRING", "File suffix, without dot") do |s|
    options[:suffix] = ".#{s.delete_prefix(".")}"
  end

  opts.on("--input_sep STRING", "Column separator in input files") do |x|
    options[:input_sep] = x
  end

  opts.on("--input_esc STRING", "Escape character in input files") do |x|
    options[:input_esc] = x
  end

  opts.on("--output_sep STRING", "Column separator in output files") do |x|
    options[:output_sep] = x
  end

  opts.on("--output_esc STRING", "Escape character in output files") do |x|
    options[:output_esc] = x
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

if options.key?(:output)
  if Dir.exist?(options[:output])
    output = options[:output]
    children = Pathname.new(output).children
    FileUtils.rm(children) unless children.empty?
  else
    FileUtils.mkdir_p(options[:output])
  end
else
  outdir = File.join(options[:input], "reformatted")
  options[:output] = outdir
  FileUtils.mkdir_p(outdir)
end

options[:suffix] = ".csv" unless options.key?(:suffix)

class InFile
  def initialize(path:, options:)
    @path = path.to_s
    @outdir = options[:output]
    @args = {
      input_sep: options[:input_sep],
      input_esc: options[:input_esc],
      output_sep: options[:output_sep],
      output_esc: options[:output_esc]
    }
  end

  def reformat
    puts "Reformatting #{path}"
    `#{command}`
  end

  private

  attr_reader :path, :outdir, :args

  def filename
    File.basename(path)
  end

  def outfile
    File.join(outdir, filename)
  end

  def argstr
    args.compact
      .map { |key, val| "--#{key} '#{val}'" }
      .join(" ")
  end

  def command
    script = File.join(__dir__, "reformat_csv.pl")
    "perl #{script} #{argstr} #{path} > #{outfile}"
  end
end

files = Pathname.new(options[:input])
  .children
  .select { |path| path.to_s.end_with?(options[:suffix]) }
  .map { |path|
  InFile.new(path: path, options: options).reformat
}
