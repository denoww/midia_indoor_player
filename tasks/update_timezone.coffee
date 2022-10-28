shell   = require 'shelljs'
request = require 'request'

do ->
  setTimeout ->
    url = 'http://ip-api.com/json'
    console.info '>> Atualizando Timezone!'
    console.info "URL", url

    request url, (error, response, body)=>
      if error || response?.statusCode != 200
        erro = 'Request Failed.'
        erro += " Status Code: #{response.statusCode}." if response?.statusCode
        erro += " #{error}" if error
        console.error erro
        return

      data = JSON.parse(body)
      return unless data.timezone

      command = "sudo ln -f -s /usr/share/zoneinfo/#{data.timezone} /etc/localtime"
      shell.exec command, (code, out, error)->
        return console.log 'Timezone -> Error:', error if error
        console.log 'Timezone atualizado!'
  , 1 * 60 * 1000 # 1 minuto
  return
