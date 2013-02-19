require '.\Site.rb'

class TestSite < Site
  def initialize
    super("Test")
  end
end

## test
test_site = TestSite.new
test = JSON.generate(test_site.get_metas["T"])
puts JSON.pretty_generate(test_site.get_metas)
test2 = JSON.parse test
puts test2.fields["ChestInvasion"].value_to_codes("true")
# puts JSON.pretty_generate(test_site.get_metas["T"])

size_in_cm = "0.0"
size_code = test_site.get_metas["T"].fields["Size"].value_to_codes(size_in_cm)[0]
true_code = test_site.get_metas["T"].fields["ChestInvasion"].value_to_codes("true")
false_code = test_site.get_metas["T"].fields["ChestInvasion"].value_to_codes("false")
# puts test_site.get_metas["T"].fields["Test"].code_to_value("2")
# puts test_site.get_metas["T"].fields["Test"].value_to_code("else")
values = {"T" => {"Size" => size_code, "ChestInvasion" => "F", "Ulceration" => "F", "Inflammation" =>"F", "Test" => "1"}}
puts (test_site.calculate_tnm(values))["TNM"][0]["Result"]
# puts 
## speed test
# time = Time.now
# 12700.times do           # 12700 lookups per second on my laptop using jruby - not too bad.
# 11555.times do           # 11555 lookups per second on my laptop using ruby - not too bad.
#   test_site.calculate_tnm(values)
# end
# puts Time.now - time