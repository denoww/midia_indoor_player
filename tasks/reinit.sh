#!/bin/bash

verify_servers(){
  SERVICE_NODE="node server.js"
  SERVICE_ELECTRON="node_modules/electron"

  NODE_RUNNING="$(pgrep -f "$SERVICE_NODE")"
  ELECTRON_RUNNING="$(pgrep -f "$SERVICE_ELECTRON")"

  if [ -z "$NODE_RUNNING" ] && [ -z "$ELECTRON_RUNNING" ]; then
    echo "starting servers!"

    export DISPLAY=":0"
    /var/lib/sc_player/tasks/./init.sh

  elif [ -z "$NODE_RUNNING" ]; then
    echo "starting node server!"

    export DISPLAY=":0"
    cd /var/lib/sc_player/
    /usr/bin/npm run start-node

  elif [ -z "$ELECTRON_RUNNING" ]; then
    echo "starting electron server!"

    export DISPLAY=":0"
    /var/lib/sc_player/tasks/./init_electron.sh

  else
    echo "servers are running!"
  fi
}

verify_servers
