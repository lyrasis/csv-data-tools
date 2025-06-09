#!/usr/bin/env ruby

# Outputs to STDOUT:
# - List of columns with no values

require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "csv"
  gem "optparse"
  gem "pry"
  gem "reline"
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby empty_columns.rb -i path-to-input-file"

  opts.on("-i", "--input PATH",
          "Path to input directory containing files") do |i|
    options[:input] = File.expand_path(i)
  end
end.parse!

# strips, collapses multiple spaces, removes terminal commas, strips again
CSV::Converters[:stripplus] = lambda { |s|
  begin
    if s.nil?
      nil
    elsif s == "NULL"
      nil
    else
      s.strip
        .gsub(/  +/, " ")
        .sub(/,$/, "")
        .sub(/^%(LINEBREAK|CRLF|CR|TAB)%/, "")
        .sub(/%(LINEBREAK|CRLF|CR|TAB)%$/, "")
        .strip
    end
  rescue ArgumentError
    s
  end
}

table = CSV.parse(
  File.read(options[:input]),
  headers: true,
  converters: [:stripplus]
)
headers = table.headers
total_header_ct = headers.length

table.by_col!
table.headers.each do |hdr|
  pop = table[hdr].reject { |v| v.nil? || v.empty? }
  headers.delete(hdr) unless pop.empty?
end

puts headers
diff = total_header_ct - headers.length
puts "#{headers.length} of #{total_header_ct} columns empty"
puts "#{diff} of #{total_header_ct} columns populated"
