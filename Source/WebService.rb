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

$:.unshift File.dirname($0) # Ref: https://github.com/larsch/ocra

require "bundler/setup" # to make sure we load the versions from the gemfile

require 'sinatra/base'
require 'json'
require 'yaml'
require 'sinatra/r18n'
require 'logger'
require 'tilt/erb'
require_relative './Site.rb'
require_relative './KeyManager.rb'
require_relative './STLogger.rb'
## fix before upgrading to newer version of Ruby (2.4+)
unless defined?({}.transform_values)
  require 'backports/2.4.0/hash/transform_values'
end
require 'fileutils'
require 'rdiscount'

# Puma stuff
require 'bundler'
require 'puma'
require "rack/handler/puma"

class CanStaging < Sinatra::Base

  # first load default config

  config_default = {
    'system' => {'log_file' => "./data/logg.db", 'port' => 4567, 'bind' => '0.0.0.0', 'staging_system' => 'v8'}
  }

  config = YAML.load_file("./data/config.yml")

  # if we are running in standalone mode load config from user folder
  if config['system']['standalone']
    puts "Standalone mode"
    # Check if we haven't overridden the config and home dir exist
    config_default['system']['port'] = 9292
    config_default['system']['bind'] = 'localhost'

    if config['system']['log_file'].nil?

      if File.directory?(Dir.home)
        # first create necessary directory
        home_dir = "#{Dir.home}/.canstaging"
        unless File.directory?(home_dir)
          FileUtils.mkdir_p(home_dir)
        end
        config['system']['log_file'] = "#{home_dir}/logg.db"
      else
        puts "Invalid home directory: #{Dir.home} -- defaulting to #{config_default['system']['log_file']}"
        config['system']['log_file'] = config_default['system']['log_file']
      end
    end
  end

  ## Merge config overwriting anything in default config...
  config['system'] = config_default['system'].merge(config['system'])

  puts config if $DEBUG

  set :server, %w[puma thin mongrel webrick]
  set :environment, :production if (config['system']['environment'] != 'development')
  set :bind, config['system']['bind']
  set :port, config['system']['port']

  ENV['RACK_ENV'] = 'production' if (config['system']['environment'] != 'development')

  $DEBUG = (settings.environment == :development)

  set :sessions, true
  set :session_secret, config['system']['session_secret']

  # use Rack::Session::Cookie,
  #         :key => 'CanStaging+',
  #         :same_site => :lax,
  #         :secret => config['system']['session_secret']

  configure :development do
    $logger = Logger.new(STDOUT)
  end

  ## configure the translations
  include R18n::Helpers

  register Sinatra::R18n
  # If we embed public-folder in exe file we need to set the root of the server to the temporary location of the script
  # set :root, File.dirname(__FILE__)
  # Otherwise we set the root to the current dir...
  set :root, File.dirname('.')

  R18n::I18n.default = 'en'
  R18n.default_places { './i18n' }
  R18n.set("en")

  $sites = {}
  $available_staging_systems = []

  ##
  def self.load_sites
    tables_path = "./Tables"
    $available_staging_systems  = Dir.entries(tables_path).select {|entry| File.directory? File.join(tables_path,entry) and !(entry =='.' || entry == '..') }
    $available_staging_systems.sort!
    $available_staging_systems.each do |tnm_version|
      tnm_verision_path = "#{tables_path}/#{tnm_version}"
      $sites[tnm_version] = {}
      available_languages = Dir.entries(tnm_verision_path).select {|entry| File.directory? File.join(tnm_verision_path, entry) and !(entry =='.' || entry == '..') }
      available_languages.each do |language|
        $sites[tnm_version][language] = {}
        language_path    = "#{tnm_verision_path}/#{language}"
        # available_sites = Dir.entries().delete_if {|e| e.start_with?('.') || e.ends_with?('txt')}
        available_sites = Dir.entries(language_path).select {|entry| File.directory? File.join(language_path,entry) and !(entry =='.' || entry == '..') }
        available_sites.each do |site|
          unless Dir.entries("#{tnm_verision_path}/#{language}/#{site}").include?(".skip")
            $sites[tnm_version][language][site.downcase.to_sym] = Site.new(site,language,tnm_version)
            ## Override the tnm version
            if site.downcase == 'colorectal' && tnm_version == 'v7'
              $sites[tnm_version][language][site.downcase.to_sym].tnm_version = 'v5'
            end
          end
        end
        $sites[tnm_version][language].delete_if {|key, elem| elem.default_name.downcase == "test"} unless settings.environment == :development
      end
    end
  end

  $st_logger = STLogger.new(config['system']['log_file'])

  load_sites
  $key_manager = KeyManager.new

  before do
    cache_control :no_cache
    headers \
      "Pragma"   => "no-cache",
      "Expires" => "0"
  end

  ## Routing rules
  before do
    ## load a stored locale or default to english
    session[:locale] = params[:locale] || session[:locale] || "en"
    R18n.set(session[:locale])
    session[:sites_locale] = R18n.t[:sites_locale]
    ## set tnm version
    session[:tnm_version] = params[:tnm_version] || session[:tnm_version] || nil

    unless request.path_info.start_with?("/login") ||
      request.path_info.start_with?("/about") ||
      request.path_info.start_with?("/register") ||
      request.path_info.start_with?("/changelog") ||
      request.path_info.start_with?("/chooser") ||
      request.path_info.start_with?("/feedback") ||
      request.path_info.start_with?("/tnm")
      if session[:tnm_version].nil? || $available_staging_systems.index(session[:tnm_version]).nil?
        # halt and show staging system chooser
        halt erb :chooser, :locals => { :sites => [], :systems => $available_staging_systems , :layout => :layout }
      end
    end
    ## see if URL corresponds to TNM version
    session[:in_memory] = $st_logger.in_memory?
  end

  # check for valid api key to all calls to the service...
  before do
    if request.path_info.start_with?("/get_log")
      error(401, erb(:login_form, :locals => { :sites => $sites[session[:tnm_version]][session[:sites_locale]].values.sort_by {|v| v.site} })) if $key_manager.get_user(params[:key] || session[:key]).nil?
    end
    session[:key] = params[:key] || session[:key] unless $key_manager.get_user(params[:key] || session[:key]).nil?
  end

  post '/tnm' do
    puts params if settings.environment == :development
    result = calculate_tnm(params)
    return JSON.pretty_generate(result)
  end

  post '/tnm_submit' do
    result = calculate_tnm(params)
    $st_logger.log(session[:key], params["tumour_id"], params["tnm_version"], params["site"], params["data"].to_json, result.to_json, request.ip.to_s)
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
    erb :log, :locals => {:log => $st_logger.report(session[:key], request.ip.to_s, true), :sites => $sites[session[:tnm_version]][session[:sites_locale]].values.sort_by {|v| v.site}, :systems => $available_staging_systems} , :layout => nil
  end

  get '/get_log.csv' do
    content_type 'application/csv'
    $st_logger.get_csv(session[:key], request.ip.to_s, true)
  end

  get '/clear_log' do
    $st_logger.clear(session[:key], request.ip.to_s).to_s
  end

  get '/tool' do
    erb :tool, :locals => { :sites => get_sites, :systems => $available_staging_systems}, :layout => :layout
  end

  get '/' do
     erb :tool, :locals => { :sites => get_sites, :systems => $available_staging_systems}, :layout => :layout
  end

  get '/about' do
    erb :about, :locals => { :sites => get_sites, :systems => $available_staging_systems }, :layout => :layout
  end

  get '/changelog' do
    markdown = RDiscount.new(open('./changelog.md').read)
    erb :changelog, :locals => { :text => markdown.to_html, :sites => get_sites, :systems => $available_staging_systems }, :layout => :layout
  end

  get '/refresh' do
    error 401, "Not admin..." unless $key_manager.admin_key? session[:key]
    load_sites
    $key_manager = KeyManager.new
    session[:message] = "OK - sites reloaded - users reloaded... <br>BTW: Your IP address is: #{request.ip}"
    redirect to('/tool')
    # erb "<div class='alert alert-message'>OK - sites reloaded - users reloaded... <br>BTW: Your IP address is: #{request.ip}</div>", :locals => { :sites => $sites[session[:tnm_version]][session[:sites_locale]].values.sort_by {|v| v.site} }
  end

  get '/locale/:locale' do |locale|
    available_locales = R18n.available_locales.map(&:code)
    
    if available_locales.include?(locale.downcase)
      session[:locale] = locale.downcase
    end

    # Redirect back to the page the user came from, with a fallback
    redirect back
  end

  get '/meta/*' do |site_name|
    site = $sites[session[:tnm_version]][session[:sites_locale]][site_name.downcase.to_sym]
    if site.nil?
      response = {"Error"=>"Unknown site: #{site_name}"}.to_json
    else
      response = JSON.pretty_generate(site.get_metas)
    end
    response
  end

  get '/sites.json' do
    get_sites.to_json
  end

  get '/site/*' do |site_name|
    # TODO: Better handling of different staging system in URL
    if $sites[session[:tnm_version]][session[:sites_locale]][site_name.downcase.to_sym].nil?
      # erb "<div class='alert alert-message'>#{t[:service][:no_such_site]}: #{site_name}</div>", :locals => { :sites =>$sites[session[:tnm_version]][session[:sites_locale]].values.sort_by {|v| v.site} }
      session[:error] = "#{t[:service][:no_such_site]}: #{site_name}"
      where_user_came_from = session[:previous_url] || '/tool'
      redirect to where_user_came_from
    else
      erb :site, :locals => {:site => $sites[session[:tnm_version]][session[:sites_locale]][site_name.downcase.to_sym], :sites => $sites[session[:tnm_version]][session[:sites_locale]].values.sort_by {|v| v.site}, :systems => $available_staging_systems }, :layout => :layout
    end
  end

  get '/login/form' do
    erb :login_form, :locals => { :sites => get_sites, :systems => $available_staging_systems  }
  end

  get '/register' do
    erb :registration, :locals => { :sites => get_sites, :systems => $available_staging_systems  }
  end

  get '/feedback' do
    erb :feedback, :locals => { :sites => get_sites, :systems => $available_staging_systems  }
  end

  post '/login/attempt' do
    user = $key_manager.get_user(params['key'])
    if !user.nil?
      session[:key] = params['key']
      session[:user] = user
      session[:local] = (request.ip.to_s == "127.0.0.1")
      $st_logger.log_access(session[:key], request.ip.to_s)
      where_user_came_from = session[:previous_url] || '/tool'
      session[:message] = R18n.t.service.logged_in
      redirect to where_user_came_from
    else
      session[:error] = 'Sorry not a valid key '
      halt erb :login_form, :locals => { :sites => get_sites, :systems => $available_staging_systems  }
    end
  end

  get '/logout' do
    session.delete(:key)
    session[:message] = R18n.t.service.logged_out
    redirect to('/tool')
  end

  get '/shutdown' do
    if config['system']['standalone'] && session[:local]
      exit!
    else
      session[:error] = R18n.t.service.invalid_url
      redirect to('/tool')
    end
  end

  get '/chooser' do
    sites = []
    session[:tnm_version] = nil
    erb :chooser, :locals => { :sites => sites, :systems => $available_staging_systems , :layout => :layout }
  end

  get "/upload" do
    erb :upload, :locals => { :sites => get_sites, :systems => $available_staging_systems }, :layout => :layout
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
    erb "<div class='alert alert-message'>#{R18n.t[:service][:not_found]}</div>", :locals => { :sites => $sites[session[:tnm_version]][session[:sites_locale]].values.sort_by {|v| v.site}, :systems => $available_staging_systems }
  end

  ## Helper functions

  def calculate_tnm params
    site_name = params["site"].downcase.strip.to_sym unless params["site"].nil?

    # TNM Version is pulled from the parameters or the session if unavailable
    tnm_version = params["tnm_version"].nil? ? session[:tnm_version] : params["tnm_version"]

    # Override for Colorectal TNM
    tnm_version = 'v7' if tnm_version == 'v5'

    site = $sites[tnm_version][session[:sites_locale]][site_name] unless !$sites[tnm_version][session[:sites_locale]].keys.include?(site_name)
    if site.nil?
      return {"Error"=> R18n.t.service.unknown_site(params["site"])}.to_json
    else
      site.get_metas.each do |part, meta|
        meta.fields.keys.each do |key|
          unless params["data"][part].nil?
            if params["data"][part].include?("#{key}-number")
              number = params["data"][part].delete "#{key}-number" # remove the temporary variables
              params["data"][part][key] = meta.fields[key].value_to_codes(number).first
            end
          end
        end
      end
      jdata = params["data"]
      result = site.calculate_tnm(jdata)
      result["tnm_version"] = session[:tnm_version]
      return result
    end
  end

  def parse(filename, session, ip, col_sep=",", quote_char='"')
    number_ok     = 0
    number_failed = 0
    CSV.foreach(filename, {col_sep: col_sep, quote_char: quote_char, headers: true}) do |row|
      params = {}
      params["site"] = row["site"] || row["Site"]
      params["tnm_version"] = row["TNM version"] || row["TNM Version"]
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
          tnm_version = params["tnm_version"].nil? ? session[:tnm_version] : params["tnm_version"]
          $st_logger.log(session[:key], params["tumour_id"], tnm_version, params["site"], params["data"].to_json, result.to_json, request.ip.to_s)
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
      part, variable_name = column.split("_", 2)
      data[part][variable_name] = value unless variable_name.nil?
    end
    data
  end

  def data_to_row data
    row = {}
    data.each do |part, list|
      list.each do |variable, value|
        row["#{part}_#{variable}"] = value
      end
    end
    row
  end

  def get_sites
    sites = $sites[session[:tnm_version]].nil? || $sites[session[:tnm_version]][session[:sites_locale]].nil? ? {} : $sites[session[:tnm_version]][session[:sites_locale]]
    sites.values.sort_by {|v| v.site }
  end

end

# If we are building the exe, we don't start the Sinatra app...

if defined?(Ocra) or defined?(Aibika)
  exit
end

# start the server if ruby file executed directly

run CanStaging.run! if __FILE__ == $0

