require 'csv'


module CsvExtensions
  module Table
    # monkey patches CSV::Table#<<
    # if `row_or_array` is a CSV::Row, converts `row_or_array` into hash
    # and then an array that is sorted by the target CSV:Table's headers
    # ensures the values are in the correct order going into the target Table
    def append(row_or_array)
      if row_or_array.is_a? Array  # append Array
        @table << CSV::Row.new(headers, row_or_array)
      elsif row_or_array.is_a? CSV::Row
        # converting Row to hash and then an array that is sorted by the Table headers
        @table << CSV::Row.new(headers,row_or_array.to_h.values_at(*headers))
      else
        @table << row_or_array
      end
    
      self # for chaining
    end
  end
end

CSV::Table.include CsvExtensions::Table

class Aggregator

  # sets up CSV::Table for aggregation
  def initialize
    @csv = CSV::Table.new([])

  end

  # returns target csv
  def get_csv
    return @csv
  end

  # loops through source CSV::Table and adds each row to the target CSV::Table
  # csv_table is a CSV::Table
  def aggregate(csv_table)
    # first, add headers if they don't already exist
    csv_table.headers.each {|header| @csv[header] = nil unless @csv.headers.include? header }
    csv_table.each {|row| @csv.append row}
  end

  # saves target csv to specified filepath
  def save_csv(path,file)
    File.write(File.join(path,file),self.get_csv.to_csv)
  end

  # saves target csv as json
  def save_json(path,file)
    File.write(File.join(path,file),self.get_csv.map(&:to_h))
  end

end