#!/usr/bin/env ruby

require 'csv'
require 'optparse'
require 'pry'
require 'strscan'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: file_info.rb -i path-to-file -o output_file'

  opts.on('-i', '--input PATH', 'Path to input file') do |i|
    options[:input] = File.expand_path(i)
  end

  opts.on('-o', '--output PATH', 'Path to output file') do |o|
    options[:output] = File.expand_path(o)
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

CONTEXT = 25

class CharInfo
  attr_reader :ctrl, :pos

  def initialize(str, pos)
    @str = str
    @pos = pos
    @ctrl = str.byteslice(pos - 1, 1)
  end

  def pre = @pre ||= get_pre

  def post = @post ||= str.byteslice(pos, CONTEXT)

  def to_csv
    {
      position_in_file: pos,
      pre_inspect: remove_quotes(pre.inspect),
      pre: pre,
      ctrl_char: ctrl,
      ctrl_char_inspect: remove_quotes(ctrl.inspect),
      post: post,
      post_inspect: remove_quotes(post.inspect)
    }
  end

  private

  attr_reader :str

  def remove_quotes(str) = str.delete_prefix('"').delete_suffix('"')

  def get_pre
    prevpos = pos - 1
    return str.byteslice(0, prevpos) if prevpos <= CONTEXT

    start = pos - CONTEXT - 1
    str.byteslice(start, CONTEXT)
  end
end

str = File.read(options[:input])
scanner = StringScanner.new(str)
pattern = /\p{C}+/

def eol?(match) = match.match?(/(\r\n|\r|\n)$/)

ctrls = []

while scanner.exist?(pattern)
  match = scanner.scan_until(pattern)
  next if eol?(match)

  ctrls << CharInfo.new(scanner.string, scanner.pos).to_csv
end

headers = ctrls.first.keys

CSV.open(options[:output], "w", headers: headers, write_headers: true) do |csv|
  ctrls.each { |ctrl| csv << ctrl.values_at(*headers) }
end
