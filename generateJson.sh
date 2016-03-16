#!/usr/bin/env bash 
#===============================================================================
#
#          FILE: generateJson.sh
# 
#         USAGE: ./generateJson.sh imdb/*
#         USAGE: ./generateJson.sh imdb/tt0032976.html
# 
#   DESCRIPTION: generate json files for given imdb tt files.
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 03/12/2016 12:54
#      REVISION:  2016-03-16 20:30
#===============================================================================

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
#IFS=$'\n\t'



ScriptVersion="1.0"

#===  FUNCTION  ================================================================
#         NAME:  usage
#  DESCRIPTION:  Display usage information.
#===============================================================================
function usage ()
{
	cat <<- EOT

  This program generates json file for the given imdb files. The imdb files have been downloaded
  from www.imdb.com/title/tt...... and contain film info.
  Usage :  ${0##/*/} [options] filenames

  Options: 
  -a, --all        Save all fields
  --json           Output json files (default)
  --yml            Output yml files
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
OPT_ALL=
OPT_TYPE=json
while [[ $1 = -* ]]; do
case "$1" in
    --json)          shift
                     OPT_TYPE=json
                     ;;
    --yml|--yaml)    shift
                     OPT_TYPE=yml
                     ;;
    -a|--all)        shift
                     # save all properties, not just select ones.
                     OPT_ALL=1
                     FLAG_A="-a"
                     ;;
    -V|--verbose)   shift
                     OPT_VERBOSE=1
                     FLAG_V="--verbose"
                     ;;
    --no-verbose)   shift
                     OPT_VERBOSE=
                     ;;
    --debug)        shift
                     OPT_DEBUG=1
                     FLAG_D="--debug"
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

if [ $# -eq 0 ]
then
    perror "ERROR: I got no filename" 1>&2
    echo -e "   Invoke as: $0 imdb/* "
    echo -e "    to generate all json files."
    echo -e "   or $0 imdb/*.gz "
    echo -e "    to generate json for newly downloaded files"
    exit 1
else
    counter=1
    for file in "$@"; do
        pinfo "==> $counter) File: $file"
        if [[ ! -f "$file" ]]; then
            echo "File:$file not found" 1>&2
            exit 1
        else
            # last three chars, if .gz then unzip it.
            lt="${file: -3}"
            if [[ $lt == ".gz" ]]; then
                echo -n " unzipping $file."
                gunzip $file
                file=$(echo $file | sed 's|\.gz||')
                pdone "renaming to $file"
            fi
            base=$( basename $file )
            outfile=$( echo $base | sed "s|\.html|.${OPT_TYPE}|" )
            outfile="${OPT_TYPE}/$outfile"
            pdone "==> target = $outfile"
            ./parseimdb.rb $FLAG_V $FLAG_D $FLAG_A $file $outfile
            #ls -l $outfile
            #wc $outfile
            (( counter++ ))
        fi
    done
fi
