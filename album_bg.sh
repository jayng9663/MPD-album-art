#!/bin/bash

MPC_CMD="mpc"
ALBUM="/tmp/album_cover.png"
ALBUM_SIZE="350"
EMB_ALBUM="/tmp/album_cover_embedded.png"
#BACKUP_ALBUM="$HOME/.ncmpcpp/backup_album.png"
MUSIC_DIR="$HOME/Music/"
DOWNLOAD_FROM_INTERNET=1
ONLINE_ALBUM="/tmp/online_album.png"

file="$MUSIC_DIR$($MPC_CMD --format %file% current)"
album="${file%/*}"

album_name=$($MPC_CMD --format '%album%' current)
artist_name=$($MPC_CMD --format '%artist%' current)
release_date=$($MPC_CMD --format '%date%' current)

urlencode() {
  echo -n "$1" | perl -MURI::Escape -ne 'print uri_escape($_)'
}

album_name=$(urlencode "$album_name")
artist_name=$(urlencode "$artist_name")
release_date=$(urlencode "$release_date")

if [ ! -d "$album" ]; then
  exit 1
fi

if ! ffmpeg -loglevel error -y -i "$file" -an -vcodec copy "$EMB_ALBUM" 2>/dev/null; then
  art=$(find "$album" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.bmp" \) | grep -i -m 1 -E "front|cover")
else
  art="$EMB_ALBUM"
fi

if [ -z "$art" ]; then
  art="$BACKUP_ALBUM"

  if [ "$DOWNLOAD_FROM_INTERNET" = 1 ]; then
    id=$(wget -qO- "https://musicbrainz.org/ws/2/release/?query=artist:${album_name}%20release:${artist_name}%20date:${release_date}&fmt=json" | jq -r '.releases[0].id')

    if [ "$id" != "null" ]; then
      cover_art_url="http://coverartarchive.org/release/$id/front"
      wget -q "$cover_art_url" -O "$ONLINE_ALBUM"
      art="$ONLINE_ALBUM"
    else
      exit 1
    fi
  fi
fi

convert "$art" -resize "${ALBUM_SIZE}x${ALBUM_SIZE}^" -gravity center -crop "${ALBUM_SIZE}x${ALBUM_SIZE}+0+0" +repage "$ALBUM"
