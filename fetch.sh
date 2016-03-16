#!/usr/bin/env bash 
#===============================================================================
#
#          FILE: fetch.sh
# 
#         USAGE: ./fetch.sh filename (containing imdb urls)
# 
#   DESCRIPTION: fetches imdb files taking a filename as arg (file contains list of tt codes in first column)
# 
#       OPTIONS: 
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#         TODO:  
#         1. force option for fetch, so we can download current years files again after academy awards are over.
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 03/14/2016 10:09
#      REVISION:  2016-03-15 13:27
#===============================================================================


#!/usr/bin/env bash

# Set magic variables for current file & dir
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__root="$(cd "$(dirname "${__dir}")" && pwd)" # <-- change this
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"

arg1="${1:-}"

# use ,fh to generate file header
source ~/bin/sh_colors.sh
APPNAME=$( basename $0 )
ext=${1:-"default value"}
today=$(date +"%Y-%m-%d-%H%M")
curdir=$( basename $(pwd))
export TAB=$'\t'



ScriptVersion="1.0"

#===  FUNCTION  ================================================================
#         NAME:  usage
#  DESCRIPTION:  Display usage information.
#===============================================================================
function usage ()
{
	cat <<- EOT

  Usage :  ${0##/*/} [options] imdb.list
  Fetches imdb film files given a file containing a list of tt00000 codes.

  Options: 
  -h, --help       Display this message
  -v, --version    Display script version
  -V, --verbose    Display processing information
  --no-verbose     Suppress extra information
  --debug          Display debug information

	EOT
}    # ----------  end of function usage  ----------


#-------------------------------------------------------------------------------
# handle command line options
#-------------------------------------------------------------------------------
OPT_VERBOSE=
OPT_DEBUG=
while [[ $1 = -* ]]; do
case "$1" in
    -V|--verbose)   shift
                     OPT_VERBOSE=1
                     ;;
    --no-verbose)   shift
                     OPT_VERBOSE=
                     ;;
    --debug)        shift
                     OPT_DEBUG=1
                     ;;
    -h|--help)
        usage
        exit
    ;;
    *)
        echo "$0 Error: Unknown option: $1" >&2   # rem _
        echo "Use -h or --help for usage" 1>&2
        exit 1
        ;;
esac
done

_process() {
    infile=$1
    wc -l $infile
    total=$(wc -l $infile | cut -f1 -d' ')
    counter=1
    HOST="http://www.imdb.com/title/"
    while IFS='' read line
    do
        #echo -e "::$line"
        #id=$(echo "$line" | cut -f1)
        id=$(echo "$line" | grep -o 'tt[0-9][0-9][0-9]*' )
        if [[ -z "$id" ]]; then
            continue
        fi
        if [[ "$id" == "imdbid" ]]; then
            continue
        fi
        file="imdb/${id}.html.gz"
        if [[ -f "$file" ]]; then
            pdone "File: $file found" 1<&2
            continue
        fi
        file="imdb/${id}.html"
        if [[ -f "$file" ]]; then
            pdone "File: $file found" 1<&2
            continue
        fi
        URL="${HOST}$id/"
        pinfo "==> ${counter} / ${total}::$line. download ($URL) > ($file)"
        #pinfo "${counter}. Downloading $file ..."
        wget -O - $URL > $file
        (( counter += 1 ))
        if [[ ! -s "$file" ]]; then
            echo " =============================================================== "
            perror "ERROR: warning ($file) empty, maybe internet connection down "
            mv $file $file.del
            pinfo sleeping two minutes
            sleep 120
        else
            # i have put gzip setting in wgetrc so i am getting gzipped file
            #file $file
            # TODO check that it is a zip file incase settings have changed
            mv $file $file.gz
            #gunzip $fn.gz
            zgrep "<title>" $file.gz
            #ls imdb/ | wc -l
        fi
        slctr=$(( ( RANDOM % 12 )  + 2 ))
        echo "Sleeping $slctr...."
        sleep $slctr
    done < $infile
    pinfo "${counter} files downloaded."
}

if [ $# -eq 0 ]
then
    echo "I got no filename" 1>&2
    exit 1
else
    echo "Got $*" 1>&2
    #echo "Got $1"
    if [[ ! -f "$1" ]]; then
        echo "File:$1 not found" 1>&2
        exit 1
    fi
    _process $1
fi
