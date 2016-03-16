#!/usr/bin/env bash 
#===============================================================================
#
#          FILE: to_parse.sh
# 
#         USAGE: ./to_parse.sh 
# 
#   DESCRIPTION: print a list of files that need to be parsed comparing imdb/ and json/
#            for missing object files, or older files.
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 03/16/2016 18:35
#      REVISION:  2016-03-16 20:15
#===============================================================================

source=imdb
target=json

# source extension and target extension
sext=html
oext=json

ls ${source}/*.{html,gz} 2>/dev/null |  while IFS='' read file
do
    # remove source name from start of string and prepend target
    obj="${target}${file#${source}}"
    # remove gz suffix in some files
    obj="${obj%.gz}"
    # replace source extn with object extn
    obj="${obj%$sext}$oext"

    # The object file is not found
    if [[ ! -f "$obj" ]]; then
        echo "$file"
        continue
    fi
    # The object file is older
    if [[ $file -nt $obj ]]; then
        echo "$file"
    fi
done 
