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

class Dictionary
  attr_accessor :table
  
  def initialize file_name = nil
    unless (file_name.nil?)
      # puts file_name if !defined?(settings) || settings.environment == :development
      csv = CSV.read(file_name, :headers => true, encoding: "UTF-8")
      @table = {}
      csv.each do |row|
        @table[row["Key"]] = row["DisplayText"]
      end
    end
  end
  
  def generate_reverse_table
    @reverse_table = {}
    @table.each { |key, value| @reverse_table[value.downcase.strip] = key }
  end
  
  def value_to_codes value
    generate_reverse_table if @reverse_table.nil?
    re = Regexp.new value.downcase.strip
    @table.values.find_all {|val| val=~re}.map{|desc| @reverse_table[desc.downcase.strip]}
    # @reverse_table[value.downcase.strip]
  end
  
  def code_to_value code
    @table[code]
  end
  
  def to_json(*a)
    {
      'json_class'   => self.class.name, # = 'Meta'
      'data'         => [ @table ]
    }.to_json(*a)
  end
  
  def self.json_create(o)
    construct(*o['data'])
  end
  
  def self.construct(table)
    dictionary = Dictionary.new
    dictionary.table = table
    dictionary
  end
  
  def to_print
    p = ""
    @table.each do |key, value|
      p += "#{key} - #{value}\n"
    end
    p
  end
  
end