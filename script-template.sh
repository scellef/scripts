#!/usr/bin/env bash
# Description: General template for my style of bash scripting
# Dependencies: bash 

### VARIABLES ###
IFS=','
array=()
variable=''
flag=''

### DOCUMENTATION ###
function usage {
  cat << EOF
Usage: script-template.sh -f mandatory-parameter [ -o optional-parameter ]
       script-template.sh -n

Options:
  -f    Parameter that must be supplied
  -o    Parameter that may be supplied
  -n    Parameter without argument

Notes:
  Information on edge-cases and limitations
EOF

exit
}


### HELPER FUNCTIONS ###
function error { IFS='\n' printf >&2 "[1;31mERROR: %s[0m\n" $* ;}
function success { IFS='\n' printf >&2 "[1;32mSUCCESS: %s[0m\n" $* ;}
function warning { IFS='\n' printf >&2 "[1;33mWARNING: %s[0m\n" $* ;}
function prompt { IFS='\n' printf >&2 "[1;36m%s[0m\n" $* ;}
function quit { prompt "Exiting..." ; exit 0 ;}


### PRIMARY FUNCTIONS ###
function check_dependencies {
  command -v color-test.sh 2> /dev/null >&2 || error "'color-test' not in your PATH."
}

function parse_arguments {
  if [ $# -eq 0 ] ; then
    prompt_for_info
  elif [ "$1" == '-' ] ; then
    error "Unknown option: $1" ; usage ; exit 2
  elif [[ ! ($1 =~ "-") ]] ; then
    error "Unknown option: $1" ; usage ; exit 2
  else
    while getopts ":o:f:nh" opt ; do
      case $opt in
         o) array+=("$OPTARG") ;;
         f) variable="$OPTARG" ;;
         n) flag+=1 ;;
         h) usage ;;
        \?) error "Unknown option: -$OPTARG" ; usage ; exit 2 ;;
         :) error "-$OPTARG requires an argument." ; usage ; exit 2 ;;
      esac
    done
  fi
  shift $((OPTIND-1)) # Cleaning up arguments

}

function function_name {
# Function purpose
echo
}


### MAIN ###
check_dependencies
parse_arguments
function_name
