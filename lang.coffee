# Connect multiple items with proper "," and "and" between then
#
# [ foo, bar ] -> foo and bar
# [ foo, bar, qux ] -> foo, bar and qux

connect_and = (items) -> switch items.length
  when 1 then items[0]
  when 2 then items.join ' and '
  else
    items[...-1].join(', ') + ' and ' + items[items.length-1]

module.exports = { connect_and }
