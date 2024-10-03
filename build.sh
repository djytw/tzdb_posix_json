#!/bin/bash

set -e

# sudo apt-get install wget lzip tar gcc make

rm -rf build
mkdir -p build
cd build

echo "Downloading latest tzdb..."

wget https://data.iana.org/time-zones/tzdb-latest.tar.lz
tar -xf tzdb-latest.tar.lz --strip-components=1
version=`cat version`
if diff ../version version > /dev/null 2>&1 ; then
    echo "On latest version $version, skip build"
    exit 0
else
    echo "New version $version found, start building"
fi
cat version > ../version
make

mkdir -p output
./zic main.zi -d output

echo "Build OK"
echo "Generating JSON..."

cd output
for i in `find -type f`; do
    tz=`tail -n 1 $i`
    echo "${i:2}=$tz" | jq -R './"=" | {key:first,value:last}'
done | jq -s -S  'from_entries' > ../../tz.json

echo "Generating OK"

cd ../..
printf "# tzdb_posix_json\n\n" > README.md
printf "Converts official [iana tzdb](https://www.iana.org/time-zones) to POSIX tz strings and output JSON file\n\n" >> README.md
printf "Current version \`$version\`\n\n" >> README.md
