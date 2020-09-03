#!/usr/bin/env bash

# Generate a `:something-intensifies:` Slack emoji, given a reasonable input
# input. I recommend grabbing an emoji from https://emojipedia.org/

set -euo pipefail


if [ $# -eq 0 ]; then
  echo "Usage: $0 input.png"
  exit 1
fi

input="$1"
cd "$(dirname "$input")"

filename=$(basename -- "$input")

tempdir="$(uuidgen)"

# Add 10% padding to width and height, then scale to 128x128
width=$(identify -format "%w" "$filename")
height=$(identify -format "%h" "$filename")
new_width=$(( width + width / 10 ))
new_height=$(( height + height / 10 ))
extended="${filename%.*}-extended.png"
convert \
  -gravity center \
  -background none \
  -extent ${new_width}x${new_height} \
  -geometry 128x128 \
  "$filename" \
  "$extended"

mkdir "$tempdir"

for ((i=1;i<=200;i=$i+12)); do
    convert "$input" -modulate 100,100,$i "$tempdir/$(printf "%05d" $i).gif"
done

# Some combination of `-coalesce -fuzz -dither -layers Optimize +map` helps to reduce overall filesize
convert -delay 4 -loop 0 \
  -coalesce \
  -fuzz 2% \
  +dither \
  -layers Optimize \
  +map \
  $tempdir/*.gif "${input%.*}-party.gif"

# Clean up
rm -rf "$tempdir"

# We did it y'all
echo "Created ${input%.*}-party.gif. Enjoy!"
