(function() {
  var Dynasty, Q, Table, dynamodb, _;

  dynamodb = require('dynamodb');

  _ = require('lodash');

  Q = require('q');

  Dynasty = (function() {
    Dynasty.generator = function(credentials) {
      if (!(this instanceof Dynasty)) {
        return new Dynasty(credentials);
      }
    };

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

    /*
    Table Operations
    */


    Dynasty.prototype.create = function(name, params, callback) {
      var deferred;
      if (callback == null) {
        callback = null;
      }
      deferred = Q.defer();
      this.ddb.createTable(name, params.key_schema, params.throughput, function(err, resp, cap) {
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

    Dynasty.prototype.drop = function(name, callback) {
      var deferred;
      if (callback == null) {
        callback = null;
      }
      deferred = Q.defer();
      this.ddb.deleteTable(name, function(err, resp, cap) {
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

    Dynasty.prototype.alter = function(name, params, callback) {
      var deferred, throughput;
      deferred = Q.defer();
      throughput = params.throughput || params;
      this.ddb.updateTable(name, throughput, function(err, resp, cap) {
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

    return Dynasty;

  })();

  Table = (function() {
    function Table(parent, name) {
      this.parent = parent;
      this.name = name;
    }

    Table.prototype.init = function(params, options, callback) {
      var deferred, hash, range;
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
      return [hash, range, deferred, options, callback];
    };

    /*
    Item Operations
    */


    Table.prototype.find = function(params, options, callback) {
      var deferred, hash, range, _ref;
      if (options == null) {
        options = {};
      }
      if (callback == null) {
        callback = null;
      }
      _ref = this.init(params, options, callback), hash = _ref[0], range = _ref[1], deferred = _ref[2], options = _ref[3], callback = _ref[4];
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

    Table.prototype.remove = function(params, options, callback) {
      var deferred, hash, range, _ref;
      if (options == null) {
        options = {};
      }
      if (callback == null) {
        callback = null;
      }
      _ref = this.init(params, options, callback), hash = _ref[0], range = _ref[1], deferred = _ref[2], options = _ref[3], callback = _ref[4];
      this.parent.ddb.deleteItem(this.name, hash, range, options, function(err, resp, cap) {
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

    /*
    Table Operations
    */


    Table.prototype.create = function(params) {
      var callback, deferred, keyschema, name, throughput;
      name = params.name, keyschema = params.keyschema, throughput = params.throughput, callback = params.callback;
      deferred = Q.defer();
      if (throughput === null) {
        throughput = {
          write: 10,
          read: 10
        };
      }
      this.ddb.createTable(name, keyschema, throughput, function(err, resp, cap) {
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

    Table.prototype.drop = function(params) {};

    return Table;

  })();

  module.exports = Dynasty.generator;

}).call(this);
