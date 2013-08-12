(function() {
  var Dynasty, Q, Table, dynamodb, _;

  dynamodb = require('dynamodb');

  _ = require('underscore');

  Q = require('Q');

  Dynasty = (function() {
    function Dynasty(credentials) {
      if (credentials.region) {
        credentials.endpoint = "dynamodb." + credentials.region + ".amazonaws.com";
      }
      this.ddb = dynamodb.ddb(credentials);
      this.name = 'Dynasty';
      this.tables = {};
    }

    Dynasty.prototype.table = function(name) {
      return this.tables[name] = this.tables[name] || new Table(this, name);
    };

    return Dynasty;

  })();

  Table = (function() {
    function Table(parent, name) {
      this.parent = parent;
      this.name = name;
    }

    Table.prototype.find = function(params, options, callback) {
      var deferred, hash, range;
      if (options == null) {
        options = {};
      }
      if (callback == null) {
        callback = null;
      }
      if (_.isFunction(options)) {
        callback = options;
        options = {};
      }
      if (_.isString(params)) {
        hash = params;
      } else {
        hash = params.hash, range = params.range;
      }
      if (!range) {
        range = null;
      }
      deferred = Q.defer();
      this.parent.ddb.getItem(this.name, hash, range, options, function(err, resp, cap) {
        if (err) {
          deferred.reject(err);
        } else {
          deferred.resolve(resp);
        }
        if (callback !== null) {
          return callback(err, resp);
        }
      });
      return deferred.promise;
    };

    Table.prototype.insert = function(obj, options, callback) {
      var deferred;
      if (options == null) {
        options = {};
      }
      if (callback == null) {
        callback = null;
      }
      if (_.isFunction(options)) {
        callback = options;
        options = {};
      }
      deferred = Q.defer();
      this.parent.ddb.putItem(this.name, obj, options, function(err, resp, cap) {
        if (err) {
          deferred.reject(err);
        } else {
          deferred.resolve(resp);
        }
        if (callback !== null) {
          return callback(err, resp);
        }
      });
      return deferred.promise;
    };

    return Table;

  })();

  module.exports = Dynasty;

}).call(this);
