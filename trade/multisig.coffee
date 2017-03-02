# Trade-specific handling for multi-signature creation

{ createMultiSigOutputScript } = require 'btc-script'
{ sha256 } = require 'crypto-hashing'
stringify = require 'json-stable-stringify'
Key = require '../cryptocoin/key'
addr = require '../cryptocoin/addr'
derive = require '../cryptocoin/derive'
{ using } = require '../util'
{ normalize_contract_names } = require './index'

HASH_SALT = 'Bitrated-Contract;'

# Conver binary BSON objects from Mongoose to standard Buffer
normalize_buff = (buff) ->
  if buff._bsontype is 'Binary' then buff.buffer
  else buff

# Create 2-of-3 multisig script for `trade`
create_multisig_script = (trade) ->
  pubkeys = trade.users_info
    # extract public keys
    .map ({ pubkey }) -> pubkey
    # determinstic ordering
    .sort (a, b) -> if a.toString('hex') < b.toString('hex') then 1 else -1
    # createMultiSigOutputScript expects byte arrays
    .map (pubkey) -> Array.apply null, pubkey

  createMultiSigOutputScript 2, pubkeys, true

# Create 2-of-3 multisig address for `trade`
create_multisig_address = (trade) ->
  addr.encode trade.currency, 'scripthash', create_multisig_script(trade).buffer

# Get the public key used by `user` for `trade`
get_trade_pubkey = (trade, user) ->
  contract_key = Key.from_pub normalize_buff user.subkeys.contract
  derive contract_key, get_trade_hash trade, user

# Create unique hash for trade, used for HD derivation and random seed
get_trade_hash = (trade, user) ->
  sha256 HASH_SALT + stringify using trade, ->
    data = {
      @id, @buyer, @seller, @arbiter
      @description, @amount, @currency, @contract
      @arb_fees
    }
    # LEGACY - fix for bug caused by the seller being invited by email.
    # the username is still unknown when the trade was created,
    # so the buyer used the email address
    #
    # Can be removed once no trades in this state exists
    if user and trade.meta?.hash_email_fix and user.username in trade.meta.hash_email_fix_users
      data.seller = trade.meta.hash_email_fix

    # New fix for users invited by email via the normalize_contract_names utility
    data = normalize_contract_names trade, data

    data

module.exports = {
  create_multisig_script, create_multisig_address
  get_trade_pubkey, get_trade_hash
}
