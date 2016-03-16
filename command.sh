#!/usr/bin/env bash 
#===============================================================================
#
#          FILE: command.sh
# 
#         USAGE: ./command.sh 
# 
#   DESCRIPTION: commands relating to creating json files from IMDB's movie files, importing into sqlite
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 02/04/2016 23:46
#      REVISION:  2016-03-16 20:20
#===============================================================================

source ~/bin/sh_colors.sh

test() {
    pinfo "Generating  a few json files ..."
    ./generateJson.sh --all imdb/tt1*.html
}
json() {
    pinfo "Generating all json files ..."
    ./generateJson.sh --all imdb/tt*.html
}
parse() {
    pinfo "Generating json files for gz files..."
    ./generateJson.sh --all imdb/tt*.html.gz
}
import() {
    pinfo "Importing all json files into imdb table ..."
    ./json2db.rb json/tt*
    sqlite3 imdb.sqlite  "select count(1) from imdb;"
}
drop() {

    echo -n "Do you wish to drop imdb table" '[y/n] ' ; read ans
    case "$ans" in
        y*|Y*) echo "dropping" ;;
        *) exit 0 ;;
    esac
    sqlite3 imdb.sqlite  "drop table imdb;"
    echo "table imdb dropped"
    echo -n "Do you wish to recreate imdb table" '[y/n] ' ; read ans
    case "$ans" in
        y*|Y*) echo "recreating from create.sql" ;;
        *) exit 0 ;;
    esac
    sqlite3 imdb.sqlite < create.sql
    pdone
}
delete() {
    echo -n "Do you wish to truncate imdb table" '[y/n] ' ; read ans
    case "$ans" in
        y*|Y*) echo "purging ..." ;;
        *) exit 0 ;;
    esac
    sqlite3 imdb.sqlite  "delete from imdb;"
    pdone

}
check() {
    pdone "Verifying json files in json dir..."
    ./check_hash.rb json/*.json
}
absent(){
    file=$1
    if [[ -z "$file" ]]; then
        echo "Pass the name of a file with imdb urls/tt codes"
        echo "This command checks to see which ones are NOT present in the imdb directory"
        echo "and places the absent ones in todo.list"
        exit 1
    fi
    wc -l $file
    echo "Will create/overwrite todo.list"
    grep -o "tt[0-9]*" $file | sort -u > t.new
    ls imdb/tt* | grep -o "tt[0-9]*" | sort -u > t.old
    wc -l t.new t.old
    comm -23 t.new t.old > todo.list
    wc -l todo.list

}
toparse() {
    ./to_parse.sh
}
help() {

    cat <<EOF
    Commands are:

    json   = convert html files to json
    parse  = convert html.gz files to json (these are the new ones)
    import = import json files into database
    dump   = dump file to a tsv
    drop   = drop and recreate table
    delete = clear data in table before import
    check  = checks all the hashes in the json folder for missing fields
    test   = generates about 10 json files from tt1..... files
    yml    = convert html files to yml
    toparse= print a list of files that need to be parsed

EOF
}
if [[ $1 =~ ^(json|import|parse|help|drop|delete|test|check|yml|absent)$ ]]; then
  "$@"
else
  echo "Invalid subcommand $1" >&2
  help
  exit 1
fi
