#!/usr/bin/env ruby

# Converts all XLSX files in the given directory to CSVs

require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "reline"
end

require "fileutils"
require "open3"
require "optparse"

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: xlsx_to_csv.rb -i path-to-input-dir "\
    "-o path-to-output-dir"

  opts.on(
    "-i", "--input PATH", "Path to input directory containing files"
  ) do |i|
    options[:indir] = File.expand_path(i)
  end

  opts.on("-o", "--output PATH", "Path to output directory") do |o|
    options[:outdir] = File.expand_path(o)
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

def source_file_paths(indir) = Dir.children(indir)
  .select { |f| f.end_with?(".xlsx") }
  .map { |f| File.join(indir, f) }

def extract_command(xlsx)
  "in2csv --write-sheets - --use-sheet-names --no-inference "\
    "--date-format - --datetime-format - --reset-dimensions '#{xlsx}'"
end

def run_extract_command(xlsx)
  puts "\nConverting #{xlsx}"
  _stdout, stderr, status = Open3.capture3(extract_command(xlsx))
  puts "ERROR: Could not convert #{xlsx}" unless status.success?
  puts stderr
rescue => err
  puts "ERROR: Could not convert #{xlsx}"
  puts err
end

def csvs(indir) = Dir.children(indir)
  .select { |f| f.end_with?(".csv") }
  .map { |f| File.join(indir, f) }

def delete_empty_csvs(outdir)
  Dir.children(outdir)
    .each do |f|
    path = File.join(outdir, f)
    next unless File.foreach(path).count == 1

    FileUtils.rm(path)
    end
end


source_file_paths(options[:indir]).each { |f| run_extract_command(f) }

options[:outdir] = File.join(options[:indir], "csv") unless options[:outdir]
FileUtils.mkdir_p(options[:outdir]) unless Dir.exist?(options[:outdir])

FileUtils.mv(csvs(options[:indir]), options[:outdir])

delete_empty_csvs(options[:outdir])
