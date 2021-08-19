#!/usr/bin/env ruby

# Converts Windows UTF-16 to UTF8
# Tries to fix EOL and TAB char within row values problems
# Creates file_report.csv which incorporates the `file` output of the original
#  files and flags the files still having structural problems
require 'csv'
require 'fileutils'
require 'json'
require 'optparse'
require 'pp'
require 'pry'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: clean_convert_report.rb -i path-to-input-dir -s file-suffix -o path-to-output-directory'

  opts.on('-i', '--input PATH', 'Path to input directory containing files') do |i|
    options[:input] = File.expand_path(i)
  end

  opts.on('-o', '--output PATH', 'Path to output directory') do |o|
    options[:output] = File.expand_path(o)
  end

  opts.on('-s', '--suffix STRING', 'File suffix, without dot') do |s|
    options[:suffix] = ".#{s.delete_prefix('.')}"
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

# makes dir if it doesn't exist; does nothing otherwise
FileUtils.mkdir_p(options[:output])




files = Dir.children(options[:input])
  .select{ |name| name.downcase.end_with?(options[:suffix]) }
  .map{ |name| "#{options[:input]}/#{name}" }

case options[:suffix]
when '.psv'
  delimiter = '|'
when '.tsv'
  delimiter = '\t'
when '.txt'
  delimiter = '|'
end

puts 'Converting character encoding for:'
files.each do |file|
  puts "  #{file}"
  outpath = file.sub(options[:input], options[:output])

  `iconv -f UTF-16LE -t UTF-8 #{file} > #{outpath}`
end

files = files.map{ |f| f.sub(options[:input], options[:output]) }

puts 'Replacing in-field line breaks in:'
files.each do |file|
  #  next unless file.end_with?('Objects.tsv')
  puts "  #{file}"
  f = File.read(file, mode: 'r:bom|utf-8')
  regexdelim = delimiter == '|' ? '\|' : delimiter
  
  # CR+LF: CR (U+000D) followed by LF (U+000A)
  fn = f.gsub("\u000A", '%LF%')
  fn = fn.gsub("\u000D", '%CR%')
  fn = fn.gsub('%CR%%LF%', '%CRLF%')
  fn = fn.gsub(/#{regexdelim} +/, delimiter)
  fn = fn.gsub(/%CRLF%(-+#{regexdelim})+-+%CRLF%/, '%NEWROW%')
  fn = fn.sub(/(---%CRLF%-1#{regexdelim}.*?)#{regexdelim}%CRLF%/, '\1NULL%CRLF%') #removes valueless rows
  fn = fn.gsub(/%CRLF%\s*#{regexdelim}+\s*%CRLF%/, '%CRLF%')
  fn = fn.gsub(/\t%CRLF%/, '%TABLINEBREAK')
  fn = fn.gsub(/%CRLF%([a-z]\.)\t(\w)/, '%LINEBREAK%\1 \2') #UU00.63
  fn = fn.gsub(/%CRLF%\t+(-\w)/, '%LINEBREAK%\1') #UR307
  fn = fn.gsub(/:%CRLF%%CRLF%-/, '%LINEBREAK%-') #UR307
  fn = fn.gsub(/\ta\.\t/, '%TAB%a. ')
  fn = fn.gsub(/%CRLF%([^ 0-9\-]+#{regexdelim})/, '%LINEBREAK%\1')
  fn = fn.gsub(/%CRLF%$/, '')
  fn = fn.gsub(/%CRLF% +([0-9\-]+#{regexdelim})/, '%NEWROW%\1')
  fn = fn.gsub('"', '%DOUBLEQUOTE%')
  fs = fn.split('%NEWROW%')
  fs.delete_at(1) if fs.length > 1 && fs[1]['----']

  fs.map!{ |row| row.split(delimiter).map(&:strip).join(delimiter) }
  
  
  puts "ROWS: #{fs.length}"

  pre = "#{options[:suffix]}"
  post = "_l#{options[:suffix]}"
  path = file.sub(pre, post)
  puts "OUTFILE: #{path}"
  
  File.open(path, 'w') do |outfile|
    fs.each{ |ln| outfile.write("#{ln}\n") }
  end
end

files = files.map{ |f| f.sub("#{options[:suffix]}", "_l#{options[:suffix]}") }

fdata = []

files.each do |thefile|
  #  next unless thefile.end_with?('Objects_l.tsv')
  h = {}
  origfile = thefile.sub(options[:output], options[:input]).sub("_l#{options[:suffix]}", "#{options[:suffix]}")
  puts "Getting file info from #{origfile}"
  fileinfo = `file #{origfile}`
  h[:tablename] = origfile.sub(/^.*\//, '')
  fi = fileinfo.match(/^.*: (.* text),(.*,|) with (.*) line terminators/)
  h[:encoding] = fi[1]
  h[:EOL] = fi[3]
  if fileinfo['very long lines']
    h[:longlines] = 'very long'
  elsif fileinfo['long lines']
    h[:longlines] = 'long'
  else
    h[:longlines] = 'no'
  end
  
  puts "Checking structure of #{thefile}"
  structure = {}

  ct = 0
  File.readlines(thefile).each do |row|
    ct += 1
    row = row.chomp.split(delimiter)
    len = row.length
    if structure.key?(len)
      structure[len] = structure[len] + 1
    else
      structure[len] = 1
    end
  end

  if structure.keys.length == 1
    h[:structureok] = 'y'
    h[:rows] = structure.values.first
    h[:columns] = structure.keys.first
    fdata << h
  else
    h[:structureok] = 'n'
    structure.each do |colct, rowct|
      newh = h.clone
      newh[:rows] = rowct
      newh[:columns] = colct
      fdata << newh
    end
  end
  
  # case delimiter
  # when '|'
  #   res = %x~ awk '{ FS="|" } {print NF}' #{thefile} | sort | uniq -c | sort -nr ~
  # when '\t'
  #   res = %x~ awk '{ FS="\t" } {print NF}' #{thefile} | sort | uniq -c | sort -nr ~
  # end
  # res = res.split("\n").map{ |line| line.strip.split(' ') }
  # if res.size == 1
  #   h[:structureok] = 'y'
  #   h[:rows] = res[0][0]
  #   h[:columns] = res[0][1]
  #   fdata << h
  # else
  #   h[:structureok] = 'n'
  #   res.each do |e|
  #     newh = h.clone
  #     newh[:rows] = e[0]
  #     newh[:columns] = e[1]
  #     fdata << newh
  #   end
  # end
  
end

CSV.open("#{options[:output]}/file_report.csv", 'w') do |csv|
  csv << fdata.first.keys
  fdata.each{ |h| csv << h.values }
end
