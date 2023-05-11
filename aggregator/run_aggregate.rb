require_relative './aggregator'

source_path = File.expand_path("path/to/csvs")

files = `ls #{source_path}`.split("\n")

aggregator = Aggregator.new

files.each do |file|
  if file[-4..] == ".csv"
    # source_csv = CSV.read(File.join(source_path,file),encoding:"utf-8",headers:true)
    source_csv = CSV.read(File.join(source_path,file),encoding:"bom|utf-8",headers:true)

    aggregator.aggregate(source_csv)
  end

end

aggregator.save_csv(File.join(source_path,"aggregated"),"aggregated.csv")
# aggregator.save_json(source_path,"aggregated.json")