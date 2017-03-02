{ connect_and } = require '../../lang'
{ extend } = require '../../util'
base = require './item'

module.exports = (username, trade) -> extend (base username, trade), {
  connect_and
  rejection_msg: get_rejection_msg trade if trade.status is 'rejected'
}

get_rejection_msg = (trade) ->
  return log.meta.message for log in trade.logs when log.action is 'rejected'
