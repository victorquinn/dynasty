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
      it('constructor exists', function() {
        expect(Dynasty).to.be.a('function');
        return expect(Dynasty.name).to.equal('Dynasty');
      });
      it('can construct', function() {
        var dynasty;
        dynasty = new Dynasty(getCredentials());
        expect(dynasty).to.exist;
        return expect(dynasty.tables).to.exist;
      });
      return it('can retrieve a table object', function() {
        var dynasty, t;
        dynasty = new Dynasty(getCredentials());
        t = dynasty.table(chance.name());
        return expect(t).to.be.an('object');
      });
    });
    return describe('find()', function() {
      beforeEach(function() {
        this.dynasty = new Dynasty(getCredentials());
        return this.table = this.dynasty.table(chance.name());
      });
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
  });

}).call(this);
