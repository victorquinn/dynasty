Promise = require('bluebird')
_ = require('lodash')

# async promise while loop, repeatedly perform action until condition met
promiseWhile = Promise.method (condition, action) ->
  if !condition()
    return
  else
    return action()
      .then promiseWhile.bind(null, condition, action)

# predicate function to validate input parameters
# returns true if valid, false otherwise
hasValidFindParams = (params) ->
  # 3 cases
  # (1) it is a string
  if _.isString params
    return true

  # (2) it is an object with a hash and range key
  if _.isObject params
    if Object.keys(params).length == 2 and params.hasOwnProperty('hash') and params.hasOwnProperty('range')
      return true

  # (3) it is an object with just a hash key
  if _.isObject params
    if Object.keys(params).length == 1 and params.hasOwnProperty('hash')
      return true

  # Otherwise it is not valid
  return false

module.exports =
  promiseWhile: promiseWhile
  hasValidFindParams: hasValidFindParams
