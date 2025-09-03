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

require_relative './Library.rb' 

require 'rdiscount'

class Variable
  attr_reader :name, :type, :display_text, :group, :colour, :ranges, :dictionary, :tooltip, :image, :text, :order, :default, :link
  def initialize (name, type, display_text, group, colour, tooltip = "", dictionary=nil, ranges=nil, image=nil, text=nil, link=nil)
    @name = name
    @type = type
    @display_text = display_text
    @group = group
    @colour = colour
    @dictionary = dictionary
    @ranges = ranges
    @tooltip = tooltip
    @image = image  # pop up image
    @text = text    # pop up text -- potentially in markdown
    @link = link    # pop up html file
  end
  
  def dictionary= dictionary
    @dictionary = dictionary
  end
  
  def ranges= ranges
    @ranges = ranges
  end
  
  def order= order
    @order = order
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
  
  def image= path 
    @image = path
  end

  def text= path 
    @text = path
  end

  def link= path 
    @link = path
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

  def default=(default)
    @default = default
  end
  
end