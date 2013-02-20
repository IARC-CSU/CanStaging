# Author: Morten Ervik, ervikm@iarc.fr, CIN/IARC

require './LookUp.rb'
require './Meta.rb'

class Site
  attr_reader :site
  
  $TABLES_PATH = '../Tables/'
  $PARTS = ["T", "N", "M", "GS"]

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
    
    $PARTS.each do |part|
      result[part] = values[part].nil? ? [{"Result" => "#{part}X", "Message" => "No data"}] : @lookups[part].look_up(values[part])
      unless part == "GS"
        tnm_result += "#{result[part][0]["Result"]}"
        tnm_message = "One of many possible..." if result[part].length>1 
      end
    end
    
    result["TNM"] = [{"Result" => tnm_result, "Message" => tnm_message}]
    result
  end

  def calculate_grouped_stage values
    @gs_lookup.look_up(values)
  end
  
  def get_metas
    @metas
  end
end