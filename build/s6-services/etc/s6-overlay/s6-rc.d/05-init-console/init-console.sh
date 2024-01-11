#!/usr/bin/env bash
set -e

# Check if data folder has been initialized
if [[ ! -f "/home/svnedge/csvn/data/conf/mime.types" ]]; then
    echo "Initializing the data folder"
    cp -Rv /home/svnedge/csvn/data-template/* /home/svnedge/csvn/data
fi

echo "Copying dist files to data/conf"
cp -fv /home/svnedge/csvn/dist/* /home/svnedge/csvn/data/conf
