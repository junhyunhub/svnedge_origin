#!/usr/bin/with-contenv bash
set -e

# Set permissions on data folder if envvar is set
if [ "$SET_PERMS" = "true" ]; then
    echo "SET_PERMS is true .. setting owner to svnedge on data folder"
    chown -R svnedge:svnedge /home/svnedge/csvn/data
fi
