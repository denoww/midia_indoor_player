#!/bin/bash
# ⚠️ DESCONTINUADO (19/09/2026) — modo de instalação Linux/Raspberry Pi /
# Orange Pi. Sem manutenção real desde 2023, sem evidência de nenhum device
# vivo em produção hoje. O parque atual roda no app Android `corpflix`
# (repo denoww/corpflix) ou, como frota legada ainda viva, em Windows via
# Chrome kiosk (ver README § "Config windows" — esse SIM continua em uso,
# ~30 TVs, e o Chrome dele se autoatualiza sozinho, sem ação necessária).
# Contexto completo: ROADMAP_dependencias_criticas.md item #26 (repo
# seucondominio).
export DISPLAY=":0"
# /usr/bin/xdotool mousemove --sync 4000 4000

projectPath=$(builtin cd "$(dirname $0)/.."; pwd)


cd $projectPath
/usr/bin/npm run start_player_fullscreen &

# cliques na tela para simular acao do usuario para corrigir problema
# de play nos videos
# array=( 200 150 100 50 )
# for i in "${array[@]}"
# do
#   sleep 5 && /usr/bin/xdotool mousemove --sync $i $i click 1 \
#   mousemove_relative --sync 4000 4000
# done
