# frozen_string_literal: true

# Usage:
#   First change any variables in "project-specific variables that may need to
#     be changed". Then run:
#     ruby compact_csvs.rb
#
#  Assuming the `compact_path` variable = `/data/project/pp/csv_compact`, a
#    log file will be written to: /data/project/pp/compact_csvs.log

require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "csv"
  gem "pry"
end

# -=-=-=-=-=-=-=-=-=-=-
# project-specific variables that may need to be changed
# -=-=-=-=-=-=-=-=-=-=-

# path to directory containing CSV files derived from PastPerfect DB
orig_path = "~/data/umich/tables"

# path to directory in which to save compact CSVs
compact_path = "~/data/umich/csv_compact"

# -=-=-=-=-=-=-=-=-=-=-
# end of project-specific variables that may need to be changed
# -=-=-=-=-=-=-=-=-=-=-

CSV::Converters[:stripplus] = lambda { |s|
  begin
    if s.nil?
      nil
    elsif s == "NULL"
      nil
    else
      s = s.strip
        .gsub(/  +/, " ")
        .sub(/,$/, "")
        .gsub("\r\n", "%CRLF%")
        .strip

      s.empty? ? nil : s
    end
  rescue ArgumentError
    s
  end
}

class Compacter
  attr_reader :orig, :logpath, :output

  def initialize(input:, output:)
    @input, @output = File.expand_path(input), File.expand_path(output)
    @orig = OrigFiles.new(@input)
    FileUtils.mkdir(@output) unless Dir.exist?(@output)
    @logpath = "#{Pathname.new(@output).dirname}/compact_csvs.log"
  end

  def compact
    report_empty_tables
    write_populated_tables
    columns_omitted_report
  end

  private

  def report_empty_tables
    empties = orig.empty_files
    return if empties.empty?

    File.open(logpath, "w") do |log|
      log << "#{empties.length} empty tables will not be rewritten "\
        "as compact:\n"
      empties.each{ |table| log << "#{table.name}\n" }
      log << "\n"
    end
  end

  def write_populated_tables
    File.open(logpath, "a") do |log|
      log << "\n\nCOMPACTED FILE SUMMARY\n"
      orig.populated_files.each do |file|
        file.write_compact(output)
        log << "#{file.summarize_compaction}\n"
      end
      log << "\n"
    end
  end

  def columns_omitted_report
    File.open(logpath, "a") do |log|
      log << "\n\nOMITTED COLUMN DETAILS\n"
      orig.populated_files.each do |file|
        file.empty_columns.each{ |col| log << "#{file.name}\t#{col}\n" }
      end
    end
  end
end

class OrigFiles
  attr_reader :path

  def initialize(path)
    @path = Pathname.new(File.expand_path(path))
  end

  def files
    @files ||= build_files
  end

  def empty_files
    @empty_files ||= files.select(&:empty_table?)
  end

  def populated_files
    @populated_files ||= files.select(&:populated_table?)
  end

  private

  def build_files
    filepaths = path.children.select{ |child| child.extname.downcase == ".csv" }
    files = []
    filepaths.each{ |path| files << CsvFile.new(path) }
    files
  end
end

class CsvColumn
  attr_reader :name, :values

  def initialize(name, values)
    @name = name
    @values = values.uniq
  end

  def empty?
    vals = values.dup.compact
    return true if vals.empty?
    return true if vals == [""]
  end

  def populated?
    vals = values.dup.compact
    return false if vals.empty?

    vals.delete("")
    return false if vals.empty?

    true
  end
end

class CsvFile
  attr_reader :path, :name, :col_ct, :empty_ct, :pop_ct
  def initialize(path)
    @path = path
    @name = @path.basename
  end

  def columns
    @columns ||= column_names.map do |colname|
      CsvColumn.new(colname, table[colname])
    end
  end

  def column_names
    @column_names ||= table.headers
  end

  def column_summary
    puts name
    puts "  Total columns: #{column_names.length}"
    puts "  Populated: #{populated_columns.length}"
    puts "  Empty: #{empty_columns.length}"
    puts ""
  end

  def compact
    @compact ||= build_compact
  end

  def empty_columns
    @empty_columns ||= columns.select(&:empty?).map(&:name)
  end

  def empty_table?
    populated_columns.empty?
  end

  def populated_table?
    !empty_table?
  end

  def populated_columns
    @populated_columns ||= columns.select(&:populated?).map(&:name)
  end

  def summarize_compaction
    "#{name} : #{pop_ct} of #{col_ct} columns written to new file "\
      "(#{empty_ct} empty columns omitted)"
  end

  def table
    @table ||= parse_table
  end

  def write_compact(dir)
    outpath = "#{dir}/#{name}"
    CSV.open(outpath, "w") do |csv|
      csv << compact.headers
      compact.each{ |row| csv << row }
    end
    puts summarize_compaction
  end

  private

  def build_compact
    @col_ct = column_names.length
    @empty_ct = empty_columns.length
    @pop_ct = populated_columns.length

    empty_columns.each{ |colname| table.delete(colname) }
    table.by_row!
  end

  def parse_table
    puts "Parsing #{name}..."
    CSV.parse(File.read(path.to_s), headers: true, converters: [:stripplus],
              skip_blanks: true, empty_value: nil).by_col!
  end
end

c = Compacter.new(input: orig_path, output: compact_path)
c.compact
