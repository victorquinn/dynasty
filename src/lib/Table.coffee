awsTrans = require('./aws-translators')
dataTrans = require('./data-translators')
_ = require('lodash')
Q = require('q')
debug = require('debug')('dynasty')

class Table

  constructor: (@parent, @name) ->
    @key = @describe().then((tableDescription)=>
      @description = tableDescription.Table
      awsTrans.getKeySchema(tableDescription)
    ).then (keySchema)=>
      @hasRangeKey = (4 == _.size _.compact _.values keySchema)
      keySchema

  updateDescription: =>
    @describe().then((tableDescription)=>
      @description = tableDescription.Table
    )

  ###
  Item Operations
  ###

  update: =>
    deferred = Q.defer() # Cannot be resolved until after @key
    promise = deferred.promise

    keyParam = {}
    returnValues = 'NONE'
    attributeUpdates = {}

    awsParams =
      TableName: @name
      Key: keyParam

    hashKeySpecified = rangeKeySpecified = false

    enableReturn = ->
      promise.returnAllOld = ->
        returnValues = 'ALL_OLD'
        promise
      promise.returnUpdatedOld = ->
        returnValues = 'UPDATED_OLD'
        promise
      promise.returnAllNew = ->
        returnValues = 'ALL_NEW'
        promise
      promise.returnUpdatedNew = ->
        returnValues = 'UPDATED_NEW'
        promise
      null

    enableActions = ->
      for action in ['add', 'put', 'delete']
        ((action)->
          promise[action] = (attributes)->
            action = action.toUpperCase()
            for name, value of attributes
              if attributeUpdates[name]
                throw new Error 'Attempting to perform two update actions on single attribute: '+name
              attributeUpdates[name] = 
                Value: if value == null then null else dataTrans.toDynamo(value)
                Action: action
            enableReturn()
            promise
        )(action)
      null

    ###
    TODO 
      The following function call needs to be placed inside the hash or range function and
      called depending on the key schema of the table. It should not be possible to
      specify an action until all information is provided that specifies a single item.
      It seems that this will only be possible if calling loadAllTables is a precondition.
      Dynasty.loadAllTables needs to have Dynasty.load to help it out
      in the event that the user wants to load specific tables only.
    ###
    enableActions()

    promise.hash = (hashKeyValue) =>
      @key.then (keySchema)->
        keyParam.HashKeyElement = {}
        keyParam.HashKeyElement[keySchema.hashKeyType] = hashKeyValue+''
        hashKeySpecified = true

      promise.range = (rangeKeyValue)=>
        @key.then (keySchema)->
          if !@hasRangeKey
            deferred.reject new Error "Specifying range key for table without range key"
          else
            keyParam.RangeKeyElement = {}
            keyParam.RangeKeyElement[keySchema.rangeKeyType] = rangeKeyValue+''
            rangeKeySpecified = true
        promise
      promise

    process.nextTick =>
      @key.done (keySchema)=>
        if !promise.isRejected()
          debug "find() - #{JSON.stringify awsParams}"
          #error checking
          if !hashKeySpecified
            return deferred.reject new Error 'Must specify hash key'
          if @hasRangeKey and !rangeKeySpecified
            return deferred.reject new Error 'Must specify range key for table with range key'
          #done error checking

          awsParams.ReturnValues = returnValues
          awsParams.AttributeUpdates = attributeUpdates

          @parent.execute('UpdateItem', awsParams)
          .fail(deferred.reject)
          .done((data)-> 
            data = dataTrans.fromDynamo(data.Attributes)
            deferred.resolve(data)
            data
          )

    promise


  # Wrapper around DynamoDB's getItem
  find: (continuer)=> 
    deferred = Q.defer() # Cannot be resolved until after @key
    promise = deferred.promise

    keyParam = {}
    awsParams =
      TableName: @name
      Key: keyParam

    hashKeySpecified = rangeKeySpecified = minRangeSpecified = false
    specifiedMinRange = null

    options = {}
    promise.options = (opts)->
      _.extend(options, opts)
      promise

    promise.hash = (hashKeyValue) =>
      @key.then (keySchema)->
        keyParam.HashKeyElement = {}
        keyParam.HashKeyElement[keySchema.hashKeyType] = hashKeyValue+''
        hashKeySpecified = true

      promise.range = (rangeKeyValue)=>
        @key.then (keySchema)=>
          if !@hasRangeKey
            deferred.reject new Error "Specifying range key for table without range key"
          else
            keyParam.RangeKeyElement = {}
            keyParam.RangeKeyElement[keySchema.rangeKeyType] = rangeKeyValue+''
            rangeKeySpecified = true
        promise

      promise.minRange = (minRange)=>
        @key.then (keySchema)=>
          if !@hasRangeKey
            deferred.reject new Error "Specifying minimum range key for table without range key"
          else
            minRangeSpecified = true
            specifiedMinRange = minRange
        promise


      promise

    # Wait a tick and then run the appropriate aws function
    process.nextTick =>
      @key.then((keySchema)=>
        if !promise.isRejected()
          debug "find() - #{JSON.stringify awsParams}"
          if (rangeKeySpecified and @hasRangeKey) or (hashKeySpecified and !@hasRangeKey)
            awsParams = _.pick _.extend(awsParams, options), 'HashKeyElement', 'AttributesToGet', 'TableName', 'Key', 'ConsistentRead', 'ReturnConsumedCapacity'
            @parent.execute('GetItem', awsParams)
            .then((data)-> 
              data = dataTrans.fromDynamo(data.Item)
              deferred.notify if data then [data] else []
              data
            )
            .then(deferred.resolve)
            .catch(deferred.reject)
          else if !rangeKeySpecified and !hashKeySpecified
            delete awsParams.Key
            awsParams = _.pick _.extend(awsParams, options),  'TableName', 'AttributesToGet', 'ExclusiveStartKey', 'Limit', 'ScanFilter', 'Segment', 'Select', 'TotalSegments', 'ReturnConsumedCapacity'
            awsTrans.processAllPages(deferred, @parent.execute, 'Scan', awsParams, continuer)
          else if !rangeKeySpecified and @hasRangeKey
            awsParams.HashKeyValue = awsParams.Key.HashKeyElement
            delete awsParams.Key
            if minRangeSpecified
              awsParams.RangeKeyCondition ?= 
                AttributeValueList : [
                  dataTrans.toDynamo(specifiedMinRange)
                ]
                ComparisonOperator: 'GT'
            awsParams = _.pick _.extend(awsParams, options),  'TableName', 'HashKeyValue', 'RangeKeyCondition', 'HashKeyCondition', 'AttributesToGet', 'ConsistentRead', 'ExclusiveStartKey', 'IndexName', 'KeyConditions', 'Limit', 'ReturnConsumedCapacity', 'ScanIndexForward', 'Select'
            awsTrans.processAllPages(deferred, @parent.execute, 'Query', awsParams, continuer)
      ).done()
    promise


  # Wrapper around DynamoDB's putItem
  insert: (obj) ->
    if !_.isArray obj
      awsParams =
        TableName: @name
        Item: _.transform(obj, (res, val, key) ->
          res[key] = dataTrans.toDynamo(val))
      console.log awsParams.Item
      @parent.execute('PutItem', awsParams)

    else
      deferred = Q.defer()
      allPutOps = []

      itemSize = (item)->
        sum = 0
        for prop, val of item
          sum += prop.length + (val+'').length
        sum

      currentNdx = 0
      while currentNdx < obj.length
        items = []
        dataLength = 0

        while items.length < 25 and dataLength < 1048576 and currentNdx < obj.length
          item = obj[currentNdx++]
          dataLength += itemSize(item)
          items.push item

        awsParams = {}
        awsParams.RequestItems = {}

        putRequests = []
        for item in items
          for prop of item
            item[prop] = dataTrans.toDynamo(item[prop])
          putRequests.push PutRequest: Item: item

        awsParams.RequestItems[@name] = putRequests

        allPutOps.push(
          @parent.execute('BatchWriteItem', awsParams).catch((error)->console.log error; deferred.reject error )
          .then((data)->
            deferred.notify(data)
            W.resolve(data)
          )
        )
      Q.all(allPutOps)
      .catch(deferred.reject)
      .done(deferred.resolve)
      deferred.promise

  remove: (params, options, callback = null) ->
    deferred = Q.defer() # Cannot be resolved until after @key
    promise = deferred.promise

    keyParam = {}
    awsParams =
      TableName: @name
      Key: keyParam

    hashKeySpecified = rangeKeySpecified = false
    specifiedHashKey = specifiedRangeKey = null

    options = {}
    promise.options = (opts)->
      _.extend(options, opts)
      promise

    enableHash = =>
      promise.hash = (hashKeyValue) =>
        @key.then (keySchema)->
          keyParam[keySchema.hashKeyName] = {}
          keyParam[keySchema.hashKeyName][keySchema.hashKeyType] = hashKeyValue+''
          hashKeySpecified = true
          specifiedHashKey = hashKeyValue+''
        promise

    enableRange = =>
      promise.range = (rangeKeyValue)=>
        @key.then (keySchema)=>
          if !@hasRangeKey
            deferred.reject new Error "Specifying range key for table without range key"
          else
            keyParam[keySchema.rangeKeyName] = {}
            keyParam[keySchema.rangeKeyName][keySchema.rangeKeyType] = rangeKeyValue+''
            rangeKeySpecified = true
            specifiedRangeKey = rangeKeyValue+''
        promise


    removeNarySpecifiers = ->
      for specifier in ['one', 'many', 'all']
        delete promise[specifier]

    permitRemovingOne = false
    promise.one = ->
      permitRemovingOne = true
      removeNarySpecifiers()
      enableHash()
      enableRange()
      promise

    permitRemovingSome = false
    promise.many = -> 
      permitRemovingSome = true
      removeNarySpecifiers()
      enableHash()
      promise

    permitRemovingAll = false
    promise.all = -> 
      permitRemovingAll = true
      removeNarySpecifiers()
      promise

    # Wait a tick and then run the appropriate aws function
    process.nextTick =>
      @key.then (keySchema)=>
        if !promise.isRejected()
          debug "remove() - #{JSON.stringify awsParams}"

          if @hasRangeKey
            if permitRemovingOne and (!hashKeySpecified or !rangeKeySpecified)
              return deferred.reject new Error 'Single element removal specified on hash/range table without specifying both a hash and range key'
            if permitRemovingSome and !hashKeySpecified
              return deferred.reject new Error 'Partial multiple element removal specified on a hash/range table without specifying a hash key'
            if permitRemovingAll and (hashKeySpecified or rangeKeySpecified)
              return deferred.reject new Error 'You cannot specify a hash or range key when attempting to remove all elements'
          else
            if rangeKeySpecified
              return deferred.reject new Error 'Range key specified for table without range key'
            if permitRemovingOne and !hashKeySpecified
              return deferred.reject new Error 'Single element removal specified on hash table without specifying hash key'
          if !permitRemovingOne and !permitRemovingSome and !permitRemovingAll
            return deferred.reject new Error 'Remove requires one(), many(), or all() to be called'

          deleteCount = 0
          #items.length must not exceed 25
          allDeleteOps = []
          deleter = (items)=>
            if items.length == 0 then return
            deleteRequests = []
            for item in items
              requestKey = {}
              requestKey.HashKeyElement = {}
              requestKey.HashKeyElement[keySchema.hashKeyType] = item[keySchema.hashKeyName]+''
              if keySchema.rangeKeyName
                requestKey.RangeKeyElement = {}
                requestKey.RangeKeyElement[keySchema.rangeKeyType] = item[keySchema.rangeKeyName]+''
              deleteRequests.push DeleteRequest: Key: requestKey

            deleteCount += deleteRequests.length
            deferred.notify(Count:deleteCount)

            awsParams = {}
            awsParams.RequestItems = {}
            awsParams.RequestItems[@name] = deleteRequests
            allDeleteOps.push @parent.execute('BatchWriteItem', awsParams)

          op = Q()
          if hashKeySpecified and !@hasRangeKey
            op = @find()
            .options(Limit:25)
            .hash(specifiedHashKey)
            .progress(deleter)
          else if rangeKeySpecified and @hasRangeKey 
            op = @find()
            .options(Limit:25)
            .hash(specifiedHashKey)
            .range(specifiedRangeKey)
            .progress(deleter)
          else if permitRemovingAll and !rangeKeySpecified and !hashKeySpecified
            op = @find()
            .options(Limit:25)
            .progress(deleter)
          else if permitRemovingSome and !rangeKeySpecified and @hasRangeKey and hashKeySpecified
            op = @find()
            .hash(specifiedHashKey)
            .options(Limit:25)
            .progress(deleter)
          op
          .then(->Q.all allDeleteOps)
          .then(-> Count:deleteCount)
          .then(deferred.resolve)
          .catch(deferred.reject)

    promise

  ###
  Table Operations
  ###

  # describe
  describe: (callback = null) ->
    debug 'describe() - ' + @name
    @parent.execute('DescribeTable', TableName: @name)

  # drop
  drop: (callback = null) ->
    @parent.drop @name callback

module.exports = Table