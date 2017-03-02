# Generic handling for p2sh multi-signature transactions
#
# ASSUMPTIONS:
# - All inputs are from the multisig, does not work when combined with others
# - All signatures are using the same hash_type, SIGHASH_ALL by default

Script = require 'btc-script'
{ map: { OP_0 } } = require 'btc-opcode'
Key = require './key'
SIGHASH_ALL = 1

# Sign `tx` with `key`, where all inputs are to be redeemed with `redeem_script`,
# keeping previous signatures in place and in correct order
sign_multisig = (key, tx, redeem_script, hash_type=SIGHASH_ALL) ->
  pubkeys = redeem_script.extractPubkeys().map (pubkey) -> new Buffer pubkey
  hpubkeys = pubkeys.map (pubkey) -> pubkey.toString 'hex'

  throw new Error 'Invalid key' unless key.pub.toString('hex') in hpubkeys

  tx.ins.forEach (inv, i) ->
    sighash = new Buffer tx.hashTransactionForSignature redeem_script, i, hash_type
    sigs = get_script_sigs pubkeys, inv.script, sighash, hash_type
    sigs[key.pub.toString 'hex'] = key.sign sighash

    in_script = new Script
    in_script.writeOp OP_0
    # Write signatures in the same order as their pubkeys
    for pubkey_hex in hpubkeys when sig = sigs[pubkey_hex]
      in_script.writeBytes [ sig..., hash_type ]
    in_script.writeBytes redeem_script.buffer

    inv.script = in_script

  tx

# Get the previous signatures, on an object map with the signing public key as the hash key
get_script_sigs = (pubkeys, script, sighash, hash_type) ->
  return {} unless script.chunks.length

  unless script.chunks[0] is OP_0 and script.chunks.length >= 2
    throw new Error 'Invalid script'

  pubkeys = pubkeys[..] # clone
  sigs = {}
  for sig in script.chunks[1...-1]
    unless sig[sig.length-1] is hash_type
      throw new Error 'Invalid hash type in signature'
    sig = new Buffer sig[...-1]
    unless signer = get_signer pubkeys, sig, sighash
      throw new Error 'Invalid signature'
    sigs[signer.toString 'hex'] = sig
    # Remove all public keys up to the current signing key.
    # Signatures must be in the same order as pubkeys, meaning that pubkeys
    # before the current one cannot be used for the next sigs.
    pubkeys.splice 0, pubkeys.indexOf(signer)+1
  sigs

# Get the signing public key that created `sig` over `sighash`
get_signer = (pubkeys, sig, sighash) ->
  for pubkey in pubkeys when Key.from_pub(pubkey).verify sighash, sig
    return pubkey
  return

module.exports = { sign_multisig, get_script_sigs }
