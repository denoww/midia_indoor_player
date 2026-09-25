shell = require 'shelljs'
fs = require 'fs'


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

# Listas de conteúdo de uma grade (ou de um item de playlist): toda chave
# `conteudo_*` que é Array. Antes eram fixas (`conteudo_superior` e
# `conteudo_mensagem`); com a tela dividida (ERP ticket #2447) chegam também
# `conteudo_regiao_2..4`, e lista fixa esquecia essas no warmup e nos feeds.
global.posicoesConteudo = (obj) ->
  return [] unless obj && typeof obj is 'object'
  (key for own key, val of obj when /^conteudo_/.test(key) and Array.isArray(val))


getDirectories = (path) ->
  fs.readdirSync(path).filter (file) ->
    fs.statSync(path + '/' + file).isDirectory()

global.apagarArquivosAntigosDaGrade = ->
  tvIdsPastas = getDirectories(pastaPublic())
  for tvId in tvIdsPastas
    global.feeds.apagarAntigos(tvId)
    global.grade.apagarAntigos(tvId)

global.removerMidiasAntigas = (tvId, pasta, arquivosAtuais) ->
  caminho = "#{getTvFolderPublic(tvId)}/#{pasta}/"
  console.log "tv #{tvId} - Verificando #{caminho}"

  itens = []
  for it in arquivosAtuais
    itens.push "-name '#{it}'"

  naoApagarArquivosAtuais = ''
  naoApagarArquivosAtuais = "! \\( #{itens.join(' -o ')} \\)" if itens.any()
  command = "find #{caminho} -type f #{naoApagarArquivosAtuais} -delete"

  shell.exec command, (code, out, error)->
    return global.logs.error "#{pasta} -> deleteOldImages #{error}", tags: class: pasta if error
    global.logs.create "tv #{tvId} - #{pasta} -> Midias antigas APAGADAS!"
