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

# Author: Morten Ervik, ervikm@iarc.who.int, CSU/IARC

class Ranges
  attr_accessor :table
  attr_reader :min_min, :max_max
  def initialize file_name = nil
    unless file_name.nil?
      csv = CSV.read(file_name, :headers => true)
      @table = {}
      csv.each do |row|
        @table[row["Key"]] = {"min" =>row["Min"].to_f, "max" => row["Max"].to_f}
      end
      find_min_max
      @float = float_or_not?
    end
  end

  def find_min_max
    @min_min = nil
    @max_max = nil
    @table.values.each do |value|
      @min_min = value["min"] if @min_min.nil? || value["min"] < @min_min
      @max_max = value["max"] if @max_max.nil? || value["max"] > @max_max
    end
  end

  def float?
    @float
  end

  def value_to_codes value
    # puts value
    value = value.gsub(',','.').gsub(/[^0-9\.]/,'') # remove all letters and replace comma with periods...
    if value.gsub('.','').empty? 
      # return "X" (don't know) if we don't have any numbers left...
      return ["X"]
    else 
      value = value.to_f
      codes = []
      @table.keys.each do |k|
        codes << k if ((value >= @table[k]["min"].to_f) && (value <= @table[k]["max"].to_f))
      end
      codes
    end
  end
  
  def code_to_value code
    "#{@table[code]["min"]}-#{@table[code]["max"]}"
  end

  def to_json(*a)
    {
      'json_class'   => self.class.name, # = 'Meta'
      'data'         => [ @table ]
    }.to_json(*a)
  end
  
  def self.json_create(o)
    # puts *o['data']
    construct(*o['data'])
  end
  
  def self.construct(table)
    ranges = Ranges.new
    ranges.table = table
    ranges.find_min_max
    ranges
  end
  
  def to_s
    float? ? "#{@min_min}-#{@max_max}" : "#{@min_min.to_i}-#{@max_max.to_i}"
  end

  private

  def float_or_not?
    @table.values.each do |value|
      return true if value["min"].to_i != value["min"] || value["max"].to_i != value["max"]  # if just one value in the range is a float - we define the range over floats
    end
    return false
  end  


end