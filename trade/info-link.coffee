links =
  BTC:
    address: 'https://blockchain.info/address/%s'
    tx: 'https://blockchain.info/tx/%s'
  'BTC-TEST':
    address: 'https://www.blocktrail.com/tBTC/address/%s'
    tx: 'https://www.blocktrail.com/tBTC/tx/%s'
  DOGE:
    address: 'https://dogechain.info/address/%s'
    tx: 'https://dogechain.info/tx/%s'

module.exports = (currency, type, str) ->
  links[currency][type].replace '%s', encodeURIComponent str

