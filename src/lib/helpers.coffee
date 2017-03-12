Promise = require('bluebird')

# async promise while loop, repeatedly perform action until condition met
promiseWhile = Promise.method (condition, action) ->
  if !condition()
    return
  else
    return action()
      .then promiseWhile.bind(null, condition, action)

module.exports =
  promiseWhile: promiseWhile
  
