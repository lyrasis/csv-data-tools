#!/usr/bin/env ruby

require 'bundler/inline'

gemfile do
  source "https://rubygems.org"
  gem "caxlsx"
  gem "csv"
  gem "pry"
end

# For each given file:
#   - outputs a txt file for each column, listing unique values (with occurrence
#   count for each)
#   - outputs to STDOUT column name, number of rows, and number of unique values
require "axlsx"
require "csv"
require "forwardable"
require "optparse"
require "pry"
require "set"

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby profiler.rb -i path-to-input-dir "\
    "-o path-to-output-file"

  opts.on("-i", "--input PATH",
          "Path to input directory containing files") do |i|
    options[:input] = File.expand_path(i)
  end

  opts.on("-o", "--output PATH", "Path to output file") do |o|
    options[:output] = File.expand_path(o)
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

class ColVal
  attr_reader :rows, :colname

  def initialize(key, val)
    @colname = key[0]
    @value = key[1]
    @rows = val
  end

  def to_main_row(file_cols)
    base = {
      colname: colname,
      value: value
    }
    fc_cols = file_col_columns(file_cols, rows)
    base[:total_occs] = fc_cols.values.sum
    base.merge(fc_cols)
  end

  private

  attr_reader :value

  def file_col_columns(file_cols, rows)
    file_cols.map { |file_col| set_file_col(file_col, rows) }
      .to_h
  end

  def set_file_col(file_col, rows)
    selector = rows.select { |row| FileCol.new(row) == file_col }
    return [file_col.to_sym, 0] if selector.empty?
    raise "Too many selectors found" if selector.length > 1

    [file_col.to_sym, selector.first["occurrences"].to_i]
  end
end

class FileCol
  include Comparable

  attr_reader :arr

  def initialize(row)
    @arr = [row["campus"], row["format"]]
  end

  def to_s = arr.reverse.join(".")

  def to_sym = to_s.to_sym

  def <=>(other) = arr <=> other.arr

  def ==(other) = self.class == other.class &&
    arr.eql?(other.arr)
  alias :eql? :==

  def hash = arr.hash
end

class RowChecker
  INV_FIELDS = ["accession date",
                "additional collections notes",
                "agency/museum name",
                "anthropologist name",
                "archaeologist name",
                "basis of determination",
                "collection history",
                "collection type",
                "collector name",
                "consultation",
                "contact email",
                "contact first name",
                "contact last name",
                "contact title",
                "contact website",
                "cultural affiliation",
                "current location",
                "date removed from site",
                "donor name",
                "ethnographer name",
                "geographical location city",
                "geographical location county",
                "geographical location other information",
                "identified afo accession number",
                "identified afo catalogue number",
                "identified afo description",
                "identified afo(associated funerary objects)",
                "inventories excel id",
                "inventory status (preliminary or final)",
                "item/lot information",
                "mni(minimum number of individuals)",
                "nahc inventory id",
                "notes",
                "repatriation status",
                "site number/name",
                "source type",
                "testing/treatment",
                "tribal identifications",
                "website information"].freeze
  SUM_FIELDS = ["accession date",
                "accession number",
                "agency/museum name",
                "anthropologist name",
                "archaeologist name",
                "basis of determination",
                "collection type",
                "collector name",
                "consultation",
                "contact email",
                "contact first name",
                "contact last name",
                "contact title",
                "contact website",
                "cultural affiliation",
                "current location",
                "date removed from site",
                "description",
                "donor name",
                "ethnographer name",
                "faunal material",
                "geographical location city",
                "geographical location county",
                "geographical location other information",
                "human remains",
                "nahc summary id",
                "number of objects",
                "repatriation status",
                "site number/name",
                "source type",
                "summary excel id",
                "summary status (preliminary or final)",
                "summary type",
                "testing/treatment",
                "tribal identifications",
                "website information"].freeze

  class << self
    def known_field?(row)
      field = row["column"]
      format = row["format"]
      known = format == "inv" ? INV_FIELDS : SUM_FIELDS
      true if known.include?(field)
    end
  end
end

