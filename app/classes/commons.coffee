shell = require 'shelljs'


global.restartApp = ->
  scPrint.warning '-----------------------------------------'
  scPrint.warning 'Reiniciando app...'
  scPrint.warning '-----------------------------------------'
  restartFile = require('path').resolve(process.cwd(), 'restart.js')
  shell = require("child_process").exec
  shell "touch #{restartFile}"

global.pastaPublic = -> "#{process.cwd()}/public"
global.getTvFolder = (tvId) -> "#{tvId}"
global.getTvFolderPublic = (tvId) -> "#{pastaPublic()}/#{getTvFolder(tvId)}"




global.apagarArquivosAntigosDaGrade = ->

  # require('../app/classes/feeds')()

  global.feeds.apagarAntigos()
  apagarOutrasMidias()

apagarOutrasMidias = ->
  fs = require 'fs'

  pastas = {}

  data = {}
  try
    data = JSON.parse(fs.readFileSync('grade.json', 'utf8') || '{}')
  catch e
  for it in data.conteudo_superior
    for it2 in it.conteudo_superior
      pasta = it2.pasta
      nomeArquivo = it2.nome_arquivo
      if pasta && nomeArquivo
        pastas[pasta] ||= []
        pastas[pasta].push nomeArquivo

  for pasta, arquivos of pastas
    removerMidiasAntigas(pasta, arquivos)



global.removerMidiasAntigas = (pasta, arquivosAtuais) ->
  caminho = "#{getTvFolder(tvId)}#{pasta}/"
  console.log "Verificando #{caminho}"

  itens = []
  for it in arquivosAtuais
    itens.push "-name '#{it}'"

  command = "find #{caminho} -type f ! \\( #{itens.join(' -o ')} \\) -delete"
  shell.exec command, (code, out, error)->
    return global.logs.error "#{pasta} -> deleteOldImages #{error}", tags: class: pasta if error
    global.logs.create "#{pasta} -> Midias antigas APAGADAS!"
