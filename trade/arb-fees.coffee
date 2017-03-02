{ pick } = require '../util'
{ validate_satoshis } = require '../cryptocoin/util'
{ get_amount_display } = require './index'

DUST_SPAM = 546

# Validate the arbiter fees are properly structred
validate_fees = (fees) ->
  fees.base?    and (validate_fees_kind fees.base) and \
  fees.dispute? and (validate_fees_kind fees.dispute)
validate_fees_kind = (config) -> switch config.type
  when 'none'  then true
  when 'fixed' then validate_satoshis config.fixed
  when 'percentage'
    (not config.min? or validate_satoshis config.min) and \
    (not config.max? or validate_satoshis config.max) and \
    (not config.min? or not config.max? or +config.min < +config.max) and \
    (config.percentage and config.percentage is +config.percentage and 0 < config.percentage <= 100)
  else false

# Calc the fees requires for `amount` with a fee structute of `fees`
calc_fees = (amount, fees) ->
  base:    calc_fees_kind amount, fees.base
  dispute: calc_fees_kind amount, fees.dispute
calc_fees_kind = (amount, config) -> switch config.type
  when 'none'  then 0
  when 'fixed' then +config.fixed
  when 'percentage'
    fees_amount = amount / 100 * config.percentage
    fees_amount = Math.min config.max, fees_amount if config.max?
    fees_amount = Math.max config.min, fees_amount if config.min?
    Math.max DUST_SPAM, Math.floor fees_amount
  else throw new Error 'Invalid fees type'

# Normalize fees structure to persist in db
normalize_fees = (fees) ->
  base: (normalize_fees_kind fees.base if fees.base?)
  dispute: (normalize_fees_kind fees.dispute if fees.dispute?)
normalize_fees_kind = (config) ->
  # Remove extra fields
  config = pick config, switch config.type
    when 'none'       then [ 'type' ]
    when 'fixed'      then [ 'type', 'fixed' ]
    when 'percentage' then [ 'type', 'percentage', 'min', 'max' ]
  # Cast satoshi amounts to strings
  config[k] = ''+config[k] for k in [ 'fixed', 'min', 'max' ] when config[k]?
  # Cast percentage to number
  config.percentage = +config.percentage if config.percentage?
  config

# Return textual explaination for fees
fees_text = ({ currency, amount, arb_fees }, fee_struct) ->
  { base, dispute } = arb_fees or calc_fees amount, fee_struct
  format_amount = (amount) -> get_amount_display { currency, amount }

  base = +base
  dispute = +dispute
  text = ''
  if base or dispute
    if base
      text += format_amount base
      if dispute then text += ' base fee + '
    else text += 'Free if no dispute, or '

    if dispute then text += "#{ format_amount dispute } if disputed"
  else text += 'None (free of charge)'

  text

# Get the amount of fees due for the given trade
fees_for_trade = (trade) ->
  +trade.arb_fees.base + (if trade.disputed then +trade.arb_fees.dispute else 0)

module.exports = { validate_fees, calc_fees, normalize_fees, fees_text, fees_for_trade }
