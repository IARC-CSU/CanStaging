# Author: Morten Ervik, ervikm@iarc.fr, CIN/IARC

require './LookUp.rb'
require './Meta.rb'

class Site
  attr_reader :site, :lookups
  
  $TABLES_PATH = '../Tables/'
  $PARTS = ["T", "N", "M", "SG", "SimpG"]

  def initialize site
    @site = site.capitalize
    path = "#{$TABLES_PATH}#{@site}/"
    @lookups = {}
    @metas = {}
    $PARTS.each do |part| 
      @lookups[part] = LookUp.new("#{path}#{@site}_#{part}.txt")
      @metas[part] = Meta.new("#{path}#{@site}_#{part}_Meta.txt")
    end
  end

  def calculate_tnm values
    result = {}
    tnm_result = ""
    tnm_message = nil
    
    # SG might only rely on generated values
    values["SG"] ||= {}
    values["SimpG"] ||= {}
    values["SGrange"] ||= {}
    # first TNM
    conclusive = true
    $PARTS.each do |part|
      unless part == "SG" || part == "SimpG" || part == "SGrange"
        result[part] = values[part].nil? ? [{"Result" => "#{part}X", "Message" => "No data"}] : @lookups[part].look_up(values[part])
        tnm_result += "#{result[part][0]["Result"]}" 
        values["SG"][part] = result[part][0]["Result"]
        if result[part].length>1
          tnm_message = "One of many possible..."
          conclusive = false
        end
      end
    end
    puts values["SG"]
    if $PARTS.include? "SG"
      result["SG"] = values["SG"].nil? ? [{"Result" => "", "Message" => "No data"}] : @lookups["SG"].look_up(values["SG"])
      values["SimpG"]["SG"] = result["SG"][0]["Result"].gsub(/[a-h|A-H]*/,"")
    end
    if $PARTS.include? "SimpG"
      result["SimpG"] = values["SimpG"].nil? ? [{"Result" => "", "Message" => "No data"}] : @lookups["SimpG"].look_up(values["SimpG"])
    end
    # calculate SG range
    result["SGrange"] = calculate_sg_range! result, values["SG"]
    puts result["SGrange"]

    result["TNM"] = [{"Result" => tnm_result, "Message" => tnm_message, "Conclusive" => conclusive}]
    # result["SG"] = [{"Result" => result["SG"][0]["Result"], "Message" => result["SG"][0]["Message"]}] unless result["SG"].nil?
    result
  end

  def calculate_grouped_stage values
    @lookups["SG"].look_up(values)
  end
  
  def get_metas
    @metas
  end

  private
  def calculate_sg_range! tnm_results, sg_values
    range = []
    tnm_results["T"].each do |t| 
      sg_values["T"] = t["Result"]
      tnm_results["N"].each do |n|
        sg_values["N"] = n["Result"]
        tnm_results["M"].each do |m|
          sg_values["M"] = m["Result"]
          range << @lookups["SG"].look_up(sg_values).map {|e| e["Result"].gsub(/[a-h|A-H]*/,"")}
        end
      end
    end
    range = range.flatten
    range.delete("RROR")
    range.delete("UNK")
    puts range
    range = range.uniq.map{|e| e.gsub("IV","IIII")}.sort_by(&:length).map {|e| e.gsub("IIII","IV")}
    range.first == range.last ?  "#{range.first}" : "#{range.first} - #{range.last}"
  end
end