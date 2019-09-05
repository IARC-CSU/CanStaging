# encoding: UTF-8
# Author: Morten Ervik, ervikm@iarc.fr, CSU/IARC

require './LookUp.rb'
require './Meta.rb'

class Site
  attr_reader :site, :lookups, :default_name, :prefixes, :metas
  
  $PARTS = ["T", "N", "M", "SG", "SimpG"]
  TABLES_ROOT_PATH = "./Tables"

  def initialize site, language, tnm_version
    puts "Loading: #{site}, #{language}, #{tnm_version}"
    @default_name = site
    translated_name = site   
    @default_language = "en"
    @css = @default_name.split("_").first.downcase  
    tnm_version_root_path = "#{TABLES_ROOT_PATH}/#{tnm_version}"
    puts tnm_version_root_path
    default_language_root_path = "#{tnm_version_root_path}/#{@default_language}"
    language_root_path = "#{tnm_version_root_path}/#{language}"
    site_root_path = "#{language_root_path}/#{site}" 
    if File.exist?("#{site_root_path}/default.yml")
      yaml = YAML.load_file("#{site_root_path}/default.yml")
      @default_name = yaml["default_name"] || @default_name
      translated_name = yaml["translated_name"] || translated_name 
      @default_language = yaml["default_language"] || @default_language
      @default_site_root_path = "#{default_language_root_path}/#{@default_name}" 
      @css = yaml["css"] || @default_name      
    end
    @site = translated_name.capitalize
    @lookups = {}
    @metas = {}
    @prefixes = {}
    $PARTS.each do |part| 
      # Load up definitions
      if File.exist? "#{site_root_path}/#{@default_name}_#{part}.txt"
        @lookups[part] = LookUp.new("#{site_root_path}/#{@default_name}_#{part}.txt")
      else
        @lookups[part] = LookUp.new("#{@default_site_root_path}/#{@default_name}_#{part}.txt")
      end    
      # Load up metas
      if File.exist? "#{site_root_path}/#{@default_name}_#{part}_Meta.txt"
        @metas[part] = Meta.new("#{site_root_path}/#{@default_name}_#{part}_Meta.txt")
      else
        @metas[part] = Meta.new("#{@default_site_root_path}/#{@default_name}_#{part}_Meta.txt")
      end
      # Add prefixes to the meta if needed
      unless part == "SG" || part == "SimpG" || part == "SGrange"
        unless @metas[part].fields.keys.include?("Pathologic") && @metas[part].fields.keys.include?("Posttherapy")
          if File.exist? "#{language_root_path}/Prefixes_Meta.txt"
            to_add = Meta.new("#{language_root_path}/Prefixes_Meta.txt")
          elsif File.exist? "#{default_language_root_path}/Prefixes_Meta.txt"
            to_add = Meta.new("#{default_language_root_path}/Prefixes_Meta.txt")
          end
          to_add.fields.values.each {|variable| @metas[part].add_field variable } unless to_add.nil?
        end
        # Load up prefixes
        if File.exist? "#{site_root_path}/#{@default_name}_#{part}_prefix.txt"
          @prefixes[part] = LookUp.new("#{site_root_path}/#{@default_name}_#{part}_prefixes.txt")
        else
          @prefixes[part] = LookUp.new("#{tnm_version_root_path}/default_prefixes.txt")
        end
      end
    end
  end

  def css
    @css.downcase
  end

  def calculate_tnm values
    result = {}
    tnm_result = ""
    tnm_with_prefixes_result = ""
    tnm_message = nil
    
    # SG might only rely on generated values
    values["SG"] ||= {}
    values["SGrange"] ||= {}
    
    # puts values

    conclusive = true
    error = false
    tnm_message_parts = []
    $PARTS.each do |part|
      unless part == "SG" || part == "SimpG" || part == "SGrange"
        result[part] = values[part].nil? || values[part].empty? ? [{"Result" => "#{part}X", "Message" => R18n.t[:site][:no_data]}] : @lookups[part].look_up(values[part])
        result[part] = keep_unique(result[part])
        values["SG"][part] = result[part][0]["Result"]
        if result[part][0]["Result"] == "ERROR"
          error = true
          result[part] = [{"Result"=> "ERROR", "Message" => R18n.t[:site][:no_possible_combination] }]
          tnm_message_parts << R18n.t.site.no_such_combination(part)
        elsif result[part].length>1
          tnm_result += "#{get_default_result(part)}" 
          tnm_message_parts << R18n.t.site.one_of_many_possible(part)
          result[part] = [{"Result"=> get_default_result(part), "Message" => R18n.t[:site][:many_possible] }] + result[part]
          conclusive = false
        else
          tnm_result += "#{result[part][0]["Result"]}"          
        end
        prefix = @prefixes[part].look_up(values[part])
        tnm_with_prefixes_result += prefix[0]["Result"] + "#{result[part][0]["Result"]}" unless prefix.nil? || prefix.length == 0
      end
    end
    
    # puts $PARTS 
    
    tnm_message = tnm_message_parts.join(" ")
    if $PARTS.include? "SG"
      result["SG"] = values["SG"].nil? ? [{ "TNM" => tnm_result, "Result" => "", "Message" => R18n.t[:site][:no_data]}] : calculate_sgs(result, values["SG"])
      result["TNM"] = [{"Result" => result["SG"].first["TNM"], "Message" => tnm_message, "Conclusive" => conclusive, "All results" => result["SG"].map{|e| e["TNM"]}.uniq } ] 
      result["TNMwP"] = [{"Result" => tnm_with_prefixes_result, "Message" => "", "Conclusive" => conclusive, "All results" => "" } ] 
      error = error || !(result["SG"].find{|e| e["Result"] == "ERROR"}.nil?)
    end    

    if error
       result["SG"] = [{ "TNM" => "ERROR", "Result" => "", "Message" => R18n.t[:site][:no_data]}]
       result["SGrange"] = [ { "Result" => get_default_result("SGrange")} ]
       result["SimpG"] = [ { "Result" => get_default_result("SimpG")} ]
    else
      if $PARTS.include? "SG" && !result["SG"].nil? && result["SG"].length > 0
        result["TNM"] = [{"Result" => result["SG"].first["TNM"], "Message" => tnm_message, "Conclusive" => conclusive, "All results" => result["SG"].map{|e| e["TNM"]}.uniq } ] 
      end
      # puts result["TNM"][0]["Result"]
      # calculate SG range
      range = result["TNM"][0]["Result"] == "TXNXM0" ? [ { "Result" =>  "" } ] : calculate_sg_range(result["SG"])
      # puts range

      result["SGrange"] = [ { "Result" =>  generate_sg_range_string(range)} ]
      # puts result["SGrange"]

      if $PARTS.include? "SimpG"
        result["SimpG"] = (result["SG"].nil? || result["SG"][0]["Result"] == "" || result["TNM"][0]["Result"] == "TXNXM0" ) ? [{"Result" => "", "Message" => R18n.t[:site][:no_data]}] : calculate_SimpGs(range)
      end
      # result["SG"] = [{"Result" => result["SG"][0]["Result"], "Message" => result["SG"][0]["Message"]}] unless result["SG"].nil?
    end
    # puts result
    result
  end
  
  def get_metas
    @metas
  end

  private

  def get_default_result(part)
    text = ""
    if(part == "T")
      text = "TX"
    elsif (part == "N")
      text = "NX"
    elsif (part == "M")
      text = "M0"
    end
    text
  end

  def keep_unique results
    found = {}
    results.reverse.each do |e| # we reverse it so we keep the first one if duplicates
      found[e["Result"]] = e
    end
    found.values
  end

  def calculate_sgs tnm_results, sg_values
    sg_results = []
    # tnm_results = simplify_TNMs tnm_results
    tnm_results["T"].each do |t| 
      sg_values["T"] = t["Result"]
      sg_values.delete("T") if t["Result"] == "TX"
      tnm_results["N"].each do |n|
        sg_values["N"] = n["Result"]
        sg_values.delete("N") if n["Result"] == "NX"
        tnm_results["M"].each do |m|
          sg_values["M"] = m["Result"]
          sg_values.delete("M") if t["Result"] == "MX"
          result = @lookups["SG"].look_up(sg_values)
          result.each do |r| 
            r["TNM"] = "#{t['Result']}#{n['Result']}#{m['Result']}" 
            r["T"] = "#{t['Result']}"
            r["N"] = "#{n['Result']}"
            r["M"] = "#{m['Result']}"
          end
          sg_results << result
        end
      end
    end
    sg_results.flatten.sort_by {|result| -count_chars(result["TNM"], "X")}
  end

  def calculate_sg_range sg_results
    # puts "SG results: #{sg_results}"
    # range = sg_results.map {|e| e["Result"] = e["Result"].strip.gsub(/[1-9|a-h|A-H]$/,""); e}.flatten
    # puts "Range: #{range}"
    range = sg_results.sort_by {|e| e["Result"]}
    range.first["Result"] == range.last["Result"] ? [range.first] : [range.first, range.last]  
  end

  def calculate_prefix 

  end

  def generate_sg_range_string range
    r = range.map{|e| e["Result"]}
    r = ["OCCULT"] if r.include? "OCCULT"
    r.join(" - ")
  end

  def calculate_SimpGs range
    simpg_elements = []
    range.each do |e|
      result = @lookups["SimpG"].look_up({"SG"=>e["Result"], "T"=>e["T"], "N"=>e["N"], "M"=>e["M"]})
      simpg_elements << result[0]["Result"] unless result[0].nil? || result[0]["Result"] == "ERROR"
    end
    simpg_elements = simpg_elements.first == simpg_elements.last ? [simpg_elements.first] : simpg_elements
    [{"Result" => simpg_elements.join(" - ")}]
  end

  private
  def count_chars string, char = "X"
    string.each_char.to_a.inject(0) {|r, c| c==char ? r+1 : r }
  end

end