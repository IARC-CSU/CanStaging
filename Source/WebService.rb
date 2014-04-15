# Author: Morten Ervik, ervikm@iarc.fr, CIN/IARC

require 'sinatra'
require 'json'
require './Site.rb'
require './KeyManager.rb'
require './STLogger.rb'
require 'yaml'

config = YAML.load_file("config.yml")

# set :server, %w[thin mongrel webrick]
set :environment, :production if (config['system']['environment'] == 'production')
set :bind, config['system']['bind']
set :port, config['system']['port']

set :sessions, true
set :session_secret, config['system']['session_secret']

def load_sites
  @@sites = {}
  available_sites = Dir.entries('../Tables/').delete_if {|e| e.start_with? '.'}   
  available_sites.delete_if {|s| s.downcase.end_with? "test"} unless settings.environment == :development
  available_sites.each do |site|
    @@sites[site.downcase.to_sym] = Site.new(site)
  end
end

def load_users
  @@key_manager = KeyManager.new
end

@@st_logger = STLogger.new(config['system']['log_file'])

load_sites
load_users

# check for valid api key to all calls to the service... 
before do
  unless request.path_info.start_with? "/login"
    error(401, erb(:login_form, :locals => { :sites => @@sites.keys })) if @@key_manager.get_user(params[:key] || session[:key]).nil?
    session[:key] = params[:key] || session[:key]
  end
end

post '/tnm' do
  # puts params
  result = calculate_tnm(params)
  return JSON.pretty_generate(result)
end

post '/tnm_submit' do 
  result = calculate_tnm(params)
  @@st_logger.log(session[:key], params["tumour_id"], params["site"], params["data"].to_json, result.to_json, request.ip.to_s)
  puts JSON.pretty_generate(result) 
  return JSON.pretty_generate(result)
end

get '/next_numeric_id' do
  number = @@st_logger.get_next_numeric_id(session[:key], request.ip.to_s).to_s
  puts number
  number
end

get '/get_log.json' do
  JSON.pretty_generate(@@st_logger.report(session[:key], request.ip.to_s, true))
end

get '/get_log' do
  erb :log, :locals => {:log => @@st_logger.report(session[:key], request.ip.to_s, true), :sites => @@sites.keys } , :layout => nil
end

get '/get_log.csv' do 
  content_type 'application/csv'
  @@st_logger.get_csv(session[:key], request.ip.to_s, true)
end

get '/clear_log' do
  @@st_logger.clear(session[:key], request.ip.to_s).to_s
end

get '/tool' do 
  erb :tool, :locals => { :sites => @@sites.keys }, :layout => :layout
end

get '/refresh' do
  error 401, "Not admin..." unless @@key_manager.admin_key? session[:key]
  load_sites
  load_users
  erb "<div class='alert alert-message'>OK - sites reloaded - users reloaded... <br>BTW: Your IP address is: #{request.ip}</div>", :locals => { :sites => @@sites.keys }
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

get '/site/*' do |site_name|
  if @@sites[site_name.downcase.to_sym].nil? 
    erb "<div class='alert alert-message'>Sorry no such site: #{site_name}</div>", :locals => { :sites => @@sites.keys }
  else
    erb :site, :locals => {:site => @@sites[site_name.downcase.to_sym], :sites => @@sites.keys }, :layout => :layout
  end
end

get '/login/form' do 
  erb :login_form, :locals => { :sites => @@sites.keys }
end

post '/login/attempt' do
  user = @@key_manager.get_user(params['key'])
  puts user
  puts params['key']
  if !user.nil?
    session[:key] = params['key']
    session[:user] = user
    where_user_came_from = session[:previous_url] || '/tool'
    redirect to where_user_came_from 
  else
    @error = 'Sorry not a valid key '
    halt erb :login_form, :locals => { :sites => @@sites.keys }
  end
end

get '/logout' do
  session.delete(:key)
  erb "<div class='alert alert-message'>Logged out</div>", :locals => { :sites => @@sites.keys }
end

get '/' do
  redirect to('/tool')
end

not_found do
  erb "<div class='alert alert-message'>Nothing to see here...</div>", :locals => { :sites => @@sites.keys }
end

def calculate_tnm params
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
    jdata = params["data"]
    result = site.calculate_tnm(jdata)
    return result
  end
end