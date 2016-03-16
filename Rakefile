require 'rake'

$source = "imdb"
$target = "json"

# we have both .html and .html.gz files
SOURCE_FILES = Rake::FileList.new("#{$source}/*.html", "#{$source}/*.gz") do |fl|
end

task :default => :json
#task :html => source_files.ext(".html")
# we need to remove the .html from the gz files
task :json   => SOURCE_FILES.pathmap("%{^#{$source}/,#{$target}/}X.json").pathmap("%{.html,}p")

#rule ".json" => ".html" do |t|
rule ".json" => ->(f){source_for_json(f)} do |t|
  sh "./generateJson.sh #{t.source}"
  #puts "#{t.source}"
end

def source_for_json(json_file)
  # detect terates through each entry and takes 19 seconds on the 1400 files.
  # # include? takes only 0.3 seconds for 1400 files
    #SOURCE_FILES.detect{|f| 
      ## we need to remove the .html from the gz files
          #f.ext('').sub(".html","") == json_file.pathmap("%{^#{$target}/,#{$source}/}X") 
            #}
  #SOURCE_FILES.include? f.sub(/\.gz$/,"").sub(/\.html$/,"")
  f = json_file.pathmap("%{^#{$target}/,#{$source}/}X") 
  return "#{f}.html" if SOURCE_FILES.include? "#{f}.html"
  return "#{f}.html.gz" if SOURCE_FILES.include? "#{f}.html.gz"
  #return f.ext('html') + ".gz" if SOURCE_FILES.include? f.ext('html')+".gz"
end
