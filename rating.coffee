stringify = require 'json-stable-stringify'
{ user_url } = require './user'

base_url = process.env.URL

rating_sig_message = (target, rating, type) ->
  obj =
    type: (type or rating.type)
    target: { user: target.username, sin: target.pubkey_sin }
    value: +rating.value
    comment: ''+(rating.comment or '')

  if rating.type is 'trade'
    obj.trade = rating.trade

  'I authorize the following rating:\n'+stringify obj

rating_url = (rating) -> "#{ user_url rating.target }/rating/#{ rating.id }"

module.exports = { rating_sig_message, rating_url }
