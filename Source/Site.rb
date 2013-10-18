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
        result[part] = values[part].nil? || values[part].empty? ? [{"Result" => "#{part}X", "Message" => "No data"}] : @lookups[part].look_up(values[part])
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
    range = calculate_sg_range(result["SG"])
    # puts range

    result["SGrange"] = [ { "Result" => generate_sg_range_string(range)} ]
    # puts result["SGrange"]

    if $PARTS.include? "SimpG"
      result["SimpG"] = (result["SG"].nil? || result["SG"][0]["Result"] == "") ? [{"Result" => "", "Message" => "No data"}] : calculate_SimpGs(range)
    end
    result["TNM"] = [{"Result" => tnm_result, "Message" => tnm_message, "Conclusive" => conclusive, "All results" => result["SG"].map{|e| e["TNM"]}.uniq } ]
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
    sg_results.flatten
  end

  def calculate_sg_range sg_results
    # puts "SG results: #{sg_results}"
    # range = sg_results.map {|e| e["Result"] = e["Result"].strip.gsub(/[1-9|a-h|A-H]$/,""); e}.flatten
    # puts "Range: #{range}"
    range = sg_results.sort_by {|e| e["Result"]}
    range.first["Result"] == range.last["Result"] ?  [range.first] : [range.first, range.last]  
  end

  def generate_sg_range_string range
    range.map{|e| e["Result"]}.join(" - ")
  end

  def calculate_SimpGs range
    simpg_elements = []
    range.each do |e|
      result = @lookups["SimpG"].look_up({"SG"=>e["Result"], "T"=>e["T"], "N"=>e["N"], "M"=>e["M"]})
      simpg_elements << result[0]["Result"] unless result[0].nil?
    end
    simpg_elements = simpg_elements.first == simpg_elements.last ? [simpg_elements.first] : simpg_elements
    [{"Result" => simpg_elements.join(" - ")}]
  end
end