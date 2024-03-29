#!/usr/bin/env ruby

# For each given file:
#   - outputs a txt file for each column, listing unique values (with occurrence
#   count for each)
#   - outputs to STDOUT column name, number of rows, and number of unique values
require "csv"
require "fileutils"
require "forwardable"
require "optparse"
require "ostruct"
require "pathname"
require "pry"

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby profiler.rb -i path-to-input-dir -s file-suffix "\
    "-o path-to-output-directory -c '{col_sep: \";\"}'"

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

  opts.on("-c", "--csvopts STRING", "CSV options hash in single quotes") do |c|
    options[:csvopts] = eval(c)
  end

  opts.on("--details STRING", "files or compile") do |details|
    accepted = %w[compile files]
    unless accepted.any?(details)
      puts "Details mode must be one of: #{accepted.join(", ")}"
      exit
    end

    options[:details] = details
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

options[:details] = "files" unless options.key?(:details)
options[:suffix] = ".csv" unless options.key?(:suffix)

# clear out pre-existing reports
if Dir.exist?(options[:output])
  output = options[:output]
  children = Pathname.new(output).children
  FileUtils.rm(children) unless children.empty?
end

# makes dir if it doesn't exist; does nothing otherwise
FileUtils.mkdir_p(options[:output])

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

module Profiler
  class Column
    # columns that do not need to be profiled
    Skippable = %w[alphasort cn gsrowversion entereddate dateentered
      displayorder sortnumber sorttype bitmapname]
    SkippableSuffixes = %w[id html]

    def initialize(name, file, index)
      @name = name
      @file = file
      @index = index
      @values = {}
    end

    def report_values(details_mode)
      return if Skippable.any?(@name.downcase)
      dc_name = @name.downcase
      SkippableSuffixes.each { |suffix| return if dc_name.end_with?(suffix) }

      puts "  Analyzing column: #{@name}..."
      @file.csv[@name].each { |val| record_value(val) }
      col_details = {
        file: @file.name,
        column: @name,
        index: @index,
        outpath: @file.outpath
      }
      ColumnSummary.new(col_details, @values)
      case details_mode
      when "files"
        ColumnFile.new(col_details, @values)
      when "compile"
        ColumnDetails.new(col_details, @values)
      end
    end

    private

    def record_value(val)
      @values.key?(val) ? @values[val] += 1 : @values[val] = 1
    end
  end

  class ColumnReport
    def initialize(col_details, values)
      @hash = values
      @table = col_details[:file]
      @column = col_details[:column]
      @index = col_details[:index]
      @outpath = File.join(
        col_details[:outpath],
        "#{filename.gsub(/\W+/, "_")}.csv"
      )
      write_headers unless File.exist?(@outpath)
      append_report
    end

    private

    def append_report
      CSV.open(@outpath, "a") { |csv| rows.each { |row| csv << row } }
    end

    def filename
      raise NotImplementedError,
        "#{self.class} has not implemented method '#{__method__}'"
    end

    def headers
      raise NotImplementedError,
        "#{self.class} has not implemented method '#{__method__}'"
    end

    def rows
      raise NotImplementedError,
        "#{self.class} has not implemented method '#{__method__}'"
    end

    def write_headers
      CSV.open(@outpath, "wb") { |csv| csv << headers }
    end
  end

  class ColumnFile < ColumnReport
    private

    def append_report
      File.open(@outpath, "w") do |file|
        @hash.each { |value, ct| file.puts "#{ct},#{value}\n" }
      end
    end

    def filename
      "#{@table}_#{@column}"
    end

    def write_headers
      # no headers
    end
  end

  class ColumnSummary < ColumnReport
    private

    def filename
      "summary"
    end

    def headers
      ["table", "column", "column index", "uniq vals", "null vals"]
    end

    def null_vals
      @hash[nil]
    end

    def row
      [@table, @column, @index, uniq_vals, null_vals]
    end

    def rows
      [row]
    end

    def uniq_vals
      @hash.keys.compact.length
    end
  end

  class ColumnDetails < ColumnReport
    private

    def filename
      "details"
    end

    def headers
      ["table", "column", "column index", "value", "occurrences"]
    end

    def rows
      @hash.map do |value, occ|
        [@table, @column, @index, value || "NULL VALUE/EMPTY FIELD", occ]
      end
    end
  end

  class Files
    extend Forwardable
    def_delegators :@list, :each
    attr_reader :path, :list
    def initialize(dir, suffix)
      @path = Pathname.new(dir)
      @list = @path.children
        .select { |child| child.extname == suffix }
    end
  end

  class CSVFile
    attr_reader :path, :name, :row_ct, :columns, :outpath, :csvopts
    DEFAULT_OPTS = {headers: true, header_converters: [:downcase],
                    converters: [:stripplus], skip_blanks: true,
                    empty_value: nil}
    def initialize(path, output, csvopts)
      @path = path
      @outpath = output
      @csvopts = set_csvopts(csvopts)
      @name = path.basename.to_s.delete_suffix(path.extname)
      @row_ct = csv.length
      @columns = set_up_columns
    end

    def report_values(details_mode)
      columns.each { |column| column.report_values(details_mode) }
    end

    def csv
      @csv ||= parse_csv
    end

    private

    def set_csvopts(csvopts)
      return DEFAULT_OPTS unless csvopts

      DEFAULT_OPTS.merge(csvopts)
    end

    def parse_csv
      puts "Parsing #{path}..."
      CSV.parse(File.read(path), **csvopts).by_col!
    end

    def set_up_columns
      csv.headers.map.with_index { |hdr, i| Column.new(hdr, self, i) }
    end
  end
end

files = Profiler::Files.new(options[:input], options[:suffix])
files.each do |path|
  file = Profiler::CSVFile.new(path, options[:output], options[:csvopts])
  puts "#{file.row_ct} rows -- #{file.columns.length} columns -- #{file.name}"

  file.report_values(options[:details])
end
