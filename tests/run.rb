Dir["#{__dir__}/**/*\_test.rb"].each do |path|
  puts "Loading #{path}"
  require_relative path
end
