# shell   = require 'shelljs'
# request = require 'request'

# do ->
#   url = 'http://ip-api.com/json'
#   console.info '>> Atualizando Timezone!'
#   console.info "URL", url

#   console.log "Descobrindo timezone..."
#   request url, (error, response, body)=>
#     if error || response?.statusCode != 200
#       erro = 'Request Failed.'
#       erro += " Status Code: #{response.statusCode}." if response?.statusCode
#       erro += " #{error}" if error
#       console.error erro
#       return

#     data = JSON.parse(body)
#     timezone = data.timezone
#     unless timezone
#       console.log "timezone não encontrado"
#       return

#     command = "sudo ln -f -s /usr/share/zoneinfo/#{data.timezone} /etc/localtime"
#     console.log "Modificando timezone..."
#     shell.exec command, (code, out, error)->
#       return console.log 'Timezone -> Error:', error if error
#       console.log "Timezone atualizado para #{timezone}"
