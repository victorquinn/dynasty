(function() {
  var Promise, dataTrans, getKey, _;

  _ = require('lodash');

  dataTrans = require('./data-translators');

  Promise = require('bluebird');

  module.exports.processAllPages = function(deferred, dynamo, functionName, params) {
    var resultHandler, stats;
    stats = {
      Count: 0
    };
    resultHandler = function(err, result) {
      if (err) {
        return deferred.reject(err);
      }
      deferred.notify(dataTrans.fromDynamo(result.Items));
      stats.Count += result.Count;
      if (result.LastEvaluatedKey) {
        params.ExclusiveStartKey = result.LastEvaluatedKey;
        return dynamo[functionName](params, resultHandler);
      } else {
        return deferred.resolve(stats);
      }
    };
    dynamo[functionName](params, resultHandler);
    return deferred.promise;
  };

  module.exports.getKeySchema = function(tableDescription) {
    var getKeyAndType, hashKeyName, hashKeyType, rangeKeyName, rangeKeyType, _ref, _ref1;
    getKeyAndType = function(keyType) {
      var keyDataType, keyName, _ref, _ref1;
      keyName = (_ref = _.find(tableDescription.Table.KeySchema, function(key) {
        return key.KeyType === keyType;
      })) != null ? _ref.AttributeName : void 0;
      keyDataType = (_ref1 = _.find(tableDescription.Table.AttributeDefinitions, function(attribute) {
        return attribute.AttributeName === keyName;
      })) != null ? _ref1.AttributeType : void 0;
      return [keyName, keyDataType];
    };
    _ref = getKeyAndType('HASH'), hashKeyName = _ref[0], hashKeyType = _ref[1];
    _ref1 = getKeyAndType('RANGE'), rangeKeyName = _ref1[0], rangeKeyType = _ref1[1];
    return {
      hashKeyName: hashKeyName,
      hashKeyType: hashKeyType,
      rangeKeyName: rangeKeyName,
      rangeKeyType: rangeKeyType
    };
  };

  getKey = function(params, keySchema) {
    var key;
    if (!_.isObject(params)) {
      params = {
        hash: params + ''
      };
    }
    key = {};
    key[keySchema.hashKeyName] = {};
    key[keySchema.hashKeyName][keySchema.hashKeyType] = params.hash + '';
    if (params.range) {
      key[keySchema.rangeKeyName] = {};
      key[keySchema.rangeKeyName][keySchema.rangeKeyType] = params.range + '';
    }
    return key;
  };

  module.exports.deleteItem = function(params, options, callback, keySchema) {
    var awsParams;
    awsParams = {
      TableName: this.name,
      Key: getKey(params, keySchema)
    };
    return this.parent.dynamo.deleteItemAsync(awsParams);
  };

  module.exports.batchGetItem = function(params, callback, keySchema) {
    var awsParams, name;
    awsParams = {};
    awsParams.RequestItems = {};
    name = this.name;
    awsParams.RequestItems[this.name] = {
      Keys: _.map(params, function(param) {
        return getKey(param, keySchema);
      })
    };
    return this.parent.dynamo.batchGetItemAsync(awsParams).then(function(data) {
      return dataTrans.fromDynamo(data.Responses[name]);
    }).nodeify(callback);
  };

  module.exports.getItem = function(params, options, callback, keySchema) {
    var awsParams;
    awsParams = {
      TableName: this.name,
      Key: getKey(params, keySchema)
    };
    return this.parent.dynamo.getItemAsync(awsParams).then(function(data) {
      return dataTrans.fromDynamo(data.Item);
    }).nodeify(callback);
  };

  module.exports.queryByHashKey = function(key, callback, keySchema) {
    var awsParams, hashKeyName, hashKeyType;
    awsParams = {
      TableName: this.name,
      KeyConditions: {}
    };
    hashKeyName = keySchema.hashKeyName;
    hashKeyType = keySchema.hashKeyType;
    awsParams.KeyConditions[hashKeyName] = {
      ComparisonOperator: 'EQ',
      AttributeValueList: [{}]
    };
    awsParams.KeyConditions[hashKeyName].AttributeValueList[0][hashKeyType] = key;
    return this.parent.dynamo.queryAsync(awsParams).then(function(data) {
      return dataTrans.fromDynamo(data.Items);
    }).nodeify(callback);
  };

  module.exports.scan = function(params, options, callback, keySchema) {
    var awsParams, filter, scanFilterFunc, _i, _len, _ref;
    if (params == null) {
      params = {};
    }
    awsParams = {
      TableName: this.name,
      ScanFilter: {},
      Select: 'SPECIFIC_ATTRIBUTES',
      AttributesToGet: params.attrsGet || [keySchema.hashKeyName],
      Limit: params.limit,
      TotalSegments: params.totalSegment,
      Segment: params.segment
    };
    scanFilterFunc = function(filter) {
      var obj;
      obj = awsParams.ScanFilter;
      obj[filter.column] = {
        ComparisonOperator: filter.op || 'EQ',
        AttributeValueList: [{}]
      };
      obj[filter.column].AttributeValueList[0][filter.type || 'S'] = filter.value;
      return obj;
    };
    if (params.filters) {
      _ref = params.filters;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        filter = _ref[_i];
        scanFilterFunc(filter);
      }
    }
    return this.parent.dynamo.scanAsync(awsParams).then(function(data) {
      return dataTrans.fromDynamo(data.Items);
    }).nodeify(callback);
  };

  module.exports.putItem = function(obj, options, callback) {
    var awsParams;
    awsParams = {
      TableName: this.name,
      Item: _.transform(obj, function(res, val, key) {
        return res[key] = dataTrans.toDynamo(val);
      })
    };
    return this.parent.dynamo.putItemAsync(awsParams);
  };

}).call(this);
