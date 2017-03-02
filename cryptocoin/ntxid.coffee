Script = require 'btc-script'
{ Transaction } = require 'btc-transaction'

get_ntxid = (tx) ->
  tx = if tx instanceof Transaction then tx.clone() \
       else Transaction.deserialize tx
  inv.script = new Script for inv in tx.ins
  tx.serialized = null # Invalidate previous serialization
  new Buffer tx.getHash()

module.exports = get_ntxid
