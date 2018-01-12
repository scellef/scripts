#!/usr/bin/env bash
# Description: Generate screen sessions arranged in a split view from genders query
# Dependencies: screen, genders

### VARIABLES ###
user="root"
query=""
nodes=()
nodeCount=""
gendersFile="/etc/genders"
screenrcDefault=""
screenrcTemp="/tmp/screenrc.${USER}"

### DOCUMENTATION ###
function usage {
  cat << EOF
Usage: pdscreen.sh [-d <domain>]
       pdscreen.sh [-d <domain>] -n <hostname> [-n <hostname> ...]
       pdscreen.sh -h

Options:
  -n    Specifies the name of the host to connect to
  -d    Append <domain> to each hostname
  -h    Shows usage information

Notes:
  <query> can be any valid genders query returning up to 25 hosts.  More than
  that and the script will exit.
EOF

exit
}

### HELPER FUNCTIONS ###
function error { IFS='\n' printf >&2 "[1;31mERROR: %s[0m\n" "$*" ;}
function success { IFS='\n' printf >&2 "[1;32mSUCCESS: %s[0m\n" "$*" ;}
function warning { IFS='\n' printf >&2 "[1;33mWARNING: %s[0m\n" "$*" ;}
function prompt { IFS='\n' printf >&2 "[1;36m%s[0m\n" "$*" ;}
function quit { prompt "Exiting..." ; exit 0 ;}

### PRIMARY FUNCTIONS ###
function check_dependencies {
  command -v screen 2> /dev/null >&2 || error "'screen' not in your PATH."
  command -v nodeattr 2> /dev/null >&2 || error "'nodeattr' not in your PATH."
  [ -f ${HOME}/.screenrc ] \
    && screenrcDefault="${HOME}/.screenrc" \
    || screenrcDefault="/etc/screenrc"
}

function parse_arguments {
  if [ $# -eq 0 ] ; then
    error 'Missing argument.' ; exit 2
  elif [ "$1" == '-' ] ; then
    error "Unknown option: $1" ; usage ; exit 2
  else
    while getopts "hd:n:" opt ; do
      case $opt in
         h) usage ;;
         n) nodes+=("$OPTARG") ;;
         d) domain="$OPTARG" ;;
         *) query="$*" ;; 
         \?) error "Unknown option: -$OPTARG" ; usage ; exit 2 ;;
         :) error "-$OPTARG requires an argument." ; usage ; exit 2 ;;
      esac
    done
  fi
  shift $((OPTIND-1)) # Cleaning up arguments
  query="$*"
}

function append_domain {
  for i in $( seq 0 $(($nodeCount - 1)) ) ; do # Index equals array length - 1
    nodes[$i]+="$domain"                       # Iterate over array and append domain to each item
  done
}

function count_nodes {
  if [ ! $nodes ] ; then
    nodes=( $(nodeattr -s $query -f $gendersFile) )
  fi
  nodeCount=${#nodes[*]}

  if [ $domain ] ; then
    append_domain
  fi

  if   [ $nodeCount -eq 1  ] ; then # 1: onebyone
    warning "Only one node returned.  Just use screen." ; quit
  elif [ $nodeCount -le 2  ] ; then # 2: onebytwo
    hsplit=1 vsplit=1 windows=2 layout=twobyone
  elif [ $nodeCount -le 4  ] ; then # 4: twobytwo
    hsplit=1 vsplit=2 windows=4 layout=twobytwo
  elif [ $nodeCount -le 6  ] ; then # 6: threebytwo
    hsplit=1 vsplit=3 windows=6 layout=threebytwo
  elif [ $nodeCount -le 9  ] ; then # 9: threebythree
    hsplit=2 vsplit=3 windows=9 layout=threebythree
  elif [ $nodeCount -le 12 ] ; then # 12: threebyfour
    hsplit=3 vsplit=3 windows=12 layout=fourbythree
  elif [ $nodeCount -le 16 ] ; then # 16: fourbyfour
    hsplit=3 vsplit=4 windows=16 layout=fourbyfour
  elif [ $nodeCount -le 20 ] ; then # 20: fourbyfive
    hsplit=4 vsplit=4 windows=20 layout=fivebyfour
  elif [ $nodeCount -le 25 ] ; then # 25: fivebyfive
    hsplit=4 vsplit=5 windows=25 layout=fivebyfive
  else
    error "Too many nodes.  Try revising your genders query."
    exit
  fi
}

function write_screenrc {
  cp $screenrcDefault $screenrcTemp

  echo "defdynamictitle off" >> $screenrcTemp # Fix name of each window to hostname
  echo "layout autosave on" >> $screenrcTemp  # Automatically remember layout
  echo "mousetrack on" >> $screenrcTemp       # Useful to be able to mouse around larger layouts

  # Create the horizontal splits first
  i=$hsplit
  until [ $i -eq 0 ] ; do
    echo 'split' >> $screenrcTemp
    let i--
  done

  for ((j=0; $j<$windows; j++)) ; do
    if [ ! -z ${nodes[$j]} ] ; then
      # Make new screen window and login to the remote host
      echo "screen -t ${nodes[$j]} ssh ${user}@${nodes[$j]}" >> $screenrcTemp
    fi

    # Create a vertical split if we're not at the end of the row
    if [ $(( ($j+1) % $vsplit )) -ne 0 ] ; then
      echo 'split -v' >> $screenrcTemp
    fi

    echo 'focus' >> $screenrcTemp
  done

  echo "layout save $layout" >> $screenrcTemp
}

  

### MAIN ###
check_dependencies
parse_arguments $@

# Gather list of nodes and count them
count_nodes

# Generate appropriate screen layout
write_screenrc

# Launch screen with layout
screen -c $screenrcTemp
