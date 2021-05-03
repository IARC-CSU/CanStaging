# This file is part of CanStaging.

# CanStaging is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# CanStaging is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with CanStaging.  If not, see <https://www.gnu.org/licenses/>.

# Author: Morten Ervik, ervikm@iarc.fr, CSU/IARC

require 'csv'

class LookUp
  attr_reader :variables_needed, :variables_generated

  def initialize file_name
    # puts file_name if !defined?(settings) || settings.environment == :development
    unless file_name.nil? || !File.exist?(file_name)
      @table = []
  
      # assume last letter of file_name is part 
      @part = file_name.split(".")[-2][-1].upcase

      # read csv
      csv = CSV.read(file_name, :headers => true, encoding: "UTF-8")

      # set up input/output variable mappings
      @variables_needed = csv.first.headers.take_while {|varb| varb != 'Result'}
      @variables_generated = ['Result'] + csv.first.headers.reverse.take_while {|varb| varb != 'Result'}

      # add a line of Xs to T, N
      # if ['T','N'].include? @part
      #   x_row = {'Result'=> @part+'X'}
      #   @variables_needed.each {|varb| x_row[varb] = 'X'}
      #   @table << x_row
      # end

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

  def add_defaults(defaults)
    # Of the form {"Nodes"=>"F", "Bone"=>"F", "Other"=>"F", "Result"=>"M0", "Message"=>nil}
    # merge defaults into @defaults
    @defaults = @defaults.merge(defaults)
    puts "#{@part} - Defaults after merge: #{@defaults}" # if DEBUG
  end

  def look_up values
    puts "#{@part} - Defaults during lookup: #{@defaults}"
    # values is a hash with values
    responses = []
    unless @table.nil?
      # puts values if $DEBUG
      keys = values.keys
      # remove keys that have empty fields
      # puts values if !defined?(settings) || settings.environment == :development
      ## If all values are X or empty
      if (values.values + ['X','']).uniq.sort == ['','X']
        valid_entries = [{'Result'=> Site.get_default_result(@part)}]
      else ## If some values are X
        new_values = {}
  
        values.each { |key, value| new_values[key] = value if values[key] != "X" }
      
        # values = new_values

        keys = keys.find_all { |key| (!new_values[key].nil?) && (new_values[key].strip.length>0) && (new_values[key] != 'X')}

        valid_entries = @table.find_all do |row|
          found = true
          keys.each do |key|
            if @variables_needed.include?(key)
              found = found && (row[key] == new_values[key] || row[key]=="ANY")
            end
            found
          end
        end
      end

      ## third pass, if needed -- replace Xs with defaults

      if valid_entries.empty?
        # does it contain don't knows -- we replace them with defaults and try again
        if values.values.include?("X") 
          temp_values = {}
          values.each { |key, value| values[key] == "X" ? temp_values[key] = @defaults[key] : temp_values[key] = value }
          # values.each { |key, value| values[key] == "X" ? temp_values[key] = "" : temp_values[key] = value }
          return look_up(temp_values)
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
