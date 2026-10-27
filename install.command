#!/bin/bash
# Finder opens executable .command files in Terminal.
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P) || exit 1
if [ "$(uname -s)" != Darwin ]; then
    printf '%s\n' '这是 macOS 安装入口。Windows 请使用 install.cmd。' >&2
    exit 1
fi
/bin/bash "$script_dir/install.sh" "$@"
result=$?
if [ -t 0 ]; then
    printf '\n按回车关闭窗口 / Press Return to close… '
    IFS= read -r answer
fi
exit "$result"
