escape = require 'escape-html'
{ is_email } = require './validation'

ROLES = [ 'buyer', 'seller', 'arbiter' ]
SIGNED_FIELDS = [ 'email', 'subkeys', 'full_name', 'about', 'tags', 'arbitration_fees', 'default_addresses' ]
RE_USERNAME = /^[A-Za-z0-9\-]{3,15}$/

base_url = process.env.URL
user_image_url = process.env.USER_IMAGE_URL

user_url = (username) -> "#{ base_url }/#{encodeURIComponent username}"

user_link = (username) ->
  if is_email username then escape username
  else """<a href="#{ user_url(username) }">#{ escape username }</a>"""

user_image = (username, size='full') -> "#{ user_image_url }/#{encodeURIComponent username}-#{size}.png"

user_tag_link = (tag) -> """<a href="#{ base_url }/users/tag/#{ encodeURIComponent tag }">#{ escape tag }</a>"""

normalize_tags = (tags) ->
  tags = tags.split ',' unless Array.isArray tags

  tags = tags
    .map (x) -> (''+x).toLowerCase().trim()[0..30]
    .filter (x) -> !!x.length
  u_tags = {}
  u_tags['$'+k] = 1 for k in tags
  Object.keys(u_tags)[0..25].map (x) -> x[1..]

normalize_addresses = (addresses) ->
  for currency, address of addresses when not address
    delete addresses[currency]
  addresses

module.exports = {
  ROLES, SIGNED_FIELDS, RE_USERNAME
  user_url, user_link, user_image
  user_tag_link
  normalize_tags, normalize_addresses
}
