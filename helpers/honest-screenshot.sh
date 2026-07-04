#!/usr/bin/env bash
# Тихий скриншот: сохраняет файл + кладёт в буфер обмена (его ловит cliphist),
# БЕЗ окна-редактора. По завершении — вспышка капсулы буфера в панели через IPC.
#
# Использование: honest-screenshot.sh area|output|screen
#   area   — выбор области (slurp)
#   output — текущий монитор
#   screen — все мониторы
#
# Биндится в hypr/userprefs.conf вместо hyde-shell screenshot.

set -o pipefail
mode="${1:-area}"
dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/$(date +%y%m%d_%Hh%Mm%Ss)_screenshot.png"

case "$mode" in
    area)
        geo="$(slurp)" || exit 1                 # отмена выбора → выходим, без вспышки
        grim -g "$geo" "$file" || exit 1
        ;;
    output)
        out="$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')"
        grim -o "$out" "$file" || exit 1
        ;;
    screen|*)
        grim "$file" || exit 1
        ;;
esac

wl-copy --type image/png < "$file"               # копия в буфер → cliphist сохранит
qs ipc call clipboard flash 2>/dev/null || true  # подсветить капсулу буфера
