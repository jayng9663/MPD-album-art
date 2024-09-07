#!/bin/bash

ALBUM="/tmp/album_cover.png"
ALBUM_SIZE="350"
EMB_ALBUM="/tmp/album_cover_embedded.png"
MUSIC_DIR="$HOME/Music/"

file="$MUSIC_DIR$(mpc --format %file% current)"
album="${file%/*}"

err=$(ffmpeg -loglevel 16 -y -i "${file}" -an -vcodec copy $EMB_ALBUM 2>&1)
if [ "$err" != "" ]; then
art=$(find "$album" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" \) | grep -i -m 1 -E "front|cover")
else
  art="$EMB_ALBUM"
fi
if [ "$art" = "" ]; then
  art="$HOME/.ncmpcpp/Blank.png"
fi

width=$(ffmpeg -i "$art" 2>&1 | grep 'Stream' | grep -oP '\d{2,}x\d{2,}' | head -n1 | cut -d'x' -f1)
height=$(ffmpeg -i "$art" 2>&1 | grep 'Stream' | grep -oP '\d{2,}x\d{2,}' | head -n1 | cut -d'x' -f2)

if [ "$width" -lt "$ALBUM_SIZE" ]; then
  max_size_x="$width"
else
  max_size_x="$ALBUM_SIZE"
fi

if [ "$height" -lt "$ALBUM_SIZE" ]; then
  max_size_y="$height"
else
  max_size_y="$ALBUM_SIZE"
fi

convert "$art" -resize "${max_size_x}x-1" -crop "${ALBUM_SIZE}x${ALBUM_SIZE}+0+0" -gravity center -background none -extent "${ALBUM_SIZE}x${ALBUM_SIZE}" "$ALBUM"
