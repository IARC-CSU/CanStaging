require 'csv'

class LookUp
  attr_reader :variables_needed
  def initialize file_name
    unless file_name.nil? || !File.exist?(file_name)
      @table = CSV.read(file_name, :headers => true)
    end
  end
  def look_up values
    # values is a hash with values
    responses = []
    unless @table.nil?
      keys = values.keys
      valid_entries = @table.find_all do |row|
        found = true
        keys.each do |key|
          found = found && (row[key] == values[key] || row[key]=="ANY")
        end
        found
      end
      if valid_entries.empty?
        valid_entries << {"Result"=>"T-ERROR ",  "Message" => "No valid codes found..."}
      end
      valid_entries.map do |entry|
        response = {}
        response["Result"] = entry["Result"]
        response["Message"] = entry["Message"]
        responses << response
      end
    end
    responses
  end
end