{ format_satoshis } = require '../cryptocoin/util'
{ get_balance } = require './outputs'

roles = [ 'buyer', 'seller', 'arbiter' ]
role_inverse = buyer: 'seller', seller: 'buyer'

role_other_rel = buyer: 'Buying from', seller: 'Selling to', arbiter: 'Trust agent for'

status_labels = new: 'New', accepted: 'Accepted', rejected: 'Rejected', \
                paid: 'Paid', released: 'Released'

action_labels = review: 'Review', pay: 'Pay', release: 'Show'

# Get information about `trade` from the perspective of `username`
get_perspective = (username, trade) ->
  return unless role = get_role username, trade

  unless role is 'arbiter'
    other_role = role_inverse[role]
    other_user = trade[other_role]

  other_users = (trade[r] for r in roles when r isnt role)

  { role, other_role, other_user, other_users }

# Get the applicable action by `username` for `trade`
get_applicable_action = (username, trade) ->
  role = get_role username, trade
  status = trade.status
  if status is 'new' and not has_accepted username, trade then 'review'
  else if status is 'accepted' and role is 'buyer' and (get_balance trade)<trade.amount then 'pay'
  else if status is 'paid'  then 'release'

  # There's no applicable action when:
  # - Trade is awaiting approval by another user
  # - Trade was rejected by one of the users
  # - Trade is awaiting payment and current user is not the buyer
  # - Trade is fully paid, but still unconfirmed
  # - Payment was released

get_current_view = (username, trade) ->
  action = get_applicable_action username, trade
  # Awaiting for payment is special-cased - always use the payment view,
  # regardless of active action
  if trade.status is 'accepted' then 'payment'
  else action or 'noop'

# Get user info of `username` for trade
get_userinfo = (username, trade) ->
  return info for info in trade.users_info when info.user is username

# Has `username` accepted the `trade`?
has_accepted = (username, trade) -> !!get_userinfo username, trade

# Get the role of `username` in `trade
get_role = (username, trade) ->
  return r for r in roles when trade[r] is username

# Get the relationship `role` has to the other party/ies
get_other_rel = (role) -> role_other_rel[role]

# Get inverse role
get_inverse_role = (role) -> role_inverse[role]

# Get textual amount for `trade` as it should be displayed in the UI
get_amount_display = ({ currency, amount }) -> (format_satoshis amount) + ' ' + currency

# Get label for `status`
get_status_label = (status) -> status_labels[status]

# Get label for `action`
get_action_label = (action) -> action_labels[action]

# Get a list of users who accepted the trade
get_accepted = (trade) -> user for { user } in trade.users_info

# Get a list of usernames who still haven't accepted the trade
get_pending_accept = (trade) ->
  accepted = get_accepted trade
  user for r in roles when (user=trade[r]) not in accepted

# Can ratings be added to this trade?
can_rate_trade = (trade) -> trade.status not in [ 'new', 'rejected', 'accepted' ]

# Normalize the "contract name" of users according to the meta.contract_names field
#
# NOTE: this mutates the `data` argument
#
# Needed when the initial "contract name" might change in the future,
# e.g. when a user is invited via email, only his email address is known
# initially, until he signs-up and his username becomes known as well
normalize_contract_names = (trade, data) ->
  if trade.meta?.contract_names? then for role, name of trade.meta.contract_names
    data[role] = name
  data

module.exports = {
  get_perspective, get_role, get_applicable_action, get_current_view
  get_other_rel, get_inverse_role, get_amount_display
  status_labels, get_status_label, get_action_label
  get_userinfo, get_pending_accept
  can_rate_trade, normalize_contract_names
}
