# Author: Morten Ervik, ervikm@iarc.fr, CIN/IARC

require 'sinatra'
require 'json'
require './Site.rb'
require './KeyManager.rb'
require './STLogger.rb'
require 'yaml'
require 'sinatra/r18n'
require 'logger'
require 'tilt/erb'

config = YAML.load_file("config.yml")

# set :server, %w[thin mongrel webrick]
set :environment, :production if (config['system']['environment'] == 'production')
set :bind, config['system']['bind']
set :port, config['system']['port']

set :sessions, true
set :session_secret, config['system']['session_secret']

configure :development do
  $logger = Logger.new(STDOUT)
end

## configure the translations
include R18n::Helpers

register Sinatra::R18n
set :root, File.dirname(__FILE__)

R18n::I18n.default = 'en'
R18n.default_places { './i18n' }
R18n.set("en")

$sites = {}

##
def load_sites
  available_languages = Dir.entries('../Tables/').delete_if {|e| e.start_with? '.'}
  available_languages.each do |language|
    $sites[language] = {}
    available_sites = Dir.entries("../Tables/#{language}").delete_if {|e| e.start_with? '.'}   
    available_sites.each do |site|
      $sites[language][site.downcase.to_sym] = Site.new(site,language)
    end
    $sites[language].delete_if {|key, elem| elem.default_name.downcase == "test"} unless settings.environment == :development
  end  
end

$st_logger = STLogger.new(config['system']['log_file'])

load_sites
$key_manager = KeyManager.new

## Routing rules

## load a stored locale or default to english
before do
  session[:locale] = params[:locale] || session[:locale] || "en"
  R18n.set(session[:locale])
  session[:sites_locale] = R18n.t[:sites_locale]
end

# check for valid api key to all calls to the service... 
before do
  unless request.path_info.start_with? "/login"
    error(401, erb(:login_form, :locals => { :sites => $sites[session[:sites_locale]].values })) if $key_manager.get_user(params[:key] || session[:key]).nil?
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
  $st_logger.log(session[:key], params["tumour_id"], params["site"], params["data"].to_json, result.to_json, request.ip.to_s)
  # puts JSON.pretty_generate(result) if settings.environment == :development
  return JSON.pretty_generate(result)
end

get '/next_numeric_id' do
  number = $st_logger.get_next_numeric_id(session[:key], request.ip.to_s).to_s
  number
end

get '/get_log.json' do
  JSON.pretty_generate($st_logger.report(session[:key], request.ip.to_s, true))
end

get '/get_log' do
  erb :log, :locals => {:log => $st_logger.report(session[:key], request.ip.to_s, true), :sites => $sites[session[:sites_locale]].values } , :layout => nil
end

get '/get_log.csv' do 
  content_type 'application/csv'
  $st_logger.get_csv(session[:key], request.ip.to_s, true)
end

get '/clear_log' do
  $st_logger.clear(session[:key], request.ip.to_s).to_s
end

get '/tool' do 
  erb :tool, :locals => { :sites => $sites[session[:sites_locale]].values }, :layout => :layout
end

get '/refresh' do
  error 401, "Not admin..." unless $key_manager.admin_key? session[:key]
  load_sites
  $key_manager = KeyManager.new
  erb "<div class='alert alert-message'>OK - sites reloaded - users reloaded... <br>BTW: Your IP address is: #{request.ip}</div>", :locals => { :sites => $sites[session[:sites_locale]].values }
end

get '/locale/*' do |locale|
  session[:locale] = locale.downcase
  R18n.set(session[:locale])
  # session[:message] = "#{R18n.t[:service][:locale_changed_to]} #{r18n.locale.title}." # +"(#{t[:service][:available]}: #{r18n.available_locales.map { |i| "#{i.title} (#{i.code})" }.join(', ')})"
  where_user_came_from = session[:previous_url] || '/tool'
  redirect to where_user_came_from 
end

get '/meta/*' do |site_name|
  site = $sites[session[:sites_locale]][site_name.downcase.to_sym]
  if site.nil?
    response = {"Error"=>"Unknown site: #{site_name}"}.to_json
  else
    response = JSON.pretty_generate(site.get_metas)
  end
  response
end

get '/sites.json' do
  $sites[session[:sites_locale]].keys.to_json
end

