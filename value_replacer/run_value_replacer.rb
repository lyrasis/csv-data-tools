require_relative './value_replacer'

input_path = "Path/to/file"
input = "input.csv"

to_replace_path = "path/to/file"
to_replace_file = "to_replace.csv"

value_hash = create_value_hash(path:to_replace_path,file:to_replace_file)

replace_values(path:input_path,file:input,value_hash:value_hash,indexes:[1,2],encoding: "utf-8",delimiter: "|")