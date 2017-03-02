coinstring = require 'coinstring'
coininfo = require 'coininfo'
{ sha256ripe160 } = require 'crypto-hashing'
{ buff_eq } = require '../util'
{ RIPEMD160_LEN, PRIVKEY_LEN, PRIVKEY_C_LEN, PRIVKEY_C_BYTE } = require './const'

# Wrapper around coinstring with some extra coin-specific 
# utilities and validation


network_versions =
  # SIN is special cased and is not part of coininfo,
  # so its specified manually here.
  SIN: persistent: (new Buffer [ 0x0f, 0x01 ]), ephemeral: (new Buffer [ 0x0f, 0x02 ])

get_versions = (network) -> network_versions[network] ?= do ->
  data = (coininfo network) or throw new Error 'Invalid network'
  versions = {}
  versions[k] = new Buffer [ v ] for k, v of data.versions
  versions

# Turn a byte array to a string address
#
# Example: encode 'BTC', 'public', bytes
encode = (network, type, bytes) ->
  V = get_versions network
  version = V[type] ? throw new Error 'Invalid type'
  # Apply sha256ripemd160 on plain pubkeys/scripts
  if (type in [ 'public', 'scripthash' ] or network is 'SIN') and bytes.length isnt RIPEMD160_LEN
    bytes = sha256ripe160 bytes

  coinstring.encode bytes, version

# Parse and validate base58 addresses
#
# Example: decode 'BTC', address
decode = (network, expected_type, address) ->
  V = get_versions network
  [ address, expected_type ] = [ expected_type, null ] unless address?

  if expected_type?
    expected_version = V[expected_type] ? throw new Error 'Unknown address type'

  bytes = new Buffer coinstring.decode address, expected_version

  if expected_version?
    version = expected_version
  else
    version = bytes[0...1]
    bytes = bytes[1..]

  # Ensure data format matches the version
  switch version.toString('hex')
    when V.public?.toString('hex'), V.scripthash?.toString('hex'), V.ephemeral?.toString('hex')
      unless bytes.length is RIPEMD160_LEN
        throw new Error 'Invalid address length'
    when V.private.toString('hex')
      unless (bytes.length is PRIVKEY_LEN) or \
             (bytes.length is PRIVKEY_C_LEN and bytes[33] is PRIVKEY_C_BYTE)
        throw new Error 'Invalid private key format'
    else
      throw new Error 'Invalid address version'

  { version, bytes }

# Validate address
#
# `types` can be an array of expected types or a single type
# Example: validate 'BTC', [ 'public', 'scripthash' ], address
validate = (network, types, address) ->
  V = get_versions network
  [ address, types ] = [ types, null ] unless address?
  try
    { version } = decode network, address
    not types or version.toString('hex') in [].concat(types).map (t) -> V[t].toString('hex')
  catch err then false

# Mock cryptocoinjs's btc-address Address format
#
# Required because btc-address is Bitcoin-specific and represents
# the address network/type differently. Only mocking the functionallity
# needed for Bitrated to operate.
to_ccAddress = (network, expected_type, address) ->
  V = get_versions network
  { version, bytes } = decode network, expected_type, address

  for _type, _ver of V when buff_eq version, _ver
    type = cc_types_map[_type]
    break
  
  hash: Array.apply null, bytes
  getType: -> type

cc_types_map = public: 'pubkeyhash', scripthash: 'scripthash'

# Turn Script to an address
script_to_addr = (network, script) ->
  switch script.getOutType()
    when 'pubkey'     then encode network, 'public',     script.chunks[0]
    when 'pubkeyhash' then encode network, 'public',     script.chunks[2]
    when 'scripthash' then encode network, 'scripthash', script.chunks[1]
    else throw new Error 'Unknown address type'

module.exports = { encode, decode, validate, to_ccAddress, script_to_addr }
