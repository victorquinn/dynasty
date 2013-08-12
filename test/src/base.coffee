expect = require('chai').expect
Chance = require('chance')
Dynasty = require('../dynasty')

chance = new Chance()

getCredentials = () ->
  accessKeyId: chance.string
    length: 20
    pool: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  secretAccessKey: chance.string
    length: 40

describe 'Dynasty', () ->
  describe 'Base', () ->
    it 'constructor exists', () ->
      expect(Dynasty).to.be.a('function')
      expect(Dynasty.name).to.equal('Dynasty')

    it 'can construct', () ->
      dynasty = new Dynasty getCredentials()
      expect(dynasty).to.exist
      expect(dynasty.tables).to.exist

    it 'can retrieve a table object', () ->
      dynasty = new Dynasty getCredentials()
      t = dynasty.table chance.name()
      expect(t).to.be.an('object')

  describe 'find()', () ->
    beforeEach () ->
      @dynasty = new Dynasty getCredentials()
      @table = @dynasty.table chance.name()

    it 'works with just a string', () ->
      promise = @table.find chance.name()
      expect(promise).to.be.an('object')

    it 'works with an object with just a hash key', () ->
      promise = @table.find
        hash: chance.name()
      expect(promise).to.be.an('object')

    it 'works with an object with both a hash and range key', () ->
      promise = @table.find
        hash: chance.name()
        range: chance.name()
      expect(promise).to.be.an('object')