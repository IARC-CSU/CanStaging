# Author: Morten Ervik, ervikm@iarc.fr, CIN/IARC

require 'rest-client'
require 'json'
require './Meta.rb'
require 'pp'

server = ARGV[0] || "localhost:4567"
api_key = ARGV[1] || "xyz"

jdata = {"T" => {"Size" => "1", "ChestInvasion" => "F", "Ulceration" => "F", "Inflammation" =>"F", "Test" => "1"}}
site = "Lung"
time = Time.now
response = ""
# 10.times do
begin
  response = RestClient.post "http://#{server}/tnm?key=#{api_key}", {:data =>jdata, :site=>site}, {:content_type => :json, :accept => :json}
  puts JSON.parse(response)["TNM"]
rescue RestClient::Unauthorized => e
  puts e.to_s
  exit
end
# end
# puts Time.now - time # ~ one second per response using mongrel or thin
# puts response

####
site_to_query = :colorectal

puts "Getting meta data from #{server} on #{site_to_query}..."
json = RestClient.get "http://#{server}/meta/#{site_to_query}?key=#{api_key}"
puts json
metas = JSON.parse(json)
puts metas
# exit
puts
puts "Please enter a case:"
data = {}
metas.each do |part, meta|
  puts "\nInformation relevant to #{part}: ----------------------"
  puts "Nothing to enter for this part" if meta.fields.nil? || meta.fields.empty?
  data[part]={}
  meta.fields.values.each do |field|
    value = nil
    puts field.display_text
    case field.type.to_sym
    when :boolean
      puts "True or false?"
      while value.nil? || value.empty?
        value = STDIN.gets.strip
        begin
          value = field.value_to_codes(value)
        rescue 
          value = nil
          puts "Please enter True or False (1/0, t/f, Y/N ...)"
        end
      end
    when :dictionary
      puts field.dictionary.to_print
      while value.nil? || value.empty?
        value = STDIN.gets.strip
        value = field.code_to_value(value).nil? ? nil : value
        puts "Invalid code" if value.nil? || value.empty?
      end
    when :number
      if field.ranges.float? 
        puts "(#{field.ranges.min_min.nil? ? "<" : field.ranges.min_min}-#{field.ranges.max_max.nil? ? ">" : field.ranges.max_max})"
      else
        puts "(#{field.ranges.min_min.nil? ? "<" : field.ranges.min_min.to_i}-#{field.ranges.max_max.nil? ? ">" : field.ranges.max_max.to_i})" 
      end
      while value.nil? || value.empty?
        value = STDIN.gets.strip
        value = field.value_to_codes(value)
        puts "Outside of range. (#{field.ranges.min_min.nil? ? "<" : field.ranges.min_min}-#{field.ranges.max_max.nil? ? ">" : field.ranges.max_max})" if value.nil? || value.empty?
      end
    end
    value = value.instance_of?(Array) && value.length > 0 ? value[0] : value
    data[part][field.name] = value
    puts field.code_to_value value
    puts
  end
end
puts
puts "You are submitting:"
pp data
puts
response = RestClient.post "http://#{server}/tnm?key=#{api_key}", {:data =>data, :site=>site_to_query}, {:content_type => :json, :accept => :json}
puts "The results are in:"
puts JSON.pretty_generate(JSON.parse(response))
puts
puts "The TNM is #{JSON.parse(response)["TNM"][0]["Result"]}"