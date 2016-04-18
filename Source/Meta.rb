# Author: Morten Ervik, ervikm@iarc.fr, CIN/IARC

require 'csv'
require 'json'

require './Variable.rb'
require './Library.rb'
require './Dictionary.rb'
require './Ranges.rb'

class Meta
  attr_accessor :fields
  def initialize file_name = nil
    @fields = {}
    unless file_name.nil? || !File.exist?(file_name)
      table = CSV.read(file_name, :headers => true, encoding: "UTF-8")
      table.each do |row|
        name = row["Field"]
        type = row["DataType"].underscore.to_sym
        text = row["DisplayText"]
        group = row["Group"]
        colour = row["Colour"]
        @fields[name] = Variable.new(name, type, text, group, colour)
        case type
        when :dictionary
          @fields[name].dictionary = Dictionary.new("#{file_name.sub("Meta.txt", "#{name}_Dict.txt")}")
        when :number
          @fields[name].ranges = Ranges.new("#{file_name.sub("Meta.txt", "#{name}_Range.txt")}")
        end
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
  
end
