require 'minitest/autorun'
require_relative './value_aggregator'



class ValueAggregatorTest < Minitest::Test
  def setup
    @path = File.expand_path("./support")
    @input = "input.csv"
    @data = CSV.read(File.join(@path,@input),headers:true)
    @value_aggregator = ValueAggregator.new
  end

  def test_aggregator_adds_new_values
    @value_aggregator.add_uniq_to_list(@data, %w(category theme))
    assert @value_aggregator.list.include? "cast"
    assert @value_aggregator.list.include? "sci-fi"
  end

end