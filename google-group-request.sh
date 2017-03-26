#!/usr/bin/env bash
# Description: Gather and resolve Google Group requests from RT
# Dependencies: gam, rt
# Written by scellef, 25 Mar 2017

### VARIABLES ###
IFS=',' # Set field separator to comma to allow for multiple owners/managers
rtUrl="https://rt.example.com/Ticket/Display.html?id="
groupUrl="https://groups.google.com/forum/#!forum/"
ticketQuery=("Subject LIKE '[Google Group]' AND Status = 'new'")
groupString="'Group Name:'"
ownerString="'Owner Username:'"
managerString=="'Manager Username'"
descString=="'Description:'"

### DOCUMENTATION ###
function usage {
  cat << EOF
Usage: google-group-request.sh
       google-group-request.sh -h
       google-group-request.sh -a
       google-group-request.sh -t TICKET [-t TICKET ...]
       google-group-request.sh -n NAME -o OWNER [-o OWNER2 ...] 
         [-m MANAGER [-m MANAGER2 ...]] [-d 'DESCRIPTION']

Options:
  -a    Queries RT for new Google Group requests and iterates through them,
        interactively prompting for corrections
  -t    Specifies the RT ticket to gather information from and resolve
  -n    Specifies the name of the Google Group to create
  -o    Specifies the owner of the Google Group to create
  -m    Specifies the manager of the Google Group to create
  -d    Specifies the description of the Google Group to create

Notes:
  NAME and OWNER must be set before a group can be created.

  OWNER and MANAGER should be valid and active Google usernames.

  DESCRIPTION has a 300-character limit and will be truncated accordingly

  While in the group settings confirmation prompt, multiple owners or managers
  may be specified in a comma-delimited list such as "larry,curly,moe".

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
function check_dependencies {
  command -v rt > /dev/null  || error "'rt' not found in your PATH."
  command -v gam > /dev/null || error "'gam' not found in your PATH."
}
    
function parse_arguments {
  if [ $# -eq 0 ] ; then
    prompt_for_info
  elif [ "$1" == '-' ] ; then
    error "Unknown option: $1" ; usage ; exit 2
  elif [[ ! ($1 =~ "-") ]] ; then
    error "Unknown option: $1" ; usage ; exit 2
  else
    while getopts ":t:n:o:m:d:ah" opt ; do
      case $opt in
         a) find_tickets ;;
         t) ticketNum+=("$OPTARG") ;; 
         n) groupName="$OPTARG" ;;
         o) groupOwner+=("$OPTARG") ;;
         m) groupManager+=("$OPTARG") ;;
         d) groupDesc="$OPTARG" ;;
         h) usage ;;
        \?) error "Unknown option: -$OPTARG" ; usage ; exit 2 ;;
         :) error "-$OPTARG requires an argument." ; usage ; exit 2 ;;
      esac
    done
  fi
  shift $((OPTIND-1)) # Cleaning up arguments

  if [ $ticketNum ] ; then
    parse_ticket_info
  else 
    confirm_group_info
  fi

}

function prompt_for_info {
  prompt 'Choose from the following options: '
  PS3="Enter a selection [1-4]: "
  select choice in 'Enter ticket' 'Find new requests' 'Manually create group' 'Exit' ; do
    case $choice in 
      'Find new requests'       ) find_tickets ; break ;;
      'Enter ticket'            ) read -p 'Enter ticket number: ' ticketNum ; break ;;
      'Manually create group'   ) confirm_group_info ; exit ;;
      'Exit'                    ) exit ;;
    esac
  done
}

function find_tickets {
  readarray -t ticketNum <<< "$(rt ls -f id "$ticketQuery" | tail -n +2)"
}
 
function confirm_group_info {
  prompt 'Choose a field to update, or select an action: '
  while [ "$confirmed" != "yes" ] ; do
    PS3="Enter a selection [1-6]: "
    select choice in \
      "Group name: $groupName" \
      "Owner(s): ${groupOwner[*]}" \
      "Manager(s): ${groupManager[*]}" \
      "Description: $groupDesc" \
      "Create group" \
      "Abort" ; do
      case $choice in 
        "Group name: $groupName") 
          read -p 'Enter the Group Name: ' groupName ; break ;; 
        "Owner(s): ${groupOwner[*]}")
          read -p 'Enter the Group Owner(s): ' -a groupOwner ; break ;;
        "Manager(s): ${groupManager[*]}")
          read -p 'Enter the Group Manager(s): ' -a groupManager ; break ;;
        "Description: $groupDesc")
          read -p 'Enter the Group Description: ' groupDesc ; break ;;
        "Create group") 
          local confirmed="yes" ; break ;;
        "Abort") quit ; exit ;;
      esac
    done
  done

  create_group
}

function check_group_info {
  if [ -z $groupName ] ; then
    error "Missing group name!" ; break
  elif [ -z $groupOwner ] ; then
    error "At least one owner must be specified!" ; break
  fi
}

function parse_ticket_info {
  for ticket in ${ticketNum[*]} ; do
    if [ ! $ticket -gt 0 ]; then
      error "'$ticket' is not a valid ticket number" ; break
    fi
    rt show $ticket > /tmp/$ticket.rt 2> /dev/null

    grep -q '^Subject:.*\[Google Group\]' /tmp/$ticket.rt
    if [ $? -ne 0 ] ; then 
      warning "RT #$ticket subject does not match; is this a Google Group request?"
    fi

    prompt
    prompt "RT #${ticket}:"
    prompt "${rtUrl}${ticket}"
    prompt

    groupName="$(grep $groupString /tmp/$ticket.rt      | cut -f 2 -d ':' | tail -c+2)"
    groupOwner="$(grep $ownerString /tmp/$ticket.rt     | cut -f 2 -d ':' | tail -c+2)"
    groupManager="$(grep $managerString /tmp/$ticket.rt | cut -f 2 -d ':' | tail -c+2)"
    groupDesc="$(grep $descString /tmp/$ticket.rt       | cut -f 2 -d ':' | tail -c+2)"

    confirm_group_info
  done
}


function create_group {
  check_dependencies
  check_group_info

  gam create group $groupName 2> /dev/null >&2 ; sleep 2
  for owner in ${groupOwner[*]} ; do
    gam update group $groupName add owner $owner  2> /dev/null >&2 ; sleep 2
  done
  for manager in ${groupManager[*]} ; do
    gam update group $groupName add manager $manager  2> /dev/null >&2 ; sleep 2
  done
  if [ ! -z "$groupDesc" ] ; then
    gam update group $groupName description "${groupDesc:0:300}" 2> /dev/null >&2
  fi

  success "Group created: ${groupUrl}${groupName}"
  unset groupName groupOwner groupManager groupDesc

  if [ $ticket ] ; then
    resolve_ticket
  fi
}

function resolve_ticket {
  rt correspond $ticket -m - -s resolved 2> /dev/null << EOF
The '${groupName}' Google group has been created.  You can access it by visiting the following URL:

${groupUrl}${groupName}
EOF

  success "Ticket resolved: ${rtUrl}${ticket}"
}

parse_arguments $@
