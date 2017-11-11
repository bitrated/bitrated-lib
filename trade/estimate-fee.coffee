request = require 'superagent'
debug   = require('debug')('bitrated:fee-estimate')

TX_EST_FEERATE = +process.env.TX_EST_FEERATE or 100
TX_EST_SIZE    = +process.env.TX_EST_SIZE or 340 # common size for bitrated's txs (2-of-3 multisig spend tx)

UPDATE_INTERVAL = 4 * 60 * 60 * 1000 # 4 hours

last_feerate = null

# @XXX hardcoded support for BTC mainnet and testnet only
estimate_feerate = (currency) -> switch currency
  when 'BTC-TEST' then 20
  when 'BTC'      then last_feerate or TX_EST_FEERATE
  else throw new Error currency + ' not implemented'

estimate_fee = (currency) -> TX_EST_SIZE * estimate_feerate(currency)

# +-5% to make bitrated txs less unique (accurate fee amounts would be a privacy leak)
fuzzy_estimate_fee = (currency) -> Math.floor estimate_fee(currency) * (Math.random()*0.1 + 0.95)

# Fetch fees in background, use the default feerate in the meanwhile
update_feerate = ->
  debug 'updating feerate...'
  request
    .get('https://bitcoinfees.21.co/api/v1/fees/recommended')
    .timeout(5000)
    .end (err, resp) ->
      debug '21 resp: %s %j', err, resp?.body

      if err or not resp.body?.halfHourFee?
        console.log 'bitcoinfees failed', (err?.stack or err), resp?.headers, resp?.body
      else
        # take the average of the 30 minutes fee and the 60 minutes fee (~45 min fee)
        feerate = (resp.body.halfHourFee + resp.body.hourFee) / 2
        # restrict to +-70% of the default feerate
        feerate = Math.min TX_EST_FEERATE*1.7, Math.max TX_EST_FEERATE*0.3, feerate
        # just in case anything went wrong...
        feerate = TX_EST_FEERATE if isNaN feerate

        last_feerate = feerate
        debug 'feerate updated to %d sat/b', last_feerate

      setTimeout update_feerate, UPDATE_INTERVAL

# wait a bit before the first run, to let everything else load first
setTimeout update_feerate, 20000

module.exports = fuzzy_estimate_fee
