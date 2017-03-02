{ user_link, user_image } = require '../../user'
reltime = require '../../reltime'
markdown = require '../../markdown'
{ get_amount_display, get_perspective, get_pending_accept,
  get_status_label, get_other_rel, get_role, can_rate_trade } = require '../index'
{ get_balances } = require '../outputs'
{ fees_text } = require '../arb-fees'
info_link = require '../info-link'

module.exports = (username, _trade) ->
  trade = _trade.toObject()
  locals = {
    trade: _trade.toJSON()
    username, authenticated: username

    can_rate: can_rate_trade trade
    perspective: get_perspective username, trade
    pending_accept: get_pending_accept trade
    format_amount: (amount) -> get_amount_display { amount, currency: trade.currency }
    tx_link: (txid) -> info_link trade.currency, 'tx', txid
    address_link: (address=trade.multisig) -> info_link trade.currency, 'address', address

    reltime, markdown, user_link, user_image, fees_text
    get_status_label, get_role, get_other_rel
  }
  if trade.multisig
    locals.balances = get_balances trade.outputs

  locals
