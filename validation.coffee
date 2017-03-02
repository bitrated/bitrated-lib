# does not match all valid email addresses, but good enough
RE_EMAIL = /^[^@\s,"'<>]+@[^@\s,"'<>]+\.[^@\s,"'<>]+$/
is_email = (value) ->
  value? and value.length <= 60 and RE_EMAIL.test value

module.exports = { is_email }
