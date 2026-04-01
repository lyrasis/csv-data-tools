#!/usr/bin/env ruby

# USAGE:
# If in csv-data-tools directory:
# safe_open.rb path/to/file.csv
#
# If in directory with your file:
# path/to/csv-data-tools/safe_open.rb file.csv
#
# If in random directory:
# path/to/csv-data-tools/safe_open.rb path/to/file.csv

require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "csv"
  gem "pry"
end

require "csv"
require "pry"

path = ARGV[0]
fail("No file path, or path to non-CSV, given") unless path

ln = File.open(path) { |f| f.readline }
cell_formats = CSV.parse(ln, liberal_parsing: true)
  .flatten
  .map { |_hdr| "2" }
  .join("/")

cmd_base = 'soffice --infilter="Text - txt - csv (StarCalc):'

# See https://help.libreoffice.org/latest/ro/text/shared/guide/csv_params.html
# 44 = comma field separator
# 34 = double quote text delimiter
# 76 = UTF-8 character set
# 1 = line number to start reading
# 0 = default/UI language
# true = quoted field as text
# false = detect special numbers
filter = "44,34, 76,1,#{cell_formats},0,true,false\""

`#{cmd_base}#{filter} #{path}`
