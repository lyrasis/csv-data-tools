CSV Value Aggregator
====================

This tool aggregates values from any number of .csv files and fields into a single unique list and adds functionality to save that list to a single-column .csv.

`#add_uniq_to_list` adds specified field values to single unique list to output later.

`#list` returns list.

`#save_csv` saves list to .csv.

See `run_value_aggregator.rb` as an example implementation and `value_aggregator_test` for test cases.

Use Cases
---------

This tool is intended to be help deal with messy controlled vocabularies. For example, a client may have multiple spreadsheets with multiple columns that would migrate as subjects. A straightforward path to normalize all these subject fields is to create a single, de-duplicated list that the client can review.

See [value_replacer](../value_replacer/) for a follow-up tool that takes a reviewed list of values and replaces values in datasets.

Assumptions
-----------

This tool takes values as-is. It does not attempt to split multi-valued cells.

