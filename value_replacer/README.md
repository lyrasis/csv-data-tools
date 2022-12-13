CSV Value Replacer
==================

This tool replaces values in a .csv file by looking up the cleaned values in a supplemental .csv.

`#create_value_hash` Creates a hash where the key is the value you want to replace and the value is the value with which to replace. It expects the first column in the .csv to be the value to replace and the second column to be the value with which to replace.

`#replace_values` takes the provided .csv and creates a new .csv, replacing values at the provided row indexes using the hash created by `#create_value_hash` as a lookup.

See `run_value_replacer.rb` as an example implementation and `value_replacer_test` for test cases.

Behaviors
---------

* will delete value if its replace value is "DELETE"
* will keep original values if the value is not in the value_hash or if the replace value in value_hash is blank (nil)
* will split and iterate through multivalues if a delimiter is provided