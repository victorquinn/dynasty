(function() {
  var Q, _;

  _ = require('lodash');

  Q = require('q');

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

  module.exports.deleteItem = function(params, options, callback, keySchema) {
    var awsParams, key, promise;
    if (_.isString(params)) {
      params = {
        hash: params
      };
    }
    key = {};
    key[keySchema.hashKeyName] = {};
    key[keySchema.hashKeyName][keySchema.hashKeyType] = params.hash;
    if (params.range) {
      key[keySchema.rangeKeyName] = {};
      key[keySchema.rangeKeyName][keySchema.rangeKeyType] = params.range;
    }
    awsParams = {
      TableName: this.name,
      Key: key
    };
    promise = Q.ninvoke(this.parent.dynamo, 'deleteItem', awsParams);
    if (callback !== null) {
      promise.nodeify(callback);
    }
    return promise;
  };

}).call(this);
