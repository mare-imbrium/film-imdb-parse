#!/usr/bin/env ruby -w
# ----------------------------------------------------------------------------- #
#         File: parseimdb.rb
#  Description: parses given html file (imdb.com/title/tt....) and saves in yaml or json file given
#      ./parseimdb.rb imdb/tt0032976.html yml/tt0032976.yml
#       Author:  r kumar
#         Date: 2016-03-13 
#  Last update: 2016-03-16 14:59
#      License: MIT License
# ----------------------------------------------------------------------------- #
# NOTE: some files have Directors and Writers others singular.

require 'nokogiri'
require 'pp'
require "yaml"
require 'json'
require 'color'


# Add only these from the creds
$keys = [ "Directors", "Director","Stars",  "Star", "Writers", "Writer", "Country", "Language", "Release_Date",
          "Runtime","Production_Co","Budget","Gross", "Filming_Locations" ]


# ----------------------------------------------------------------------------------------- #
# rename these fields to the values given to keep consistent with our other imdb database
$renamed = { "Release_Date"      => "Released", 
             "Filming_Locations" => "Location",
             "Stars"             => "Actors",
             "Star"              => "Actors",
             "Directors"         => "Director",
             "Writers"           => "Writer"
}

# delete these since they don't contain anything meaningful
$deleted = %W[ Official_Sites Parents_Guide Motion_Picture_Rating_(MPAA) ]


# remove newlines and extra spaces and other unneeded stuff like see more.
def clean(str)
  s =  str.gsub("\n"," ").tr_s(" ", " ").strip
  if s.index("See more »")
    s = s.gsub("See more »","")
  end
  return s
end

# --------------- check --------------------------------------#
# checks the hash for blank entries and reports
# ----------------------------------------------------------- #
# the following keys must exist in the hash or else we report errors
#$keys_imp = %W[ Director Stars Release_Date Runtime Title Year imdbID ]
$keys_imp = %W[ Director Actors Released Runtime Title Year imdbID Language Country Genre imdbRating imdbVotes ]
def check_hash hash
  return if $opt_quiet
  $keys_imp.each do |e|
    if hash[e].nil?
      $stderr.puts color("   WARNING: check() #{e} is null", "yellow", "reverse")
    else
      $stderr.puts color("   GOOD: check() #{e} is #{hash[e]}", "green", "bold") if $opt_debug
    end
  end
  hash.each_pair { |k, v| 
    if v.nil?
      if $keys_imp.include? k
        $stderr.puts color("   WARNING: check() #{k} is null", "yellow", "reverse")
      else
        $stderr.puts color("   WARNING: check() #{k} is null", "red", "bold")
      end
    end
    #puts "Key: #{k}, Value: #{v}" 
  }
end

def _process creds, hash
  creds.each_with_index do |e, ix|
    k = e.css("h4").text.strip.sub(":","")
    # Motion Picture Rating has a newline and lots of spaces
    k = k.gsub("\n"," ").gsub(" ","_").tr_s("_","_")
    if $keys.include?(k) || $opt_all
      e.css("h4").remove
      hash[k] = clean(e.text)
      #puts "#{ix}: #{k} :" + clean(e.text) if $opt_verbose
    else
      if $opt_debug
        puts "NOT ADDED #{ix}: " + e.text.gsub("\n"," ").strip.tr_s(" "," ")
      end
    end
  end
  return hash
