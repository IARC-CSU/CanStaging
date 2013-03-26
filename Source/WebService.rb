# Author: Morten Ervik, ervikm@iarc.fr, CIN/IARC

require 'sinatra'
require 'json'

# set :server, %w[thin mongrel webrick]
# set :environment, :production

require './Site.rb'
@@sites = {}

available_sites = Dir.entries('../Tables/').delete_if {|e| e.start_with? '.'} 

# Potential override...
# available_sites = [
#  "Breast", 
#  "Test"
#  ]

available_sites.each do |site|
  @@sites[site.downcase.to_sym] = Site.new(site)
end

# Added a check for valid api key to all calls to the service... 
before do
  error 401 unless params[:key] =~ /^xyz/ # todo: change this to a system of keys per user... (now it just checks for keys starting with xyz)
end

post '/tnm' do
  puts params
  site = @@sites[params["site"].downcase.to_sym] unless params["site"].nil?
  if site.nil?
    return {"Error"=>"Unknown site: #{params["site"]}"}.to_json
  else
    site.get_metas.each do |part, meta| 
      meta.fields.keys.each do |key|
        unless params["data"][part].nil?
          number = params["data"][part].delete "#{key}-number" # remove the temporary variables
          params["data"][part][key] = meta.fields[key].value_to_codes(number).first unless (number.nil? || number.length == 0)
        end
      end
    end
    puts params
    jdata = params["data"]
    return JSON.pretty_generate(site.calculate_tnm(jdata)) #["TNM"]
  end
end

get '/tool' do 
  erb :tool, :locals => {:sites => @@sites.keys }
end

get '/meta/*' do |site_name|
  site = @@sites[site_name.downcase.to_sym]
  if site.nil?
    response = {"Error"=>"Unknown site: #{site_name}"}.to_json
  else
    response = JSON.pretty_generate(site.get_metas)
  end
  response
end

get '/sites.json' do
  @@sites.keys.to_json
end

get '/test/*' do |site_name|
  if @@sites[site_name.downcase.to_sym].nil? 
    halt 440, "Nothing to see here..."
  else
    erb :test, :locals => {:site => @@sites[site_name.downcase.to_sym] }
  end
end

not_found do
  halt 440, "Nothing to see here..."
end
