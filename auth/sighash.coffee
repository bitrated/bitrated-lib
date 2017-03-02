{ sha256 } = require 'crypto-hashing'
stringify = require 'json-stable-stringify'
{ stringify_buffs } = require '../util'

REQ_SALT = 'Bitrated-request-sig:'
FIELD_SALT = 'Bitrated-field-sig:'

# Create sig hash for HTTP request
#
# Buffers are expected to already be stringified at this point
req_sighash = ({ method, url, body }) ->
  method = method.toUpperCase()
  body ?= {}
  sha256 REQ_SALT + stringify { method, url, body }

# Create sig hash for a field key-value pair
field_sighash = (user, key, val) ->
  val = stringify_buffs val
  sha256 FIELD_SALT + stringify { user, key, val }

module.exports = { req_sighash, field_sighash }
