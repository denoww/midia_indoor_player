fs    = require 'fs'
path  = require 'path'
shell = require 'shelljs'

module.exports = ->
  ctrl =
    init: ->
      @versionFile    = path.join(__dirname, '../../.current_version')
      @pathUpdates    = path.join(__dirname, '../../tasks/updates/')
      @updating       = false
      @gradeVersion   = null
      @currentVersion = null
      @getCurrentVersion()
    exec: (forceUpdate=false)->
      @versions = []
      @getGradeVersion()
      return unless @gradeVersion

      if @gradeVersion != @currentVersion || forceUpdate
        @getVersionsFile ->
          if ctrl.versions.length
            ctrl.sendLog 'Atualizado Player!', 'create'
            ctrl.execUpdateRepository ->
              ctrl.callNextVersion()
          else
            ctrl.saveCurrentVersion(ctrl.gradeVersion, forceUpdate)
      return
    getGradeVersion: ->
      return unless global.versao_player
      ctrl.gradeVersion = global.versao_player

      return unless typeof ctrl.gradeVersion == 'string'
      ctrl.gradeVersion = parseFloat ctrl.gradeVersion

      unless ctrl.gradeVersion
        ctrl.sendLog "Erro na versão do player", 'error',
          grade_version: global.versao_player
      return
    getCurrentVersion: (callback)->
      fs.readFile ctrl.versionFile, 'utf8', (error, contents)->
        if error && error.code != 'ENOENT'
          return ctrl.sendLog "getCurrentVersion -> #{error}"

        contents ||= 0.1
        ctrl.currentVersion = parseFloat contents
        callback?()
      return
    getVersionsFile: (callback)->
      fs.readdir ctrl.pathUpdates, (error, files)->
        return ctrl.sendLog "getVersionsFile -> #{error}" if error
        ctrl.versions ||= []

        for file in files
          fileVersion = file.match(/version-(\d+\.*\d*).sh/)?[1]

          if fileVersion
            fileVersion = parseFloat fileVersion

            if fileVersion > ctrl.currentVersion && fileVersion <= ctrl.gradeVersion
              ctrl.versions.push version: fileVersion, fileName: file

        ctrl.versions = ctrl.versions.sortByField('version')
        callback?()
      return
    callNextVersion: ->
      return if !ctrl.currentVersion || (ctrl.versions || []).empty()

      if ctrl.currentVersion > ctrl.gradeVersion
        return ctrl.saveCurrentVersion(ctrl.gradeVersion)

      unless ctrl.currentVersion == ctrl.gradeVersion
        for obj in ctrl.versions || []
          continue if obj.version <= ctrl.currentVersion || obj.version > ctrl.gradeVersion
          return ctrl.execUpdateToVersion(obj)
    execUpdateToVersion: (obj)->
      return unless obj?.version
      arquivo = path.join(ctrl.pathUpdates, obj.fileName)
      ctrl.sendLog "Atualizando para #{obj.version}", 'create'

      # verificar se existe arquivo de update para esta versao
      fs.stat arquivo, (error)->
        return ctrl.sendLog "Erro ao pegar arquivo: #{obj.version} - #{error}" if error

        # evitando rodar .sh em development
        return ctrl.saveCurrentVersion(obj.version) if ENV.NODE_ENV == 'development'

        # if !(obj.fileName == 'version-1.8.sh' && ['5', 5].includes(ENV.TV_ID))
        #   ctrl.sendLog "ignorando update para : #{ENV.TV_ID}"
        #   ctrl.saveCurrentVersion(obj.version, !ctrl.versions.length)
        #   return

        ctrl.updating = true
        # se o arquivo existe entao executa a atualizacao
        shell.exec "#{ctrl.pathUpdates}./#{obj.fileName}", (code, out, error)->
          if error && error.match(/erro/gi)
            ctrl.updating = false
            return ctrl.sendLog "Erro ao atualizar: #{obj.version} - #{error}"

          ctrl.updating = false
          ctrl.sendLog "Atualizado para #{obj.version}!", 'info'
          ctrl.versions.removeByField('version', obj.version)
          ctrl.saveCurrentVersion(obj.version, !ctrl.versions.length)
      return
    execUpdateRepository: (callback)->
      return callback?() if ENV.NODE_ENV == 'development'

      folder = path.join(__dirname, '../../tasks/')
      shell.exec "#{folder}./update_repository.sh", (code, out, error)->
        ctrl.sendLog "execUpdateRepository -> #{error}" if error
        callback?()
      return
    saveCurrentVersion: (version, updateRepository=false)->
      return unless version
      version = version + ''
      fs.writeFile ctrl.versionFile, version, 'utf8', (error)->
        return ctrl.sendLog "saveCurrentVersion -> #{error}" if error
        ctrl.currentVersion = version

        return ctrl.callNextVersion() if ctrl.versions.length
        if updateRepository
          ctrl.execUpdateRepository ->
            try
              { app } = require 'electron'
              app?.relaunch({ args: process.argv.slice(1).concat(['--relaunch']) })
              app?.exit(0)
            catch e
              ctrl.sendLog "saveCurrentVersion -> #{e}"
      return
    sendLog: (message, level='error', extra={})->
      global.logs[level] message, tags: { class: 'versions_control' }, extra: extra
  ctrl.init()
  global.versionsControl = ctrl
