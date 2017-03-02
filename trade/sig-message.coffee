stringify = require 'json-stable-stringify'
{ get_role, get_amount_display, normalize_contract_names } = require './index'
{ extend } = require '../util'

JSON_PROPS = [ 'id', 'buyer', 'seller', 'arbiter', 'description'
               'amount', 'currency', 'arb_fees' ]

module.exports = (trade, userinfo) ->
  data = trade.toJSON?() or extend {}, trade
  data = normalize_contract_names trade, data
  """
    Signed by #{ userinfo.user } on #{ userinfo.ts.toISOString() } for trade #{ trade.id }.

    #{ messages[get_role userinfo.user, trade] userinfo, data}

    #{ jsonify data }\
    #{ if trade.contract then '\n\n' + trade.contract else '' }
  """

jsonify = (trade) ->
  ser = {}
  ser[k] = trade[k] for k in JSON_PROPS
  stringify ser, space: '\t'

messages =
  buyer: ({ user, pubkey, address }, trade) -> """
    I, #{ user }, am willing to buy "#{ trade.description }" \
    from #{ trade.seller } \
    for #{ get_amount_display trade }, \
    with #{ trade.arbiter } as the trust agent. \

    My public key for the multi-signature is #{ pubkey.toString 'hex' }, \
    and my refund address is #{ address }.
  """

  seller: ({ user, pubkey, address }, trade) -> """
    I, #{ user }, am willing to sell "#{ trade.description }" \
    to #{ trade.buyer } \
    for #{ get_amount_display trade }, \
    with #{ trade.arbiter } as the trust agent. \

    My public key for the multi-signature is #{ pubkey.toString 'hex' }, \
    and my payout address is #{ address }.
  """

  arbiter: ({ user, pubkey, address }, trade) -> """
    I, #{ user }, am willing to provide arbitration services \
    for #{ trade.buyer } \
    to buy "#{ trade.description }" \
    from #{ trade.seller } \
    for #{ get_amount_display trade }. \

    My public key for the multi-signature is #{ pubkey.toString 'hex' }, \
    and my payout address for the arbitration fees is #{ address }.    
  """
