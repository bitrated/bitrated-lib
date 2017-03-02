# Scrub `x` from memory
#
# Based on TripleSec's implementation
scrub = (x) ->
  if Buffer.isBuffer x
    n_full_words = (x.length >> 2)
    i = 0
    while i < n_full_words
      x.writeUInt32LE 0, i
      i += 4
    while i < x.length
      x.writeUInt8 0, i
      i++
  else if Array.isArray x
    x[i] = 0 for i in [0..x.length]
  else
    throw new Error 'I don\'t know how to scrub that'

# Returns a function that scrubbes `xs` when invoked
scrubber = (xs...) -> ->
  scrub x for x in xs
  return

module.exports = { scrub, scrubber }
