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
Usage: pdscreen.sh <query>
       pdscreen.sh -h

Options:
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
    error 'Missing argument.'
    quit
  elif [ "$1" == '-' ] ; then
    error "Unknown option: $1" ; usage ; exit 2
  else
    while getopts "h" opt ; do
      case $opt in
         h) usage ;;
         *) query="$*" ;; 
         \?) error "Unknown option: -$OPTARG" ; usage ; exit 2 ;;
      esac
    done
  fi
  shift $((OPTIND-1)) # Cleaning up arguments
  query="$*"
}

function count_nodes {
  nodes=( $(nodeattr -s $query -f $gendersFile) )
  nodeCount=${#nodes[*]}

  if   [ $nodeCount -le 4  ] ; then # 4: twobytwo
    hsplit=1 vsplit=2 layout=twobytwo
  elif [ $nodeCount -le 6  ] ; then # 6: threebytwo
    hsplit=2 vsplit=3 layout=threebytwo
  elif [ $nodeCount -le 9  ] ; then # 9: threebythree
    hsplit=2 vsplit=3 layout=threebythree
  elif [ $nodeCount -le 12 ] ; then # 12: threebyfour
    hsplit=2 vsplit=3 layout=threebyfour
  elif [ $nodeCount -le 16 ] ; then # 16: fourbyfour
    hsplit=3 vsplit=4 layout=fourbyfour
  elif [ $nodeCount -le 20 ] ; then # 20: fourbyfive
    hsplit=3 vsplit=4 layout=fourbyfive
  elif [ $nodeCount -le 25 ] ; then # 25: fivebyfive
    hsplit=4 vsplit=5 layout=fivebyfive
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

  for ((j=0; $j<$nodeCount; j++)) ; do
    # Make new screen window and login to the remote host
    echo "screen -t ${nodes[$j]} ssh ${user}@${nodes[$j]}" >> $screenrcTemp

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
