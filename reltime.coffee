vagueTime = require 'vague-time'

reltime = (date, type='past') ->
  { datestr, vaguestr } = reltime.calc date, type
  """<time class="reltime" datetime="#{datestr}" title="#{datestr}" data-reltime-type="#{type}">#{vaguestr}</time>"""

reltime.calc = (date, type='past') ->
  date = new Date date unless date instanceof Date
  datestr = date.toISOString()
  ts = +date

  switch type
    when 'past'   then ts = Math.min ts, Date.now()
    when 'future' then ts = Math.max ts, Date.now()
    when 'any'    then # nothing
    else throw new Error 'unknown type'

  vaguestr = vagueTime.get to: ts

  { datestr, vaguestr }

module.exports = reltime
