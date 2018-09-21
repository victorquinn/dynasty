(function() {
  var Promise, _, addAwsParams, buildFilters, dataTrans, debug, getKey, scanFilterFunc,
    indexOf = [].indexOf;

  _ = require('lodash');

  dataTrans = require('./data-translators');

  Promise = require('bluebird');

  debug = require('debug')('dynasty:aws-translators');

  buildFilters = function(target, filters) {
    var filter, j, len, results;
    if (filters) {
      results = [];
      for (j = 0, len = filters.length; j < len; j++) {
        filter = filters[j];
        results.push(scanFilterFunc(target, filter));
      }
      return results;
    }
  };

  scanFilterFunc = function(target, filter) {
    target[filter.column] = {
      ComparisonOperator: filter.op || 'EQ',
      AttributeValueList: [{}]
    };
    target[filter.column].AttributeValueList[0][filter.type || 'S'] = filter.value;
    return target;
  };

  addAwsParams = function(target, params) {
    var key, results, value;
    results = [];
    for (key in params) {
      value = params[key];
      if (indexOf.call(target, key) < 0 && key[0] === key[0].toUpperCase()) {
        results.push(target[key] = value);
      } else {
        results.push(void 0);
      }
    }
    return results;
  };

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
    var getKeyAndType, hashKeyName, hashKeyType, rangeKeyName, rangeKeyType;
    getKeyAndType = function(keyType) {
      var keyDataType, keyName, ref, ref1;
      keyName = (ref = _.find(tableDescription.Table.KeySchema, function(key) {
        return key.KeyType === keyType;
      })) != null ? ref.AttributeName : void 0;
      keyDataType = (ref1 = _.find(tableDescription.Table.AttributeDefinitions, function(attribute) {
        return attribute.AttributeName === keyName;
      })) != null ? ref1.AttributeType : void 0;
      return [keyName, keyDataType];
    };
    [hashKeyName, hashKeyType] = getKeyAndType('HASH');
    [rangeKeyName, rangeKeyType] = getKeyAndType('RANGE');
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
    addAwsParams(awsParams, options);
    return this.parent.dynamo.deleteItemPromise(awsParams);
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
    addAwsParams(awsParams, params);
    return this.parent.dynamo.batchGetItemPromise(awsParams).then(function(data) {
      return dataTrans.fromDynamo(data.Responses[name]);
    }).nodeify(callback);
  };

  module.exports.getItem = function(params, options, callback, keySchema) {
    var awsParams;
    awsParams = {
      TableName: this.name,
      Key: getKey(params, keySchema)
    };
    addAwsParams(awsParams, options);
    return this.parent.dynamo.getItemPromise(awsParams).then(function(data) {
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
    return this.parent.dynamo.queryPromise(awsParams).then(function(data) {
      return dataTrans.fromDynamo(data.Items);
    }).nodeify(callback);
  };

  module.exports.scan = function(params, options, callback, keySchema) {
    var awsParams, prop, ref, val;
    if (params == null) {
      params = {};
    }
    awsParams = {
      TableName: this.name,
      ScanFilter: {},
      AttributesToGet: params.attrsGet || null,
      Limit: params.limit,
      TotalSegments: params.totalSegment,
      Segment: params.segment
    };
    if (params.ExclusiveStartKey != null) {
      awsParams.ExclusiveStartKey = {};
      ref = params.ExclusiveStartKey;
      for (prop in ref) {
        val = ref[prop];
        awsParams.ExclusiveStartKey[prop] = dataTrans.toDynamo(val);
      }
    }
    buildFilters(awsParams.ScanFilter, params.filters);
    addAwsParams(awsParams, options);
    return this.parent.dynamo.scanPromise(awsParams).then(function(data) {
      return dataTrans.fromDynamo(data.Items);
    }).nodeify(callback);
  };

  module.exports.query = function(params, options, callback, keySchema) {
    var awsParams;
    if (params == null) {
      params = {};
    }
    awsParams = {
      TableName: this.name,
      IndexName: params.indexName,
      KeyConditions: {},
      QueryFilter: {}
    };
    buildFilters(awsParams.KeyConditions, params.keyConditions);
    buildFilters(awsParams.QueryFilter, params.filters);
    addAwsParams(awsParams, options);
    return this.parent.dynamo.queryPromise(awsParams).then(function(data) {
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
    addAwsParams(awsParams, options);
    return this.parent.dynamo.putItemPromise(awsParams);
  };

  module.exports.updateItem = function(params, obj, options, callback, keySchema) {
    var awsParams, expressionAttributeNames, expressionAttributeValues, i, j, key, len, ref, updateExpression;
    key = getKey(params, keySchema);
    // Set up the Expression Attribute Values map.
    expressionAttributeValues = _.mapKeys(obj, function(value, key) {
      return ':' + key;
    });
    expressionAttributeValues = _.mapValues(expressionAttributeValues, function(value, key) {
      return dataTrans.toDynamo(value);
    });
    // Setup ExpressionAttributeNames mapping key -> #key so we don't bump into
    // reserved words
    expressionAttributeNames = {};
    ref = Object.keys(obj);
    for (i = j = 0, len = ref.length; j < len; i = ++j) {
      key = ref[i];
      expressionAttributeNames[`#${key}`] = key;
    }
    // Set up the Update Expression
    updateExpression = 'SET ' + _.keys(_.mapKeys(obj, function(value, key) {
      return `#${key} = :${key}`;
    })).join(',');
    awsParams = {
      TableName: this.name,
      Key: getKey(params, keySchema),
      ExpressionAttributeNames: expressionAttributeNames,
      ExpressionAttributeValues: expressionAttributeValues,
      UpdateExpression: updateExpression
    };
    addAwsParams(awsParams, options);
    return this.parent.dynamo.updateItemPromise(awsParams);
  };

}).call(this);
