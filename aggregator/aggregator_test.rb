require 'minitest/autorun'
require_relative './aggregator'



class AggregatorTest < Minitest::Test
  def setup
    @csv = CSV.parse("age,name,likes\n37,Jacob,games\n25,Anna,",headers:true)
    @aggregator = Aggregator.new
    @aggregator.aggregate(@csv)
  end

  def test_aggregate_creates_headers
    output = @aggregator.get_csv
    assert @aggregator.get_csv.headers == ['age','name','likes']
  end

  def test_out_to_csv_matches_source
    assert @aggregator.get_csv.to_csv == "age,name,likes\n37,Jacob,games\n25,Anna,\n"
  end

  def test_new_headers_added
    csv = CSV::Table.new([])
    row = CSV::Row.new([],[]) << {"age"=>"40","name"=>"Jon","pets"=>"cat"}
    csv << row
    @aggregator.aggregate(csv)
    assert @aggregator.get_csv.headers == ['age','name','likes','pets']
  end

  def test_unsupplied_field_nilled
    csv = CSV::Table.new([])
    row = CSV::Row.new([],[]) << {"pets"=>"cat","name"=>"Jon","age"=>"40"}
    # csv.append(row)
    csv << row
    @aggregator.aggregate(csv)
    assert @aggregator.get_csv[2].to_h == {"age"=>"40","name"=>"Jon","pets"=>"cat","likes"=>nil}
    assert @aggregator.get_csv.to_csv == "age,name,likes,pets\n37,Jacob,games,\n25,Anna,,\n40,Jon,,cat\n"
  end


end