_isPlainObject = require 'lodash/isPlainObject'
_isArray = require 'lodash/isArray'
_defaults = require 'lodash/defaults'
Qs = require 'qs'

nodeFetch = unless window?
  # Avoid webpack include
  _fetch = 'node-fetch'
  fetch = require _fetch
  fetch.Promise = Promise
  fetch

class RequestError extends Error
  constructor: ({url, options, res, body}) ->
    super()
    @name = 'RequestError'
    @message = res.statusText
    @stack = (new Error()).stack
    @url = url
    @options = options
    @body = body

    Object.defineProperty this, 'res', {value: res, enumerable: false}

statusCheck = (response) ->
  if response.status >= 200 and response.status < 300
    Promise.resolve response
  else
    Promise.reject response

toJson = (response) ->
  if response.headers.get('Content-Type') is 'application/json'
    if response.status is 204
    then null
    else response.json()
  else
    response.text()
    .then (text) ->
      try
        JSON.parse text
      catch
        text

module.exports = (url, options) ->
  if _isPlainObject(options?.body) or _isArray(options?.body)
    options.headers = _defaults (options.headers or {}),
      'Accept': 'application/json'
      'Content-Type': 'application/json'
    options.body = JSON.stringify options.body

  if _isPlainObject(options?.qs)
    url += '?' + Qs.stringify options.qs

  (if window?
    window.fetch url, options
  else
    nodeFetch url, options
  ).then statusCheck
  .then toJson
  .catch (err) ->
    if err.ok?
      return toJson err
      .then (body) ->
        throw new RequestError {url, options, body, res: err}
    else
      throw err
