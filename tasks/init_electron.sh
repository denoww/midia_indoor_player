#!/bin/bash
export DISPLAY=":0"
/usr/bin/xdotool mousemove --sync 4000 4000

cd /var/lib/sc_player/
/usr/bin/npm run start-electron &

# cliques na tela para simular acao do usuario para corrigir problema
# de play nos videos
array=( 200 150 100 50 )
for i in "${array[@]}"
do
  sleep 5 && /usr/bin/xdotool mousemove --sync $i $i click 1 \
  mousemove_relative --sync 4000 4000
done