end
def parseimdb filename
  hash = {}


  page = Nokogiri::HTML(open(filename));
  return unless page
  id = File.basename(filename,File.extname(filename))
  hash["imdbID"] = id
  title = page.css("h1").text.strip
  #puts "h1= #{title} "
  title = title.gsub("\n"," ")
  match = title.match(/^(.*).\((\d\d\d\d)\)$/)
  if match
    hash["Title"] = match.captures.first.strip
    hash["Year"] = match.captures[1].strip
    unless $opt_quiet
      puts "==> title: " + hash["Title"] + " Year: " + hash["Year"]
    end
  end
  $oldformat = false
  creds = page.css("div.credit_summary_item")

  if creds.size != 0
    hash = _process creds, hash
  end
  creds = page.css("div.txt-block")
  hash = _process creds, hash

  lang = hash["Language"]
  if lang
    hash["Language"] = lang.gsub(" | ", ", ")
  end
  s = hash["Stars"] || hash["Star"]
  if s.index("| See full cast & crew »")
    s = s.sub("| See full cast & crew »","")
    hash["Stars"] = s
  end

  # old pages from 2013 don't have this.
  if creds.size == 0
    $oldformat = true
  end
  # This is cast 
  actarr = []
  actors = page.css("td.itemprop")
  actors.each_with_index do |e,ix|
    actarr << clean(e.text)
    #puts "#{ix}: " + clean( e.text ) if $opt_verbose
  end
  hash["Cast"] = actarr.join(", ")

  # storyline is plot
  desc = page.css("div[itemprop='description']")
  hash["Plot"] = clean(desc.text)

  genres = []
  xgenres = page.css("span[itemprop='genre']")
  xgenres.each_with_index {|e,i| genres << e.text }
  hash["Genre"] = genres.join(", ")

  keyw = []
  x = page.css("span[itemprop='keywords']")
  x.each_with_index {|e,i| keyw << e.text }
  hash["Keywords"] = keyw.join(", ")

  hash["imdbRating"] = page.css("span[itemprop='ratingValue']").text
  hash["imdbVotes"] = page.css("span[itemprop='ratingCount']").text

  hash["Awards"] = clean( page.css("span[itemprop='awards']").text )

  # get metascore
  metascore = page.css("div.metacriticScore")
  m = nil
  if metascore
    m = metascore.css("span").text.strip
  end
  hash["Metascore"] = (m || "N/A")

  # fix directors and writers
  #s =  hash.delete("Directors")
  #hash["Director"] = s if s
  #s =  hash.delete("Writers")
  #hash["Writer"] = s if s

  $renamed.each_pair do |k, v|
    s =  hash.delete(k)
    hash[v] = s if s
  end

  # Some films like The Help do not have Runtime
  # this gives something like PT146M for 146 minutes
  s = page.css("time").attribute("datetime").text
  # this gives something like "2h 26m"
  # However, if they do have runtime then it gives both, TODO take only the first one.
  s1 = clean(page.css("time").first().text)
  hash["Running_time"] = "#{s} / #{s1}"
  description = page.css("meta[name='description']")[0]["content"] rescue nil
  hash["Description"] = description
  # Not always there
  contentRating = page.css("meta[itemprop='contentRating']")[0]["content"] rescue "N/A"
  #contentRating = page.css("meta[itemprop='contentRating']") 
  #if contentRating 
    #contentRating = contentRating[0]["content"]
  #end
  hash["Rated"] = contentRating

  %W[ Country Language ].each do |e|
    if hash[e]
      hash[e] = hash[e].gsub(" | ", ", ")
    end
  end

  $deleted.each do |d|
    hash.delete(d)
  end
  # one blank entry coming through
  hash.delete("")
  return hash
end

# ------------------------- writehash ------------------------------------ #
# write hash to a file depending on extension of file. Does yaml or json.
# hash.to_yaml should also work
def writehash hash, filename
  if File.extname(filename) == ".yml"
    File.open(filename, 'w' ) do |f|
      f << YAML::dump(hash)
    end
  elsif File.extname(filename) == ".json"
    File.open(filename, 'w') {|f| f.write(hash.to_json) }
  end
end


if __FILE__ == $0
  include Color
  $opt_debug = false
  $opt_verbose = false
  $opt_quiet = false
  $opt_check = true
  $opt_all = false
  begin
    # http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
    require 'optparse'
    OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"

      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        $opt_verbose = true
      end
      opts.on("-q", "--quiet", "Run quietly") do |v|
        $opt_quiet = true
      end
      opts.on("--debug", "Run verbosely") do |v|
        $opt_debug = true
      end
      opts.on("-a","--all", "Save all elements") do 
        $opt_all = true
      end
      opts.on("--no-check", "check hash for missing fields") do |v|
        $opt_check = v
      end
    end.parse!

    #p ARGV

    filename=ARGV[0] || "defaultname";
    unless File.exist? filename
      $stderr.puts "File: #{filename} does not exist. Aborting"
      exit 1
    end
    outfile=ARGV[1] 
    hash = parseimdb filename
    check_hash hash if $opt_check
    exit 1 unless hash
    if $opt_debug
      pp hash
    end
    if outfile and hash
      writehash(hash, outfile)
    end
  ensure
  end
end

