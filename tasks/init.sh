#!/bin/bash

projectPath=$(builtin cd "$(dirname $0)/.."; pwd)

echo "iniciando $projectPath"
sleep 10 # esperar uma conexao com a internet
export DISPLAY=":0.0"
# /usr/bin/xdotool mousemove --sync 4000 4000

killall node

cd $projectPath
/usr/bin/git pull &
/usr/bin/npm start &

# cd $projectPath
# /usr/bin/git pull &
# sleep 1m && /usr/bin/npm run update_timezone &
# /usr/bin/npm start &

# a cada x minutos verifica se tá rodando, senão chama o reinit.sh
while [[ true ]]
do
  sleep 2m
  $projectPath/tasks/./reinit.sh
done

# cliques na tela para simular acao do usuario para corrigir problema
# de play nos videossudo
# array=( 200 150 100 50 )
# for i in "${array[@]}"
# do
#   sleep 5 && /usr/bin/xdotool mousemove --sync $i $i click 1 \
#   mousemove_relative --sync 4000 4000
# done
