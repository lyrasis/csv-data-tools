#!/usr/bin/env ruby

# Replaces all field values in a CSV that do not match the
#  SKIP_PATTERNS with a MD5 digest (translated to bubblebabble) of the
#  original value. Header values and fields matching SKIP_PATTERNS
#  regular expressions are left as-is.
#
# This script is used to remove actual client data from CSVs exported from
#   provided client databases, while retaining data structure and linkages
#   across tables. This allows us to NOT retain actual client data, but
#   retain usable data for building and testing tooling.
#
# The MD5 digest of "test string" will always be computed as:
#   6f8db599de986fab7a21625b7916589c
#
# The MD5 digest algorithm was once widely used as a cryptographic
#   hash function. That is, it was believed you could not decode the
#   digest shown above back into "test string". It is no longer
#   used for cryptography as vulnerabilities in the algorithm have
#   been discovered. However, it is deemed sufficient for our purposes
#   of converting the client-specific data content in a database into
#   random-looking gibberish that can be used as test data. More
#   secure algorithms are much more processing-intensive and are
#   overkill for these purposes.
#
# The MD5 digest for "test string", converted into bubblebabble is
#   "xirom-tetun-nilyn-murap-ruvod-comeh-rivec-kyken-saxyx"
#
# When using the data to develop/test tooling, that is going to be
#   much easier for human eyes to compare and match to other data than
#   the plain digest. Doing this has the added benefit of making it
#   more annoying for anyone to convert back to client data. First
#   they'd have to un-bubblebabble the digest (trivial,
#   computationally, but still another step for every field value),
#   and then un-digest each field value.
require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "csv"
  gem "pry"
  gem "reline"
end

require "digest/bubblebabble"
require "fileutils"
require "optparse"

# Field values matching any of these patterns are kept as-is. This is intended
#   to retain id/foreign key linkages intact in the data
SKIP_PATTERNS = [
  /^\d+$/, # digits-only data - ids, etc
  # PPD indicates item type(s) with ALOP and sometimes includes N or Y instead
  #   0 or 1 for boolean values
  /^[A-Z]{1,4}$/,
  # Frequently occurring default values
  /^0\.00$/, # currency default
  /^\.0+$/, # float default
  /^\/   - *$/, # phone num default value in PPD
  /^-?\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(?:\.\d{3,}| [AP]M)?$/, #date/timestamp
  # UUIDs are sometimes used as primary/foreign keys in PP
  /^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$/
]

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: obfuscator.rb -i path-to-input-dir "\
    "-o path-to-output-dir"

  opts.on(
    "-i", "--input PATH", "Path to input directory containing CSV files"
  ) do |i|
    options[:input] = File.expand_path(i)
  end

  opts.on("-o", "--output PATH", "Path to output directory") do |o|
    path = File.expand_path(o)
    FileUtils.mkdir_p(path) unless Dir.exist?(path)
    options[:outdir] = path
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

def obfuscated(row)
  row.to_h
    .values
    .map do |val|
      next val if val.nil? || val.empty?
      next val if SKIP_PATTERNS.any? { |pattern| val.match?(pattern) }

      Digest::MD5.bubblebabble(val)
    end
end

def obfuscate(path, outdir)
  puts "Obfuscating #{path}..."
  outpath = File.join(outdir, Pathname(path).basename)
  table = CSV.parse(File.open(path), headers: true)
  headers = table.headers

  CSV.open(outpath, 'w', headers: headers, write_headers: true) do |csv|
    table.each { |r| csv << obfuscated(r) }
  end
end


Dir.children(options[:input])
  .select { |f| f.downcase.end_with?(".csv") }
  .map { |f| File.join(options[:input], f) }
  .each { |f| obfuscate(f, options[:outdir]) }
