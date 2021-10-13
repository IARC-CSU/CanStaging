require 'csv'
require 'json'
require 'rest-client'
require 'pp'

server      = 'localhost:4567'
api_key     = 'xyz'
tnm_versions = ['v8','v7','Toronto']

DEBUG = true

def all_combinations(a_of_a)
    a_of_a.reduce() { |acc, n| acc.product(n).map(&:flatten) }
end

def parse_ranges(json)
  #{"json_class"=>"Ranges", "data"=>[{"1"=>{"min"=>0.0, "max"=>0.0}, "2"=>{"min"=>0.11, "max"=>0.5}, "3"=>{"min"=>0.51, "max"=>1.0}, "4"=>{"min"=>1.01, "max"=>2.0}, "5"=>{"min"=>0.0, "max"=>0.1}, "6"=>{"min"=>2.01, "max"=>5.0},
  ranges = {}
  json['data'][0].each do |key, range|
    ranges[key] = range
  end 
  ranges
end

def parse_dicts(json)
  dict = {}
  #{"json_class"=>"Dictionary", "data"=>[{"1"=>"No distant metastases", "2"=>"Distant metastases"}]}
  json['data'][0].each do |key, label|
    dict[key] = label
  end 
  dict
end

tnm_versions.each do |tnm_version|

  out_file = File.open("out/#{tnm_version}.txt",'w')

  out_file << "#{tnm_version}\n-----"

  response = RestClient.get("http://#{server}/sites.json?key=#{api_key}&tnm_version=#{tnm_version}", {:content_type => :json, :accept => :json})

  sites = JSON.parse(response)

  # out_file << sites

  number_of_calls = 0

  sites.each do |site|
    out_file << "\nInvestigating: #{site}...\n"
    response = RestClient.get("http://#{server}/meta/#{site}?key=#{api_key}&tnm_version=#{tnm_version}", {:content_type => :json, :accept => :json})

    meta = JSON.parse(response)

    structure = {}

    meta.each do |part, data_part |

      structure[part] = {}

      variables = data_part['data'][0]
      variables.each do |variable|
        id = variable[1]['data'][0]
        structure[part][id] = {}
        structure[part][id][:type] = variable[1]['data'][1]
        structure[part][id][:text] = variable[1]['data'][2]

        combos = []

        if structure[part][id][:type] == 'dictionary'
          dictionary = parse_dicts(variable[1]['data'][5])
          combos = dictionary.keys
        elsif structure[part][id][:type] == 'number'
          ranges = parse_ranges(variable[1]['data'][6])
          combos = ranges.keys
        elsif structure[part][id][:type] == 'boolean'
          combos = ['T','F']
        end
        structure[part][id][:combos] = combos
      end
    end

    # puts structure

    # pp all_combinations(structure["T"].map { |variable, data| data[:combos] })

    parts = structure.keys

    # puts parts

    parts.each do |part|
      out_file << part
      ok = true
      combinations = all_combinations(structure[part].map { |variable, data| data[:combos] })
      if combinations.is_a?(Array)
        combinations.each do |vars|
          jdata = {}
          if vars.is_a?(Array)
            jdata[part] = Hash[structure[part].keys.zip(vars)]
            begin
              # puts jdata
              response = RestClient.post("http://#{server}/tnm?key=#{api_key}&tnm_version=#{tnm_version}", {:data => jdata, :site => site, :tnm_version => tnm_version, :tumour_id => 'X', :auto_id => "off"}, {:content_type => 'application/json', :accept => :json})
              number_of_calls += 1 
              if JSON.parse(response)[part].length != 1
                out_file << "\n#{jdata[part]} => #{JSON.parse(response)[part]}"
                ok = false
              end
              # exit if DEBUG && number_of_calls > 100
            rescue RestClient::Unauthorized => e
              puts e.to_s
              exit
            end
          end
        end
      end
      out_file << " OK!" if ok
      out_file << "\n"
    end
    out_file << "\n"
  end

  out_file << "Number of calls to /tnm: #{number_of_calls}"
  out_file.close

end