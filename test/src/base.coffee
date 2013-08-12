expect = require('chai').expect
Dynasty = require('../dynasty')

describe 'Dynasty', () ->
  describe 'constructor', () ->
    it 'Base', () ->
      expect(Dynasty).to.be.a('function')
      expect(Dynasty.name).to.equal('Dynasty')
