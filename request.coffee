superagent = require 'superagent'
methods = require 'methods'
{ stringify_buffs } = require './util'
{ req_sighash } = require './auth/sighash'

csrf_token = $('meta[name=csrf-token]').attr('content') if window?

class Request extends superagent.Request
  init: ->
    # always accept application/json by default
    @accept 'json'
    @unset 'User-Agent'

    @on 'finalize', ->
      @_data = stringify_buffs @_data
      if csrf_token? and is_local_url @url
        @set 'X-CSRF-Token', csrf_token

  sign: (key) ->
    @on 'finalize', =>
      method = (@getHeader 'X-HTTP-Method-Override') or @method
      sig = key.sign req_sighash { method, @url, body: @_data }
      @set 'X-Req-Signature', key.pub.toString('base64') + ';' + sig.toString('base64')

  end: (cb) ->
    # Emit "finalize" to allow making final modifications to the request
    @emit 'finalize', this
    # Trick superagent into always calling cb with (err, res)
    super (err, res) -> cb? err, res

wrap = (fn) -> (a..., cb) ->
  unless typeof cb is 'function'
    a.push cb
    cb = null

  req = fn a...
  req.__proto__ = Request::
  req.init()
  req.end cb if cb?

  req

request = wrap superagent

# the underlying superagent is used directly by some connect linkers
request.superagent = superagent

for method in methods when method of superagent
  request[method] = wrap superagent[method]
request.del = wrap superagent.del

# Prepare error from response object
request.prep_err = prep_err = (res) ->
  res.body or (res.text and message: res.text, public: true) or res.error

# iferr-like error delegator that handles HTTP errors
request.iferr = (fail, succ) -> (err, res) ->
  if err? then fail err
  else if res.error then fail prep_err res
  else succ res

module.exports = request

# Helpers

is_local_url = (url) ->
  a = document.createElement 'a'
  a.href = url

  a.hostname is location.hostname \
  # IE does not populate the `hostname` property for relative URLs.
  # In this case, just check the URL doesn't contain anything that looks
  # like a protocol/schema, as an extra precatuion.
  or (not a.hostname and !~url.indexOf('//') and !~url.indexOf(':'))
