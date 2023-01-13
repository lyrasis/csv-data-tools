require 'csv'

# Creates a hash where the key is the value you want to replace
#   and the value is the value with which to replace
# 
# @param path [String] the folder path
# @param file [String] the filename
# @param encoding [String, Nil] the character encoding for the file. default is nil.
#   If you want the CSV library to detect the character encoding, do not provide encoding
# @return [Hash] the lookup hash used in #replace_values
def create_value_hash (path:,file:,encoding:nil)
  filepath = File.join(path,file)
  value_hash = {}
  
  CSV.foreach(filepath,encoding: encoding) do |row|
    value_hash[row[0]] = row[1]
  end

  value_hash
end

# Given a CSV and a hash where the key is the value you want to replace
#   and the value is the value with which to replace,
#   create a new .csv file and replace values
# 
# @param path [String] the folder path
# @param file [String] the filename
# @param value_hash [Hash] a hash where the key is the value you want to replace
#   and the value is the value with which to replace. This is meant to be created using #create_value_hash
# @param indexes [Integer, Array<Integer>] the column index(es) within the CSV row array of the 
#   values to look up and replace
# @param encoding [String, Nil] the character encoding for the file. default is nil.
#   If you want the CSV library to detect the character encoding, do not provide encoding
# @param delimiter [String, Nil] the delimiter if you have multivalued fields. default is nil
# @return [Nil] returns nothing. instead writes to .csv file
def replace_values (path:,file:,value_hash:,indexes:,encoding:nil,delimiter:nil)
  filepath = File.join(path,file)
  indexes = [indexes].flatten
  CSV.open(File.join(path,"#{file[..-5]}_values_replaced.csv"),"wb") do |csv|
    CSV.foreach(filepath,encoding: encoding) do |row|
      new_row = row
      indexes.each do |i|
        unless row[i].nil?
          if delimiter.nil?
            if value_hash[row[i]] == nil
            elsif value_hash[row[i]] == "DELETE"
              new_row[i] = nil
            else
              new_row[i] = value_hash[row[i]]
            end
          else
            values = row[i].split(delimiter)
            values.map! do |value|
              if value_hash[value] == nil
                value
              elsif value_hash[value] == "DELETE"
                value
              else
                value_hash[value]
              end
            end
            values.each {|value| values.delete(value) if value_hash[value] == "DELETE"}
            new_row[i] = values.empty? ? nil : values.join(delimiter)
          end
        end

      end
      csv << new_row
    end
  end

end