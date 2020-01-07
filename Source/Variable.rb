# Author: Morten Ervik, ervikm@iarc.fr, CSU/IARC

require_relative './Library.rb' 

class Variable
  attr_reader :name, :type, :display_text, :group, :colour, :ranges, :dictionary, :tooltip, :image
  def initialize (name, type, display_text, group, colour, tooltip = "", dictionary=nil, ranges=nil, image=nil)
    @name = name
    @type = type
    @display_text = display_text
    @group = group
    @colour = colour
    @dictionary = dictionary
    @ranges = ranges
    @tooltip = tooltip
    @image = image
  end
  
  def dictionary= dictionary
    @dictionary = dictionary
  end
  
  def ranges= ranges
    @ranges = ranges
  end
  
  def value_to_codes value
    codes = []
    case type.to_sym
    when :number
      codes = @ranges.value_to_codes value
    when :boolean
      codes << (value.to_bool ? "T" : "F")
    when :dictionary
      codes = @dictionary.value_to_codes value
    end
  end
  
  def code_to_value code
    case type.to_sym
    when :dictionary
      @dictionary.code_to_value code
    when :number
      @ranges.code_to_value code
    else
      code
    end
  end
  
  def set_image_path path 
    @image = path
  end

  def to_s
    "#{@name}(#{@type})"
  end
  
  def to_json(*a)
    {
      'json_class'   => self.class.name, # = 'Variable'
      'data'         => [ @name, @type, @display_text, @group, @colour, @dictionary, @ranges ]
    }.to_json(*a)
  end
  
  def self.json_create(o)
    # puts *o['data']
    new(*o['data'])
  end
  
end