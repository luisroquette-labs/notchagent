#!/bin/zsh
set -euo pipefail

repo_root="${0:A:h:h}"
svg="$repo_root/Resources/AppIcon.svg"
png="$repo_root/Resources/AppIcon.png"
icns="$repo_root/Resources/AppIcon.icns"
iconset="$(mktemp -d "${TMPDIR:-/tmp}/notchagent-icon.XXXXXX")/AppIcon.iconset"
trap 'rm -rf "${iconset:h}"' EXIT

command -v magick >/dev/null || {
  print -u2 "ImageMagick is required: brew install imagemagick"
  exit 1
}

mkdir -p "$iconset"
magick -background none "$svg" -resize 1024x1024 -colorspace sRGB -depth 8 "$png"

for size in 16 32 128 256 512; do
  magick "$png" -resize "${size}x${size}" "$iconset/icon_${size}x${size}.png"
  retina=$((size * 2))
  magick "$png" -resize "${retina}x${retina}" "$iconset/icon_${size}x${size}@2x.png"
done

iconutil -c icns "$iconset" -o "$icns"

[[ "$(sips -g pixelWidth "$png" | awk '/pixelWidth/{print $2}')" == "1024" ]]
[[ -s "$icns" ]]
print "Prepared $png and $icns"
