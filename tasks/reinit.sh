#!/bin/bash

projectPath=$(builtin cd "$(dirname $0)/.."; pwd)


verify_servers(){
  SERVICE_NODE="node server.coffee"
  # SERVICE_NODE="node server.js"
  SERVICE_PLAYER="chromium"
  # SERVICE_PLAYER="node_modules/electron"


  NODE_RUNNING="$(pgrep -f "$SERVICE_NODE")"
  PLAYER_RUNNING="$(pgrep -f "$SERVICE_PLAYER")"

  if [ -z "$NODE_RUNNING" ] && [ -z "$PLAYER_RUNNING" ]; then
    echo "starting servers!"

    export DISPLAY=":0"
    $projectPath/tasks/./init.sh

  elif [ -z "$NODE_RUNNING" ]; then
    echo "starting node server!"

    export DISPLAY=":0"
    cd $projectPath/
    /usr/bin/npm run start_fullscreen

  elif [ -z "$PLAYER_RUNNING" ]; then
    echo "starting player!"

    export DISPLAY=":0"
    $projectPath/tasks/./init_player.sh

  else
    echo "servers are running!"
  fi
}

verify_servers
