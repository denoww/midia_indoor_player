#!/bin/bash
# ⚠️ DESCONTINUADO (19/09/2026) — modo de instalação Linux/Raspberry Pi /
# Orange Pi. Sem manutenção real desde 2023, sem evidência de nenhum device
# vivo em produção hoje. O parque atual roda no app Android `corpflix`
# (repo denoww/corpflix) ou, como frota legada ainda viva, em Windows via
# Chrome kiosk (ver README § "Config windows" — esse SIM continua em uso,
# ~30 TVs, e o Chrome dele se autoatualiza sozinho, sem ação necessária).
# Contexto completo: ROADMAP_dependencias_criticas.md item #26 (repo
# seucondominio).

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