get '/site/*' do |site_name|
  if $sites[session[:sites_locale]][site_name.downcase.to_sym].nil? 
    erb "<div class='alert alert-message'>#{t[:service][:no_such_site]}: #{site_name}</div>", :locals => { :sites =>$sites[session[:sites_locale]].values }
  else
    erb :site, :locals => {:site => $sites[session[:sites_locale]][site_name.downcase.to_sym], :sites => $sites[session[:sites_locale]].values }, :layout => :layout
  end
end

get '/login/form' do 
  erb :login_form, :locals => { :sites => $sites[session[:sites_locale]].values }
end

post '/login/attempt' do
  user = $key_manager.get_user(params['key'])
  if !user.nil?
    session[:key] = params['key']
    session[:user] = user
    $st_logger.log_access(session[:key], request.ip.to_s)
    where_user_came_from = session[:previous_url] || '/tool'
    redirect to where_user_came_from 
  else
    @error = 'Sorry not a valid key '
    halt erb :login_form, :locals => { :sites => $sites[session[:sites_locale]].values }
  end
end

get '/logout' do
  session.delete(:key)
  erb "<div class='alert alert-message'>#{R18n.t.service.logged_out}</div>", :locals => { :sites => $sites[session[:sites_locale]].values }
end

get '/' do
  redirect to('/tool')
end

get "/upload" do 
  erb :upload, :locals => { :sites => $sites[session[:sites_locale]].values }, :layout => :layout
end

post '/upload' do
  params['col_sep'] = params['col_sep'] || ","
  params['col_sep'] = "\t" if params['col_sep'] == "tab"
  params['quote_char'] = params['quote_char'] || "\""
  begin
    numbers = parse(params['myfile'][:tempfile], session, request.ip.to_s, params['col_sep'] , params['quote_char'])
    if numbers[:ok] > 0 && numbers[:failed] == 0
      session[:message] = R18n.t.service.uploaded_successfully_n(numbers[:ok])
    elsif numbers[:ok] > 0 && numbers[:failed] > 0
      session[:message] = "#{R18n.t.service.uploaded_successfully_n(numbers[:ok])}. \n#{R18n.t.service.failed_to_import_n(numbers[:ok])}"
    else
      session[:error] = R18n.t[:service][:upload_failed_no_records]
    end
  rescue Exception => e
    session[:error] = R18n.t[:service][:upload_failed]
    session[:error] += "\n#{e}" if settings.environment == :development
  end
  redirect to('/upload')
end

not_found do
  erb "<div class='alert alert-message'>#{R18n.t[:service][:not_found]}</div>", :locals => { :sites => $sites[session[:sites_locale]].values }
end


## Helper functions

def calculate_tnm params
  site_name = params["site"].downcase.strip.to_sym unless params["site"].nil?
  site = $sites[session[:sites_locale]][site_name] unless !$sites[session[:sites_locale]].keys.include?(site_name)
  if site.nil?
    return {"Error"=> R18n.t.service.unknown_site(params["site"])}.to_json
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

def parse(filename, session, ip, col_sep=",", quote_char='"')
  number_ok     = 0
  number_failed = 0
  CSV.foreach(filename, {col_sep: col_sep, quote_char: quote_char, headers: true}) do |row|
    params = {}
    params["site"] = row["site"] || row["Site"]
    if row.headers.include? "input"
      params["data"] = JSON.parse(row["input"])
    else
      params["data"] = row_to_data(row)
    end
    # puts params if settings.environment == :development
    if params["site"] # we really need to know the site...
      result = calculate_tnm(params)
      # puts result if settings.environment == :development
      if result["Error"] == nil
        params["tumour_id"] = (row["tumourid"].nil? || row["tumourid"].length == 0) ? $st_logger.get_next_numeric_id(session[:key], ip).to_s : row["tumourid"]
        $st_logger.log(session[:key], params["tumour_id"], params["site"], params["data"].to_json, result.to_json, request.ip.to_s)  
        number_ok += 1
      else
        number_failed += 1
      end
    end
  end
  {ok: number_ok, failed: number_failed}
end

def row_to_data row
  data = Hash.new { |hash, key| hash[key] = {} }
  row.each do |column, value|
    part, variable_name = column.split(" ", 2)
    data[part][variable_name] = value unless variable_name.nil?
  end
  data
end

def data_to_row data
  row = {}
  data.each do |part, list| 
    list.each do |variable, value| 
      row["#{part} #{variable}"] = value  
    end 
  end
  row
end