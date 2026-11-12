#!/bin/sh

# Copyright (c) 2025 by Philip Collier, github.com/AB9IL
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

case "$(file -Lb --mime-type -- "$1")" in
image/*)
    chafa -f sixel -s "${2}x${3}" "$1" 2>/dev/null || chafa "$1" -s "${2}x${3}"
    ;;
application/vnd.oasis.opendocument.text)
    odt2txt "$1" 2>/dev/null || pandoc -t plain "$1" 2>/dev/null
    ;;
application/pdf)
    pdftotext "$1" -
    ;;
text/* | application/json)
    bat --color=always --style=plain "$1" 2>/dev/null || cat "$1"
    ;;
*)
    # Archive and other file previews
    case "$1" in
    *.tar*) tar tf "$1" ;;
    *.zip) unzip -l "$1" ;;
    *.rar) unrar l "$1" ;;
    *.7z) 7z l "$1" ;;
    *) echo "lesspipe not installed or could not open file" ;;
    esac
    ;;
esac
