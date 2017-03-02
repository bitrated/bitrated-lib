qs = require 'querystring'
{ format_satoshis } = require '../cryptocoin/util'

# TODO: this shouldn't be here, move elsewhere (part of coininfo?)
currency_map = BTC: 'bitcoin', 'BTC-TEST': 'bitcoin', LTC: 'litecoin', DOGE: 'dogecoin'

# Get a "bitcoin:" payment URI for a trade
module.exports = ({ currency, seller, id, multisig }, amount) ->
  "#{ currency_map[currency] }:#{multisig}?" + qs.stringify
    amount: format_satoshis amount
    label: "#{ seller } (#{ id })"
