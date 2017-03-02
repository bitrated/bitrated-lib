{ get_perspective, get_applicable_action, get_other_rel, get_amount_display,
  get_status_label, get_action_label, status_labels, get_pending_accept } = require '../index'
{ connect_and } = require '../../lang'
{ user_link } = require '../../user'
reltime = require '../../reltime'

module.exports = (username, { trades, page, pages, search }) -> {
  username, search, page, pages
  searching: search.role or search.status or search.q

  trades: (t.toJSON() for t in trades)

  get_perspective: (trade) -> get_perspective username, trade
  get_applicable_action: (trade) -> get_applicable_action username, trade
  trade_amount: get_amount_display

  get_other_rel, get_status_label, status_labels, get_action_label
  user_link, reltime, connect_and, get_pending_accept
}
