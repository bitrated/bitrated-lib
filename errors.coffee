make_err = (name, defaults={}, init) -> (message, options) ->
  unless options?
    if message is Object message
      options = message
      message = options.message
    else options = {}

  err = new Error message
  err.name = name
  err[k] = v for k, v of defaults when not options[k]?
  err[k] = v for k, v of options
  err.toJSON = -> {
    name: err.name
    message: err.message
    code: err.code
    public: err.public
    meta: err.meta
  }
  init? err
  err

module.exports =
  PublicError: PublicError = make_err 'PublicError', public: true

  UserError: make_err 'UserError', status: 400, public: true

  HttpError: (status, message) -> new PublicError { status, message, name: 'HttpError', public: true }

  ValidationError: make_err 'ValidationError', status: 422, public: true, (err) ->
    # Transform arrays of [ { field, message } ] to object of { field: message, ...}
    if Array.isArray err.errors
      new_errors = {}
      new_errors[field] = message for { field, message } in err.errors
      err.errors = new_errors

    # When there's only one validation error, use that as the primary error message
    if err.errors and (fields = Object.keys err.errors).length is 1
      err.message = "#{ fields[0] }: #{ err.errors[fields[0]] }"
    # Otherwise, use a generic "Validation error"
    else
      err.message = 'Validation error'

    err.toJSON = do ({ toJSON } = err) -> ->
      json = toJSON.call err
      json.errors = err.errors
      json
