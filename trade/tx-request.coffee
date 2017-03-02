{ Transaction } = require 'btc-transaction'
{ UserError } = require '../errors'
{ buff_eq } = require '../util'
{ bytes_to_num } = require '../conv'
get_ntxid = require '../cryptocoin/ntxid'
{ script_to_addr } = require '../cryptocoin/addr'
{ get_script_sigs } = require '../cryptocoin/multisig'
{ get_userinfo } = require './index'
{ get_used_outs, make_tx_to } = require './tx'
{ fees_for_trade } = require './arb-fees'
{ create_multisig_script } = require './multisig'

SIGHASH_ALL = 1
MAX_TX_SIZE = 4096

# Parse and validate `tx` request for `trade`
#
# Validates basic tx structure, inputs and that fees are paid -
# but does NOT validate signatures (see verify_tx_sigs for that)
parse_tx_request = (trade, tx) ->
  tx = new Buffer tx, 'base64' if typeof tx is 'string'
  unless tx instanceof Transaction
    if tx.length > MAX_TX_SIZE
      throw new UserError 'Invalid transaction'
    unless tx = Transaction.deserialize tx
      throw new UserError 'Invalid transaction'

  rawtx = new Buffer tx.serialized or tx.serialize()
  ntxid = get_ntxid tx

  # Rertieve and validate the inputs (throws errors for invalid ones)
  spent_outs = get_used_outs trade, tx

  # Verify arbitration fees
  unless verify_arb_fees trade, tx
    throw new UserError 'Must include trust agent fees', status: 402

  # Get the primary user being paid out, if one exists
  for role in [ 'buyer', 'seller' ] when buff_eq ntxid, get_ntxid make_tx_to trade, trade[role]
    paying_to = trade[role]
    break

  { tx, spent_outs, rawtx, ntxid, paying_to }

# Find a transaction request sending the funds to `username`
find_txr_to = (trade, username) ->
  try # invalid cases (e.g. no funds to make txs) should return undefined without throwing
    ntxid = get_ntxid make_tx_to trade, username
    return txr for txr in trade.txs when buff_eq txr.ntxid, ntxid

# Verify arbitration fees are being paid
# @private
verify_arb_fees = (trade, tx) ->
  arb_fees = fees_for_trade trade
  return true if arb_fees is 0
  arb_addr = get_userinfo(trade.arbiter, trade).address
  tx.outs.some (out) ->
    (script_to_addr trade.currency, out.script) is arb_addr and \
    (bytes_to_num out.value) >= arb_fees

# Verify `tx` is properly signed by `users`
verify_tx_sigs = (trade, tx, users, hash_type=SIGHASH_ALL) ->
  redeem_script = create_multisig_script trade

  # Get the pubkeys belonging to `users`
  users_pubkeys = users.map (user) ->
    get_userinfo(user, trade)?.pubkey or throw new Error 'Invalid user, cannot fund pubkey'

  # Filter the user pubkeys from the multisig pubkeys, to get them in correct order
  pubkeys = redeem_script.extractPubkeys()
    .map (pubkey) -> new Buffer pubkey
    .filter (pubkey) -> users_pubkeys.some (upubkey) -> buff_eq upubkey, pubkey
  unless pubkeys.length is users_pubkeys.length
    throw new Error 'Some users pubkeys not found in multisig pubkeys'

  hpubkeys = pubkeys.map (pubkey) -> pubkey.toString 'hex'

  try tx.ins.every (inv, i) ->
    sighash = new Buffer tx.hashTransactionForSignature redeem_script, i, hash_type
    signees = Object.keys get_script_sigs pubkeys, inv.script, sighash, hash_type

    signees.length is hpubkeys.length and \
    hpubkeys.every (hpubkey) -> hpubkey in signees
  catch err then console.error err; false

module.exports = { parse_tx_request, verify_tx_sigs, find_txr_to }
