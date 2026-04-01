#!/usr/bin/env ruby

# Print to screen the results of `file` command for all
require 'csv'
require 'optparse'
require 'pathname'
require 'pp'
require 'pry'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: file_info.rb -i path-to-input-dir -s file-suffix -m min-file-size'

  opts.on('-i', '--input PATH', 'Path to input directory containing files') do |i|
    options[:input] = File.expand_path(i)
  end

  opts.on('-s', '--suffix STRING', 'File suffix, without dot') do |s|
    options[:suffix] = ".#{s.delete_prefix('.')}"
  end

  opts.on('-m', '--min-file-size INTEGER', 'Minimum file size to report on, in bytes') do |m|
    options[:min_file_size] = m
  end

  opts.on('-o', '--output PATH', 'Where to write file if CSV output format') do |o|
    options[:output] = o ? File.expand_path(o) : nil
  end

  opts.on('-t', '--target TARGET', %i[stdout csv], 'stdout (default) or CSV') do |t|
    options[:target] = t
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

options[:min_file_size] = 1 unless options[:min_file_size]
options[:target] = :stdout unless options[:target]
if options[:target] == :csv && options[:output].nil?
  options[:output] = File.join(options[:input], "file_info_output.csv")
end

MIN_FILE_SIZE = options[:min_file_size]

class FileInfo
  attr_reader :filename

  def initialize(path)
    @path = path
    @filename = File.basename(path)
    @size = File.size(path)
  end

  def report? = size >= MIN_FILE_SIZE

  def mimetype = @mimetype ||= get_info(:mimetype)

  def encoding = @encoding ||= get_info(:encoding)

  def to_stdout
    <<~MSG
      #{filename}:
        size: #{size}
        info: #{mimetype}; #{encoding}

    MSG
  end

  def to_csv
    {
      filename: filename,
      size: size,
      mimetype: mimetype,
      encoding: encoding
    }
  end

  private

  attr_reader :path, :size

  def get_info(type)
    return unless report?

    flag = type == :mimetype ? "mime-type" : "mime-encoding"
    result = `file --#{flag} #{path}`
  rescue StandardError => e
    e.message
  else
    result.chomp.delete_prefix("#{path}: ")
  end
end

files = Dir.children(options[:input])
  .select{ |name| name.downcase.end_with?(options[:suffix]) }
  .map{ |name| "#{options[:input]}/#{name}" }
  .map{ |path| FileInfo.new(path) }
  .select(&:report?)
  .sort_by(&:filename)

if options[:target] == :csv
  headers = %i[filename size mimetype encoding]
  CSV.open(options[:output], "w", headers: headers, write_headers: true) do |csv|
    files.each { |file| csv << file.to_csv.values_at(*headers) }
  end
else
  files.each { |file| puts file.to_stdout }
end
