#!/bin/bash
resdir=${1}

cp -r ${resdir} .
find ./Result/ -name "*_files" -print0 | xargs -0 -i rm -rf {}
find ./Result/ -name "*.html" ! -name "krona.html" -print0 | xargs -0 -i rm -f {}