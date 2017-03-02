{ find_txr_to } = require '../tx-request'
base = require './item'

module.exports = (username, trade) ->
  locals  = base username, trade
  locals.trade.txs?.reverse() # newest first

  locals.find_txr_to = (user) ->
    # Yikes. The only place in bitrated-lib that requires separate handling for
    # the browser and server-side environment. Very hacky and hairy solution,
    # should be changed at some point.
    if window?
      if txr = find_txr_to trade.toObject(), user
        new trade.txs.model(txr).toJSON()
    else find_txr_to(trade, user)?.toJSON()

  if trade.disputed
    for log in locals.trade.logs when log.action is 'dispute'
      locals.dispute_log_id = "logmsg-#{ log.id }"
      break

  locals
