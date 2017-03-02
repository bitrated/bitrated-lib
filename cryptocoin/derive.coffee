HDKey = require 'hdkey'
{ createHmac } = require 'crypto'

HARDENED_OFFSET = 0x80000000

# BIP32-based ECDSA key derivation
#
# Instead of using a static chain code and dynamic index (as specified in BIP32),
# this uses the chain code as the dynamic index and a static hardcoded index.
module.exports = (key, chain_code, hardend=false) ->
  hd = new HDKey
  hd.chainCode = chain_code

  index = if hardend then HARDEND_OFFSET else 0
  
  switch key.type
    when 'pub'
      hd.publicKey = key.pub
      hd.deriveChild(index).publicKey
    when 'priv'
      hd.privateKey = key.priv
      hd.deriveChild(index).privateKey
