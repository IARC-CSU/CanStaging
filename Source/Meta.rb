# Author: Morten Ervik, ervikm@iarc.fr, CIN/IARC

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
    @fields[variable.name] = variable
  end
end
