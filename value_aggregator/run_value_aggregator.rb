require_relative './value_aggregator'

input_path = File.expand_path("./support")
input = "input.csv"
data = CSV.read(File.join(input_path,input), encoding: "utf-8", headers:true)

value_aggregator = ValueAggregator.new

value_aggregator.add_uniq_to_list(data, %w(category theme))

value_aggregator.save_csv(input_path,"single_list.csv")