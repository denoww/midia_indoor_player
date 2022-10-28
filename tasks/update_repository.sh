#!/bin/bash
cd /var/lib/sc_player/

# sudo /bin/chown pi:pi -R .
/usr/bin/git reset --hard
/usr/bin/git clean -f
/usr/bin/git pull

/usr/bin/npm install
/usr/bin/npx electron-rebuild
