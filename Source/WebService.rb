# Author: Morten Ervik, ervikm@iarc.fr, CIN/IARC

require 'sinatra'
# set :server, %w[thin mongrel webrick]
# set :environment, :production
set :bind, '0.0.0.0'

require 'json'
require './Site.rb'
require './KeyManager.rb'

def load_sites
  @@sites = {}
  available_sites = Dir.entries('../Tables/').delete_if {|e| e.start_with? '.'} 
  # Potential override...
  # available_sites = ["Breast","Test"]
  available_sites.each do |site|
    @@sites[site.downcase.to_sym] = Site.new(site)
  end
end

def load_users
  @@key_manager = KeyManager.new
end

load_sites
load_users

# Added a check for valid api key to all calls to the service... 
before do
  error 401, "Key needed..." unless @@key_manager.valid_key? params[:key]
end

post '/tnm' do
  puts params
  puts params[:key]
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
  erb :tool, :locals => { :sites => @@sites.keys }
end

get '/refresh' do
  error 401, "Not admin..." unless @@key_manager.admin_key? params[:key]
  load_sites
  load_users
  "OK - sites reloaded - users reloaded... <br>BTW: Your IP address is: #{request.ip}"
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
