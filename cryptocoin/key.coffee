assert = require 'assert'
BigInteger = require 'bigi'
{ Point } = require 'ecurve'
coinmsg = require 'coinmsg'
lazy = require 'lazy-prop'
{ curve, ecdsa } = require './index.coffee'
{ PUBKEY_LEN, PUBKEY_C_LEN, PRIVKEY_LEN } = require './const'

class Key
  constructor: (@type, buff, @compressed) ->
    @[@type] = buff

    # If compressed is not defined, determine it according to the public key
    # length or default to true when a private key is provided
    @compressed ?= if type is 'pub' then (buff.length is PUBKEY_C_LEN) else true

    # @TODO support private key with compressed flag and detect it here?
    # @TODO default should be uncompressed?

    if type is 'priv'
      lazy this, pub: -> curve.G.multiply(@priv_bigi).getEncoded(@compressed)
    else
      lazy this, priv: -> throw new Error 'Unknown private key'

  lazy @::,
    # Private key as BigInteger
    priv_bigi: -> BigInteger.fromBuffer @priv

    # Public key point
    pub_point: -> Point.decodeFrom curve, @pub

  # Raw sign/verify
  sign: (data) -> new Buffer ecdsa.serializeSig ecdsa.sign data, @priv
  verify: (data, sig) -> ecdsa.verify data, (ecdsa.parseSig sig), @pub

  # Message sign/verify
  sign_message: (msg) -> coinmsg.sign @priv, msg
  verify_message: (msg, sig) -> coinmsg.verify @pub, sig, msg

  # Returns a new Key instance from public key hex string or buffer
  @from_pub: (pub) ->
    assert @validate_pubkey(pub), 'Invalid public key'
    new Key 'pub', pub

  # Returns a new Key instance for the provided key
  @from_priv: (priv) ->
    assert Buffer.isBuffer(priv), 'Private key should be a buffer'
    assert priv.length is PRIVKEY_LEN, 'Invalid private key length'
    new Key 'priv', priv

  @validate_pubkey: (pubkey) ->
    return false unless Buffer.isBuffer pubkey

    try curve.validate Point.decodeFrom curve, pubkey
    catch err then false

module.exports = Key
