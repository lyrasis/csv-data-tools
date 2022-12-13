require_relative './value_replacer'

input_path = "Path/to/file"
input = "input.csv"

to_replace_path = "path/to/file"
to_replace_file = "to_replace.csv"

value_hash = create_value_hash(to_replace_path,to_replace_file)

replace_values(input_path,input,value_hash,[1,16,17,28,55,60,110],encoding: "utf-8",delimiter: "|")