#!/usr/bin/env ruby

require 'bundler/inline'

gemfile do
  source "https://rubygems.org"
  gem "csv"
  gem "pry"
end

require 'csv'
require 'fileutils'
require 'optparse'
require 'pry'

ID_HEADERS = ["Inventories Excel ID", "InventoryID", "Summary Excel ID",
              "SummaryId"].freeze
MAX_EXAMPLES = 100

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: field_signatures.rb -i path-to-input-file "\
    "-s file-suffix -o path-to-output-file -d comma"

  opts.on('-i', '--input PATH', 'Path to input file') do |i|
    options[:input] = File.expand_path(i)
  end

  opts.on('-o', '--output PATH', 'Path to output file') do |o|
    options[:output] = File.expand_path(o)
  end

  opts.on('-s', '--suffix STRING', 'File suffix, without dot') do |s|
    options[:suffix] = ".#{s.delete_prefix('.')}"
  end

  opts.on('-d', '--delimiter STRING', 'comma, pipe, tab, or literal string') do |d|
    options[:delimiter] = d
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

def get_delim_opt(delim)
  lookup = {
    'comma' => ',',
    'pipe' => '|',
    'tab' => "\t"
  }

  common_value = lookup[delim]
  return common_value if common_value

  ","
end

def get_id_field(headers)
  ID_HEADERS.intersection(headers).first
end

delim_opt = get_delim_opt(options[:delimiter])

table = CSV.parse(File.read(options[:input]), headers: true, col_sep: delim_opt)
id_field = get_id_field(table.headers)

sigs = {}

table.each do |row|
  sig = row.to_h.compact.keys
  if sigs.key?(sig)
    sigs[sig][:occs] += 1
    next if sigs[sig][:ids].length == MAX_EXAMPLES

    sigs[sig][:ids] << row[id_field]
  else
    sigs[sig] = {occs: 1, ids: [row[id_field]]}
  end
end

occ_header = "sigOccs"
example_header = "exampleIds"
orig_headers = sigs.keys.flatten.uniq
write_headers = [occ_header, example_header, orig_headers].flatten

def sig_to_row(sig, vals, headers)
  [vals[:occs],
   vals[:ids].join(" | "),
   headers.map { |hdr| sig.include?(hdr) ? "X" : nil }
  ].flatten
end

CSV.open(options[:output], "w", headers: write_headers, write_headers: true) do |csv|
  sigs.each { |sig, ct| csv << sig_to_row(sig, ct, orig_headers) }
end
