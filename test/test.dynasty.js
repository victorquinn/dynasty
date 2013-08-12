(function() {
  var Dynasty, expect;

  expect = require('chai').expect;

  Dynasty = require('../dynasty');

  describe('Dynasty', function() {
    return describe('constructor', function() {
      return it('Base', function() {
        expect(Dynasty).to.be.a('function');
        return expect(Dynasty.name).to.equal('Dynasty');
      });
    });
  });

}).call(this);
