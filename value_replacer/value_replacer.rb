require 'csv'

# Creates a hash where the key is the value you want to replace
# and the value is the value with which to replace
# PATH is a string to the folder path
# FILE is a string of the filename
# ENCODING (nil) is a string indicating the character encoding for the file
# If you want the CSV library to detect the character encoding, do not provide encoding
def create_value_hash (path,file,encoding=nil)
  filepath = File.join(path,file)
  value_hash = {}
  
  CSV.foreach(filepath,encoding: encoding) do |row|
    value_hash[row[0]] = row[1]
  end

  value_hash
end

# Given a CSV and a hash where the key is the value you want to replace
# and the value is the value with which to replace,
# create a new .csv file and replace values
# PATH (string) is the folder path
# FILE (string) is the filename
# VALUE_HASH (hash) is a hash where the key is the value you want to replace
# and the value is the value with which to replace. This is meant to be created using
# create_value_hash
# INDEXES(int or array of ints) are the indexes of the values to replace
# ENCODING (default: nil, string) indicates the character encoding for the file
# If you want the CSV library to detect the character encoding, do not provide encoding
# DELIMITER (default: nil, string) is the delimiter if you have multivalued fields
def replace_values (path,file,value_hash,indexes,encoding:nil,delimiter:nil)
  filepath = File.join(path,file)
  fields = [fields].flatten
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