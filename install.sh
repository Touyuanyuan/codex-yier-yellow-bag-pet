#!/bin/bash
# Offline installer. Compatible with the Bash 3.2 shipped with macOS.
set -eu

fail() { printf '安装未完成 / Installation failed: %s\n' "$*" >&2; exit 1; }
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
source_dir="$script_dir/pet"

if [ "$#" -gt 1 ]; then
    fail 'Usage: bash install.sh [CODEX_HOME]'
fi
if [ "$#" -eq 1 ]; then
    [ -n "$1" ] || fail 'The supplied CODEX_HOME must not be empty.'
    codex_dir=$1
elif [ -n "${CODEX_HOME:-}" ]; then
    codex_dir=$CODEX_HOME
else
    [ -n "${HOME:-}" ] || fail 'HOME is unavailable; supply a Codex directory explicitly.'
    codex_dir="$HOME/.codex"
fi

for name in pet.json spritesheet.webp; do
    [ -f "$source_dir/$name" ] && [ -s "$source_dir/$name" ] ||
        fail "Missing pet/$name. Extract the entire ZIP before installing."
done

# macOS includes plutil; no Python, Node.js, Homebrew or network is required.
if [ "$(uname -s)" = Darwin ]; then
    manifest="$source_dir/pet.json"
    [ "$(/usr/bin/plutil -extract id raw -o - "$manifest")" = yier-yellow-bag ] &&
    [ "$(/usr/bin/plutil -extract displayName raw -o - "$manifest")" = 小黄包一二 ] &&
    [ "$(/usr/bin/plutil -extract spriteVersionNumber raw -o - "$manifest")" = 2 ] &&
    [ "$(/usr/bin/plutil -extract spritesheetPath raw -o - "$manifest")" = spritesheet.webp ] ||
        fail 'pet.json is not the Little Yellow Bag Yier v2 manifest.'
fi

pets_dir="$codex_dir/pets"
target="$pets_dir/yier-yellow-bag"
[ ! -L "$target" ] || fail "The destination is a symbolic link: $target"

selection_help() {
    printf '\n安装位置 / Installed location: %s\n' "$target"
    printf '%s\n' '回到 Codex：设置 → Mini 与虚拟宠物（或 Pets）→ 刷新 ↻ → 选择「小黄包一二」。'
    printf '%s\n' '若仍显示旧版云端宠物，请参照 README 中的更新说明。'
}

if [ -e "$target" ]; then
    if [ -d "$target" ] &&
       cmp -s "$source_dir/pet.json" "$target/pet.json" &&
       cmp -s "$source_dir/spritesheet.webp" "$target/spritesheet.webp"; then
        printf '%s\n' '小黄包一二已经安装，无需重复安装 / Already installed.'
        selection_help
        exit 0
    fi
    printf '已有不同内容，未覆盖 / Existing files were preserved: %s\n' "$target" >&2
    printf '%s\n' '请先把旧的 yier-yellow-bag 文件夹移出 pets 留作备份，再安装。' >&2
    exit 2
fi

mkdir -p -- "$pets_dir"
# mkdir reserves a new, empty destination and fails if it already exists.
mkdir -- "$target" || fail "Cannot create a new destination: $target"
complete=0
cleanup() {
    if [ "$complete" -eq 0 ]; then
        # Only remove the two files in the directory created by this invocation.
        rm -f -- "$target/pet.json" "$target/spritesheet.webp"
        rmdir -- "$target" 2>/dev/null || true
    fi
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM
cp -- "$source_dir/pet.json" "$target/pet.json"
cp -- "$source_dir/spritesheet.webp" "$target/spritesheet.webp"
complete=1
printf '%s\n' '小黄包一二安装完成 / Little Yellow Bag Yier installed.'
selection_help
