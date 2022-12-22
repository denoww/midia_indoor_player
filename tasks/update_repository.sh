#!/bin/bash
projectPath=$(builtin cd "$(dirname $0)/.."; pwd)

cd $projectPath

# sudo /bin/chown pi:pi -R .
/usr/bin/git reset --hard
/usr/bin/git clean -f
/usr/bin/git pull

/usr/bin/npm install
# /usr/bin/npx electron-rebuild
