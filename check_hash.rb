#!/usr/bin/env ruby -w
# ----------------------------------------------------------------------------- #
#         File: update.rb
#  Description: check the json files for missing fields
#
#       Author:  jkepler
#         Date: 2016-03-12 - 14:52
#  Last update: 2016-03-15 10:58
#      License: MIT License
# ----------------------------------------------------------------------------- #
# CHANGELOG

require 'color'

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
    require 'yaml'
    hash = YAML::load( File.open( filename ) )
  else
    $stderr.puts color("#{$0}: Don't know how to handle #{filename}, pass either .json or .yml", "red")
    exit 1
  end
  puts "==>  readfile: imdbid=" + hash["imdbID"] if $opt_verbose
  return hash
end

$keys_imp = %W[ Director Actors Released Runtime Title Year imdbID Metascore imdbVotes imdbRating Genre Language Country]
$keys_others = %W[  Writer Cast Location Budget Production_Co Keywords ]
def check_hash hash
  #return if $opt_quiet
  key = hash["imdbID"]
  $keys_imp.each do |e|
    if hash[e].nil?
      $stderr.puts color("   ERROR: check() #{key}  #{e} is null", "yellow", "reverse")
      $errors += 1
    end
  end
  $keys_others.each do |e|
    if hash[e].nil?
      $stderr.puts color("   WARNING: check() #{key}  #{e} is null", "white", "reverse")
      $warnings += 1
    end
  end
  # next won't really do. we need to have other keys also
  hash.each_pair { |k, v| 
    if v.nil?
      if $keys_imp.include? k
        # it won't come here in the first place
        $stderr.puts color("   WARNING: check() #{key} #{k} is null", "yellow", "reverse")
        $errors += 1
      else
        $stderr.puts color("   WARNING: check() #{key} #{k} is null", "red")
        $warnings += 1
      end
    end
    #puts "Key: #{k}, Value: #{v}" 
  }
end

def process_args args
  ctr = 0
  args.each do |e|
    if File.exist? e
      hash = readfile e
      check_hash hash
      ctr += 1
    else
      $stderr.puts color("ERROR: Cannot open file: #{e}.", "red")
      exit 1
    end
  end
  $stderr.puts "==> #{ctr} files processed" unless $opt_quiet
  $stderr.puts "==> #{$errors} error/s." unless $opt_quiet
  $stderr.puts "==> #{$warnings} warnings/s." if $warnings > 0 and !$opt_quiet
end

if __FILE__ == $0
  include Color
  #filename = nil
  $opt_verbose = false
  $opt_debug = false
  $opt_quiet = false
  $errors = 0
  $warnings = 0
  begin
    # http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
    require 'optparse'
    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"

      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        options[:verbose] = v
        $opt_verbose = v
      end
      opts.on( "--debug", "Run verbosely") do 
        options[:debug] = true
        $opt_debug = true
      end
      opts.on("-q", "--quiet", "Run quietly") do |v|
        $opt_quiet = true
      end
    end.parse!

    p options if $opt_debug
    p ARGV if $opt_debug

    if ARGV.size > 0
      # we have ttcodes
      $stderr.puts color("==> processing ttcodes: #{ARGV.size}", "blue", "bold") unless $opt_quiet
      process_args ARGV
    else
      # passed as stdin
      $stderr.puts "   Expecting filenames passed as stdin "
      $stdin.each_line do |file|
        hash = readfile file
        check_hash hash
      end
    end

  ensure
  end
end
