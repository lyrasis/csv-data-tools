#!/usr/bin/env ruby

# Converts all CSV files in a directory to XLSX files, with all data values
#   encoded as strings
require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "caxlsx"
  gem "csv"
end

require "fileutils"
require "optparse"

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: csv_to_xlsx.rb -i path-to-input-dir "\
    "-o path-to-output-dir"

  opts.on(
    "-i", "--input PATH", "Path to input directory containing files"
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

def write(file, outdir)
  basename = Pathname.new(file).basename(".csv").to_s

  outfile = basename + ".xlsx"
  outpath = File.join(outdir, outfile)
  p = Axlsx::Package.new
  wb = p.workbook
  default_style = wb.styles.add_style(
    {
      format_code: '@',
      alignment: {horizontal: :left, vertical: :top, wrap_text: true}
    }
  )
  csv = CSV.parse(File.read(file), headers: true)
  sheetname = basename.length <= 31 ? basename : "data"
  wb.add_worksheet(name: sheetname) do |sheet|
    sheet.add_row(csv.headers)
    csv.each do |r|
      data = r.values_at(*csv.headers)
      styles = data.map { |v| v ? default_style : nil }
      types = data.map { |v| v ? :string : nil }
      sheet.add_row(data, style: styles, types: types)
    end
    sheet.to_xml_string
  end

  p.serialize(outpath)
end


Dir.children(options[:input])
  .select { |f| f.downcase.end_with?(".csv") }
  .map { |f| File.join(options[:input], f) }
  .each { |f| write(f, options[:outdir]) }
