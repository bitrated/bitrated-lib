{ ValidationError, UserError } = require '../errors'
addr = require '../cryptocoin/addr'
{ validate_satoshis } = require '../cryptocoin/util'

# Some common validation for client and server side
#
# There's some some additional validation elsewhere that's not specified here.

MAX_DESC_LENGTH = 100

# Validate that `trade` created by `username` is valid.
#
# Returns an error for invalid trades (doesn't throw)
module.exports = (username, trade) ->
  unless (lc username) in [ (lc trade.buyer), (lc trade.seller), (lc trade.arbiter) ]
    return new UserError 'You must be a party to the trade.'

  errors = {}
  # Validate parties
  if (lc trade.buyer) is (lc trade.seller)
    errors.other_user = 'You can\'t buy from yourself.'
  if (lc trade.arbiter) in [ (lc trade.buyer), (lc trade.seller) ]
    errors.arbiter = 'The trust agent cannot be the same as the buyer/seller.'

  # Validate amount
  unless validate_satoshis +trade.amount
    errors.amount = 'Invalid amount'

  # Validate description
  if trade.description.length > MAX_DESC_LENGTH or ~trade.description.indexOf('\n') or ~trade.description.indexOf('\r')
    errors.description = "Description must be one-liner and less than #{ MAX_DESC_LENGTH } characters."

  # Validate payment address (this validation is only ran on the client-side,
  # its validated separately on the server-side)
  if trade.payment_address? and not addr.validate trade.currency, [ 'public', 'scripthash' ], trade.payment_address
    errors.payment_address = 'Invalid address.'

  new ValidationError { errors } if Object.keys(errors).length

lc = (s) -> s.toLowerCase()
