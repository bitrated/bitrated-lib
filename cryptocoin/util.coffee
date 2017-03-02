move_decimal = require 'move-decimal-point'

# Number of decimal places in a coin
COIN_PRECISION = 8

# Pretty-format satoshis amount in whole coins
format_satoshis = (val) ->
  coins = +move_decimal val, COIN_PRECISION*-1
  # at least two decimal places and avoid scientific notation
  if (0|coins*10) is coins*10 then coins.toFixed(2)
  else coins.toFixed(8).replace(/0+$/,'')

# Turn whole coins amounts to satoshis, throw for invalid amounts
to_satoshis = (val) ->
  nval = +val
  throw new Error 'Amount must be numeric and positive' unless nval is nval and nval >= 0
  satoshis = +move_decimal val, COIN_PRECISION
  throw new Error 'Amount cannot have more than 8 decimal places' unless satoshis%1 is 0
  '' + satoshis

# Valdiate satoshis amount (check its a positive integer)
# @TODO validate amount exists in currency (i.e. <=21M for Bitcoin)
validate_satoshis = (val) ->
  val = +val
  val is val and val > 0 and val%1 is 0

module.exports = { format_satoshis, to_satoshis, validate_satoshis }
