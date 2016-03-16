#!/usr/bin/env ruby -w
# ----------------------------------------------------------------------------- #
#         File: update.rb
#  Description: reads up json files, updates table.
#    This is mostly required for new movies which don't have oscar and other award info updated yet.
#    Sometimes the plot also changes.
#
#       Copied from imdbdata. But now i check fields against database table
#       Author:  jkepler
#         Date: 2016-03-12 - 14:52
#  Last update: 2016-03-15 11:33
#      License: MIT License
# ----------------------------------------------------------------------------- #
# CHANGELOG
# 2016-03-01 - added. insert imdbid first, then update.

require 'json'
require 'sqlite3'
require 'color'

dbname = "imdb.sqlite"
$db = SQLite3::Database.new(dbname)
# this contains imdb ids one per line, to read up and insert into DB
# It does not check for exists, and will crash if record already exists
# TODO we cannot be picking up json files which have Response = Error in it.
# Also how do we handle dupes without having to check ? retrieve has already checked.
#    should it create an output file so we can use that only.

# ---------- get_column_names ------------------------------------------ # 
# return an array of columns names for given table
#  @example :  column_array = get_column_names(db, table)
# ---------------------------------------------------------------------- # 
def get_column_names db, table
  columns, *rows = db.execute2(" select * from #{table} limit 1; ")
  return columns
end
# ---------------------------------------------------------------------- # 
# read up yaml file
# then update table
# ---------------------------------------------------------------------- # 
def readfile filename
  if filename.index(".json")
    require 'json'
    str = File.read(filename)
    hash = JSON.parse(str)
  elsif filename.index ".yml"
    hash = YAML::load( File.open( filename ) )
  else
    $stderr.puts color("#{$0}: Don't know how to handle #{filename}, pass either .json or .yml", "red")
    exit 1
  end
  # 2016-03-05 - adding processing of update_dt
  hash["update_dt"] = File.mtime(filename).to_s[0,19]
  hash["imdbVotes"] = hash["imdbVotes"].gsub(",","")
  s = hash["Certificate"]
  if s
    if s.index("| See all certifications »")
      s = s.gsub("| See all certifications »","")
    elsif s.index("See all certifications »")
      s = s.gsub("See all certifications »","")
    end
    s = s.strip
    s = nil if s == ""
    hash["Certificate"] = s
  end
  # some field names are change/shortened, so hash needs to change.
  #hash["mtime"] = mtime

  if $opt_verbose
    hash.each_pair {|k, v| 
      puts "#{k} : #{v}"
    }
  end
  puts "==>  readfile: imdbid=" + hash["imdbID"] if $opt_verbose
  rowid = table_insert_hash $db, "imdb", "imdbID", hash
  return rowid
end

# recieves an array of json strings, one for each movie
# which are inserted into db and table
def table_insert_hash db, table, keyname, hash
  #$stderr.puts "inside table_insert_hash "
  #keyname = "imdbID"
  imdbid = hash.delete keyname
  raise ArgumentError, "imdbid is nil" unless imdbid
  # 2016-03-01 - added. first try inserting in case it is not there. This takes care of any new rows.
  #str = "INSERT OR IGNORE INTO #{table} (imdbID) VALUES ('#{imdbid}') ;"
  create_dt = hash.delete "create_dt"
  str = "INSERT OR IGNORE INTO #{table} (#{keyname}, create_dt) VALUES (? , ?);"
  $stderr.puts str if $opt_debug
  db.execute(str, [imdbid, create_dt])
  rowid = db.get_first_value( "select last_insert_rowid();")
  title = hash["Title"]
  if rowid == 0
    $stderr.puts color("==> UPDATED: #{imdbid}/ #{title}","green") unless $opt_quiet
  else
    $stderr.puts color("==> INSERTED: #{rowid} for #{imdbid}/ #{title}","green","bold") unless $opt_quiet
  end

  column_array = get_column_names(db, table)
  str = "UPDATE #{table} SET "
  qstr = [] # question marks
  bind_vars = [] # values to insert
  hash.each_pair { |name, val| 
    if column_array.include? name.to_s
      bind_vars << val
      qstr << " #{name}=? "
    end
  }
  #str << fstr
  #str << ") values ("
  str << qstr.join(",")
  str << %Q[ WHERE imdbID = '#{imdbid}' ]
  str << ";"
  #$stderr.puts color( "   #{hash["Title"]} ", "green") unless $opt_quiet
  #puts " #{hash["Title"]} #{hash["imdbID"]} "
  db.execute(str, bind_vars)
  #rowid = $db.get_first_value( "select last_insert_rowid();")
  return rowid
end

# read imdb id's from a file into an array
def process_file_containing_imdbids inputfile
  filename = inputfile
  file = File.new(filename, "r");
  array=file.readlines;
  file.close
  return array
end

def process_args args
  args.each do |e|
    if File.exist? e
      readfile e
    else
      $stderr.puts color("ERROR: Cannot open file: #{e}.", "red")
      exit 1
    end
  end
end

# ------------------
#  file contains an imdbid on each line
#  This points to a file like tt001111.json.
#  We read this file into a hash and push this hash onto an array of hashes.
# ------------------
# recieve an array of imdb id's which are then read up from disk into an array of hashes
def process_imdbarray array
hasharray = []
array.each_with_index do |e, i| 
  e = e.chomp
  if e.index(".json").nil?
    e += ".json"
  end
  unless File.exist?(e)
    puts "File #{e} not found. Please correct file name\n"
    next
  end
  # file contains just one line of JSON.
  mtime = File.mtime(e).to_s[0,10]
  File.open(e).each { |line|
    hash = JSON.parse(line)
    if hash["Response"] == "False"
      $stderr.puts " ======== #{e} has error. ignoring ... ======"
      next
    end
    hash.delete "Response"
    # added 2015-11-07 - I don't need this, large field
    hash.delete "Poster"
    # remove commas from votes so we can sort on it.
    hash["imdbVotes"] = hash["imdbVotes"].gsub(",","")
    hash["mtime"] = mtime
    #puts hash.to_s
    $stderr.print " #{hash["Title"]}  #{hash["Year"]}     #{e}"
    $stderr.puts 
    hasharray << hash
    #str = generate_insert_statements "imdb", hash
    #puts str
    #print hash.keys
  }

end
table_insert_hash $db, "imdb", "imdbID", hash
$db.close
end

if __FILE__ == $0
  include Color
  filename = nil
  $opt_verbose = false
  $opt_debug = false
  $opt_quiet = false
  begin
    # http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
    require 'optparse'
    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"
      opts.on("-f", "--filename imdbid.list", String, "File containing IMDB ids") do |l|
        filename = l
      end

      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        options[:verbose] = v
        $opt_verbose = v
      end
      opts.on( "--debug", "Run verbosely") do 
        options[:debug] = true
        $opt_debug = true
      end
    end.parse!

    p options if $opt_debug
    p ARGV if $opt_debug

    if ARGV.size > 0
      # we have ttcodes
      $stderr.puts color("==> processing ttcodes: #{ARGV.size}", "blue") unless $opt_quiet
      process_args ARGV
    else
      # passed as stdin
      $stderr.puts "   Expecting filenames passed as stdin "
      $stdin.each_line do |file|
        readfile file
      end
    end

  ensure
  end
end
