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

require 'csv'
require 'json'

require_relative './Variable.rb'
require_relative './Library.rb'
require_relative './Dictionary.rb'
require_relative './Ranges.rb'

class Meta
  attr_accessor :fields
  def initialize file_name = nil
    # puts file_name if $DEBUG
    @fields = {}
    unless file_name.nil? || !File.exist?(file_name)
      table = CSV.read(file_name, :headers => true, encoding: "UTF-8")
      table.each do |row|
        name = row["Field"]
        type = row["DataType"].underscore.to_sym
        text = row["DisplayText"]
        group = row["Group"] || "1"
        colour = row["Colour"]
        tooltip = row["Tooltip"] || ""
        variable = Variable.new(name, type, text, group, colour, tooltip)
        case type
        when :dictionary
          variable.dictionary = Dictionary.new("#{file_name.sub("Meta.txt", "#{name}_Dict.txt")}")
        when :number
          variable.ranges = Ranges.new("#{file_name.sub("Meta.txt", "#{name}_Range.txt")}")
        end
        variable.default= row["Default"] unless row["Default"].nil? || row["Default"].empty?
        add_field(variable)
      end
    end
  end
  
  def to_json(*a)
    {
      'json_class'   => self.class.name, # = 'Meta'
      'data'         => [ @fields ]
    }.to_json(*a)
  end
  
  def self.json_create(o)
    # puts *o['data'][0].class
    construct(*o['data'])
  end
  
  def self.construct(fields)
    meta = Meta.new
    meta.fields = fields
    meta
  end
  
  def add_field(variable)
    variable.order = @fields.length
    @fields[variable.name] = variable
  end

  def defaults
    defaults = {}
    @fields.each do |name, variable|
      d = variable.default
      defaults[name] = d unless d.nil? || d.empty?
    end
    defaults
  end

end
