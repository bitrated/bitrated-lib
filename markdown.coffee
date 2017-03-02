marked = require 'marked'
sanitize = require 'caja-html-sanitizer'

uri_rewriter = (uri) ->
  uri.toString() if uri.j in [ 'http', 'https', 'mailto' ]

# Delegate to `marked` with some options and safe compilation by default
module.exports = (content, unsafe=false) ->
  html = marked content, sanitize: !unsafe, smartypants: true
  # marked already attempts to santize the HTML and does that pretty well,
  # but it can't hurt to use Caja as well.
  html = sanitize html, uri_rewriter unless unsafe
  html
