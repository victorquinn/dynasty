(function() {
  var Dynasty, Table, dynamodb, _;

  dynamodb = require('dynamodb');

  _ = require('underscore');

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

    Table.prototype.find = function(opts, callback) {
      var hash, range;
      if (callback == null) {
        callback = null;
      }
      if (_.isString(opts)) {
        hash = opts;
      } else {
        hash = opts.hash, range = opts.range;
      }
      return console.log([hash, range]);
    };

    return Table;

  })();

  module.exports = Dynasty;

}).call(this);
