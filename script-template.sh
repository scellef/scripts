#!/usr/bin/env bash
# Description: General template for my style of bash scripting
# Dependencies: bash 

### VARIABLES ###
variableName=''


### DOCUMENTATION ###
function usage {
# Print usage information
  cat << EOF
Usage: script-template.sh -f mandatory-parameter [ -o optional-parameter ]

Options:
  -f    Parameter that must be supplied
  -o    Parameter that may be supplied

Notes:
  Information on edge-cases and limitations
EOF

exit
}


### HELPER FUNCTIONS ###
function error { printf >&2 "[1;31mERROR: %s[0m\n" $* ;}
function success { printf >&2 "[1;32mSUCCESS: %s[0m\n" $* ;}
function warning { printf >&2 "[1;33mWARNING: %s[0m\n" $* ;}
function prompt { printf >&2 "[1;36m%s[0m\n" $* ;}
function quit { prompt "Exiting..." ; exit 0 ;}


### PRIMARY FUNCTIONS ###
function function_name {
# Function purpose
}


### MAIN ###
