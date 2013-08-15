(function() {
  var Chance, Dynasty, chance, expect, getCredentials;

  expect = require('chai').expect;

  Chance = require('chance');

  Dynasty = require('../dynasty');

  chance = new Chance();

  getCredentials = function() {
    return {
      accessKeyId: chance.string({
        length: 20,
        pool: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
      }),
      secretAccessKey: chance.string({
        length: 40
      })
    };
  };

  describe('Dynasty', function() {
    describe('Base', function() {
      it('constructor exists and is a function', function() {
        return expect(require('../dynasty')).to.be.a('function');
      });
      it('can construct', function() {
        var dynasty;
        dynasty = require('../dynasty')(getCredentials());
        expect(dynasty).to.exist;
        return expect(dynasty.tables).to.exist;
      });
      return it('can retrieve a table object', function() {
        var dynasty, t;
        dynasty = require('../dynasty')(getCredentials());
        t = dynasty.table(chance.name());
        return expect(t).to.be.an('object');
      });
    });
    return describe('Table', function() {
      beforeEach(function() {
        this.dynasty = require('../dynasty')(getCredentials());
        return this.table = this.dynasty.table(chance.name());
      });
      describe('find()', function() {
        it('works with just a string', function() {
          var promise;
          promise = this.table.find(chance.name());
          return expect(promise).to.be.an('object');
        });
        it('works with an object with just a hash key', function() {
          var promise;
          promise = this.table.find({
            hash: chance.name()
          });
          return expect(promise).to.be.an('object');
        });
        return it('works with an object with both a hash and range key', function() {
          var promise;
          promise = this.table.find({
            hash: chance.name(),
            range: chance.name()
          });
          return expect(promise).to.be.an('object');
        });
      });
      return describe('describe()', function() {
        return it('returns an object', function() {
          var promise;
          promise = this.table.describe();
          return expect(promise).to.be.an('object');
        });
      });
    });
  });

}).call(this);
