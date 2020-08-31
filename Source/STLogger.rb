# Author: Morten Ervik, ervikm@iarc.fr, CSU/IARC

## Logger
require 'sequel'
require 'csv'
require 'fileutils'

class STLogger
  DB_FILE_NAME = './data/logg.db' # overridden by config.yml
  def initialize(db_file_name = DB_FILE_NAME)
    dirname = File.dirname(db_file_name)
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end
    begin
      @db = Sequel.amalgalite(db_file_name)
    rescue Exception => e # Sequel::DatabaseConnectionError
      puts e 
      # Fall back to memory db
      @db = Sequel.amalgalite(":memory:")
    end
    create_tables
    @entries_table = @db[:entries]
    @deleted_entries_table = @db[:deleted_entries]
    @access_log_table = @db[:access_log]
  end

  def log(key, tumour_id, tnm_version, site, input, result, ip_address)
    # puts tumour_id if $DEBUG
    
    # if the user does not specify tumour ID we keep everything
    if (tumour_id == nil || tumour_id.length == 0) 
      move_to_deleted(@entries_table.where(
        :key => key, 
        :tumour_id => tumour_id,
        :ip_address => ip_address)) 
    else
      delete(@entries_table.where(
        :key => key, 
        :tumour_id => tumour_id,
        :ip_address => ip_address))
    end

    @entries_table.insert(
      :key => key,
      :input => input, 
      :result => result, 
      :tumour_id => tumour_id, 
      :ip_address => ip_address,
      :tnm_version => tnm_version,
      :site => site,
      :created_at => DateTime.now)
  end

  def log_access(key, ip_address)
    @access_log_table.insert(
      :key => key,
      :ip_address => ip_address,
      :created_at => DateTime.now)
  end

  def report(key, ip_address, report_all = false)
    query = @entries_table.where(:key =>key, :ip_address => ip_address)
    query = query.exclude(:reported => true) unless report_all
    list = query.all
    query.update(:reported => true)
    list
  end

  def get_csv(key, ip_address, report_all = false)
    list = report(key, ip_address, report_all)
    csv_string = CSV.generate do |csv|
      unless list.length==0
        header = [:site, "TNM version", :tumour_id, :created_at, "T", "N", "M", "TNM", "SG", "SimpG", "SGrange", "SiteSpecific", :input, :result]
        csv << header.map{ |e| e.to_s.gsub("_", "") }
        list.each do |entry|
          result = JSON.parse(entry[:result])
          site_specific =  result["SG"][0].keys - ["Result", "Message", "TNM", "T", "N", "M"]
          puts result if site_specific.length > 0
          entry["T"]   = result["T"][0]["Result"]
          entry["N"]   = result["N"][0]["Result"]
          entry["M"]   = result["M"][0]["Result"]
          entry["TNM"] = result["TNM"][0]["Result"]
          entry["SG"]  = result["SG"][0]["Result"]
          entry["TNM version"] = result["tnm_version"] || "v7"
          entry["SimpG"] = (result["SimpG"] && result["SimpG"][0]) ? result["SimpG"][0]["Result"] : ""
          entry["SGrange"] = (result["SGrange"] && result["SGrange"][0]) ? result["SGrange"][0]["Result"] : ""
          entry["SiteSpecific"] = site_specific.map { |ss| "#{ss}: #{result['SG'][0][ss]}" }.join("; ")
          row = []
          header.each do |column|
            row << entry[column]
          end
          csv << row
        end
      end
    end
    csv_string
  end

  def clear(key, ip_address)
    move_to_deleted @entries_table.where(:key =>key, :ip_address => ip_address)
  end

  def get_next_numeric_id(key, ip_address)
    highest = @entries_table.where(:key =>key, :ip_address => ip_address).all.max_by {|e| e[:tumour_id].to_i}
    highest == nil ? 0 : (highest[:tumour_id].to_i + 1)
  end

  def in_memory?
    @db.opts[:database] == ":memory:"
  end

  private

  def move_to_deleted(query)
    query.all.each do |entry|
      @deleted_entries_table.insert(
        :key => entry[:key], 
        :input => entry[:input],
        :result => entry[:result],
        :site => entry[:site], 
        :tnm_version => entry[:tnm_version],
        :ip_address => entry[:ip_address], 
        :created_at => entry[:created_at])
    end
    delete(query)
  end

  def delete(query)
    query.delete
  end

  def create_tables
    unless @db.tables.include? :entries
      @db.create_table :entries do
        primary_key :id
        String :key
        String :site
        String :tnm_version
        String :tumour_id
        String :input
        String :result
        String :ip_address
        TrueClass :reported, :default => false
        DateTime :created_at
        index :key
        unique [:key, :tumour_id, :ip_address]
      end
      @db.create_table :deleted_entries do
        primary_key :id
        String :key
        String :site
        String :tnm_version
        String :input
        String :result
        String :ip_address
        DateTime :created_at
        index :key
      end
    end
    unless @db.tables.include? :access_log
      @db.create_table :access_log do
        primary_key :id
        String :key
        String :ip_address
        DateTime :created_at
        index :key
      end
    end
  end
end

# STLogger.new