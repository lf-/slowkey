#!/bin/bash
mkdir "slowkey_${1}"
find . -maxdepth 1 -not -iname '*.zip' -not -name .git -not -name 'slowkey_*' -not -name 'package.sh' -not -path . -exec cp -r '{}' "slowkey_${1}" ';'
zip -r "slowkey_${1}.zip" "slowkey_${1}"