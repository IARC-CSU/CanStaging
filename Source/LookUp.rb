# Author: Morten Ervik, ervikm@iarc.fr, CSU/IARC

require 'csv'

class LookUp
  attr_reader :variables_needed, :variables_generated

  def initialize file_name
    unless file_name.nil? || !File.exist?(file_name)
      @table = []
  
      # assume last letter of file_name is part 
      part = file_name.split(".")[-2][-1].upcase

      # read csv
      csv = CSV.read(file_name, :headers => true, encoding: "UTF-8")

      # set up input/output variable mappings
      @variables_needed = csv.first.headers.take_while {|varb| varb != 'Result'}
      @variables_generated = ['Result'] + csv.first.headers.reverse.take_while {|varb| varb != 'Result'}

      # add a line of Xs to T, N
      if ['T','N'].include? part
        x_row = {'Result'=> part+'X'}
        @variables_needed.each {|varb| x_row[varb] = 'X'}
        @table << x_row
      end

      # convert csv to array of hashes
      csv.map { |row| @table << row.to_h }

      # find first row with no Xs and threat them as defaults
      @table.each do |row| 
        if row.to_h.values.include?("X")
          # do nothing
        else
          # default values found
          @defaults = row.to_h
          # ANY is not a valid default and is replaced with blank...
          @defaults.inject(@defaults) { |h, (k,v)| v == "ANY" ? h[k] = "" : h[k] = v; h }
          # puts "Defaults: #{@defaults}" # if DEBUG
          break
        end
      end
    end
  end

  def look_up values
    # values is a hash with values
    responses = []
    unless @table.nil?
      keys = values.keys
      # remove keys that have empty fields
      # puts values if settings.environment == :development
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
        # does it contain don't knows -- we replace them with no's and try again
        if values.values.include?("X") 
          new_values = {}
          values.each { |key, value| values[key] == "X" ? new_values[key] = @defaults[key] : new_values[key] = value }
          # values.each { |key, value| values[key] == "X" ? new_values[key] = "" : new_values[key] = value }
          r_temp = look_up(new_values)
          return r_temp
        else
          # else return 
          valid_entries << {"Result"=>"ERROR",  "Message" => R18n.t[:look_up][:no_valid_code_found]}
        end 
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