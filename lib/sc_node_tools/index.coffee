# Vendorizado de https://github.com/denoww/sc-node-tools (v1.4.4, PSC-27).
# Pacote npm depreciado — a dependência foi internalizada pra eliminar
# supply-chain (owners npm antigos) e a subárvore `request`/tough-cookie
# que as versões <1.4.4 puxavam. Não recriar a dependência externa.
# scChannel.coffee ficou de fora de propósito: este repo não usa e ele
# exigiria adicionar `axios` como dependência.
require './array'
require './date'
require './object'
require './scErrorsHandle'
require './scPrint'
require './string'
require './functions'
