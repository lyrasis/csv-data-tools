#!/usr/bin/env ruby

# Rolled it myself because csv-lint gem wanted to report spurious invalid encoding for US-ASCII files
#   and not report ragged columns in said files
require 'bundler/inline'
gemfile do
  source 'https://rubygems.org'
  gem 'csv'
  gem 'pry'
end

require 'optparse'

options = {
  delimiter: ',',
  suffix: 'csv'
}
OptionParser.new do |opts|
  opts.banner = 'Usage: check_structure.rb -i path-to-input-dir -s file_suffix -d delimiter_name -o output_file'

  opts.on('-i', '--input PATH', String, 'Path to input directory containing files') do |i|
    options[:input] = File.expand_path(i)
  end

  opts.on('-s', '--suffix STRING', String, 'File suffix, without dot') do |s|
    options[:suffix] = ".#{s.delete_prefix('.')}"
  end

  opts.on('-d', '--delimiter STRING', String, 'Delimiter name: comma (default), tab, pipe') do |d|
    translations = {
      comma: ',',
      pipe: '|',
      tab: "\t"
    }
    allowed = translations.keys.map(&:to_s)
    d_allowed = allowed.any?(d)

    unless d_allowed
      puts "#{d} is not an allowed delimiter value. Use one of: #{allowed.join(', ')}"
      exit
    end
    
    options[:delimiter] = translations[d.to_sym]
  end

  opts.on('-o', '--output PATH', String, 'Path to output CSV file') do |o|
    options[:output] = File.expand_path(o)
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

class Checker
  attr_reader :filename, :report
  def initialize(path, delimiter)
    @path = path
    @filename = Pathname.new(path).basename
    @rows = CSV.foreach(path, col_sep: delimiter)
    @report = RowReport.new(@rows.first.length)
  end

  def check
    @rows.each_with_index do |row, ind|
      next if ind == 0

      report.record(row, ind)
    end
  end

  def ok?
    report.ok?
  end
end

class RaggedReport
  attr_reader :count, :examples
  Sufficient_Examples = 3
  
  def initialize
    @count = 0
    @examples = {}
  end

  def add(row, ind)
    @count += 1
    return if sufficient_examples?

    add_example(row, ind)
  end

  private

  def add_example(row, ind)
    row_num = ind + 1
    @examples[row_num] = row
  end

  def sufficient_examples?
    @examples.length == Sufficient_Examples
  end
end

class RowReport
  attr_reader :header_ct, :correct, :ragged
  def initialize(header_ct)
    @header_ct = header_ct
    @ragged = {}
    @correct = 0
  end

  def ok?
    @ragged.empty?
  end
  
  def record(row, ind)
    col_ct = row.length
    col_ct == header_ct ? report_expected : report_ragged(col_ct, row, ind)
  end

  private

  def report_expected
    @correct += 1
  end

  def prepare_ragged_report(col_ct)
    return if @ragged.key?(col_ct)

    @ragged[col_ct] = RaggedReport.new
  end
  
  def report_ragged(col_ct, row, ind)
    prepare_ragged_report(col_ct)
    @ragged[col_ct].add(row, ind)
  end
end

class CumulativeReport
  attr_reader :path
  def initialize(path)
    @path = path
    headers = %w[filename ok? col_ct occurrences example_rows]
    CSV.open(path, 'w'){ |csv| csv << headers }
  end

  def add_file_info(checker)
    CSV.open(path, 'a') do |csv|
      rows_for(checker).each{ |row| csv << row }
    end
  end

  private

  def bad_rows(checker)
    rows = [good_row(checker)]
    checker.report.ragged.each do |col_ct, details|
      rows << [
        checker.filename,
        'n',
        col_ct,
        details.count,
        details.examples.keys.join(', ')
      ]
    end
    rows
  end

  def good_row(checker)
    report = checker.report
    [
      checker.filename,
      checker.ok? ? 'y' : 'n',
      report.header_ct,
      report.correct,
      nil
    ]
  end

  def rows_for(checker)
    return [good_row(checker)] if checker.ok?

    bad_rows(checker)
  end
end

report = CumulativeReport.new(options[:output])

files = Dir.children(options[:input])
  .select{ |name| name.downcase.end_with?(options[:suffix]) }
  .map{ |name| "#{options[:input]}/#{name}" }

files.each do |file|
  checker = Checker.new(file, options[:delimiter])
  checker.check
  report.add_file_info(checker)
end

