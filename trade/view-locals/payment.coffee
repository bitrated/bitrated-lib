qruri = require 'qruri'
get_payment_uri = require '../payment-uri'
{ get_balance } = require '../outputs'
base = require './item'

module.exports = (username, trade) ->
  locals = base username, trade
  if locals.payment_due = Math.max 0, trade.amount - get_balance trade
    locals.payment_uri = get_payment_uri trade, locals.payment_due
    locals.qr_uri = qruri locals.payment_uri, margin: 0
  locals
