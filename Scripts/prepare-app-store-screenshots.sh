#!/bin/zsh
set -euo pipefail

repo_root="${0:A:h:h}"
source_dir="${1:-$repo_root/dist/app-store-screenshots-v14}"
output_dir="${2:-$repo_root/dist/app-store-screenshots-polished}"
font="/System/Library/Fonts/SFNS.ttf"
accent="#E47752"
foreground="#F5F3F1"
muted="#A9A5A2"

command -v magick >/dev/null || {
  print -u2 "ImageMagick is required: brew install imagemagick"
  exit 1
}

[[ -f "$font" ]] || {
  print -u2 "Missing system font: $font"
  exit 1
}

mkdir -p "$output_dir"

render() {
  local input="$1"
  local output="$2"
  local eyebrow="$3"
  local headline="$4"
  local detail="$5"

  [[ -f "$input" ]] || {
    print -u2 "Missing source screenshot: $input"
    exit 1
  }

  magick \
    -size 2880x1800 gradient:'#080808-#15110F' \
    \( "$input" -resize 2304x1440! \
       -bordercolor '#2A2421' -border 2 \
    \) -gravity south -geometry +0+0 -composite \
    -font "$font" -fill "$accent" -pointsize 28 \
    -gravity northwest -annotate +288+82 "$eyebrow" \
    -fill "$foreground" -pointsize 76 -annotate +288+122 "$headline" \
    -fill "$muted" -pointsize 32 -annotate +288+230 "$detail" \
    -alpha off -colorspace sRGB -depth 8 "$output"
}

render "$source_dir/05-dashboard.png" \
  "$output_dir/01-custos-e-decisoes.png" \
  "CONTROLE DE USO" \
  "Entenda seu custo de IA." \
  "Sessões, modelos e estimativas em uma visão clara."

render "$source_dir/01-overview.png" \
  "$output_dir/02-claude-codex-notch.png" \
  "VISÃO RÁPIDA" \
  "Claude e Codex no notch." \
  "O essencial à mão, sem interromper seu trabalho."

render "$source_dir/04-claude-models.png" \
  "$output_dir/03-tokens-por-modelo.png" \
  "TOKENS POR MODELO" \
  "Veja onde seus tokens foram." \
  "Compare o uso por modelo e ajuste suas escolhas."

render "$source_dir/03-rhythm.png" \
  "$output_dir/04-ritmo-de-trabalho.png" \
  "PADRÕES DE USO" \
  "Descubra seu ritmo de trabalho." \
  "Encontre picos e hábitos ao longo do dia."

render "$source_dir/02-burn.png" \
  "$output_dir/05-antecipe-limites.png" \
  "PROJEÇÃO DE SESSÃO" \
  "Antecipe o próximo limite." \
  "Acompanhe ritmo e projeção enquanto você trabalha."

for screenshot in "$output_dir"/*.png; do
  dimensions="$(sips -g pixelWidth -g pixelHeight "$screenshot" | awk '/pixel/{print $2}' | paste -sdx -)"
  alpha="$(sips -g hasAlpha "$screenshot" | awk '/hasAlpha/{print $2}')"
  [[ "$dimensions" == "2880x1800" && "$alpha" == "no" ]] || {
    print -u2 "Invalid output: $screenshot ($dimensions, alpha=$alpha)"
    exit 1
  }
done

print "Prepared 5 App Store screenshots in $output_dir"
