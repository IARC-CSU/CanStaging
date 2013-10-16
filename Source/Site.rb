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
    values["SGrange"] ||= {}
    # first TNM
    conclusive = true
    $PARTS.each do |part|
      unless part == "SG" || part == "SimpG" || part == "SGrange"
        result[part] = values[part].nil? ? [{"Result" => "#{part}X", "Message" => "No data"}] : @lookups[part].look_up(values[part])
        result[part] = keep_unique(result[part])
        tnm_result += "#{result[part][0]["Result"]}" 
        values["SG"][part] = result[part][0]["Result"]
        if result[part].length>1
          tnm_message = "One of many possible..."
          conclusive = false
        end
      end
    end

    if $PARTS.include? "SG"
      result["SG"] = values["SG"].nil? ? [{ "TNM" => tnm_result, "Result" => "", "Message" => "No data"}] : calculate_sgs(result, values["SG"])
    end

    # calculate SG range
    result["SGrange"] = [ { "Result" => calculate_sg_range(result["SG"]) } ]
    puts result["SGrange"]

    if $PARTS.include? "SimpG"
      result["SimpG"] = (result["SG"].nil? || result["SG"][0]["Result"] == "") ? [{"Result" => "", "Message" => "No data"}] : calculate_SimpGs(result["SGrange"][0]["Result"])
    end
    result["TNM"] = [{"Result" => tnm_result, "Message" => tnm_message, "Conclusive" => conclusive, "All results" => result["SG"].map{|e| e["TNM"]}} ]
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

  def keep_unique results
    found = {}
    results.reverse.each do |e| # we reverse it so we keep the first one if duplicates
      found[e["Result"]] = e
    end
    found.values
  end

  def calculate_sgs tnm_results, sg_values
    sg_results = []
      tnm_results["T"].each do |t| 
      sg_values["T"] = t["Result"]
      tnm_results["N"].each do |n|
        sg_values["N"] = n["Result"]
        tnm_results["M"].each do |m|
          sg_values["M"] = m["Result"]
          result = @lookups["SG"].look_up(sg_values)
          result.each { |r| r["TNM"] = "#{t['Result']}#{n['Result']}#{m['Result']}" }
          sg_results << result
        end
      end
    end
    sg_results.flatten
  end

  def calculate_sg_range sg_results
    puts "SG results: #{sg_results}"
    range = sg_results.map {|e| e["Result"].gsub(/[1-9|a-h|A-H]*/,"")}.flatten.map(&:strip)
    range.delete("RROR")
    range.delete("UNK")
    puts "Range: #{range}"
    range = range.uniq.map{|e| e.gsub("IV","IIII")}.sort_by(&:length).map {|e| e.gsub("IIII","IV")}
    range_string = range.first == range.last ?  "#{range.first}" : "#{range.first} - #{range.last}"
    puts "Range string: #{range_string}"
    range_string
  end

  def calculate_SimpGs sg_range
    range = sg_range.split("-").map(&:strip)
    simpg_elements = []
    range.each do |e|
      result = @lookups["SimpG"].look_up({"SG"=>e})
      simpg_elements << result[0]["Result"] unless result[0].nil?
    end
    [{"Result" => simpg_elements.join(" - ")}]
  end
end