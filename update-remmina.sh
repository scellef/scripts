#!/usr/bin/env bash
# Desccription: Script for generating .remmina files to SSH tunnel VNC console on ganeti nodes
# Dependencies: jq, curl, genders
# Written by scellef, 27 Apr 2017

ganetiUrl="https://example.com:5080/2/instances"
remminaDir="${HOME}/.local/share/remmina"

function error { IFS='\n' printf >&2 "[1;31mERROR: %s[0m\n" "$*" ;}
function success { IFS='\n' printf >&2 "[1;32mSUCCESS: %s[0m\n" "$*" ;}
function warning { IFS='\n' printf >&2 "[1;33mWARNING: %s[0m\n" "$*" ;}
function prompt { IFS='\n' printf >&2 "[1;36m%s[0m\n" "$*" ;}
function quit { prompt "Exiting..." ; exit 0 ;}

function check_dependencies {
  command -v curl 2> /dev/null >&2 || error "'curl' not in your PATH."
  command -v jq 2> /dev/null >&2 || error "'jq' not in your PATH."
  command -v nodeattr 2> /dev/null >&2 || error "'nodeattr' not in your PATH."
}

if [ $@ ] ; then
  instances=("$@")
else
  instances=( $(nodeattr -s virt=ganeti) )
fi

for instance in ${instances[*]} ; do 
  server=$(curl -sk ${ganetiUrl}/${instance} | jq '[.pnode,.network_port|tostring]|join(":")')
  if [ $server == "null:null" ] ; then
    warning "$instance not found.  Is this a ganeti instance?"
  else
    sed -e "s/INSTANCE/$instance/" -e "s/SERVER/$server/" -e 's/"//g' << EOF > ${remminaDir}/${instance}.remmina \
      && success "Remmina configuration file for '$instance' written!" \
      || error "Could not write configuration file for '$instance'!"
[remmina]
keymap=
ssh_auth=2
quality=9
disableencryption=0
postcommand=
ssh_privatekey=${HOME}/.ssh/id_rsa
viewmode=1
ssh_charset=UTF-8
window_maximize=0
password=
group=Ganeti
name=INSTANCE
precommand=
proxy=
ssh_username=$USER
ssh_loopback=1
viewonly=0
disableclipboard=0
protocol=VNC
ssh_server=
window_width=874
window_height=875
ssh_enabled=1
username=$USER
showcursor=0
disablepasswordstoring=0
colordepth=32
server=SERVER
disableserverinput=0
EOF
  fi
done

quit
