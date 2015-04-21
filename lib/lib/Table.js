(function() {
  var Table, awsTrans, dataTrans, debug, _;

  awsTrans = require('./aws-translators');

  dataTrans = require('./data-translators');

  _ = require('lodash');

  debug = require('debug')('dynasty');

  Table = (function() {
    function Table(parent, name) {
      this.parent = parent;
      this.name = name;
      this.update = this.insert;
      this.key = this.describe().then(awsTrans.getKeySchema).then((function(_this) {
        return function(keySchema) {
          _this.hasRangeKey = 4 === _.size(_.compact(_.values(keySchema)));
          return keySchema;
        };
      })(this));
    }


    /*
    Item Operations
     */

    Table.prototype.batchFind = function(params, callback) {
      if (callback == null) {
        callback = null;
      }
      debug("batchFind() - " + params);
      return this.key.then(awsTrans.batchGetItem.bind(this, params, callback));
    };

    Table.prototype.findAll = function(params, callback) {
      if (callback == null) {
        callback = null;
      }
      debug("findAll() - " + params);
      return this.key.then(awsTrans.queryByHashKey.bind(this, params, callback));
    };

    Table.prototype.find = function(params, options, callback) {
      if (options == null) {
        options = {};
      }
      if (callback == null) {
        callback = null;
      }
      debug("find() - " + params);
      return this.key.then(awsTrans.getItem.bind(this, params, options, callback));
    };

    Table.prototype.scan = function(params, options, callback) {
      if (options == null) {
        options = {};
      }
      if (callback == null) {
        callback = null;
      }
      debug("scan() - " + params);
      return this.key.then(awsTrans.scan.bind(this, params, options, callback));
    };

    Table.prototype.insert = function(obj, options, callback) {
      if (options == null) {
        options = {};
      }
      if (callback == null) {
        callback = null;
      }
      debug("insert() - " + JSON.stringify(obj));
      if (_.isFunction(options)) {
        callback = options;
        options = {};
      }
      return this.key.then(awsTrans.putItem.bind(this, obj, options, callback));
    };

    Table.prototype.remove = function(params, options, callback) {
      if (callback == null) {
        callback = null;
      }
      return this.key.then(awsTrans.deleteItem.bind(this, params, options, callback));
    };


    /*
    Table Operations
     */

    Table.prototype.describe = function(callback) {
      if (callback == null) {
        callback = null;
      }
      debug('describe() - ' + this.name);
      return this.parent.dynamo.describeTableAsync({
        TableName: this.name
      }).nodeify(callback);
    };

    Table.prototype.drop = function(callback) {
      if (callback == null) {
        callback = null;
      }
      return this.parent.drop(this.name, callback);
    };

    return Table;

  })();

  module.exports = Table;

}).call(this);
