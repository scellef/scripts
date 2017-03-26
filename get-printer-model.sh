#!/bin/sh
# get-printer-model.sh -- query a printer over the network via SNMP for its model
# author: Sean Ellefson
# email: scellef@pdx.edu
# date: 10/22/2014

# SNMP MIB declarations
model='1.3.6.1.2.1.25.3.2.1.3.1'
pagecount='1.3.6.1.2.1.43.10.2.1.4.1.1'

printcount () {
  printer_model=`snmpget -v1 -Ovq -c public $line $model 2> /dev/null`
  printer_count=`snmpget -v1 -Ovq -c public $line $pagecount 2> /dev/null`
}

if [ "$*" = "-h" ] ; then
  cat << EOF
get-printer-model.sh -- query a printer over the network via SNMP for its model.\n"
usage: get-printer-model.sh [network_address]
       get-printer-model.sh -h
EOF
  exit 0
elif [ "$1" != "" ] ; then
  line=$1
  printcount
else 
  printf "Enter the printer's address:  "
  read line
  printcount
fi

if [ -z printer_model ] ; then
  printf "Unable to contact to contact printer.  Please confirm network address and try again.\n"
  exit 1
else 
  printf "Printer at $line reports itself as: $printer_model\n"
  printf "Number of pages reported as printed: $printer_count\n"
  exit 0
fi

