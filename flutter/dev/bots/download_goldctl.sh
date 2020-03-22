#!/usr/bin/env bash

git clone --depth 1 https://chromium.googlesource.com/chromium/tools/depot_tools.git ./depot_tools
cd depot_tools
echo -e '# Ensure File\n$ServiceURL https://chrome-infra-packages.appspot.com\n\n# Skia Gold Client goldctl\nskia/tools/goldctl/${platform} latest' > ensure.txt
./cipd ensure -ensure-file ./ensure.txt -root .
