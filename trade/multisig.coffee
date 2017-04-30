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

# Conver Mongoose binary BSON objects or hex strings to standard Buffer
normalize_buff = (buff) ->
  if typeof buff is 'string' then new Buffer buff, 'hex'
  else if buff?._bsontype is 'Binary' then buff.buffer
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
  (normalize_buff trade.chaincode) \ # use cached chaincode when available
  or sha256 HASH_SALT + stringify using trade, ->
    normalize_contract_names trade, {
      @id, @buyer, @seller, @arbiter
      @description, @amount, @currency, @contract
      @arb_fees
    }

module.exports = {
  create_multisig_script, create_multisig_address
  get_trade_pubkey, get_trade_hash
}
