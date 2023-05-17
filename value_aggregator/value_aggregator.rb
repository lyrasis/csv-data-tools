require 'csv'

# Simple class that collects unique values from fields and outputs
#   a single-column CSV with all the aggregated values
#
# @attr_reader list [Array<String>] the uniq list of aggregated values
class ValueAggregator

  attr_reader :list

  def initialize
    @list = []
  end

  # Adds specified field values to single unique list to output later 
  # 
  # @param csv_table [CSV::Table] the CSV Table with the data
  # @param field_names [Array<String>] the field names with the values to grab
  # @return [nil] adds the values to @list
  def add_uniq_to_list(csv_table,field_names)
    field_names.each{|field| csv_table[field].reject{|value| value.nil?}.uniq.each{|value| @list << value}}
  end

  # Saves @list to a specified file 
  # 
  # @param path [String] folder path to save the data
  # @param file [String] name of the file to save
  # @return [nil] saves @list to file
  def save_csv(path,file)
    CSV.open(File.join(path,file), "wb") do |csv|
      @list.uniq.each {|item| csv << [item]}
    end
  end

end
