if File.basename(Dir.pwd) != 'coding_game'
  raise "Please run this in top folder (coding_game)"
end

puts `ruby tests/run.rb`

MERGED_FILES = []

def merge_file!(merged_file, file_abs_path)
  if !MERGED_FILES.include?(file_abs_path)
    current_abs_folder = File.dirname(file_abs_path)
    MERGED_FILES << file_abs_path
    text = File.open(file_abs_path, 'r').read
    text.each_line do |line|
      manage_line(merged_file, current_abs_folder, line)
    end
  else
    puts "SKIP : #{file_abs_path} (already merged)"
  end
end

def manage_line(merged_file, current_abs_folder, line)
  if matches = /require_relative\s+('|")(.*)('|")/.match(line)
    required_file = matches[2].gsub(/\.rb$/, "")
    file_to_merge_path = File.expand_path("#{current_abs_folder}/#{required_file}.rb")
    merge_file!(merged_file, file_to_merge_path)
  elsif matches = /^\s*#(.*)/.match(line)
    puts "SKIP : This is a comment line : #{line}"
  else
    merged_file << line
  end
end

origin_file_path = File.expand_path("#{Dir.pwd}/main.rb")
merged_file_path = 'main.cg.rb'

File.delete(merged_file_path) if File.exist?(merged_file_path)
File.open(merged_file_path,'a') do |merged_file|
  merge_file!(merged_file, origin_file_path)
end

puts "The following files :"
puts "#{MERGED_FILES.map { |f| " -> #{f.to_s}"}.join("\n") }"
puts "Have been merged into : #{merged_file_path}"
puts "Checking syntax : " + `ruby -c #{merged_file_path}`
