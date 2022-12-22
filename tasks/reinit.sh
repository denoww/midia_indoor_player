#!/bin/bash

verify_servers(){
  SERVICE_NODE="node server.js"
  SERVICE_PLAYER="chromium"
  # SERVICE_PLAYER="node_modules/electron"


  NODE_RUNNING="$(pgrep -f "$SERVICE_NODE")"
  PLAYER_RUNNING="$(pgrep -f "$SERVICE_PLAYER")"

  if [ -z "$NODE_RUNNING" ] && [ -z "$PLAYER_RUNNING" ]; then
    echo "starting servers!"

    export DISPLAY=":0"
    /var/lib/midia_indoor_player/tasks/./init.sh

  elif [ -z "$NODE_RUNNING" ]; then
    echo "starting node server!"

    export DISPLAY=":0"
    cd /var/lib/midia_indoor_player/
    /usr/bin/npm run start-node

  elif [ -z "$PLAYER_RUNNING" ]; then
    echo "starting player!"

    export DISPLAY=":0"
    /var/lib/midia_indoor_player/tasks/./init_player.sh

  else
    echo "servers are running!"
  fi
}

verify_servers
