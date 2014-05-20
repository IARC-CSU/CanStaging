# Author: Morten Ervik, ervikm@iarc.fr, CIN/IARC
require 'csv'

class LookUp
  attr_reader :variables_needed, :variables_generated

  def initialize file_name
    unless file_name.nil? || !File.exist?(file_name)
      @table = CSV.read(file_name, :headers => true)
      @variables_needed = @table.first.headers.take_while {|varb| varb != 'Result'}
      @variables_generated = ['Result'] + @table.first.headers.reverse.take_while {|varb| varb != 'Result'}
    end
  end

  def look_up values
    # values is a hash with values
    responses = []
    unless @table.nil?
      keys = values.keys
      # remove keys that have empty fields
      puts values
      keys = keys.find_all { |key| (!values[key].nil?) && (values[key].strip.length>0)}
      valid_entries = @table.find_all do |row|
        found = true
        keys.each do |key|
          if @variables_needed.include?(key)
            found = found && (row[key] == values[key] || row[key]=="ANY")
          end
        end
        found
      end
      if valid_entries.empty?
        valid_entries << {"Result"=>"ERROR",  "Message" => "No valid codes found..."}
      end
      valid_entries.map do |entry|
        response = {}
        @variables_generated.each do |varb|
          response[varb] = entry[varb]
        end
        response["Message"] = entry["Message"].nil? ? "" : entry["Message"]
        responses << response
      end
    end
    responses
  end

  def control_categories control, value
    valid_entries = @table.find_all do |row|
      (row[control] == value || row[control]=="ANY")
    end
    
    valid_entries
  end

end