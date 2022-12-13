require 'minitest/autorun'
require_relative './value_replacer'



class ValueReplacer < Minitest::Test
  def setup
    @path = File.expand_path("./support")
    @to_replace = "to_replace.csv"
    @input = "input.csv"
    @value_hash = create_value_hash(@path,@to_replace)
    replace_values(@path,@input,@value_hash,[1,2],delimiter:"|")
    @data = CSV.read(File.join(@path,"#{@input[..-5]}_values_replaced.csv"))
  end

  def test_replacer_replaces_values
    assert @data[1] == ['This is a title','cats','thriller']
  end

  def test_replacer_deletes_unwanted_values
    assert @data[3] == ['Yet another title','cats',nil]
    assert @data[5] == ['Yet another title','cats','thriller']
  end

  def test_replacer_ignores_values_not_in_value_hash
    assert @data[2] == ['This is another title','dogs','sci-fi']
  end

  def test_replacer_replaces_multivalues
    assert @data[4] == ['The fourth title','cats|dogs',nil]
    assert @data[6] == ['Real example 1','Historical Images~Construction~1950-1959~1960-1969',nil]
  end

end