class Compiler
  def initialize(table)
    @table = table
    @base_cols = [:colname, :value]
    @id_fields = ["inventories excel id", "summary excel id",
                  "nahc inventory id", "nahc summary id", "accession number",
                  "identified afo accession number",
                  "identified afo catalogue number"]
    @date_fields = ["date removed from site", "accession date"]
  end


  def write(outfile)
    p = Axlsx::Package.new
    wb = p.workbook
    prepare_main_sheet(wb)
    prepare_norm_sheet(wb, :ids)
    prepare_norm_sheet(wb, :dates)
    p.serialize(outfile)
  end

  def prepare_main_sheet(wb)
    main_rows = col_vals.select { |key, _rows| value_fields.include?(key.colname) }
      .map { |colval| colval.to_main_row(file_cols) }
      .sort_by { |r| "#{r[:colname]} #{r[:value]}" }
    last_row = main_rows.length + 1
    cols = [:pad, ("A".."Z").to_a].flatten
    col_count = main_rows.first.length
    last_col = cols[col_count]
    table_range = "A1:#{last_col}#{last_row}"
    widths = [nil, 30, Array.new(col_count - 2, nil)].flatten


    wb.add_worksheet(name: "variableVals") do |sheet|
      sheet.add_row(headers)
      main_rows.each { |row| sheet.add_row(row.values_at(*headers)) }

      sheet.add_table(table_range, name: "field_vals")
      sheet.column_widths(*widths)
    end
  end

  # @param type [:ids, :dates]
  def prepare_norm_sheet(wb, type)
    fieldlist = type == :ids ? id_fields : date_fields

    rows = norm_rows(fieldlist)
      .values
      .map { |rows| to_norm_rows(rows) }
      .flatten

    last_row = rows.length + 1
    cols = [:pad, ("A".."Z").to_a].flatten
    col_count = rows.first.length
    last_col = cols[col_count]
    table_range = "A1:#{last_col}#{last_row}"
    # widths = [nil, 30, Array.new(col_count - 2, nil)].flatten

    wb.add_worksheet(name: "norm#{type.capitalize}") do |sheet|
      sheet.add_row(norm_headers)
      rows.each { |row| sheet.add_row(row.values_at(*norm_headers)) }

      sheet.add_table(table_range, name: "norm#{type}")
      #sheet.column_widths(*widths)
    end
  end

  def norm_headers = %w[campus format column value occurrences unique?]

  def norm_rows(fieldnamelist)
    col_vals.select{ |cv| fieldnamelist.include?(cv.colname) }
      .map(&:rows)
      .flatten(1)
      .group_by { |r| "#{r["campus"]}\t#{r["format"]}\t#{r["column"]}" }
      .sort
      .to_h
  end

  def to_norm_rows(rows)
    rows.map { |r| normalize_vals(r, :id) }
      .group_by { |r| r["value"] }
      .map { |val, rows| to_norm_row(val, rows) }
  end

  def to_norm_row(val, rows)
    uniqvals = rows.all? { |r| r["occurrences"] == "1" }
    total_occs = rows.map { |r| r["occurrences"].to_i }.sum
    {
      "campus" => rows.first["campus"],
      "format" => rows.first["format"],
      "column" => rows.first["column"],
      "value" => val,
      "occurrences" => total_occs,
      "unique?" => uniqvals
    }
  end

  def normalize_vals(row, type)
    val = row["value"]

    result = if val.match?(/^ *\d+ *$/)
                "integer (e.g. '1', '32', '953')"
              elsif val.match?(/^ *n\/?a */i)
                "n/a is explicitly specified"
             elsif val == "NULL VALUE/EMPTY FIELD"
               val
              else
                val.gsub(/\d/, "#")
                  .gsub(/[a-z]/, "a")
                  .gsub(/[A-Z]/, "A")
              end

    row["value"] = result
    row
  end

  # @return [Array] columns to be added to compiled report, which represent
  #   original input files (e.g. chico inventory, sonoma summary)
  def file_cols
    @file_cols ||= table.map { |row| FileCol.new(row) }.to_set
  end

  private

  attr_reader :table, :base_cols, :id_fields, :date_fields

  def value_fields
    @value_fields ||=
      table.reject { |row| non_value_fields.include?(row["column"]) }
      .map { |row| row["column"]}
      .uniq
      .sort
  end

  def non_value_fields = @non_value_fields ||= id_fields + date_fields

  def col_vals
    @col_vals ||= table.by_column_value
      .map { |key, val| ColVal.new(key, val) }
  end

  def headers = @headers ||= [base_cols, file_cols.map(&:to_sym), :total_occs]
    .flatten
end

class Table
  extend Forwardable

  attr_reader :table

  def_delegators :@table, :size, :map, :reject

  def initialize(string)
    @table = CSV.parse(string, headers: true)
      #.delete_if { |row| row["value"] == "NULL VALUE/EMPTY FIELD" }
      .each { |row| derive_campus_and_format(row) }
  end

  def report_and_remove_unknown_fields
    unknown = unknown_field_rows
    return if unknown.empty?

    report_unknown_fields(unknown)
    remove_unknown_fields(unknown)
  end

  def by_campus_format_column
    table.group_by { |row| campus_format_column(row) }
  end

  def by_column_value
      table.group_by { |row| [row["column"], row["value"]] }
  end

  private

  def derive_campus_and_format(row)
    parts = row["table"].split("_")
    row["campus"] = parts[1]
    row["format"] = parts[0] == "INV" ? "inv" : "sum"
    row
  end

  def unknown_field_rows
    by_campus_format_column
      .values
      .map { |rows| rows.first }
      .reject { |row| RowChecker.known_field?(row) }
  end

  def report_unknown_fields(unknown)
    puts "\nUNKNOWN FIELDS - OMITTED FROM COMPILATION"
    unknown.sort_by { |row| campus_format_column(row) }
      .each { |r| puts campus_format_column(r) }
  end

  def remove_unknown_fields(unknown)
    matchers = unknown.map { |row| campus_format_column(row) }

    @table.delete_if { |r| matchers.include?(campus_format_column(r)) }
  end

  def campus_format_column(row) = "#{row["campus"]}\t#{row["format"]}\t"\
    "#{row["column"]}"
end


table = Table.new(File.read(options[:input]))
puts "Initial table length: #{table.size}"

table.report_and_remove_unknown_fields
puts "\nCleaned table length: #{table.size}"


# def uniq_val_fields(table)
#   table.by_campus_format_column
#     .select { |key, rows| rows.all?{ |row| row["occurrences"] == "1" } }
# end
# uvf = uniq_val_fields(table)

compiler = Compiler.new(table)
compiler.write(options[:output])
