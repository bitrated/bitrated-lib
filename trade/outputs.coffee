# Get the total value of outputs, filtered by `options`
#
# `options` can contain `spent` and `confirmed` with a boolean value.
# Omitting the option will not filter by that option.
sum_outputs = (outputs, opt) ->
  outputs = outputs.outputs if outputs.outputs? # Support Trade model
  outputs = outputs.models if outputs.models? # Support Backbone collection

  { spent, confirmed } = opt if opt?
  if spent? or confirmed?
    outputs = outputs.filter (output) ->
      (not spent?     or spent     is output.spender?.txid?) and \
      (not confirmed? or confirmed is output.block?)

  res = outputs.reduce ((a, b) -> a + +b.amount), 0
  res

get_balance = (outputs, confirmed) -> sum_outputs outputs, { spent: false, confirmed }

get_balances = (outputs) ->
  total:       get_balance outputs
  confirmed:   get_balance outputs, true
  unconfirmed: get_balance outputs, false

module.exports = { sum_outputs, get_balance, get_balances }
