# Author: Morten Ervik, ervikm@iarc.fr, CSU/IARC

## Library

## Some helper functions to the String class
class String
  def underscore
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end
  def to_bool
    return true if self == true || self =~ (/(true|t|yes|y|1)$/i)
    return false if self == false || self.empty? || self =~ (/(false|f|no|n|0)$/i)
    raise ArgumentError.new("invalid value for Boolean: \"#{self}\"")
  end
end

## Some general helper functions
def csv_to_array_of_hashes csv
  arr = []
  csv.entries.each {|e| arr << e.to_hash }
  arr
end
