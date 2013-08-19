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
    it 'constructor exists and is a function', () ->
      expect(require('../dynasty')).to.be.a('function')

    it 'can construct', () ->
      dynasty = require('../dynasty')(getCredentials())
      expect(dynasty).to.exist
      expect(dynasty.tables).to.exist

    it 'can retrieve a table object', () ->
      dynasty = require('../dynasty')(getCredentials())
      t = dynasty.table chance.name()
      expect(t).to.be.an('object')

    describe 'create()', () ->

      beforeEach () ->
        @dynasty = require('../dynasty')(getCredentials())

      it 'should return an object with valid key_schema', () ->
        promise = @dynasty.create chance.name(),
          key_schema:
            hash: [chance.name(), 'string']

        expect(promise).to.be.an('object')


  describe 'Table', () ->

    beforeEach () ->
      @dynasty = require('../dynasty')(getCredentials())
      @table = @dynasty.table chance.name()

    describe 'find()', () ->

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

    describe 'describe()', () ->

      it 'should return an object', () ->
        promise = @table.describe()
        expect(promise).to.be.an('object')

    describe 'alter()', () ->

      it 'should return an object', () ->
        promise = @table.describe()
        expect(promise).to.be.an('object')
