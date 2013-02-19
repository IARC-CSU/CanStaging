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

post '/tnm' do
  site = @@sites[params["site"].downcase.to_sym] unless params["site"].nil?
  if site.nil?
    return {"Error"=>"Unknown site: #{params["site"]}"}.to_json
  else
    site.get_metas.each do |part, meta| 
      meta.fields.keys.each do |key|
        number = params["data"][part].delete "#{key}-number" # remove the temporary variables
        params["data"][part][key] = meta.fields[key].value_to_codes(number).first  unless number.nil?
      end
    end
    puts params
    jdata = params["data"]
    return JSON.pretty_generate(site.calculate_tnm(jdata)) #["TNM"]
  end
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
