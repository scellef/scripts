#!/usr/bin/env bash
# Usage: check-packt-ebook.sh 
# Dependencies: curl
#
# With thanks to http://stackoverflow.com/a/6541324

function read_dom {
  local IFS='\>'
  read -d \< entity content
  local ret="$?"
  tag_name=${entity%% *}
  attributes=${entity#* }
  return $ret
}

function parse_book {
  if [[ $tag_name = "h2" && $book_found != 1 ]] ; then
    eval local $attributes
    echo "Today's free eBook: $content"
    book_found=1
  fi
}

while read_dom ; do
  parse_book
done <<< $(curl -s https://www.packtpub.com/packt/offers/free-learning)
