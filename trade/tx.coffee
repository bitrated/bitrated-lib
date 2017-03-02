# Trade-specific handling for creating and parsing transactions
#
# ASSUMPTIONS:
# - All inputs belong to the trade, cannot mix with other inputs

srand = require 'seed-random'
shuffle = require 'shuffle-array'
{ Transaction } = require 'btc-transaction'
{ num_to_bytes, bytes_to_num } = require '../conv'
{ UserError } = require '../errors'
{ to_ccAddress, script_to_addr } = require '../cryptocoin/addr'
{ sum_outputs } = require './outputs'
{ get_userinfo } = require './index'
{ fees_for_trade } = require './arb-fees'
{ get_trade_hash } = require './multisig'

# backward compatibility: old trades have no fee amount associated with them,
# use the old fixed value for them
LEGACY_FEE = 10000

# Make a transaction paying all from `trade` to `recipients`
make_tx = (trade, recipients...) ->
  tx = new Transaction
  # Add all confirmed and unspent outputs as inputs
  for output in trade.outputs when output.block? and not output.spender?.txid?
    tx.addInput { hash: output.txid.toString('hex') }, output.index
  # Randomize output order, to prevent leaking the users roles
  rng = srand get_trade_hash(trade).toString('base64')
  recipients = shuffle recipients, { rng, copy: true }
  # Add all recipients as outputs
  for { address, amount } in recipients
    tx.addOutput (to_ccAddress trade.currency, address), (num_to_bytes amount)
  tx

# Make a transaction sending everything to `username`
make_tx_to = (trade, username) ->
  { address } = (get_userinfo username, trade) or throw new Error 'User not part of trade'

  balance = sum_outputs trade, spent: false, confirmed: true
  arb_fees = fees_for_trade trade
  total_fees = (+trade.meta.miner_fee or LEGACY_FEE) + arb_fees

  unless balance > total_fees
    throw new UserError 'Insufficient funds'

  recipients = [ { address, amount: balance - total_fees } ]

  if arb_fees
    recipients.push address: (get_userinfo trade.arbiter, trade).address, amount: arb_fees

  make_tx trade, recipients...

# Parse `tx` paying out from `trade`
parse_tx = (trade, tx, allow_spent) ->
  total_in = sum_outputs get_used_outs trade, tx, allow_spent
  total_out = 0

  labels = get_user_addresses trade
  labels[trade.multisig] = 'Multisig change'

  recipients = for out in tx.outs
    total_out += amount = bytes_to_num out.value
    
    address: address = script_to_addr trade.currency, out.script
    label: labels[address]
    amount: amount

  tx_fees = total_in - total_out
  throw new UserError 'Insufficient funds' unless tx_fees >= 0

  { total_in, total_out, tx_fees, recipients }

# Get address labels
get_user_addresses = (trade) ->
  labels = {}
  labels[address] = user for { user, address } in trade.users_info
  labels

# Get the outputs from `trade` used an inputs for `tx`
get_used_outs = (trade, tx, allow_spent) ->
  tx.ins.map (inv) ->
    for out in trade.outputs when out.txid.toString('hex') is inv.outpoint.hash \
                              and out.index is inv.outpoint.index
      throw new UserError 'Transaction input not confirmed' unless out.block?
      throw new UserError 'Transaction input already spent' if not allow_spent and out.spender?.txid?
      return out
    throw new UserError "Transaction input not found (#{ inv.outpoint.hash }:#{ inv.outpoint.index })"

# Just to avoid a direct dependency on btc-transaction in other places
deserialize_tx = Transaction.deserialize

module.exports = { make_tx, make_tx_to, parse_tx, deserialize_tx, get_used_outs, get_user_addresses }
