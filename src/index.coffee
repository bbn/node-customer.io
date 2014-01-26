
https       = require('https')
querystring = require('querystring')
request     = require "request"

DEFAULT_API_ENDPOINT  = "app.customer.io/api"
DEFAULT_API_URL_PATTERNS = [
  "/v1/customers/{CUSTOMER_ID}"
  "/v1/customers/{CUSTOMER_ID}/events"
]



init = (siteId, secretKey) ->

  authString      = null
  client          = null
  hostname        = null
  pathPrefix      = null
  apiEndpoint     = null
  apiUrlPatterns  = null

  cio = {}

  # -------------------------------
  # Set up HTTP Basic Auth
  # -------------------------------
  if not siteId? or not secretKey?
    throw new Error("You must supply a customer.io site id and secret key: `init(siteId, secretKey)`")
  cio.siteId = siteId
  cio.secretKey = secretKey
  authString = 'Basic ' + new Buffer(siteId + ':' + secretKey).toString('base64')
  # -------------------------------


  # -------------------------------
  # Define HTTP convenience method
  # -------------------------------
  methods = {}
  methods.http = (method, path, authString, data, callback) ->

    data = JSON.stringify(data)

    options = {
      host: hostname,
      port: 443,
      path: pathPrefix + path,
      method: method,
      headers: {
        'Authorization': authString,
        'Content-Type': 'application/json',
        'Content-Length': data.length
      }
    }

    request
      uri: "https://#{options.host}#{options.path}"
      method: options.method
      port: 443
      headers: options.headers
      body: data
    ,callback

  # -------------------------------


  # -------------------------------
  # Endpoint override methods
  # -------------------------------
  # These are exposed to allow easy
  # modifications if the customer.io
  # API changes in future
  # -------------------------------  
  cio.initAPIEndpoint = (newEndpoint) ->
    if not typeof newPatterns is 'string'
      throw new Error("You can only override the API ENDPOINT with a URI string.")
    apiEndpoint = newEndpoint
    hostname    = apiEndpoint.split('/')[0]
    pathPrefix  = apiEndpoint.replace(hostname, '')

  cio.initAPIURLPatterns = (newPatterns) ->
    if not typeof newPatterns is 'array'
      throw new Error("You can only override the API URL patterns with an array of strings.")
    apiUrlPatterns = newPatterns
  # -------------------------------  


  # Call the above methods with our defaults
  cio.initAPIEndpoint(DEFAULT_API_ENDPOINT)
  cio.initAPIURLPatterns(DEFAULT_API_URL_PATTERNS)


  # -------------------------------
  # Core module methods
  # -------------------------------
  cio.identify = (customerId, email, data, callback) ->
    if not customerId?
      throw new Error("You must supply a customer id `identify(customerId, email, data)`")
    if not email?
      throw new Error("You must supply a customer email `identify(customerId, email, data)`")
    if typeof data is 'function'
      callback = data
      data = null
    attributes = data or {}
    path = apiUrlPatterns[0].replace "{CUSTOMER_ID}", encodeURIComponent(customerId)
    attributes.email = email
    return methods.http 'PUT', path, authString, attributes, callback

  cio.track = (customerId, eventName, data, callback) ->
    if not customerId?
      throw new Error("You must supply a customer id `track(customerId, eventName, data)`")
    if not eventName?
      throw new Error("You must supply an event name `track(customerId, eventName, data)`")
    if typeof data is 'function'
      callback = data
      data = null
    attributes = 
      name: eventName
      data: data  
    path = apiUrlPatterns[1].replace "{CUSTOMER_ID}", encodeURIComponent(customerId)
    return methods.http 'POST', path, authString, attributes, callback
  # -------------------------------

  return cio


# Expose only the init method
module.exports = {
  init: init
}

